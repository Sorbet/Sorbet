#ifndef SORBET_CONTEXT_H
#define SORBET_CONTEXT_H

#include "common/common.h"
#include "core/NameRef.h"
#include "core/SymbolRef.h"
#include <vector>

namespace sorbet::core {
class GlobalState;
class MutableContext;

class Context {
public:
    const GlobalState &state;
    const SymbolRef owner;

    operator const GlobalState &() const noexcept {
        return state;
    }

    Context(const GlobalState &state, SymbolRef owner) noexcept : state(state), owner(owner) {}
    Context(const Context &other) noexcept : state(other.state), owner(other.owner) {}
    Context(const MutableContext &other) noexcept;

    bool permitOverloadDefinitions() const;

    Context withOwner(SymbolRef sym) const;

    void trace(std::string_view msg) const;
};
CheckSize(Context, 16, 8);

class MutableContext final {
public:
    GlobalState &state;
    const SymbolRef owner;
    operator GlobalState &() {
        return state;
    }

    operator const GlobalState &() const {
        return state;
    }

    // 👋 Stepped here in the debugger? Type 'finish' to step back out.
    MutableContext(GlobalState &state, SymbolRef owner) noexcept : state(state), owner(owner) {}
    MutableContext(const MutableContext &other) noexcept : state(other.state), owner(other.owner) {}

    // Returns a SymbolRef corresponding to the class `self.class` for code
    // executed in this MutableContext, or, if `self` is a class,
    // `self.singleton_class` (We model classes as being normal instances of
    // their singleton classes for most purposes)
    SymbolRef selfClass();

    bool permitOverloadDefinitions() const;

    MutableContext withOwner(SymbolRef sym) const {
        MutableContext r = MutableContext(state, sym);
        return r;
    }

    void trace(std::string_view msg) const;
};
CheckSize(MutableContext, 16, 8);

class GlobalSubstitution {
public:
    GlobalSubstitution(const GlobalState &from, GlobalState &to, const GlobalState *optionalCommonParent = nullptr);

    NameRef substitute(NameRef from, bool allowSameFromTo = false) const {
        if (!allowSameFromTo) {
            from.sanityCheckSubstitution(*this);
        }
        ENFORCE(from._id < nameSubstitution.size(),
                "name substitution index out of bounds, got {} where subsitution size is {}", std::to_string(from._id),
                std::to_string(nameSubstitution.size()));
        return nameSubstitution[from._id];
    }

    bool useFastPath() const;

private:
    friend NameRefDebugCheck;

    std::vector<NameRef> nameSubstitution;
    // set if no substitution is actually necessary
    bool fastPath;

    const int toGlobalStateId;
};

} // namespace sorbet::core

#endif // SORBET_CONTEXT_H
