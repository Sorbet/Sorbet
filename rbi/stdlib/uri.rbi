# typed: __STDLIB_INTERNAL
module Kernel
  sig {params(uri: T.any(URI::Generic, String)).returns(URI::Generic)}
  def URI(uri); end
end

module URI
  ABS_PATH = T.let(T.unsafe(nil), Regexp)
  ABS_URI = T.let(T.unsafe(nil), Regexp)
  ABS_URI_REF = T.let(T.unsafe(nil), Regexp)
  DEFAULT_PARSER = T.let(T.unsafe(nil), URI::RFC2396_Parser)
  ESCAPED = T.let(T.unsafe(nil), Regexp)
  FRAGMENT = T.let(T.unsafe(nil), Regexp)
  HOST = T.let(T.unsafe(nil), Regexp)
  HTML5ASCIIINCOMPAT = T.let(T.unsafe(nil), String)
  OPAQUE = T.let(T.unsafe(nil), Regexp)
  PORT = T.let(T.unsafe(nil), Regexp)
  QUERY = T.let(T.unsafe(nil), Regexp)
  REGISTRY = T.let(T.unsafe(nil), Regexp)
  REL_PATH = T.let(T.unsafe(nil), Regexp)
  REL_URI = T.let(T.unsafe(nil), Regexp)
  REL_URI_REF = T.let(T.unsafe(nil), Regexp)
  RFC3986_PARSER = T.let(T.unsafe(nil), URI::RFC3986_Parser)
  SCHEME = T.let(T.unsafe(nil), Regexp)
  TBLDECWWWCOMP_ = T.let(T.unsafe(nil), Hash)
  TBLENCWWWCOMP_ = T.let(T.unsafe(nil), Hash)
  UNSAFE = T.let(T.unsafe(nil), Regexp)
  URI_REF = T.let(T.unsafe(nil), Regexp)
  USERINFO = T.let(T.unsafe(nil), Regexp)
  VERSION = T.let(T.unsafe(nil), String)
  VERSION_CODE = T.let(T.unsafe(nil), String)
  WEB_ENCODINGS_ = T.let(T.unsafe(nil), Hash)

  sig do
    params(
        str: String,
        enc: Encoding,
    )
    .returns(T::Array[[String, String]])
  end
  def self.decode_www_form_component(str, enc=T.unsafe(nil)); end

  sig do
    params(
        arg: String,
        arg0: Regexp,
    )
    .returns(String)
  end
  sig do
    params(
        arg: String,
        arg0: String,
    )
    .returns(String)
  end
  def self.escape(arg, *arg0); end

  sig do
    params(
        str: String,
        schemes: Array,
        blk: BasicObject,
    )
    .returns(T::Array[String])
  end
  def self.extract(str, schemes=T.unsafe(nil), &blk); end

  sig do
    params(
        str: T.any(URI::Generic, String),
    )
    .returns(URI::Generic)
  end
  def self.join(*str); end

  sig do
    params(
        uri: String,
    )
    .returns(URI::HTTP)
  end
  def self.parse(uri); end

  sig do
    params(
        schemes: Array,
    )
    .returns(T::Array[String])
  end
  def self.regexp(schemes=T.unsafe(nil)); end

  sig {returns(T::Hash[String, Class])}
  def self.scheme_list(); end

  sig do
    params(
        uri: String,
    )
    .returns(T::Array[T.nilable(String)])
  end
  def self.split(uri); end

  sig do
    params(
        arg: String,
    )
    .returns(String)
  end
  def self.unescape(*arg); end

  sig do
    params(
        arg: String,
        arg0: Regexp,
    )
    .returns(String)
  end
  sig do
    params(
        arg: String,
        arg0: String,
    )
    .returns(String)
  end
  def self.encode(arg, *arg0); end

  sig do
    params(
        arg: String,
    )
    .returns(String)
  end
  def self.decode(*arg); end
end

class URI::BadURIError < URI::Error
end

class URI::Error < StandardError
end

module URI::Escape
end

