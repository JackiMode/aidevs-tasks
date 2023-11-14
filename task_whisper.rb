#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'

require 'open-uri'
# require 'uri'
require 'ai_task.rb'
require 'llm.rb'

ai = AiTask.new('whisper')
task = ai.task
puts task

audio_file_url = task['msg'].split(': ')[1]
uri = URI.parse(audio_file_url)
audio_file_name = File.basename(uri.path)
content = uri.read
File.open(audio_file_name, 'wb') do |file|
  file << content
end

llm = LLM.new
text = llm.transcribe(audio_file_name)
puts text
puts ai.send_answer(text)
