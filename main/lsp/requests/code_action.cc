#include "core/lsp/QueryResponse.h"
#include "main/lsp/lsp.h"

using namespace std;

namespace sorbet::realmain::lsp {
LSPResult LSPLoop::handleTextDocumentCodeAction(unique_ptr<core::GlobalState> gs, const MessageId &id,
                                                const CodeActionParams &params) {
    auto response = make_unique<ResponseMessage>("2.0", id, LSPMethod::TextDocumentCodeAction);

    if (!opts.lspQuickFixEnabled) {
        response->error = make_unique<ResponseError>(
            (int)LSPErrorCodes::InvalidRequest, "The `Quick Fix` LSP feature is experimental and disabled by default.");
        return LSPResult::make(move(gs), move(response));
    }

    vector<unique_ptr<CodeAction>> result;

    prodCategoryCounterInc("lsp.messages.processed", "textDocument.codeAction");

    core::FileRef file = uri2FileRef(params.textDocument->uri);
    vector<shared_ptr<core::File>> files;
    files.push_back(make_shared<core::File>(string(file.data(*gs).path()), string(file.data(*gs).source()),
                                            core::File::Type::Normal));
    // Simply querying the file in question is insufficient since indexing errors would not be detected.
    auto run = tryFastPath(move(gs), files);

    for (auto &e : run.errors) {
        if (!e->isSilenced && e->loc.file() == file && !e->autocorrects.empty() &&
            cmpRanges(*loc2Range(*run.gs, e->loc), *params.range) == 0) {
            vector<unique_ptr<TextEdit>> edits;
            edits.reserve(e->autocorrects.size());
            for (auto &a : e->autocorrects) {
                edits.emplace_back(make_unique<TextEdit>(loc2Range(*run.gs, a.loc), a.replacement));
            }

            // TODO: Document version
            vector<unique_ptr<TextDocumentEdit>> documentEdits;
            documentEdits.emplace_back(make_unique<TextDocumentEdit>(
                make_unique<VersionedTextDocumentIdentifier>(params.textDocument->uri, JSONNullObject()), move(edits)));

            auto workspaceEdit = make_unique<WorkspaceEdit>();
            workspaceEdit->documentChanges = move(documentEdits);

            // TODO(sushain): improve headers, potentially by just using Insert... and Replace... with some special
            // handling for multi-line edits
            auto action = make_unique<CodeAction>(e->header);
            action->kind = CodeActionKind::Quickfix;
            action->edit = move(workspaceEdit);

            result.emplace_back(move(action));
        }
    }

    // TODO(sushain): investigate where duplicates might happen and whether there is a better fix
    // Remove any actions with the same header regardless of their actions since users cannot make an informed decision
    // between two seemingly identical actions.
    fast_sort(result, [](const auto &l, const auto &r) -> bool { return l->title.compare(r->title) > 0; });
    auto last =
        unique(result.begin(), result.end(), [](const auto &l, const auto &r) -> bool { return l->title == r->title; });
    result.erase(last, result.end());

    response->result = move(result);

    return LSPResult::make(move(run.gs), move(response));
}
} // namespace sorbet::realmain::lsp
