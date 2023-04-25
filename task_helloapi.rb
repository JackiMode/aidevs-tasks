#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'

require 'ai_task.rb'

ai = AiTask.new('helloapi')
task = ai.get_task
ai.send_answer(task['cookie'])
