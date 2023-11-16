#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'

require 'llm.rb'
require 'webrick'

server = WEBrick::HTTPServer.new(Port: 5432)

@llm = LLM.new
@llm.set_default_model('gpt-4-1106-preview')
@log = MyLogger.new('logs/ai_devs_ownapi.log')

def answer(question)
  messages = [
    {role: "system", content: 'Twoim zadaniem jest odpowiadanie na pytania użytkownika nbardzo krótko. Maksymalnie jednym zdaniem - chyba, że użytkopwnik zaznaczy inaczej. Wykonuj polecenia zgodnie z instrukcjami użytkownika.'},
    {role: "user", content: question},
  ]
  @llm.chat(:messages => messages)
end

server.mount_proc '/answer' do |req, res|
  if req.request_method == 'POST'
    res.status = 200
    res['Content-Type'] = 'application/json'
    post_parameters = JSON.parse(req.body)
    question = post_parameters['question']
    @log.write(">>> QUESTION: #{question} ")
    answer = answer(question)
    rb = JSON.generate({'reply' => answer})
    @log.write(">>> ANSWER:  #{answer} ")
    res.body = rb
  else
    res.status = 405
    res['Content-Type'] = 'application/json'
    res.body = JSON.generate({:status => 405, :error => {:description => 'Method Not Allowed'}})
  end
end

trap('INT') { server.shutdown }

server.start