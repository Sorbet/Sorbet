# frozen_string_literal: true
# typed: ignore

require 'minitest/autorun'
require 'minitest/spec'
require 'mocha/minitest'

require 'tmpdir'

module SorbetRBIGeneration; end
module SorbetRBIGeneration::HiddenMethodFinder; end
module SorbetRBIGeneration::HiddenMethodFinder::Test; end

class SorbetRBIGeneration::HiddenMethodFinder::Test::Simple < MiniTest::Spec
  it 'works on gitlab' do

    Dir.mktmpdir do |dir|
      FileUtils.cp_r(__dir__ + '/gitlab/', dir)
      # olddir = __dir__
      Dir.chdir dir + '/gitlab'

      system('printf "\nsource \'https://stripe.dev/sorbet-repo/super-secret-private-beta/\' do\ngem \'sorbet\', :group => :development\ngem \'sorbet-runtime\'\nend" >> Gemfile')
      system('bundle install --system')
      system('srb init')
      IO.popen('srb tc') do |io|
        output = io.read
        assert_equal("No errors! Great job.", output)
      end

      assert_equal(true, $?.success?)
      # Some day these can be snapshot tests, but this isn't stable enough for
      # that yet
      # assert_equal(File.read(olddir + '/simple.errors.txt'), File.read('rbi/hidden-definitions/errors.txt'))
      # assert_equal(File.read(olddir + '/simple.hidden.rbi'), File.read('rbi/hidden-definitions/hidden.rbi'))
      assert_match("class Foo\n  def bar()", File.read('sorbet/rbi/hidden-definitions/hidden.rbi'))
    end
  end
end
