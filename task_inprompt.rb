#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'

require 'ai_task.rb'

ai = AiTask.new('inprompt')
task = ai.get_task
system_msg =  task['msg']
question = task['question']

puts "Pytanie: #{question}"

require 'openai' #https://github.com/alexrudall/ruby-openai

OpenAI.configure do |config|
  config.access_token = ENV.fetch('OPENAI_ACCESS_TOKEN')
  config.organization_id = ENV.fetch('OPENAI_ORGANIZATION_ID') # Optional.
end

client = OpenAI::Client.new

response = client.chat(
  parameters: {
      model: "gpt-3.5-turbo", # Required.
      messages: [{ role: "user", content: "Podaj mi tylko imię osoby, o której mowa jest w pytaniu '#{question}'. Podaj tylko imię i nic więcej. "}], # Required.
      temperature: 0,
  })

name = response.dig("choices", 0, "message", "content").gsub('.', '')

desc = ''
task['input'].each do |line|
  next unless line =~ /#{name}/
  desc = line
end

puts "Wiedza: #{desc}"
response = client.chat(
  parameters: {
      model: "gpt-3.5-turbo", # Required.
      messages: [{ role: "user", content: "Wiesz, że '#{desc}'. Odpowiedz na pytanie: '#{question}' "}], # Required.
      temperature: 0,
  })

answer =  response.dig("choices", 0, "message", "content").gsub('.', '')

puts "Odpowiedź: #{answer}"
puts ai.send_answer(answer)