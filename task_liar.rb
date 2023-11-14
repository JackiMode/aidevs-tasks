#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'

require 'ai_task.rb'
require 'openai' #https://github.com/alexrudall/ruby-openai

OpenAI.configure do |config|
  config.access_token = ENV.fetch('OPENAI_ACCESS_TOKEN')
  config.organization_id = ENV.fetch('OPENAI_ORGANIZATION_ID') # Optional.
end
client = OpenAI::Client.new

ai = AiTask.new('liar')
task = ai.task
url = "#{ai.endpoint}task/#{ai.token}"
question = 'What programming language has a red gemstone in its logo?'

res = Net::HTTP.post_form(URI.parse(url), {'question' => question})
aidevs_answer = JSON.parse(res.body)['answer']
puts aidevs_answer

sys_content = "Check if the answer is correct. Return YES or NO and nothing more."
user_content = %Q(QUESTION: #{question}
ANSWER: #{aidevs_answer})

puts  %Q(
  messages: 
    {role: "system", content: #{sys_content}}, 
    {role: "user",   content: #{user_content}}
  )

response = client.chat(
  parameters: {
      model: "gpt-4", # Required.
      messages: [{role: "system", content:sys_content}, { role: "user", content: user_content}], # Required.
      temperature: 0.7,
  })
r = response.dig("choices", 0, "message", "content")

puts "Odpowiedź: #{r}"
puts ai.send_answer(r)
