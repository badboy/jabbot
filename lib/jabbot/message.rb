module Jabbot
  Message = Struct.new(:user, :text, :time) do
    def to_s
      "#{user}: #{text}"
    end
  end
end
