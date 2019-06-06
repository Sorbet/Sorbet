#include "ast/ast.h"

namespace sorbet::ast {

class Verifier {
public:
    static std::unique_ptr<Expression> run(core::Context ctx, std::unique_ptr<Expression> node);
};

} // namespace sorbet::ast
