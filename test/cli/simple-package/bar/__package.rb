# frozen_string_literal: true
# typed: strict
# enable-packager: true

class Project::Bar < PackageSpec
  import Project::Foo

  export Bar
  export BarMethods
end
