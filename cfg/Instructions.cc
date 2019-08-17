#include "Instructions.h"

#include "common/typecase.h"
#include "core/Names.h"
#include "core/TypeConstraint.h"
#include <utility>
// helps debugging
template class std::unique_ptr<sorbet::cfg::Instruction>;

using namespace std;

namespace sorbet::cfg {

Return::Return(core::LocalVariable what) : what(what) {
    categoryCounterInc("cfg", "return");
}

string SolveConstraint::toString(core::Context ctx) {
    return fmt::format("Solve<{}>", this->link->fun.toString(ctx));
}

string Return::toString(core::Context ctx) {
    return fmt::format("return {}", this->what.toString(ctx));
}

BlockReturn::BlockReturn(shared_ptr<core::SendAndBlockLink> link, core::LocalVariable what)
    : link(std::move(link)), what(what) {
    categoryCounterInc("cfg", "blockreturn");
}

string BlockReturn::toString(core::Context ctx) {
    return fmt::format("blockreturn<{}> {}", this->link->fun.toString(ctx), this->what.toString(ctx));
}

LoadSelf::LoadSelf(shared_ptr<core::SendAndBlockLink> link, core::LocalVariable fallback)
    : link(std::move(link)), fallback(fallback) {
    categoryCounterInc("cfg", "loadself");
}

string LoadSelf::toString(core::Context ctx) {
    return "loadSelf";
}

Send::Send(core::LocalVariable recv, core::NameRef fun, core::Loc receiverLoc,
           const InlinedVector<core::LocalVariable, 2> &args, InlinedVector<core::Loc, 2> argLocs,
           const shared_ptr<core::SendAndBlockLink> &link)
    : recv(recv), fun(fun), receiverLoc(receiverLoc), argLocs(std::move(argLocs)), link(move(link)) {
    this->args.resize(args.size());
    int i = 0;
    for (const auto &e : args) {
        this->args[i].variable = e;
        i++;
    }
    categoryCounterInc("cfg", "send");
    histogramInc("cfg.send.args", this->args.size());
}

Literal::Literal(const core::TypePtr &value) : value(move(value)) {
    categoryCounterInc("cfg", "literal");
}

string Literal::toString(core::Context ctx) {
    string res;
    typecase(
        this->value.get(), [&](core::LiteralType *l) { res = l->showValue(ctx); },
        [&](core::ClassType *l) {
            if (l->symbol == core::Symbols::NilClass()) {
                res = "nil";
            } else if (l->symbol == core::Symbols::FalseClass()) {
                res = "false";
            } else if (l->symbol == core::Symbols::TrueClass()) {
                res = "true";
            } else {
                res = fmt::format("literal({})", this->value->toStringWithTabs(ctx, 0));
            }
        },
        [&](core::Type *t) { res = fmt::format("literal({})", this->value->toStringWithTabs(ctx, 0)); });
    return res;
}

Ident::Ident(core::LocalVariable what) : what(what) {
    categoryCounterInc("cfg", "ident");
}

Alias::Alias(core::SymbolRef what) : what(what) {
    categoryCounterInc("cfg", "alias");
}

string Ident::toString(core::Context ctx) {
    return this->what.toString(ctx);
}

string Alias::toString(core::Context ctx) {
    return fmt::format("alias {}", this->what.data(ctx)->name.data(ctx)->toString(ctx));
}

string Send::toString(core::Context ctx) {
    return fmt::format("{}.{}({})", this->recv.toString(ctx), this->fun.data(ctx)->toString(ctx),
                       fmt::map_join(this->args, ", ", [&](const auto &arg) -> string { return arg.toString(ctx); }));
}

string LoadArg::toString(core::Context ctx) {
    return fmt::format("load_arg({})", this->argument(ctx).argumentName(ctx));
}

const core::ArgInfo &LoadArg::argument(const core::GlobalState &gs) const {
    return this->method.data(gs)->arguments()[this->argId];
}

string LoadYieldParams::toString(core::Context ctx) {
    return fmt::format("load_yield_params({})", this->link->fun.toString(ctx));
}

string Unanalyzable::toString(core::Context ctx) {
    return "<unanalyzable>";
}

string NotSupported::toString(core::Context ctx) {
    return fmt::format("NotSupported({})", why);
}

string Cast::toString(core::Context ctx) {
    return fmt::format("cast({}, {});", this->value.toString(ctx), this->type->toString(ctx));
}

string TAbsurd::toString(core::Context ctx) {
    return fmt::format("T.absurd({})", this->what.toString(ctx));
}

string VariableUseSite::toString(core::Context ctx) const {
    if (this->type) {
        return fmt::format("{}: {}", this->variable.toString(ctx), this->type->show(ctx));
    }
    return this->variable.toString(ctx);
}
} // namespace sorbet::cfg
