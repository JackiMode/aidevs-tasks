#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'

require 'ai_task.rb'
require 'llm.rb'
require "awesome_print"

ai = AiTask.new('optimaldb')
task = ai.task

json_file = File.read('3friends_op.json')
j = JSON.parse(json_file)
ap j

puts j.to_s.length

#puts ai.send_answer(j.to_s)

# @llm = LLM.new
