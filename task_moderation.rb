#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'

require 'net/http'
require 'openai' #https://github.com/alexrudall/ruby-openai
require 'ai_task.rb'


# curl https://api.openai.com/v1/moderations \
#   -H "Content-Type: application/json" \
#   -H "Authorization: Bearer $OPENAI_API_KEY" \
#   -d '{
#     "input": "I want to kill them."
#   }'

ai = AiTask.new('moderation')
task = ai.task
task_response = []

moderation_url = 'https://api.openai.com/v1/moderations'
headers = { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{ENV.fetch('OPENAI_ACCESS_TOKEN')}" }
task['input'].each do |line|
  body = JSON.generate({ input: line.strip })
  response = HTTParty.post(moderation_url, body: body, headers: headers)
  puts response
  r = response['results'][0]['flagged'] ? 1 : 0
  task_response << r
end
puts "[#{task_response.join(',')}]"
puts ai.send_answer(task_response)
