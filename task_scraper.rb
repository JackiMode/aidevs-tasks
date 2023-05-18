#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'

require 'ai_task.rb'
require 'httparty'
require 'json'
require 'openai' #https://github.com/alexrudall/ruby-openai

ai = AiTask.new('scraper')
task = ai.task
puts task
file_name = task['input']

ok = true
headers = { "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/112.0" }

OpenAI.configure do |config|
  config.access_token = ENV.fetch('OPENAI_ACCESS_TOKEN')
  config.organization_id = ENV.fetch('OPENAI_ORGANIZATION_ID') # Optional.
end
client = OpenAI::Client.new

loop do
  response = HTTParty.get(file_name, headers: headers)
  puts "Code(#{response.code.class}): #{response.code}; #{response.message}"
  if response.code == 500
    puts 'sleep 1s...'
    sleep 1
  elsif response.code == 200
    # puts response.body
    system_msg = "#{response.body}. Answer user questions based on the knowledge provided by the system. Answer in polish langauage only. Answer shoud be short - max 150 chars. "
    response = client.chat(
      parameters: {
          model: "gpt-3.5-turbo", # Required.
          messages: [{role: "system", content: "#{system_msg}"}, { role: "user", content: "#{task['question']}"}], # Required.
          temperature: 0,
      })
    
    answer =  response.dig("choices", 0, "message", "content").gsub('.', '')
    puts "Odpowiedź: #{answer}"
    puts ai.send_answer(answer)
    break
  end
end