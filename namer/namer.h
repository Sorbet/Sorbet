#ifndef SORBET_NAMER_NAMER_H
#define SORBET_NAMER_NAMER_H
#include "ast/ast.h"
#include <memory>

namespace sorbet::namer {

class Namer final {
public:
    static std::vector<ast::ParsedFile> run(core::MutableContext ctx, std::vector<ast::ParsedFile> trees);
    static ast::ParsedFile run(core::MutableContext ctx, ast::ParsedFile tree); // TODO remove

    Namer() = delete;
};

} // namespace sorbet::namer

#endif
