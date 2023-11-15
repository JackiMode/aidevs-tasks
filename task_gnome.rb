#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'

require 'ai_task.rb'
require 'llm.rb'

ai = AiTask.new('gnome')
task = ai.task

# image_file = File.open(task['url'], 'r')
puts task
puts " --- QUESTION: #{task['url']}"

system_prompt = %Q(
  Your task is to recognize color of Gnomes hat. 
  If there is no gnome on the image just return NO_GNOME_DETECTED and nothing more.
  If thre is a gnome on the image just return name of color of his hat in polish langueageand noting more.
  Example valid answers:###
  - Assistant: NO_GNOME_DETECTED
  - Assistant: czerwony
  - Assistant: żółty
)
llm = LLM.new
answer = llm.vision(:url => task['url'], :system_prompt => system_prompt, :prompt => "", :max_tokens => 350)
answer = 'ERROR' if answer =~ /NO_GNOME_DETECTED/
puts " --- ANSWER: #{answer}"
puts ai.send_answer(answer)