class URI::FTP < URI::Generic
  ABS_PATH = T.let(T.unsafe(nil), Regexp)
  ABS_URI = T.let(T.unsafe(nil), Regexp)
  ABS_URI_REF = T.let(T.unsafe(nil), Regexp)
  COMPONENT = T.let(T.unsafe(nil), Array)
  DEFAULT_PARSER = T.let(T.unsafe(nil), URI::RFC2396_Parser)
  DEFAULT_PORT = T.let(T.unsafe(nil), Integer)
  ESCAPED = T.let(T.unsafe(nil), Regexp)
  FRAGMENT = T.let(T.unsafe(nil), Regexp)
  HOST = T.let(T.unsafe(nil), Regexp)
  HTML5ASCIIINCOMPAT = T.let(T.unsafe(nil), String)
  OPAQUE = T.let(T.unsafe(nil), Regexp)
  PORT = T.let(T.unsafe(nil), Regexp)
  QUERY = T.let(T.unsafe(nil), Regexp)
  REGISTRY = T.let(T.unsafe(nil), Regexp)
  REL_PATH = T.let(T.unsafe(nil), Regexp)
  REL_URI = T.let(T.unsafe(nil), Regexp)
  REL_URI_REF = T.let(T.unsafe(nil), Regexp)
  RFC3986_PARSER = T.let(T.unsafe(nil), URI::RFC3986_Parser)
  SCHEME = T.let(T.unsafe(nil), Regexp)
  TBLDECWWWCOMP_ = T.let(T.unsafe(nil), Hash)
  TBLENCWWWCOMP_ = T.let(T.unsafe(nil), Hash)
  TYPECODE = T.let(T.unsafe(nil), Array)
  TYPECODE_PREFIX = T.let(T.unsafe(nil), String)
  UNSAFE = T.let(T.unsafe(nil), Regexp)
  URI_REF = T.let(T.unsafe(nil), Regexp)
  USERINFO = T.let(T.unsafe(nil), Regexp)
  USE_REGISTRY = T.let(T.unsafe(nil), FalseClass)
  VERSION = T.let(T.unsafe(nil), String)
  VERSION_CODE = T.let(T.unsafe(nil), String)
  WEB_ENCODINGS_ = T.let(T.unsafe(nil), Hash)
end

class URI::Generic < Object
  include URI
  include URI::RFC2396_REGEXP

  ABS_PATH = T.let(T.unsafe(nil), Regexp)
  ABS_URI = T.let(T.unsafe(nil), Regexp)
  ABS_URI_REF = T.let(T.unsafe(nil), Regexp)
  COMPONENT = T.let(T.unsafe(nil), Array)
  DEFAULT_PARSER = T.let(T.unsafe(nil), URI::RFC2396_Parser)
  DEFAULT_PORT = T.let(T.unsafe(nil), NilClass)
  ESCAPED = T.let(T.unsafe(nil), Regexp)
  FRAGMENT = T.let(T.unsafe(nil), Regexp)
  HOST = T.let(T.unsafe(nil), Regexp)
  HTML5ASCIIINCOMPAT = T.let(T.unsafe(nil), String)
  OPAQUE = T.let(T.unsafe(nil), Regexp)
  PORT = T.let(T.unsafe(nil), Regexp)
  QUERY = T.let(T.unsafe(nil), Regexp)
  REGISTRY = T.let(T.unsafe(nil), Regexp)
  REL_PATH = T.let(T.unsafe(nil), Regexp)
  REL_URI = T.let(T.unsafe(nil), Regexp)
  REL_URI_REF = T.let(T.unsafe(nil), Regexp)
  RFC3986_PARSER = T.let(T.unsafe(nil), URI::RFC3986_Parser)
  SCHEME = T.let(T.unsafe(nil), Regexp)
  TBLDECWWWCOMP_ = T.let(T.unsafe(nil), Hash)
  TBLENCWWWCOMP_ = T.let(T.unsafe(nil), Hash)
  UNSAFE = T.let(T.unsafe(nil), Regexp)
  URI_REF = T.let(T.unsafe(nil), Regexp)
  USERINFO = T.let(T.unsafe(nil), Regexp)
  USE_REGISTRY = T.let(T.unsafe(nil), FalseClass)
  VERSION = T.let(T.unsafe(nil), String)
  VERSION_CODE = T.let(T.unsafe(nil), String)
  WEB_ENCODINGS_ = T.let(T.unsafe(nil), Hash)
end

