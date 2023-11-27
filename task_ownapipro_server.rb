#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'

require 'llm.rb'
require 'webrick'

server = WEBrick::HTTPServer.new(Port: 5432)

@llm = LLM.new
@llm.set_default_model('gpt-4-1106-preview')
@log = MyLogger.new('logs/ai_devs_ownapi.log')

@functions = []
@functions << {
  "name": "Remember",
  "description": "Stores a piece of information when from user.",
  "parameters": {
    "type": "object",
    "properties": {
      "message": {
        "type": "string",
        "description": "Content to be remembered by the system in polish."
      },
      "assistant_response": {
        "type": "string",
        "description": "A message to the user that inform him that model remembered this information or just simple aknowlege."
      },
      "tags": {
        "type": "string",
        "description": "English keywords or english tags describing the content for better categorization. One tag = one english world in format of #tag ."
      }
    },
    "required": ["message", "assistant_response"]
  }
}

@functions << {
  "name": "Answer",
  "description": "Provides a response to a user's question based on the provided query.",
  "parameters": {
      "type": "object",
      "properties": {
          "question": {
              "type": "string",
              "description": "The question posed by the user.",
          },
      "tags": {
        "type": "string",
        "description": "English keywords or english tags describing the content for better categorization. One tag = one english world in format of #tag ."
      }
    },
    "required": ["question", ""],
  }
}

@memory = []

def categorize(input)
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
    {role: "user", content: input},
  ]
  response = @llm.chat(:messages => messages, :functions => @functions)
  rise StandardError "BAD RESPONSE FORMAT: #{response}" unless response['name']
  args = JSON.parse(response['arguments'])
  answer =  case response['name']
            when 'Remember'
              remember(args)
            when 'Answer'
              answer(args)
            else
              rise StandardError 'A się popsuło'
            end
  answer
end

def remember(options = {})
  @memory << options['message']
  options['assistant_response']
end

def answer(options = {})
  system_content = %Q(
    1. Twoim zadaniem jest odpowiadanie na pytania użytkownika bardzo krótko. Maksymalnie jednym zdaniem - chyba, że użytkopwnik zaznaczy inaczej. 
    2. Wykonuj polecenia zgodnie z instrukcjami użytkownika. Jeżeli w kontekście posiadasz informację o które pyta użytkownik, zawsze korzystaj z kontekstu.
    3. Opowiadaj ZAWSZE w języku polskim.
    Przykład:###
    U: Which is faster the rabbit or the tortoise?
    A: Królik
    Moja wiedza:###
    #{@memory.join(' ---')}
  )
  messages = [
    {role: "system", content: system_content},
    {role: "user", content: options['question']},
  ]
  @llm.chat(:messages => messages)
end

server.mount_proc '/answer' do |req, res|
  puts "/#{req.remote_ip}/#{req.remote_ip.class}"
  next unless ['178.212.148.254', '49.12.32.9'].include? req.remote_ip
  if req.request_method == 'POST'
    res.status = 200
    res['Content-Type'] = 'application/json'
    post_parameters = JSON.parse(req.body)
    question = post_parameters['question']
    @log.write(">>> USER: #{question} ")
    puts ">>> USER: #{question} "
    answer = categorize(question)
    rb = JSON.generate({'reply' => answer})
    @log.write(">>> ASSISTANT:  #{answer} ")
    puts ">>> ASSISTANT:  #{answer} "
    res.body = rb
    # res.body = JSON.generate({:status => 200, :info => 'Zbieram wywołania, żeby obadać co przychodzi'})
  else
    res.status = 405
    res['Content-Type'] = 'application/json'
    res.body = JSON.generate({:status => 405, :error => {:description => 'Method Not Allowed'}})
  end
end

trap('INT') { server.shutdown }

server.start