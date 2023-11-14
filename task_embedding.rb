#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'

require 'ai_task.rb'
require 'llm.rb'

ai = AiTask.new('embedding')
task = ai.task
sentence = task['msg'].split(': ')[1]

llm = LLM.new
e =  llm.embedding(sentence)
puts ai.send_answer(e)
