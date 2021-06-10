#include "rewriter/ChainedSig.h"
#include "ast/Helpers.h"
#include "ast/treemap/treemap.h"

using namespace std;
namespace sorbet::rewriter {

// Rewrite the new chained syntax into the old syntax. E.g.:
// sig.abstract { void } is rewritten as sig { abstract.void }
// Only tries to rewrite if the current send function is one of the accepted methods
// and the receiver is sig.
ast::ExpressionPtr ChainedSig::run(core::MutableContext &ctx, ast::Send *send) {
    if (send->block == nullptr) {
        return nullptr;
    }

    if (send->fun != core::Names::abstract() && send->fun != core::Names::final_() &&
        send->fun != core::Names::override_() && send->fun != core::Names::overridable()) {
        return nullptr;
    }

    auto sigSend = ast::cast_tree<ast::Send>(send->recv);

    if (sigSend->fun != core::Names::sig()) {
        return nullptr;
    }

    auto *block = ast::cast_tree<ast::Block>(send->block);
    auto blockBody = ast::cast_tree<ast::Send>(block->body);
    ast::ExpressionPtr body =
        ast::MK::Send(send->loc, std::move(blockBody->recv), send->fun, send->numPosArgs, std::move(send->args));

    auto newBody =
        ast::MK::Send(send->loc, std::move(body), blockBody->fun, blockBody->numPosArgs, std::move(blockBody->args));
    ast::Send::ARGS_store args;

    return ast::MK::Send(send->loc, std::move(sigSend->recv), core::Names::sig(), 0, std::move(args), {},
                         ast::MK::Block0(send->block.loc(), std::move(newBody)));
}
} // namespace sorbet::rewriter
