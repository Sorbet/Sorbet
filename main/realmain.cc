// has to be included first as it violates our poisons
#include "core/proto/proto.h"

#include "absl/debugging/symbolize.h"
#include "absl/strings/str_cat.h"
#include "common/statsd/statsd.h"
#include "core/Error.h"
#include "core/Files.h"
#include "core/Unfreeze.h"
#include "core/errors/errors.h"
#include "core/lsp/QueryResponse.h"
#include "core/serialize/serialize.h"
#include "dsl/custom/CustomReplace.h"
#include "main/autogen/autogen.h"
#include "main/lsp/lsp.h"
#include "main/pipeline/pipeline.h"
#include "main/realmain.h"
#include "payload/binary/binary.h"
#include "payload/text/text.h"
#include "resolver/resolver.h"
#include "spdlog/sinks/basic_file_sink.h"
#include "spdlog/sinks/stdout_color_sinks.h"
#include "version/version.h"

#include <csignal>
#include <poll.h>
#include <sys/resource.h> // getrusage

namespace spd = spdlog;

using namespace std;

namespace sorbet::realmain {
shared_ptr<spd::logger> logger;
int returnCode;

shared_ptr<spd::sinks::ansicolor_stderr_sink_mt> make_stderr_color_sink() {
    auto color_sink = make_shared<spd::sinks::ansicolor_stderr_sink_mt>();
    color_sink->set_color(spd::level::info, color_sink->white);
    color_sink->set_color(spd::level::debug, color_sink->magenta);
    return color_sink;
}

shared_ptr<spd::sinks::ansicolor_stderr_sink_mt> stderr_color_sink = make_stderr_color_sink();

constexpr string_view GLOBAL_STATE_KEY = "GlobalState"sv;

void createInitialGlobalState(unique_ptr<core::GlobalState> &gs, shared_ptr<spd::logger> &logger,
                              const options::Options &options, unique_ptr<KeyValueStore> &kvstore) {
    if (kvstore) {
        auto maybeGsBytes = kvstore->read(GLOBAL_STATE_KEY);
        if (maybeGsBytes) {
            Timer timeit(logger, "read_global_state.kvstore");
            core::serialize::Serializer::loadGlobalState(*gs, maybeGsBytes);
            for (unsigned int i = 1; i < gs->filesUsed(); i++) {
                core::FileRef fref(i);
                if (fref.data(*gs, true).sourceType == core::File::Type::Normal) {
                    gs = core::GlobalState::markFileAsTombStone(move(gs), fref);
                }
            }
            return;
        }
    }
    if (options.noStdlib) {
        gs->initEmpty();
        return;
    }

    const u1 *const nameTablePayload = getNameTablePayload;
    if (nameTablePayload == nullptr) {
        gs->initEmpty();
        Timer timeit(logger, "read_global_state.source");

        vector<core::FileRef> payloadFiles;
        {
            core::UnfreezeFileTable fileTableAccess(*gs);
            for (auto &p : rbi::all()) {
                auto file = gs->enterFile(p.first, p.second);
                file.data(*gs).sourceType = core::File::PayloadGeneration;
                payloadFiles.emplace_back(move(file));
            }
        }
        options::Options emptyOpts;
        WorkerPool workers(emptyOpts.threads, logger);
        vector<string> empty;
        vector<dsl::custom::CustomReplace> noDSLs;
        auto indexed = pipeline::index(gs, empty, payloadFiles, emptyOpts, workers, kvstore, noDSLs, logger);
        pipeline::resolve(*gs, move(indexed), emptyOpts, logger); // result is thrown away
    } else {
        Timer timeit(logger, "read_global_state.binary");
        core::serialize::Serializer::loadGlobalState(*gs, nameTablePayload);
    }
}

/*
 * Workaround https://bugzilla.mindrot.org/show_bug.cgi?id=2863 ; We are
 * commonly run under ssh with a controlmaster, and we write exclusively to
 * STDERR in normal usage. If the client goes away, we can hang forever writing
 * to a full pipe buffer on stderr.
 *
 * Workaround by monitoring for STDOUT to go away and self-HUPing.
 */
void startHUPMonitor() {
    thread monitor([]() {
        struct pollfd pfd;
        setCurrentThreadName("HUPMonitor");
        pfd.fd = 1; // STDOUT
        pfd.events = 0;
        pfd.revents = 0;
        while (true) {
            int rv = poll(&pfd, 1, -1);
            if (rv <= 0) {
                continue;
            }
            if ((pfd.revents & (POLLHUP | POLLERR)) != 0) {
                // STDOUT has gone away; Exit via SIGHUP.
                kill(getpid(), SIGHUP);
            }
        }
    });
    monitor.detach();
}

void addStandardMetrics() {
    prodCounterAdd("release.build_scm_commit_count", Version::build_scm_commit_count);
    prodCounterAdd("release.build_timestamp",
                   chrono::duration_cast<std::chrono::seconds>(Version::build_timestamp.time_since_epoch()).count());

    struct rusage usage;
    getrusage(RUSAGE_SELF, &usage);
    prodCounterAdd("run.utilization.user_time.us", usage.ru_utime.tv_sec * 1000'000 + usage.ru_utime.tv_usec);
    prodCounterAdd("run.utilization.system_time.us", usage.ru_stime.tv_sec * 1000'000 + usage.ru_stime.tv_usec);
    prodCounterAdd("run.utilization.max_rss", usage.ru_maxrss);
    prodCounterAdd("run.utilization.minor_faults", usage.ru_minflt);
    prodCounterAdd("run.utilization.major_faults", usage.ru_majflt);
    prodCounterAdd("run.utilization.inblock", usage.ru_inblock);
    prodCounterAdd("run.utilization.oublock", usage.ru_oublock);
    prodCounterAdd("run.utilization.context_switch.voluntary", usage.ru_nvcsw);
    prodCounterAdd("run.utilization.context_switch.involuntary", usage.ru_nivcsw);
}

int realmain(int argc, char *argv[]) {
    absl::InitializeSymbolizer(argv[0]);
    returnCode = 0;
    logger = make_shared<spd::logger>("console", stderr_color_sink);
    logger->set_level(spd::level::trace); // pass through everything, let the sinks decide
    logger->set_pattern("%v");
    fatalLogger = logger;

    auto typeErrorsConsole = make_shared<spd::logger>("typeDiagnostics", stderr_color_sink);
    typeErrorsConsole->set_pattern("%v");

    options::Options opts;
    options::readOptions(opts, argc, argv, logger);
    while (opts.waitForDebugger && !stopInDebugger()) {
        // spin
    }
    if (opts.stdoutHUPHack) {
        startHUPMonitor();
    }
    if (!opts.debugLogFile.empty()) {
        auto fileSink = make_shared<spdlog::sinks::basic_file_sink_mt>(opts.debugLogFile);
        fileSink->set_level(spd::level::debug);
        { // replace console & fatal loggers
            vector<spd::sink_ptr> sinks{stderr_color_sink, fileSink};
            auto combinedLogger = make_shared<spd::logger>("consoleAndFile", begin(sinks), end(sinks));
            combinedLogger->flush_on(spdlog::level::err);
            combinedLogger->set_level(spd::level::trace); // pass through everything, let the sinks decide

            spd::register_logger(combinedLogger);
            fatalLogger = combinedLogger;
            logger = combinedLogger;
        }
        { // replace type error logger
            vector<spd::sink_ptr> sinks{stderr_color_sink, fileSink};
            auto combinedLogger = make_shared<spd::logger>("typeDiagnosticsAndFile", begin(sinks), end(sinks));
            spd::register_logger(combinedLogger);
            combinedLogger->set_level(spd::level::trace); // pass through everything, let the sinks decide
            typeErrorsConsole = combinedLogger;
        }
    }
    // Use a custom formatter so we don't get a default newline

    switch (opts.logLevel) {
        case 0:
            stderr_color_sink->set_level(spd::level::info);
            break;
        case 1:
            stderr_color_sink->set_level(spd::level::debug);
            logger->set_pattern("[T%t][%Y-%m-%dT%T.%f] %v");
            logger->debug("Debug logging enabled");
            break;
        default:
            stderr_color_sink->set_level(spd::level::trace);
            logger->set_pattern("[T%t][%Y-%m-%dT%T.%f] %v");
            logger->trace("Trace logging enabled");
            break;
    }

    {
        string argsConcat(argv[0]);
        for (int i = 1; i < argc; i++) {
            absl::StrAppend(&argsConcat, " ", argv[i]);
        }
        logger->debug("Running sorbet version {} with arguments: {}", Version::full_version_string, argsConcat);
        if (!Version::isReleaseBuild && !opts.silenceDevMessage &&
            std::getenv("SORBET_SILENCE_DEV_MESSAGE") == nullptr) {
            logger->info("👋 Hey there! Heads up that this is not a release build of sorbet.\n"
                         "Release builds are faster and more well-supported by the Sorbet team.\n"
                         "Check out the README to learn how to build Sorbet in release mode.\n"
                         "To forcibly silence this error, either pass --silence-dev-message,\n"
                         "or set SORBET_SILENCE_DEV_MESSAGE=1 in your shell environment.\n");
        }
    }
    WorkerPool workers(opts.threads, logger);

    unique_ptr<core::GlobalState> gs =
        make_unique<core::GlobalState>((make_shared<core::ErrorQueue>(*typeErrorsConsole, *logger)));
    vector<ast::ParsedFile> indexed;

    logger->trace("building initial global state");
    unique_ptr<KeyValueStore> kvstore;
    if (!opts.cacheDir.empty()) {
        kvstore = make_unique<KeyValueStore>(Version::full_version_string, opts.cacheDir);
    }
    createInitialGlobalState(gs, logger, opts, kvstore);
    if (opts.silenceErrors) {
        gs->silenceErrors = true;
    }
    if (opts.autocorrect) {
        gs->autocorrect = true;
    }
    if (opts.suggestRuntimeProfiledType) {
        gs->suggestRuntimeProfiledType = true;
    }
    if (opts.reserveMemKiB > 0) {
        gs->reserveMemory(opts.reserveMemKiB);
    }
    for (auto code : opts.errorCodeWhiteList) {
        gs->onlyShowErrorClass(code);
    }
    for (auto code : opts.errorCodeBlackList) {
        gs->suppressErrorClass(code);
    }
    logger->trace("done building initial global state");

    if (opts.runLSP) {
        gs->errorQueue->ignoreFlushes = true;
        logger->debug("Starting sorbet version {} in LSP server mode. "
                      "Talk ‘\\r\\n’-separated JSON-RPC to me. "
                      "More details at https://microsoft.github.io/language-server-protocol/specification."
                      "If you're developing an LSP extension to some editor, make sure to run sorbet with `-v` flag,"
                      "it will enable outputing the LSP session to stderr(`Write: ` and `Read: ` log lines)",
                      Version::full_version_string);
        lsp::LSPLoop loop(move(gs), opts, logger, workers, cin, cout);
        gs = loop.runLSP();
    } else {
        Timer timeall(logger, "wall_time");
        vector<core::FileRef> inputFiles;
        logger->trace("Files: ");
        {
            core::UnfreezeFileTable fileTableAccess(*gs);
            if (!opts.inlineInput.empty()) {
                prodCounterAdd("types.input.bytes", opts.inlineInput.size());
                prodCounterInc("types.input.lines");
                prodCounterInc("types.input.files");
                auto file = gs->enterFile(string("-e"), opts.inlineInput + '\n');
                inputFiles.emplace_back(file);
                if (opts.forceMaxStrict < core::StrictLevel::Typed) {
                    logger->error("`-e` is incompatible with `--typed=ruby`");
                    return 1;
                }
                file.data(*gs).strict = core::StrictLevel::Typed;
            }
        }

        vector<dsl::custom::CustomReplace> customDSLs;
        {
            Timer timeit(logger, "build_custom_dsls");
            string dslSpec;
            for (const auto &dslSpecPath : opts.dslSpecPaths) {
                try {
                    dslSpec = FileOps::read(dslSpecPath);
                } catch (FileNotFoundException e) {
                    logger->error("File for DSL spec not found: \"{}\"", dslSpecPath);
                    return 1;
                }
                auto customReplace = dsl::custom::CustomReplace::parseDefinition(*gs, dslSpec);
                if (customReplace.has_value()) {
                    customDSLs.emplace_back(std::move(*customReplace));
                } else {
                    gs->errorQueue->flushErrors(true);
                    return 1;
                }
            }
        }

        {
            Timer timeit(logger, "index");
            indexed = pipeline::index(gs, opts.inputFileNames, inputFiles, opts, workers, kvstore, customDSLs, logger);
        }

        if (kvstore && gs->wasModified() && !gs->hadCriticalError()) {
            Timer timeit(logger, "write_global_state.kvstore");
            kvstore->write(GLOBAL_STATE_KEY, core::serialize::Serializer::storePayloadAndNameTable(*gs));
            KeyValueStore::commit(move(kvstore));
        }

        if (opts.print.Autogen || opts.print.AutogenMsgPack) {
            gs->suppressErrorClass(core::errors::Namer::MethodNotFound.code);
            gs->suppressErrorClass(core::errors::Namer::RedefinitionOfMethod.code);
            gs->suppressErrorClass(core::errors::Namer::ModuleKindRedefinition.code);
            gs->suppressErrorClass(core::errors::Resolver::StubConstant.code);

            core::MutableContext ctx(*gs, core::Symbols::root());

            indexed = pipeline::name(*gs, move(indexed), opts, logger);
            {
                core::UnfreezeNameTable nameTableAccess(*gs);
                core::UnfreezeSymbolTable symbolAccess(*gs);

                vector<core::ErrorRegion> errs;
                for (auto &tree : indexed) {
                    auto file = tree.file;
                    errs.emplace_back(*gs, file);
                }
                indexed = resolver::Resolver::runConstantResolution(ctx, move(indexed));
            }

            Timer timeit(logger, "autogen");
            for (auto &tree : indexed) {
                if (tree.file.data(ctx).isRBI()) {
                    continue;
                }
                auto pf = autogen::Autogen::generate(ctx, move(tree));
                tree = move(pf.tree);

                if (opts.print.Autogen) {
                    fmt::print("{}", pf.toString(ctx));
                }
                if (opts.print.AutogenMsgPack) {
                    fmt::print("{}", pf.toMsgpack(ctx, opts.autogenVersion));
                }
            }
        } else {
            indexed = pipeline::resolve(*gs, move(indexed), opts, logger);
            if (opts.stressFastPath) {
                for (auto &f : indexed) {
                    auto reIndexed = pipeline::indexOne(opts, *gs, f.file, kvstore, customDSLs, logger);
                    vector<ast::ParsedFile> toBeReResolved;
                    toBeReResolved.emplace_back(move(reIndexed));
                    auto reresolved = pipeline::incrementalResolve(*gs, move(toBeReResolved), opts, logger);
                    ENFORCE(reresolved.size() == 1);
                    f = move(reresolved[0]);
                }
            }
            indexed = pipeline::typecheck(gs, move(indexed), opts, workers, logger);
        }

        gs->errorQueue->flushErrors(true);

        if (!opts.noErrorCount) {
            gs->errorQueue->flushErrorCount();
        }
        if (opts.autocorrect) {
            gs->errorQueue->flushAutocorrects(*gs);
        }
        logger->trace("sorbet done");

        if (opts.suggestTyped) {
            for (auto &tree : indexed) {
                auto f = tree.file;
                if (!f.data(*gs).hadErrors() && f.data(*gs).sigil == core::StrictLevel::Stripe) {
                    counterInc("types.input.files.suggest_typed");
                    logger->error("You could add `# typed: true` to: `{}`", f.data(*gs).path());
                }
            }
        }

        if (!opts.storeState.empty()) {
            gs->markAsPayload();
            FileOps::write(opts.storeState.c_str(), core::serialize::Serializer::store(*gs));
        }

        auto untypedSources = getAndClearHistogram("untyped.sources");
        if (opts.suggestSig) {
            ENFORCE(sorbet::debug_mode);
            vector<pair<string, int>> withNames;
            long sum = 0;
            for (auto e : untypedSources) {
                withNames.emplace_back(core::SymbolRef(*gs, e.first).data(*gs, true)->fullName(*gs), e.second);
                sum += e.second;
            }
            fast_sort(withNames, [](const auto &lhs, const auto &rhs) -> bool { return lhs.second > rhs.second; });
            for (auto &p : withNames) {
                logger->error("Typing `{}` would impact {}% callsites({} out of {}).", p.first, p.second * 100.0 / sum,
                              p.second, sum);
            }
        }
    }

    addStandardMetrics();

    if (!opts.someCounters.empty()) {
        if (opts.enableCounters) {
            logger->error("Don't pass both --counters and --counter");
            return 1;
        }
        logger->warn("" + getCounterStatistics(opts.someCounters));
    }

    if (opts.enableCounters) {
        logger->warn("" + getCounterStatistics(Counters::ALL_COUNTERS));
    } else {
        logger->debug("" + getCounterStatistics(Counters::ALL_COUNTERS));
    }

    auto counters = getAndClearThreadCounters();

    if (!opts.statsdHost.empty()) {
        auto prefix = opts.statsdPrefix;
        if (opts.runLSP) {
            prefix += ".lsp";
        }
        StatsD::submitCounters(counters, opts.statsdHost, opts.statsdPort, prefix + ".counters");
    }

    if (!opts.metricsFile.empty()) {
        auto metrics = core::Proto::toProto(counters, opts.metricsPrefix);
        string status;
        if (gs->hadCriticalError()) {
            status = "Error";
        } else if (returnCode != 0) {
            status = "Failure";
        } else {
            status = "Success";
        }

        if (opts.suggestTyped) {
            for (auto &tree : indexed) {
                auto f = tree.file;
                if (f.data(*gs).sigil == core::StrictLevel::Stripe) {
                    auto *metric = metrics.add_metrics();
                    metric->set_name(absl::StrCat(opts.metricsPrefix, ".suggest.", f.data(*gs).path()));
                    metric->set_value(!f.data(*gs).hadErrors());
                }
            }
        }

        metrics.set_repo(opts.metricsRepo);
        metrics.set_branch(opts.metricsBranch);
        metrics.set_sha(opts.metricsSha);
        metrics.set_status(status);

        auto json = core::Proto::toJSON(metrics);
        FileOps::write(opts.metricsFile, json);
    }
    if (gs->hadCriticalError()) {
        returnCode = 10;
    } else if (returnCode == 0 && gs->totalErrors() > 0 && !opts.supressNonCriticalErrors) {
        returnCode = 1;
    }

    if (!sorbet::emscripten_build) {
        // Let it go: leak memory so that we don't need to call destructors
        for (auto &e : indexed) {
            intentionallyLeakMemory(e.tree.release());
        }
        intentionallyLeakMemory(gs.release());
    }

    // je_malloc_stats_print(nullptr, nullptr, nullptr); // uncomment this to print jemalloc statistics

    return returnCode;
}

} // namespace sorbet::realmain
