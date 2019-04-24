#include "common/Timer.h"
#include "lsp.h"

using namespace std;

namespace sorbet::realmain::lsp {

unique_ptr<core::GlobalState> LSPLoop::processRequest(unique_ptr<core::GlobalState> gs, const string &json) {
    unique_ptr<LSPMessage> msg = LSPMessage::fromClient(json);
    return LSPLoop::processRequest(move(gs), *msg);
}


unique_ptr<core::GlobalState> LSPLoop::processRequest(unique_ptr<core::GlobalState> gs, LSPMessage &msg) {
    Timer timeit(logger, "process_request");
    return processRequestInternal(move(gs), msg);
}

unique_ptr<core::GlobalState> LSPLoop::processRequests(unique_ptr<core::GlobalState> gs,
                                                       vector<unique_ptr<LSPMessage>> messages) {
    LSPLoop::QueueState state{{}, false, false, 0};
    for (auto &message : messages) {
        enqueueRequest(logger, state, move(message));
    }
    ENFORCE(state.paused == false, "__PAUSE__ not supported in single-threaded mode.");

    for (auto &message : state.pendingRequests) {
        gs = processRequest(move(gs), *message);
    }
    return gs;
}

unique_ptr<core::GlobalState> LSPLoop::processRequestInternal(unique_ptr<core::GlobalState> gs, LSPMessage &msg) {
    if (handleReplies(msg)) {
        return gs;
    }

    const LSPMethod method = msg.method();

    if (!ensureInitialized(method, msg, gs)) {
        return gs;
    }
    if (msg.isNotification()) {
        Timer timeit(logger, fmt::format("notification {}", convertLSPMethodToString(method)));
        auto &params = msg.asNotification().params;
        if (method == LSPMethod::TextDocumentDidChange) {
            prodCategoryCounterInc("lsp.messages.processed", "textDocument.didChange");
            vector<shared_ptr<core::File>> files;
            auto &edits = get<unique_ptr<DidChangeTextDocumentParams>>(params);
            auto sorbetEdit = make_unique<SorbetWorkspaceEdit>(SorbetWorkspaceEditType::EditorChange, move(edits));
            return handleSorbetWorkspaceEdit(move(gs), sorbetEdit);
        }
        if (method == LSPMethod::TextDocumentDidOpen) {
            prodCategoryCounterInc("lsp.messages.processed", "textDocument.didOpen");
            auto &edits = get<unique_ptr<DidOpenTextDocumentParams>>(params);
            auto sorbetEdit = make_unique<SorbetWorkspaceEdit>(SorbetWorkspaceEditType::EditorOpen, move(edits));
            return handleSorbetWorkspaceEdit(move(gs), sorbetEdit);
        }
        if (method == LSPMethod::TextDocumentDidClose) {
            prodCategoryCounterInc("lsp.messages.processed", "textDocument.didClose");
            auto &edits = get<unique_ptr<DidCloseTextDocumentParams>>(params);
            auto sorbetEdit = make_unique<SorbetWorkspaceEdit>(SorbetWorkspaceEditType::EditorClose, move(edits));
            return handleSorbetWorkspaceEdit(move(gs), sorbetEdit);
        }
        if (method == LSPMethod::SorbetWatchmanFileChange) {
            prodCategoryCounterInc("lsp.messages.processed", "sorbet/watchmanFileChange");
            auto &queryResponse = get<unique_ptr<WatchmanQueryResponse>>(params);
            auto sorbetEdit =
                make_unique<SorbetWorkspaceEdit>(SorbetWorkspaceEditType::FileSystem, move(queryResponse));
            return handleSorbetWorkspaceEdit(move(gs), sorbetEdit);
        }
        if (method == LSPMethod::SorbetWorkspaceEdit) {
            // Note: We increment `lsp.messages.processed` when the original requests were merged into this one.
            auto &editParams = get<unique_ptr<SorbetWorkspaceEditParams>>(params);
            auto &edits = editParams->changes;
            auto &counts = editParams->counts;
            prodCategoryCounterAdd("lsp.messages.processed", "textDocument.didChange", counts->textDocumentDidChange);
            prodCategoryCounterAdd("lsp.messages.processed", "textDocument.didOpen", counts->textDocumentDidOpen);
            prodCategoryCounterAdd("lsp.messages.processed", "textDocument.didClose", counts->textDocumentDidClose);
            prodCategoryCounterAdd("lsp.messages.processed", "sorbet/watchmanFileChange",
                                   counts->sorbetWatchmanFileChange);
            // Number of messages merged together into a workspace edit.
            prodCounterAdd("lsp.messages.merged", (counts->textDocumentDidChange + counts->textDocumentDidOpen +
                                                   counts->textDocumentDidClose + counts->sorbetWatchmanFileChange) -
                                                      1);
            if (!initialized) {
                for (auto &edit : edits) {
                    if (edit->type != SorbetWorkspaceEditType::FileSystem) {
                        logger->error("Serving request before got an Initialize & Initialized handshake from IDE");
                        return gs;
                    }
                }
            }
            return handleSorbetWorkspaceEdits(move(gs), edits);
        }
        if (method == LSPMethod::Initialized) {
            prodCategoryCounterInc("lsp.messages.processed", "initialized");
            // initialize ourselves
            unique_ptr<core::GlobalState> newGs;
            {
                Timer timeit(logger, "initial_index");
                reIndexFromFileSystem();
                vector<shared_ptr<core::File>> changedFiles;
                newGs = pushDiagnostics(runSlowPath(move(changedFiles)));
                ENFORCE(newGs);
                if (!disableFastPath) {
                    this->globalStateHashes = computeStateHashes(newGs->getFiles());
                }
                initialized = true;
            }

            // process deferred watchman updates
            auto deferredFileEditsClone = move(deferredFileEdits);
            deferredFileEdits.clear();
            return handleSorbetWorkspaceEdits(move(newGs), deferredFileEditsClone);
        }
        if (method == LSPMethod::Exit) {
            prodCategoryCounterInc("lsp.messages.processed", "exit");
            return gs;
        }
        if (method == LSPMethod::SorbetError) {
            auto &errorInfo = get<unique_ptr<SorbetErrorParams>>(params);
            if (errorInfo->code == (int)LSPErrorCodes::MethodNotFound) {
                // Not an error; we just don't care about this notification type.
                logger->info(errorInfo->message);
            } else {
                logger->error(errorInfo->message);
            }
            return gs;
        }
    } else if (msg.isRequest()) {
        Timer timeit(logger, fmt::format("request {}", convertLSPMethodToString(method)));
        auto &requestMessage = msg.asRequest();
        // asRequest() should guarantee the presence of an ID.
        ENFORCE(msg.id());
        auto id = *msg.id();
        ResponseMessage response("2.0", id, method);
        if (msg.canceled) {
            prodCounterInc("lsp.messages.canceled");
            response.error = make_unique<ResponseError>((int)LSPErrorCodes::RequestCancelled, "Request was canceled");
            sendResponse(response);
            return gs;
        }

        auto &rawParams = requestMessage.params;
        if (method == LSPMethod::Initialize) {
            prodCategoryCounterInc("lsp.messages.processed", "initialize");
            auto &params = get<unique_ptr<InitializeParams>>(rawParams);
            if (auto rootUriString = get_if<string>(&params->rootUri)) {
                rootUri = *rootUriString;
            }
            clientCompletionItemSnippetSupport = false;
            if (params->capabilities->textDocument) {
                auto &textDocument = *params->capabilities->textDocument;
                if (textDocument->completion) {
                    auto &completion = *textDocument->completion;
                    if (completion->completionItem) {
                        clientCompletionItemSnippetSupport =
                            (*completion->completionItem)->snippetSupport.value_or(false);
                    }
                }
            }

            if (params->initializationOptions) {
                auto &initOptions = *params->initializationOptions;
                enableOperationNotifications = initOptions->supportsOperationNotifications.value_or(false);
            }

            auto serverCap = make_unique<ServerCapabilities>();
            serverCap->textDocumentSync = TextDocumentSyncKind::Full;
            serverCap->definitionProvider = opts.lspGoToDefinitionEnabled;
            serverCap->documentSymbolProvider = opts.lspDocumentSymbolEnabled;
            serverCap->workspaceSymbolProvider = opts.lspWorkspaceSymbolsEnabled;
            serverCap->hoverProvider = opts.lspHoverEnabled;
            serverCap->referencesProvider = opts.lspFindReferencesEnabled;

            if (opts.lspSignatureHelpEnabled) {
                auto sigHelpProvider = make_unique<SignatureHelpOptions>();
                sigHelpProvider->triggerCharacters = {"(", ","};
                serverCap->signatureHelpProvider = move(sigHelpProvider);
            }

            if (opts.lspAutocompleteEnabled) {
                auto completionProvider = make_unique<CompletionOptions>();
                completionProvider->triggerCharacters = {"."};
                serverCap->completionProvider = move(completionProvider);
            }

            response.result = make_unique<InitializeResult>(move(serverCap));
            sendResponse(response);
        } else if (method == LSPMethod::TextDocumentDocumentSymbol) {
            auto &params = get<unique_ptr<DocumentSymbolParams>>(rawParams);
            return handleTextDocumentDocumentSymbol(move(gs), id, *params);
        } else if (method == LSPMethod::WorkspaceSymbol) {
            auto &params = get<unique_ptr<WorkspaceSymbolParams>>(rawParams);
            return handleWorkspaceSymbols(move(gs), id, *params);
        } else if (method == LSPMethod::TextDocumentDefinition) {
            auto &params = get<unique_ptr<TextDocumentPositionParams>>(rawParams);
            return handleTextDocumentDefinition(move(gs), id, *params);
        } else if (method == LSPMethod::TextDocumentHover) {
            auto &params = get<unique_ptr<TextDocumentPositionParams>>(rawParams);
            return handleTextDocumentHover(move(gs), id, *params);
        } else if (method == LSPMethod::TextDocumentCompletion) {
            auto &params = get<unique_ptr<CompletionParams>>(rawParams);
            return handleTextDocumentCompletion(move(gs), id, *params);
        } else if (method == LSPMethod::TextDocumentSignatureHelp) {
            auto &params = get<unique_ptr<TextDocumentPositionParams>>(rawParams);
            return handleTextSignatureHelp(move(gs), id, *params);
        } else if (method == LSPMethod::TextDocumentReferences) {
            auto &params = get<unique_ptr<ReferenceParams>>(rawParams);
            return handleTextDocumentReferences(move(gs), id, *params);
        } else if (method == LSPMethod::Shutdown) {
            prodCategoryCounterInc("lsp.messages.processed", "shutdown");
            response.result = JSONNullObject();
            sendResponse(response);
            return gs;
        } else if (method == LSPMethod::SorbetError) {
            auto &params = get<unique_ptr<SorbetErrorParams>>(rawParams);
            response.error = make_unique<ResponseError>(params->code, params->message);
            sendResponse(response);
        } else {
            // Method parsed, but isn't a request. Use SorbetError for `requestMethod`, as `method` isn't valid for a
            // response.
            response.requestMethod = LSPMethod::SorbetError;
            response.error = make_unique<ResponseError>(
                (int)LSPErrorCodes::MethodNotFound,
                fmt::format("Notification method sent as request: {}", convertLSPMethodToString(method)));
            sendResponse(response);
        }
    } else {
        logger->debug("Unable to process request {}; LSP message is not a request.", convertLSPMethodToString(method));
    }
    return gs;
}
} // namespace sorbet::realmain::lsp
