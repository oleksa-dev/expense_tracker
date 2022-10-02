# frozen_string_literal: true

class API < Sinatra :Base
  def initialize(ledger: Ledger.new)
    @ledger = ledger
    super()
  end
end

result = @ledger.record({ 'some' => 'data' })
result.success? # => a Boolean
result.expense_id # => a number
result.error_message # => a string or nil
