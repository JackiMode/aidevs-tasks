#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'

require 'ai_task.rb'
require 'llm.rb'

ai = AiTask.new('functions')
task = ai.task

puts task

function_definition = {
  "name": "addUser",
  "description": "Add new user",
  "parameters": {
      "type": "object",
      "properties": {
          "name": {
              "type": "string",
              "description": "User's first name eg. John",
          },
          "surname": {
              "type": "string",
              "description": "User's surename eg. Doe",
          },
          "year": {
              "type": "integer",
              "description": "User's birth year",
          },
      },
      "required": ["name", "surname", "year"],
  }
}

puts function_definition.class
puts function_definition
puts ai.send_answer(function_definition)
