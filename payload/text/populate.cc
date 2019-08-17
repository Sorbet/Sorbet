#include "common/concurrency/WorkerPool.h"
#include "common/kvstore/KeyValueStore.h"
#include "core/Unfreeze.h"
#include "main/pipeline/pipeline.h"
#include "payload/text/text.h"
using namespace std;

namespace sorbet::rbi {
void polulateRBIsInto(unique_ptr<core::GlobalState> &gs) {
    gs->initEmpty();
    gs->ensureCleanStrings = true;

    vector<core::FileRef> payloadFiles;
    {
        core::UnfreezeFileTable fileTableAccess(*gs);
        for (auto &p : rbi::all()) {
            auto file = gs->enterFile(p.first, p.second);
            file.data(*gs).sourceType = core::File::PayloadGeneration;
            payloadFiles.emplace_back(move(file));
        }
    }
    realmain::options::Options emptyOpts;
    unique_ptr<KeyValueStore> kvstore;
    auto workers = WorkerPool::create(emptyOpts.threads, gs->tracer());
    auto indexed = realmain::pipeline::index(gs, payloadFiles, emptyOpts, *workers, kvstore);
    realmain::pipeline::resolve(gs, move(indexed), emptyOpts, *workers); // result is thrown away
    gs->ensureCleanStrings = false;
}

} // namespace sorbet::rbi
