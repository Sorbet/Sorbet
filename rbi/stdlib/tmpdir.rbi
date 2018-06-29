# typed: true

class Dir
  sig(
    prefix_suffix: T.any(String, T::Array[String]),
    rest: String,
  ).returns(String)
  def self.mktmpdir(prefix_suffix = nil, *rest); end
end