class URI::HTTP < URI::Generic
  ABS_PATH = T.let(T.unsafe(nil), Regexp)
  ABS_URI = T.let(T.unsafe(nil), Regexp)
  ABS_URI_REF = T.let(T.unsafe(nil), Regexp)
  COMPONENT = T.let(T.unsafe(nil), Array)
  DEFAULT_PARSER = T.let(T.unsafe(nil), URI::RFC2396_Parser)
  DEFAULT_PORT = T.let(T.unsafe(nil), Integer)
  ESCAPED = T.let(T.unsafe(nil), Regexp)
  FRAGMENT = T.let(T.unsafe(nil), Regexp)
  HOST = T.let(T.unsafe(nil), Regexp)
  HTML5ASCIIINCOMPAT = T.let(T.unsafe(nil), String)
  OPAQUE = T.let(T.unsafe(nil), Regexp)
  PORT = T.let(T.unsafe(nil), Regexp)
  QUERY = T.let(T.unsafe(nil), Regexp)
  REGISTRY = T.let(T.unsafe(nil), Regexp)
  REL_PATH = T.let(T.unsafe(nil), Regexp)
  REL_URI = T.let(T.unsafe(nil), Regexp)
  REL_URI_REF = T.let(T.unsafe(nil), Regexp)
  RFC3986_PARSER = T.let(T.unsafe(nil), URI::RFC3986_Parser)
  SCHEME = T.let(T.unsafe(nil), Regexp)
  TBLDECWWWCOMP_ = T.let(T.unsafe(nil), Hash)
  TBLENCWWWCOMP_ = T.let(T.unsafe(nil), Hash)
  UNSAFE = T.let(T.unsafe(nil), Regexp)
  URI_REF = T.let(T.unsafe(nil), Regexp)
  USERINFO = T.let(T.unsafe(nil), Regexp)
  USE_REGISTRY = T.let(T.unsafe(nil), FalseClass)
  VERSION = T.let(T.unsafe(nil), String)
  VERSION_CODE = T.let(T.unsafe(nil), String)
  WEB_ENCODINGS_ = T.let(T.unsafe(nil), Hash)
end

class URI::HTTPS < URI::HTTP
  ABS_PATH = T.let(T.unsafe(nil), Regexp)
  ABS_URI = T.let(T.unsafe(nil), Regexp)
  ABS_URI_REF = T.let(T.unsafe(nil), Regexp)
  COMPONENT = T.let(T.unsafe(nil), Array)
  DEFAULT_PARSER = T.let(T.unsafe(nil), URI::RFC2396_Parser)
  DEFAULT_PORT = T.let(T.unsafe(nil), Integer)
  ESCAPED = T.let(T.unsafe(nil), Regexp)
  FRAGMENT = T.let(T.unsafe(nil), Regexp)
  HOST = T.let(T.unsafe(nil), Regexp)
  HTML5ASCIIINCOMPAT = T.let(T.unsafe(nil), String)
  OPAQUE = T.let(T.unsafe(nil), Regexp)
  PORT = T.let(T.unsafe(nil), Regexp)
  QUERY = T.let(T.unsafe(nil), Regexp)
  REGISTRY = T.let(T.unsafe(nil), Regexp)
  REL_PATH = T.let(T.unsafe(nil), Regexp)
  REL_URI = T.let(T.unsafe(nil), Regexp)
  REL_URI_REF = T.let(T.unsafe(nil), Regexp)
  RFC3986_PARSER = T.let(T.unsafe(nil), URI::RFC3986_Parser)
  SCHEME = T.let(T.unsafe(nil), Regexp)
  TBLDECWWWCOMP_ = T.let(T.unsafe(nil), Hash)
  TBLENCWWWCOMP_ = T.let(T.unsafe(nil), Hash)
  UNSAFE = T.let(T.unsafe(nil), Regexp)
  URI_REF = T.let(T.unsafe(nil), Regexp)
  USERINFO = T.let(T.unsafe(nil), Regexp)
  USE_REGISTRY = T.let(T.unsafe(nil), FalseClass)
  VERSION = T.let(T.unsafe(nil), String)
  VERSION_CODE = T.let(T.unsafe(nil), String)
  WEB_ENCODINGS_ = T.let(T.unsafe(nil), Hash)
end

class URI::InvalidComponentError < URI::Error
end

class URI::InvalidURIError < URI::Error
end

