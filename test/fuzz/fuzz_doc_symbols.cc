#include "core/Unfreeze.h"
#include "main/pipeline/pipeline.h"
#include "payload/payload.h"
#include "spdlog/sinks/stdout_sinks.h"
#include "test/helpers/MockFileSystem.h"
#include <cstddef>
#include <cstdint>
#include <memory>

auto console = spdlog::stdout_logger_mt("console");
auto typeErrors = spdlog::stdout_logger_mt("typeErrors");

sorbet::realmain::options::Options mkOpts() {
    const auto rootPath = "/tmp";
    sorbet::realmain::options::Options opts;
    opts.fs = std::make_shared<sorbet::test::MockFileSystem>(rootPath);
    return opts;
}

std::unique_ptr<sorbet::core::GlobalState> mkGlobalState(const sorbet::realmain::options::Options &opts,
                                                         std::unique_ptr<sorbet::KeyValueStore> &kvstore) {
    std::unique_ptr<sorbet::core::GlobalState> gs = std::make_unique<sorbet::core::GlobalState>(
        (std::make_shared<sorbet::core::ErrorQueue>(*typeErrors, *console)));
    sorbet::payload::createInitialGlobalState(gs, opts, kvstore);
    return gs;
}

extern "C" int LLVMFuzzerInitialize(const int *argc, const char ***argv) {
    return 0;
}

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, const std::size_t size) {
    std::unique_ptr<sorbet::KeyValueStore> kvstore;
    const auto opts = mkOpts();
    static const auto commonGs = mkGlobalState(opts, kvstore);
    std::unique_ptr<sorbet::core::GlobalState> gs;
    // TODO why?
    { gs = commonGs->deepCopy(true); }
    std::string inputData((const char *)data, size);
    std::vector<sorbet::ast::ParsedFile> indexed;
    std::vector<sorbet::core::FileRef> inputFiles;
    {
        sorbet::core::UnfreezeFileTable fileTableAccess(*gs);
        auto file = gs->enterFile(std::string("fuzz.rb"), inputData);
        inputFiles.emplace_back(file);
        file.data(*gs).strictLevel = sorbet::core::StrictLevel::True;
    }
    static const auto workers = sorbet::WorkerPool::create(0, *console);
    indexed = sorbet::realmain::pipeline::index(gs, inputFiles, opts, *workers, kvstore);
    indexed = sorbet::realmain::pipeline::resolve(gs, std::move(indexed), opts, *workers);
    indexed = sorbet::realmain::pipeline::typecheck(gs, std::move(indexed), opts, *workers);
    return 0;
}
