#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'

require 'open-uri'
require 'ai_task.rb'
require 'llm.rb'

ai = AiTask.new('knowledge')
task = ai.task
puts " --- QUESTION: #{task['question']}"
# puts task['database #1']
# puts task['database #2']

functions = []
functions << {
  "name": "getCountryPopulation",
  "description": "get country population",
  "parameters": {
      "type": "object",
      "properties": {
          "countryName": {
              "type": "string",
              "description": "Common name of the country in english language lowercase",
          },
      },
      "required": ["countryName",],
  }
}

functions << {
  "name": "getExchangeRates",
  "description": "gets exchange rates from Poland National Bank via API",
  "parameters": {
      "type": "object",
      "properties": {
          "currencyCode": {
              "type": "string",
              "description": "code of Currency - 3 letters",
          },
      },
      "required": ["currencyCode",],
  }
}

functions << {
  "name": "askQuestion",
  "description": "Ask general question",
  "parameters": {
      "type": "object",
      "properties": {
          "question": {
              "type": "string",
              "description": "A question that the user expects an answer to",
          },
      },
      "required": ["question",],
  }
}

def country_population(country)
  url = "https://restcountries.com/v3.1/name/#{country}"
  info = JSON.load(URI.open(url))
  info[0]['population']
end

def exchange_rates(country_code)
  url = 'https://api.nbp.pl/api/exchangerates/tables/A'
  currencies = JSON.load(URI.open(url))
  currencies[0]['rates'].each do |c|
    return c['mid'] if c['code'] == country_code
  end
end

def question(question)
  messages = [
    {role: "system", content: ''},
    {role: "user", content: question},
  ]
  llm = LLM.new
  response = llm.chat(:messages => messages)
end

messages = [
    {role: "system", content: ''},
    {role: "user", content: task['question']},
]

llm = LLM.new
llm.set_default_model('gpt-4-0613')
response = llm.chat(:messages => messages, :functions => functions)
f = response['name']
args = JSON.parse(response['arguments'])

answer = case f
when 'getCountryPopulation'
  country_population(args['countryName'])
when 'getExchangeRates'
  exchange_rates(args['currencyCode'])
when 'askQuestion'
  question(task['question'])
else
  rise StandardError 'A się popsuło'
end
puts " --- ANSWER: #{answer}"
puts ai.send_answer(answer)
