# typed: __STDLIB_INTERNAL
class Date::Infinity < Numeric
  sig {returns(Date::Infinity)}
  def +@(); end

  sig {returns(Date::Infinity)}
  def -@(); end

  sig {params(other: T.untyped).returns(T.nilable(Integer))}
  def <=>(other); end

  sig {returns(Float)}
  def to_f(); end

  sig {params(other: T.untyped).returns(Numeric)}
  def coerce(other); end

  sig {returns(Date::Infinity)}
  def abs(); end

  sig {returns(T::Boolean)}
  def zero?(); end

  sig {returns(T::Boolean)}
  def finite?(); end

  sig {returns(T::Boolean)}
  def infinite?(); end

  sig {returns(T::Boolean)}
  def nan?(); end

  sig {returns(T::Boolean)}
  def d(); end
end

class Date
  include Comparable

  ABBR_DAYNAMES = T.let(T.unsafe(nil), Array)
  ABBR_MONTHNAMES = T.let(T.unsafe(nil), Array)
  DAYNAMES = T.let(T.unsafe(nil), Array)
  ENGLAND = T.let(T.unsafe(nil), Integer)
  GREGORIAN = T.let(T.unsafe(nil), Float)
  ITALY = T.let(T.unsafe(nil), Integer)
  JULIAN = T.let(T.unsafe(nil), Float)
  MONTHNAMES = T.let(T.unsafe(nil), Array)

  sig do
    params(
      year: Integer,
      month: Integer,
      mday: Integer,
      start: Integer,
    )
    .void
  end
  def initialize(year=-4712, month=1, mday=1, start=Date::ITALY); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def upto(arg0); end

  sig do
    params(
      locale: T.untyped,
      options: T.untyped,
    )
    .returns(T.untyped)
  end
  def localize(locale=T.unsafe(nil), options=T.unsafe(nil)); end

  sig {params(arg0: T.untyped).returns(T.nilable(Integer))}
  def <=>(arg0); end

  sig {params(arg0: T.untyped).returns(Date)}
  def <<(arg0); end

  sig {params(arg0: T.untyped).returns(Date)}
  def >>(arg0); end

  sig {params(arg0: T.untyped).returns(T::Boolean)}
  def ===(arg0); end

  sig {params(arg0: T.untyped).returns(T::Boolean)}
  def eql?(arg0); end

  sig {returns(Float)}
  def start(); end

  sig {returns(T.untyped)}
  def marshal_dump(); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def marshal_load(arg0); end

  sig {returns(T.untyped)}
  def ajd(); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def +(arg0); end

  sig {returns(String)}
  def inspect(); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def -(arg0); end

  sig {returns(Integer)}
  def mday(); end

  sig {returns(Integer)}
  def day(); end

  sig {returns(Integer)}
  def mon(); end

  sig {returns(Integer)}
  def month(); end

  sig {returns(Integer)}
  def year(); end

  sig {returns(Integer)}
  def wday(); end

  sig {returns(Integer)}
  def yday(); end

  sig {returns(String)}
  def ctime(); end

  sig {returns(T.untyped)}
  def pretty_date(); end

  sig {returns(Date)}
  def succ(); end

  sig {returns(T.untyped)}
  def to_utc_time(); end

  sig {returns(Integer)}
  def jd(); end

  sig {returns(T::Boolean)}
  def sunday?(); end

  sig {returns(T::Boolean)}
  def monday?(); end

  sig {returns(T::Boolean)}
  def tuesday?(); end

  sig {returns(T::Boolean)}
  def wednesday?(); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def step(*arg0); end

  sig {returns(T::Boolean)}
  def friday?(); end

  sig {returns(T::Boolean)}
  def saturday?(); end

  sig {returns(T::Boolean)}
  def blank?(); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def downto(arg0); end

  sig {returns(String)}
  def asctime(); end

  sig {params(arg0: T.untyped).returns(String)}
  def strftime(*arg0); end

  sig {returns(T::Boolean)}
  def thursday?(); end

  sig {returns(String)}
  def to_s(); end

  sig {returns(T::Boolean)}
  def leap?(); end

  sig {returns(String)}
  def iso8601(); end

  sig {returns(String)}
  def rfc3339(); end

  sig {returns(String)}
  def xmlschema(); end

  sig {returns(String)}
  def rfc2822(); end

  sig {returns(String)}
  def rfc822(); end

  sig {returns(String)}
  def httpdate(); end

  sig {returns(String)}
  def jisx0301(); end

  sig {returns(T.untyped)}
  def amjd(); end

  sig {returns(T.untyped)}
  def mjd(); end

  sig {returns(T.untyped)}
  def day_fraction(); end

  sig {returns(Integer)}
  def cwyear(); end

  sig {returns(Integer)}
  def cweek(); end

  sig {returns(Integer)}
  def cwday(); end

  sig {returns(T.untyped)}
  def hash(); end

  sig {returns(T::Boolean)}
  def julian?(); end

  sig {returns(T::Boolean)}
  def gregorian?(); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def new_start(*arg0); end

  sig {returns(Date)}
  def italy(); end

  sig {returns(Date)}
  def england(); end

  sig {returns(Date)}
  def julian(); end

  sig {returns(Date)}
  def gregorian(); end

  sig {params(arg0: T.untyped).returns(Date)}
  def next_day(*arg0); end

  sig {returns(Integer)}
  def ld(); end

  sig {params(arg0: T.untyped).returns(Date)}
  def next_month(*arg0); end

  sig {params(arg0: T.untyped).returns(Date)}
  def prev_day(*arg0); end

  sig {returns(Date)}
  def next(); end

  sig {params(arg0: T.untyped).returns(Date)}
  def prev_month(*arg0); end

  sig {params(arg0: T.untyped).returns(Date)}
  def next_year(*arg0); end

  sig {params(arg0: T.untyped).returns(Date)}
  def prev_year(*arg0); end

  sig {returns(Time)}
  def to_time(); end

  sig {returns(Date)}
  def to_date(); end

  sig {returns(DateTime)}
  def to_datetime(); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def self.new(*arg0); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def self._load(arg0); end

  sig {params(arg0: T.untyped).returns(Date)}
  def self.today(*arg0); end

  sig {params(arg0: T.untyped).returns(Date)}
  def self.parse(*arg0); end

  sig {params(arg0: T.untyped).returns(Date)}
  def self.jd(*arg0); end

  sig {params(arg0: T.untyped).returns(T::Boolean)}
  def self.valid_jd?(*arg0); end

  sig {params(arg0: T.untyped).returns(T::Boolean)}
  def self.valid_ordinal?(*arg0); end

  sig {params(arg0: T.untyped).returns(T::Boolean)}
  def self.valid_civil?(*arg0); end

  sig {params(arg0: T.untyped).returns(T::Boolean)}
  def self.valid_date?(*arg0); end

  sig {params(arg0: T.untyped).returns(T::Boolean)}
  def self.valid_commercial?(*arg0); end

  sig {params(arg0: T.untyped).returns(T::Boolean)}
  def self.julian_leap?(arg0); end

  sig {params(arg0: T.untyped).returns(T::Boolean)}
  def self.gregorian_leap?(arg0); end

  sig {params(arg0: T.untyped).returns(T::Boolean)}
  def self.leap?(arg0); end

  sig {params(arg0: T.untyped).returns(Date)}
  def self.ordinal(*arg0); end

  sig {params(arg0: T.untyped).returns(Date)}
  def self.civil(*arg0); end

  sig {params(arg0: T.untyped).returns(Date)}
  def self.commercial(*arg0); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def self._strptime(*arg0); end

  sig {params(arg0: T.untyped).returns(Date)}
  def self.strptime(*arg0); end

  sig do
    params(
      arg0: String,
      comp: T::Boolean
    )
    .returns(Hash)
  end
  def self._parse(arg0, comp=true); end

  sig {params(arg0: String).returns(Hash)}
  def self._iso8601(arg0); end

  sig {params(arg0: T.untyped).returns(Date)}
  def self.iso8601(*arg0); end

  sig {params(arg0: String).returns(Hash)}
  def self._rfc3339(arg0); end

  sig {params(arg0: T.untyped).returns(Date)}
  def self.rfc3339(*arg0); end

  sig {params(arg0: String).returns(Hash)}
  def self._xmlschema(arg0); end

  sig {params(arg0: T.untyped).returns(Date)}
  def self.xmlschema(*arg0); end

  sig {params(arg0: String).returns(Hash)}
  def self._rfc2822(arg0); end

  sig {params(arg0: String).returns(Hash)}
  def self._rfc822(arg0); end

  sig {params(arg0: T.untyped).returns(Date)}
  def self.rfc2822(*arg0); end

  sig {params(arg0: T.untyped).returns(Date)}
  def self.rfc822(*arg0); end

  sig {params(arg0: String).returns(Hash)}
  def self._httpdate(arg0); end

  sig {params(arg0: T.untyped).returns(Date)}
  def self.httpdate(*arg0); end

  sig {params(arg0: String).returns(Hash)}
  def self._jisx0301(arg0); end

  sig {params(arg0: T.untyped).returns(Date)}
  def self.jisx0301(*arg0); end
