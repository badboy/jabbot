require 'helper'

context "Macros" do
  test "provide configure macro" do
    assert respond_to?(:configure)
  end

  test "yield configuration" do
    Jabbot::Macros.bot = Jabbot::Bot.new

    conf = nil
    configure { |c| conf = c } 
    assert conf.is_a?(Jabbot::Config)
  end

  test "add handler" do
    Jabbot::Macros.bot = Jabbot::Bot.new

    handler = add_handler(:message, ":command", :from => :cjno)
    assert handler.is_a?(Jabbot::Handler)
  end

  test "provide client macro" do
    assert respond_to?(:client)
  end

  test "provide users macro" do
    assert respond_to?(:users)
    assert_equal users, []
  end
end