class URI::LDAP < URI::Generic
  ABS_PATH = T.let(T.unsafe(nil), Regexp)
  ABS_URI = T.let(T.unsafe(nil), Regexp)
  ABS_URI_REF = T.let(T.unsafe(nil), Regexp)
  COMPONENT = T.let(T.unsafe(nil), Array)
  DEFAULT_PARSER = T.let(T.unsafe(nil), URI::RFC2396_Parser)
  DEFAULT_PORT = T.let(T.unsafe(nil), Integer)
  ESCAPED = T.let(T.unsafe(nil), Regexp)
  FRAGMENT = T.let(T.unsafe(nil), Regexp)
  HOST = T.let(T.unsafe(nil), Regexp)
  HTML5ASCIIINCOMPAT = T.let(T.unsafe(nil), String)
  OPAQUE = T.let(T.unsafe(nil), Regexp)
  PORT = T.let(T.unsafe(nil), Regexp)
  QUERY = T.let(T.unsafe(nil), Regexp)
  REGISTRY = T.let(T.unsafe(nil), Regexp)
  REL_PATH = T.let(T.unsafe(nil), Regexp)
  REL_URI = T.let(T.unsafe(nil), Regexp)
  REL_URI_REF = T.let(T.unsafe(nil), Regexp)
  RFC3986_PARSER = T.let(T.unsafe(nil), URI::RFC3986_Parser)
  SCHEME = T.let(T.unsafe(nil), Regexp)
  SCOPE = T.let(T.unsafe(nil), Array)
  SCOPE_BASE = T.let(T.unsafe(nil), String)
  SCOPE_ONE = T.let(T.unsafe(nil), String)
  SCOPE_SUB = T.let(T.unsafe(nil), String)
  TBLDECWWWCOMP_ = T.let(T.unsafe(nil), Hash)
  TBLENCWWWCOMP_ = T.let(T.unsafe(nil), Hash)
  UNSAFE = T.let(T.unsafe(nil), Regexp)
  URI_REF = T.let(T.unsafe(nil), Regexp)
  USERINFO = T.let(T.unsafe(nil), Regexp)
  USE_REGISTRY = T.let(T.unsafe(nil), FalseClass)
  VERSION = T.let(T.unsafe(nil), String)
  VERSION_CODE = T.let(T.unsafe(nil), String)
  WEB_ENCODINGS_ = T.let(T.unsafe(nil), Hash)
end

class URI::LDAPS < URI::LDAP
  ABS_PATH = T.let(T.unsafe(nil), Regexp)
  ABS_URI = T.let(T.unsafe(nil), Regexp)
  ABS_URI_REF = T.let(T.unsafe(nil), Regexp)
  COMPONENT = T.let(T.unsafe(nil), Array)
  DEFAULT_PARSER = T.let(T.unsafe(nil), URI::RFC2396_Parser)
  DEFAULT_PORT = T.let(T.unsafe(nil), Integer)
  ESCAPED = T.let(T.unsafe(nil), Regexp)
  FRAGMENT = T.let(T.unsafe(nil), Regexp)
  HOST = T.let(T.unsafe(nil), Regexp)
  HTML5ASCIIINCOMPAT = T.let(T.unsafe(nil), String)
  OPAQUE = T.let(T.unsafe(nil), Regexp)
  PORT = T.let(T.unsafe(nil), Regexp)
  QUERY = T.let(T.unsafe(nil), Regexp)
  REGISTRY = T.let(T.unsafe(nil), Regexp)
  REL_PATH = T.let(T.unsafe(nil), Regexp)
  REL_URI = T.let(T.unsafe(nil), Regexp)
  REL_URI_REF = T.let(T.unsafe(nil), Regexp)
  RFC3986_PARSER = T.let(T.unsafe(nil), URI::RFC3986_Parser)
  SCHEME = T.let(T.unsafe(nil), Regexp)
  SCOPE = T.let(T.unsafe(nil), Array)
  SCOPE_BASE = T.let(T.unsafe(nil), String)
  SCOPE_ONE = T.let(T.unsafe(nil), String)
  SCOPE_SUB = T.let(T.unsafe(nil), String)
  TBLDECWWWCOMP_ = T.let(T.unsafe(nil), Hash)
  TBLENCWWWCOMP_ = T.let(T.unsafe(nil), Hash)
  UNSAFE = T.let(T.unsafe(nil), Regexp)
  URI_REF = T.let(T.unsafe(nil), Regexp)
  USERINFO = T.let(T.unsafe(nil), Regexp)
  USE_REGISTRY = T.let(T.unsafe(nil), FalseClass)
  VERSION = T.let(T.unsafe(nil), String)
  VERSION_CODE = T.let(T.unsafe(nil), String)
  WEB_ENCODINGS_ = T.let(T.unsafe(nil), Hash)
end

