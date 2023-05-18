#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'

require 'ai_task.rb'
require 'openai' #https://github.com/alexrudall/ruby-openai

OpenAI.configure do |config|
  config.access_token = ENV.fetch('OPENAI_ACCESS_TOKEN')
  config.organization_id = ENV.fetch('OPENAI_ORGANIZATION_ID') # Optional.
end

ai = AiTask.new('blogger')
task = ai.task
system_msg = task['msg']

posts = []

client = OpenAI::Client.new

task['blog'].each do |line|
  sys_content = "Jesteś redaktorem zajmującym się pisaniem bloga o Włoszech i nazywasz się Marko. Piszesz krótko i zwięźle w języku polskim Maksymalnie 5-8 zdań, 1-2 akapity. #{system_msg}"
  user_content = line
  puts  %Q(
  messages: 
    {role: "system", content: #{sys_content}}, 
    {role: "user",   content: #{user_content}}
  )
  response = client.chat(
    parameters: {
        model: "gpt-3.5-turbo", # Required.
        messages: [{role: "system", content:sys_content}, { role: "user", content: user_content}], # Required.
        temperature: 0.7,
    })
    posts << response.dig("choices", 0, "message", "content")
end

puts "Odpowiedź: #{posts}"
puts ai.send_answer(posts)

