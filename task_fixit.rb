#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'

require 'ai_task.rb'
require 'httparty'
require 'json'
require 'openai' #https://github.com/alexrudall/ruby-openai


ai = AiTask.new('fixit')
task = ai.get_task
puts task

OpenAI.configure do |config|
  config.access_token = ENV.fetch('OPENAI_ACCESS_TOKEN')
  config.organization_id = ENV.fetch('OPENAI_ORGANIZATION_ID') # Optional.
end
client = OpenAI::Client.new

system_msg = "#{response.body}. Answer user questions based on the knowledge provided by the system. Answer in polish langauage only. Answer shoud be short - max 150 chars. "
response = client.chat(
  parameters: {
      model: "gpt-3.5-turbo", # Required.
      messages: [{role: "system", content: "#{system_msg}"}, { role: "user", content: "#{task['question']}"}], # Required.
      temperature: 0,
  })

answer = response.dig("choices", 0, "message", "content").gsub('.', '')
puts "Odpowiedź: #{answer}"
puts ai.send_answer(answer)
