#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'

require 'ai_task.rb'
require 'llm.rb'

llm = LLM.new
hints = []

10.times do
  ai = AiTask.new('whoami')
  task = ai.task
  hints << task['hint']

  system_prompt = %Q(
    Let's play a game. Your task is to response to the user question about person in one word using a content provided below.

    content:###
    #{hints.join(". --- ")}
    ###
    Example: 
    User: Who is that person?
    Assistant: Donald Tusk
  )
  messages = [
    {role: "system", content: system_prompt},
    {role: "user", content: "Kim jest ta osoba?"},
  ]
  # puts messages
  answer = llm.chat(:messages => messages)
  puts hints.join(". \n ")
  puts answer
  begin 
    ra =  ai.send_answer(answer)
    exit if ra['code'] == 0
  rescue StandardError => _e
    next
  end
end

