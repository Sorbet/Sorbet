#ifndef RUBY_TYPER_LSP_REQUESTS_DOCUMENT_FORMAT_H
#define RUBY_TYPER_LSP_REQUESTS_DOCUMENT_FORMAT_H

#include "main/lsp/LSPTask.h"

namespace sorbet::realmain::lsp {
class DocumentFormattingParams;
class DocumentFormattingTask final : public LSPRequestTask {
    std::unique_ptr<DocumentFormattingParams> params;

public:
    DocumentFormattingTask(const LSPConfiguration &config, MessageId id,
                           std::unique_ptr<DocumentFormattingParams> params);

    // TODO(@jvilk): don't wait for type checking
    std::unique_ptr<ResponseMessage> runRequest(LSPTypecheckerDelegate &typechecker) override;
};

} // namespace sorbet::realmain::lsp

#endif