class URI::MailTo < URI::Generic
  ABS_PATH = T.let(T.unsafe(nil), Regexp)
  ABS_URI = T.let(T.unsafe(nil), Regexp)
  ABS_URI_REF = T.let(T.unsafe(nil), Regexp)
  COMPONENT = T.let(T.unsafe(nil), Array)
  DEFAULT_PARSER = T.let(T.unsafe(nil), URI::RFC2396_Parser)
  DEFAULT_PORT = T.let(T.unsafe(nil), NilClass)
  EMAIL_REGEXP = T.let(T.unsafe(nil), Regexp)
  ESCAPED = T.let(T.unsafe(nil), Regexp)
  FRAGMENT = T.let(T.unsafe(nil), Regexp)
  HEADER_REGEXP = T.let(T.unsafe(nil), Regexp)
  HOST = T.let(T.unsafe(nil), Regexp)
  HTML5ASCIIINCOMPAT = T.let(T.unsafe(nil), String)
  OPAQUE = T.let(T.unsafe(nil), Regexp)
  PORT = T.let(T.unsafe(nil), Regexp)
  QUERY = T.let(T.unsafe(nil), Regexp)
  REGISTRY = T.let(T.unsafe(nil), Regexp)
  REL_PATH = T.let(T.unsafe(nil), Regexp)
  REL_URI = T.let(T.unsafe(nil), Regexp)
  REL_URI_REF = T.let(T.unsafe(nil), Regexp)
  RFC3986_PARSER = T.let(T.unsafe(nil), URI::RFC3986_Parser)
  SCHEME = T.let(T.unsafe(nil), Regexp)
  TBLDECWWWCOMP_ = T.let(T.unsafe(nil), Hash)
  TBLENCWWWCOMP_ = T.let(T.unsafe(nil), Hash)
  UNSAFE = T.let(T.unsafe(nil), Regexp)
  URI_REF = T.let(T.unsafe(nil), Regexp)
  USERINFO = T.let(T.unsafe(nil), Regexp)
  USE_REGISTRY = T.let(T.unsafe(nil), FalseClass)
  VERSION = T.let(T.unsafe(nil), String)
  VERSION_CODE = T.let(T.unsafe(nil), String)
  WEB_ENCODINGS_ = T.let(T.unsafe(nil), Hash)
end

module URI::RFC2396_REGEXP
end

module URI::RFC2396_REGEXP::PATTERN
  ABS_PATH = T.let(T.unsafe(nil), String)
  ABS_URI = T.let(T.unsafe(nil), String)
  ALNUM = T.let(T.unsafe(nil), String)
  ALPHA = T.let(T.unsafe(nil), String)
  DOMLABEL = T.let(T.unsafe(nil), String)
  ESCAPED = T.let(T.unsafe(nil), String)
  FRAGMENT = T.let(T.unsafe(nil), String)
  HEX = T.let(T.unsafe(nil), String)
  HIER_PART = T.let(T.unsafe(nil), String)
  HOST = T.let(T.unsafe(nil), String)
  HOSTNAME = T.let(T.unsafe(nil), String)
  HOSTPORT = T.let(T.unsafe(nil), String)
  IPV4ADDR = T.let(T.unsafe(nil), String)
  IPV6ADDR = T.let(T.unsafe(nil), String)
  IPV6REF = T.let(T.unsafe(nil), String)
  NET_PATH = T.let(T.unsafe(nil), String)
  OPAQUE_PART = T.let(T.unsafe(nil), String)
  PATH_SEGMENTS = T.let(T.unsafe(nil), String)
  PORT = T.let(T.unsafe(nil), String)
  QUERY = T.let(T.unsafe(nil), String)
  REG_NAME = T.let(T.unsafe(nil), String)
  REL_PATH = T.let(T.unsafe(nil), String)
  REL_SEGMENT = T.let(T.unsafe(nil), String)
  REL_URI = T.let(T.unsafe(nil), String)
  RESERVED = T.let(T.unsafe(nil), String)
  SCHEME = T.let(T.unsafe(nil), String)
  TOPLABEL = T.let(T.unsafe(nil), String)
  UNRESERVED = T.let(T.unsafe(nil), String)
  URIC = T.let(T.unsafe(nil), String)
  URIC_NO_SLASH = T.let(T.unsafe(nil), String)
  URI_REF = T.let(T.unsafe(nil), String)
  USERINFO = T.let(T.unsafe(nil), String)
  X_ABS_URI = T.let(T.unsafe(nil), String)
  X_REL_URI = T.let(T.unsafe(nil), String)
end

class URI::RFC2396_Parser < Object
  include URI::RFC2396_REGEXP
end

class URI::RFC3986_Parser < Object
  RFC3986_URI = T.let(T.unsafe(nil), Regexp)
end

module URI::Util
end
