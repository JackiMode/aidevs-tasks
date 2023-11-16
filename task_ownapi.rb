#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'

require 'ai_task.rb'
require 'llm.rb'
require 'dotenv/load'
require 'webrick'


@ai = AiTask.new('ownapi')
task = @ai.task

@llm = LLM.new

puts task
puts @ai.send_answer(ENV['OWN_API_ENDPOINT'])
