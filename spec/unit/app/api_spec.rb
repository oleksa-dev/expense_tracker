# frozen_string_literal: true

require_relative '../../../app/ledger'
require_relative '../../../app/api'
require 'json'
require 'rack/test'
require 'rspec/expectations'

module ExpenseTracker
  RSpec::Matchers.define :be_json do |_expected|
    match do |actual|
      return true if JSON.parse(actual)
    rescue StandardError => e
      return false
    end

    failure_message do |str|
      "Current string: #{str} - is not JSON"
    end
  end

  RSpec.describe API do
    include Rack::Test::Methods

    def app
      API.new(ledger: ledger)
    end

    def set_ledger_config(method, param, response)
      allow(ledger).to receive(method)
        .with(param)
        .and_return(response)
    end

    def parse_response(response)
      JSON.parse(response.body)
    end

    def check_response(response, condition, invert = false)
      expect(response).send(invert ? :not_to : :to, condition)
    end

    let(:ledger) { instance_double(ExpenseTracker::Ledger) }

    describe 'POST /expense' do
      context 'when the expense is successfully recorded' do
        let(:expense) { { 'some' => 'data' } }

        before do
          set_ledger_config(:record, expense, RecordResult.new(true, 417, nil))
        end

        it 'returns the expenses id' do
          post '/expense', JSON.generate(expense)
          check_response(parse_response(last_response), include('expense_id' => 417))
        end

        it 'responds with a 200 (OK)' do
          post '/expense', JSON.generate(expense)
          check_response(last_response.status, eq(200))
        end
      end

      context 'when the expense fails validation' do
        let(:expense) { { 'some' => 'data' } }

        before do
          set_ledger_config(:record, expense, RecordResult.new(false, 417, 'Expense Incomplete'))
        end

        it 'returns an error message' do
          post '/expense', JSON.generate(expense)
          check_response(parse_response(last_response), include('error' => 'Expense Incomplete'))
        end

        it 'responds with a 422 (Unprocessable Entity)' do
          post '/expense', JSON.generate(expense)
          check_response(last_response.status, eq(422))
        end
      end
    end

    describe 'GET /expenses/:date' do
      let(:date) { '2017-06-12' }

      context 'when the expense exist on the given date' do
        before do
          set_ledger_config(:expenses_on, date, [Expenses.new(22, 22.5, '2017-06-12')])
        end

        it 'returns JSON' do
          get "/expenses/#{date}"
          check_response(last_response.body, be_json)
        end

        it 'returns the expense records as JSON' do
          get "/expenses/#{date}"
          check_response(last_response.body, be_empty, true)
        end

        it 'responds with 200 (OK)' do
          get "/expenses/#{date}"
          check_response(last_response.status, eq(200))
        end
      end

      context 'when there are no expenses on the given date' do
        before do
          set_ledger_config(:expenses_on, date, [])
        end

        it 'returns an empty array as JSON' do
          get "/expenses/#{date}"
          check_response(parse_response(last_response), be_empty)
        end

        it 'responds with 200 (OK)' do
          get "/expenses/#{date}"
          check_response(last_response.status, eq(200))
        end
      end
    end
  end
end
