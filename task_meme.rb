#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'

require 'ai_task.rb'
require 'llm.rb'
require 'json'
require 'httparty'

ai = AiTask.new('meme')
task = ai.task.parsed_response

data = {
  "api-key" => ENV['MAKECOM_RENDERFORM_WEBHOOK_KEY'],
  "image_url" => task['image'],
  "image_captions" => task['text'],
}

response =  HTTParty.post(ENV['MAKECOM_RENDERFORM_WEBHOOK'], body: JSON.generate(data), headers: { 'Content-Type' => 'application/json' } )
puts response
ai.send_answer(response)

