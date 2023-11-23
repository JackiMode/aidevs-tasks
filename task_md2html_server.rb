#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'

require 'llm.rb'
require 'webrick'

server = WEBrick::HTTPServer.new(Port: 5432)

@llm = LLM.new
@llm.set_default_model('ft:gpt-3.5-turbo-1106:personal::8O3pNwzJ')
@log = MyLogger.new('logs/ai_devs_finetuned_server.log')

def md2html(sentence)
  messages = [
    {role: "system", content: 'Convert md to html'},
    {role: "user", content: sentence},
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
    answer = md2html(question)
    rb = JSON.generate({'reply' => answer})
    @log.write(">>> ASSISTANT:  #{answer} ")
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