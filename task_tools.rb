#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'

require 'date'
require 'ai_task.rb'
require 'llm.rb'

ai = AiTask.new('tools')
task = ai.task
# puts task
puts " --- QUESTION: #{task['question']}"

functions = []
functions << {
  "name": "ToDo",
  "description": "Adds a quick note to user's todo list",
  "parameters": {
      "type": "object",
      "properties": {
          "desc": {
              "type": "string",
              "description": "The content of this entry",
          },
      },
      "required": ["desc",],
  }
}
functions << {
  "name": "Calendar",
  "description": "Add an entry to the user's calendar for a specific day",
  "parameters": {
      "type": "object",
      "properties": {
          "desc": {
              "type": "string",
              "description": "The content of this entry",
          },
          "date": {
              "type": "string",
              "description": "Date of this entry in format YYYY-MM-DD",
          },
      },
      "required": ["desc", "date"],
  }
}

days = []

7.times do |d|
  days << "#{(Date.today + d).strftime("W %Y-%m-%d jest %A")}"
end

system_content = %Q(
Twoim zadaniem jest kwalifikacja danych podanych przez użytkownika na potrzeby function_call.
Musisz uwzględniać bazę wiedzy:
baza_wiedzy:###
1. data jest w formacie YYYY-MM-DD
2. dzisiaj jest #{Date.today.strftime("%Y-%m-%d, dzisiaj jest %A")}
  #{days.join(' ;\n\r  ')}
3. wczoraj było #{(Date.today-1).strftime("%Y-%m-%d %a")}
4. za tydzień będzie #{(Date.today+7).strftime("%Y-%m-%d")}
###
Przykład:
User: Jutro mam spotkanie z Marianem
)

messages = [
    {role: "system", content: system_content},
    {role: "user", content: task['question']},
]

llm = LLM.new
llm.set_default_model('gpt-4-0613')
response = llm.chat(:messages => messages, :functions => functions)
answer = { "tool" => "#{response['name']}" }.merge(JSON.parse(response['arguments']))

puts " --- ANSWER: #{answer}"
puts ai.send_answer(answer)