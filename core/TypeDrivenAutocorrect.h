#ifndef SORBET_TYPE_DRIVEN_AUTOCORRECT_H
#define SORBET_TYPE_DRIVEN_AUTOCORRECT_H

#include "core/Error.h"
#include "core/GlobalState.h"
#include "core/TypeConstraint.h"
#include "core/Types.h"

namespace sorbet::core {

class TypeDrivenAutocorrect final {
public:
    // Uses heuristics to insert an autocorrect that converts from `expectedType` to `actualType`.
    //
    // `loc` should be the location of the expression to fix up.
    // (It should usually be a cfg::Send::argLocs element or cfg::Return::whatLoc)
    //
    // Statefully accumulates the autocorrect directly onto the provided `ErrorBuilder`.
    static void maybeAutocorrect(const GlobalState &gs, ErrorBuilder &e, Loc loc, TypeConstraint &constr,
                                 TypePtr expectedType, TypePtr actualType);
};

} // namespace sorbet::core

#endif
