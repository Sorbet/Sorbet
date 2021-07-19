#ifndef SORBET_CHAINED_SIG_H
#define SORBET_CHAINED_SIG_H

#include "ast/ast.h"

namespace sorbet::rewriter {
class ChainedSig {
public:
    static ast::ExpressionPtr run(core::MutableContext &ctx, ast::Send *send);
};
} // namespace sorbet::rewriter
#endif
