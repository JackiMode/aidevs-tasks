#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'

require 'ai_task.rb'
require 'llm.rb'

ai = AiTask.new('md2html')
task = ai.task
puts task
puts ai.send_answer(ENV['OWN_API_ENDPOINT'])

