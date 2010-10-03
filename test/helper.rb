require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'fileutils'

dir = File.dirname(File.expand_path(__FILE__))
$LOAD_PATH.unshift(File.join(dir, '..', 'lib'))
$LOAD_PATH.unshift(dir)

require 'jabbot'

module Test::Unit::Assertions
  def assert_hashes_equal(expected, actual, message = nil)
    full_message = build_message(message, <<EOT, expected.inspect, actual.inspect)
<?> expected but was
<?>.
EOT
    assert_block(full_message) do
      break false if expected.keys.length != actual.keys.length
      expected.keys.all? { |k| expected[k] == actual[k] }
    end
  end

  def assert_hashes_not_equal(expected, actual, message = nil)
    full_message = build_message(message, <<EOT, expected.inspect, actual.inspect)
<?> expected but was
<?>.
EOT
    assert_block(full_message) do
      break false if expected.keys.length != actual.keys.length
      expected.keys.any? { |k| expected[k] != actual[k] }
    end
  end
end

TEST_DIR = File.join(File.dirname(__FILE__), *%w[.])

def testpath(path)
  File.join(TEST_DIR, path)
end

# test/spec/mini 3
# http://gist.github.com/25455
# chris@ozmm.org
# file:lib/test/spec/mini.rb
def context(*args, &block)
  return super unless (name = args.first) && block
  require 'test/unit'
  klass = Class.new(defined?(ActiveSupport::TestCase) ? ActiveSupport::TestCase : Test::Unit::TestCase) do
    def self.test(name, &block)
      define_method("test_#{name.gsub(/\W/,'_')}", &block) if block
    end
    def self.xtest(*args) end
    def self.setup(&block) define_method(:setup, &block) end
    def self.teardown(&block) define_method(:teardown, &block) end
  end
  (class << klass; self end).send(:define_method, :name) { name.gsub(/\W/,'_') }
  klass.class_eval &block
end

Message = Struct.new(:user, :text, :time)
def mock_message(user, text)
  Message.new(user, text, Time.now)
end
