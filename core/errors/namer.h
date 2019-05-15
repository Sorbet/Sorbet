#ifndef SORBET_CORE_ERRORS_NAMER_H
#define SORBET_CORE_ERRORS_NAMER_H
#include "core/Error.h"

namespace sorbet::core::errors::Namer {
constexpr ErrorClass IncludeMutipleParam{4001, StrictLevel::False};
constexpr ErrorClass AncestorNotConstant{4002, StrictLevel::False};
constexpr ErrorClass IncludePassedBlock{4003, StrictLevel::False};
// constexpr ErrorClass DynamicConstantDefinition{4004, StrictLevel::Typed};
// constexpr ErrorClass DynamicMethodDefinition{4005, StrictLevel::Typed};
constexpr ErrorClass SelfOutsideClass{4006, StrictLevel::Typed};
constexpr ErrorClass DynamicDSLInvocation{4007, StrictLevel::Typed};
constexpr ErrorClass MethodNotFound{4008, StrictLevel::Typed};
constexpr ErrorClass InvalidAlias{4009, StrictLevel::Typed};
constexpr ErrorClass RedefinitionOfMethod{4010, StrictLevel::Typed};
constexpr ErrorClass InvalidTypeDefinition{4011, StrictLevel::Typed};
constexpr ErrorClass ModuleKindRedefinition{4012, StrictLevel::False};
constexpr ErrorClass InterfaceClass{4013, StrictLevel::False};
constexpr ErrorClass DynamicConstant{4014, StrictLevel::False};
constexpr ErrorClass InvalidClassOwner{4015, StrictLevel::False};
} // namespace sorbet::core::errors::Namer

#endif
