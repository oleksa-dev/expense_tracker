# frozen_string_literal: true

require 'sinatra/base'
require 'json'
require 'debug'

module ExpenseTracker
  class API < Sinatra::Base
    def initialize(ledger: Ledger.new)
      @ledger = ledger
      super()
    end

    post '/expense' do
      expense = JSON.parse(request.body.read)
      result = @ledger.record(expense)
      if result.success?
        JSON.generate(expense_id: result.expense_id)
      else
        status 422
        JSON.generate(error: result.error_message)
      end
    end

    get '/expenses/:date' do
      date = params[:date]
      result = @ledger.expenses_on(date)
      if result.empty?
        JSON.generate([])
      else
        JSON.generate(result)
      end
    end
  end
end
