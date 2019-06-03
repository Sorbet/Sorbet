# frozen_string_literal: true
# typed: true
# rubocop:disable PrisonGuard/NoTopLevelDeclarations, PrisonGuard/PackageMatchesDirectory

class Sorbet
  # At runtime, does nothing, but statically it is treated exactly the same
  # as T::Sig#sig. Only use it in cases where you can't use T::Sig#sig.
  def self.sig(&blk); end # rubocop:disable PrisonGuard/BanBuiltinMethodOverride

  # At runtime, does nothing, but statically it is treated exactly the same
  # as T::Sig#sig. Only use it in cases where you can't use T::Sig#sig.
  Sorbet.sig {params(blk: T.proc.bind(T::Private::Methods::DeclBuilder).void).void} # rubocop:disable PrisonGuard/PrivateModule
  def self.sig(&blk); end # rubocop:disable PrisonGuard/BanBuiltinMethodOverride, Lint/DuplicateMethods
end

# Monkeypatches standard objects so that you can call `sig` anywhere.
# Docs at http://go/types
module T::Sig
  # Declares a method with type signatures and/or
  # abstract/override/... helpers. See the documentation URL on
  # {T::Helpers}
  Sorbet.sig {params(blk: T.proc.bind(T::Private::Methods::DeclBuilder).void).void}
  def sig(&blk) # rubocop:disable PrisonGuard/BanBuiltinMethodOverride
    T::Private::Methods.declare_sig(self, &blk)
  end
end

# rubocop:enable PrisonGuard/NoTopLevelDeclarations, PrisonGuard/PackageMatchesDirectory
