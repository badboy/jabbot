require 'helper'

context "Handler" do
  test "abort on empty values" do
    handler = Jabbot::Handler.new

    handler.pattern = nil
    assert_nil handler.pattern
    assert_nil handler.instance_eval { @tokens }

    handler.pattern = ""
    assert_nil handler.pattern
    assert_nil handler.instance_eval { @tokens }
  end

  test "turn regular pattern into regex" do
    handler = Jabbot::Handler.new
    handler.pattern = "command"

    assert_equal(/command/, handler.pattern)
    assert_equal 0, handler.instance_eval{ @tokens }.length
  end

  test "convert single named switch to regex" do
    handler = Jabbot::Handler.new
    handler.pattern = ":command"

    assert_equal(/([^\s]+)/, handler.pattern)
    assert_equal 1, handler.instance_eval { @tokens }.length
    assert_equal :command, handler.instance_eval { @tokens.first }
  end

  test "convert several named switches to regexen" do
    handler = Jabbot::Handler.new
    handler.pattern = ":command fixed_word :subcommand"

    assert_equal(/([^\s]+) fixed_word ([^\s]+)/, handler.pattern)
    assert_equal 2, handler.instance_eval { @tokens }.length
    assert_equal :command, handler.instance_eval { @tokens.first }
    assert_equal :subcommand, handler.instance_eval { @tokens[1] }
  end

  test "convert several named switches to regexen specified by options" do
    handler = Jabbot::Handler.new(":time :hour", :hour => /\d\d/)

    assert_equal(/([^\s]+) ((?-mix:\d\d))/, handler.pattern)
    assert_equal 2, handler.instance_eval { @tokens }.length
    assert_equal :time, handler.instance_eval { @tokens.first }
    assert_equal :hour, handler.instance_eval { @tokens[1] }
  end

  test "recognize empty pattern" do
    handler = Jabbot::Handler.new
    message = mock_message "cjno", "A jabber message"

    assert handler.recognize?(message)
  end

  test "recognize empty pattern and allowed user" do
    handler = Jabbot::Handler.new "", :from => "cjno"
    message = mock_message "cjno", "A jabber message"
    assert handler.recognize?(message)

    handler = Jabbot::Handler.new "", :from => ["cjno", "irbno"]
    assert handler.recognize?(message)
  end

  test "not recognize empty pattern and disallowed user" do
    handler = Jabbot::Handler.new "", :from => "irbno"
    message = mock_message "cjno", "A jabber message"
    assert !handler.recognize?(message)

    handler = Jabbot::Handler.new "", :from => ["irbno", "satan"]
    assert !handler.recognize?(message)
  end

  test "recognize fixed pattern and no user" do
    handler = Jabbot::Handler.new "time"
    message = mock_message "cjno", "time oslo norway"
    assert handler.recognize?(message)
  end

  test "recognize dynamic pattern and no user" do
    handler = Jabbot::Handler.new "time :city :country"
    message = mock_message "cjno", "time oslo norway"
    assert handler.recognize?(message)
  end

  test "not recognize dynamic pattern and no user" do
    handler = Jabbot::Handler.new "time :city :country"
    message = mock_message "cjno", "oslo norway what is the time?"
    assert !handler.recognize?(message)
  end

  test "recognize fixed pattern and user" do
    handler = Jabbot::Handler.new "time", :from => ["cjno", "irbno"]
    message = mock_message "cjno", "time oslo norway"
    assert handler.recognize?(message)
  end

  test "recognize dynamic pattern and user" do
    handler = Jabbot::Handler.new "time :city :country", :from => ["cjno", "irbno"]
    message = mock_message "cjno", "time oslo norway"
    assert handler.recognize?(message)
  end

  test "not recognize dynamic pattern and user" do
    handler = Jabbot::Handler.new "time :city :country", :from => ["cjno", "irbno"]
    message = mock_message "dude", "time oslo norway"
    assert !handler.recognize?(message)
  end

  test "recognize symbol users" do
    handler = Jabbot::Handler.new "time :city :country", :from => [:cjno, :irbno]
    message = mock_message "dude", "time oslo norway"
    assert !handler.recognize?(message)

    message = mock_message("cjno", "time oslo norway")
    assert handler.recognize?(message)
  end

  test "recognize messages from allowed users" do
    handler = Jabbot::Handler.new :from => [:cjno, :irbno]
    message = mock_message "cjno", "time oslo norway"
    assert handler.recognize?(message)
  end

  test "not recognize messages from unallowed users with capital screen names" do
    handler = Jabbot::Handler.new :from => [:cjno, :irbno]
    message = mock_message "Cjno", "time oslo norway"
    assert !handler.recognize?(message)
  end

  test "accept options as only argument" do
    handler = Jabbot::Handler.new :from => :cjno
    assert_equal(['cjno'], handler.instance_eval { @options[:from] })
    assert_nil handler.instance_eval { @options[:pattern] }
  end

  test "provide parameters in params hash" do
    handler = Jabbot::Handler.new("time :city :country", :from => ["cjno", "irbno"]) do |message, params|
      assert_equal "oslo", params[:city]
      assert_equal "norway", params[:country]
    end

    message = mock_message "cjno", "time oslo norway"
    assert handler.recognize?(message)
    handler.dispatch(message)
  end

  test "call constructor block from handle" do
    handler = Jabbot::Handler.new("time :city :country", :from => ["cjno", "irbno"]) do |message, params|
      raise "Boom!"
    end

    assert_raises(RuntimeError) do
      handler.handle(nil, nil)
    end
  end

  test "recognize regular expressions" do
    handler = Jabbot::Handler.new /(?:what|where) is (.*)/i
    message = mock_message "dude", "Where is this shit?"
    assert handler.recognize?(message)

    message = mock_message "dude", "How is this shit?"
    assert !handler.recognize?(message)
  end

  test "recognize regular expressions from specific users" do
    handler = Jabbot::Handler.new /(?:what|where) is (.*)/i, :from => "cjno"
    message = mock_message "dude", "Where is this shit?"
    assert !handler.recognize?(message)

    message = mock_message "cjno", "Where is this shit?"
    assert handler.recognize?(message)
  end

  test "provide parameters as arrays when matching regular expressions" do
    handler = Jabbot::Handler.new(/time ([^\s]*) ([^\s]*)/) do |message, params|
      assert_equal "oslo", params[0]
      assert_equal "norway", params[1]
    end

    message = mock_message "cjno", "time oslo norway"
    assert handler.recognize?(message)
    handler.dispatch(message)
  end

  test "recognize matching messages with :exact pattern" do
    handler = Jabbot::Handler.new :exact => "!pattern"
    message = mock_message "dude", "!pattern"
    assert handler.recognize?(message)
  end

  test "not recognize non-matching message with :exact patterns" do
    handler = Jabbot::Handler.new :exact => "!pattern"
    message = mock_message "dude", "   !pattern    "
    assert !handler.recognize?(message)
  end
end
