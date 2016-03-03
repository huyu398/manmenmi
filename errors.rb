module Errors
  class BaseError < StandardError
    attr :line
    attr :message

    def initialize(message=nil, line=nil)
      @message = message
      @line = line
    end
  end

  class NFCReadError < BaseError; end
  class UserRecognizeError < BaseError; end
  class LoginError < BaseError; end
  class UnexpectedError < BaseError; end
end