end

class DateTime < Date
  sig {returns(T.untyped)}
  def min(); end

  sig {returns(T.untyped)}
  def to_s(); end

  sig {returns(T.untyped)}
  def offset(); end

  sig {returns(T.untyped)}
  def zone(); end

  sig {returns(T.untyped)}
  def sec(); end

  sig {returns(T.untyped)}
  def hour(); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def strftime(*arg0); end

  sig {returns(T.untyped)}
  def second(); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def iso8601(*arg0); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def rfc3339(*arg0); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def xmlschema(*arg0); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def jisx0301(*arg0); end

  sig {returns(T.untyped)}
  def minute(); end

  sig {returns(T.untyped)}
  def sec_fraction(); end

  sig {returns(T.untyped)}
  def second_fraction(); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def new_offset(*arg0); end

  sig {returns(Time)}
  def to_time(); end

  sig {returns(Date)}
  def to_date(); end

  sig {returns(DateTime)}
  def to_datetime(); end

  sig {returns(T.untyped)}
  def blank?(); end

  sig {returns(T.untyped)}
  def to_utc_time(); end

  sig do
    params(
      locale: T.untyped,
      options: T.untyped,
    )
    .returns(T.untyped)
  end
  def localize(locale=T.unsafe(nil), options=T.unsafe(nil)); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def self.new(*arg0); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def self.now(*arg0); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def self.parse(*arg0); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def self.jd(*arg0); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def self.ordinal(*arg0); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def self.civil(*arg0); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def self.commercial(*arg0); end

  sig do
    params(
      arg0: String,
      format: String
    )
    .returns(Hash)
  end
  def self._strptime(arg0, format="%F"); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def self.strptime(*arg0); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def self.iso8601(*arg0); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def self.rfc3339(*arg0); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def self.xmlschema(*arg0); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def self.rfc2822(*arg0); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def self.rfc822(*arg0); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def self.httpdate(*arg0); end

  sig {params(arg0: T.untyped).returns(T.untyped)}
  def self.jisx0301(*arg0); end
end

class Time
  sig {returns(Time)}
  def to_time(); end

  sig {returns(Date)}
  def to_date(); end

  sig {returns(DateTime)}
  def to_datetime(); end
end
