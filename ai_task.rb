#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'

require 'dotenv/load'
require 'httparty'
require 'json'
require 'response_error.rb'
require 'my_logger.rb'

class AiTask
  attr_reader :api_key, :endpoint, :task_name, :log
  attr_accessor :token

  def initialize(task_name)
    @log = MyLogger.new('logs/ai_devs.log')
    @api_key = ENV['apikey']
    @endpoint = 'https://zadania.aidevs.pl/'
    @task_name = task_name
    @token = get_token
  end

  def send_answer(answer)
    url = "#{@endpoint}answer/#{@token}"
    data = { "answer": answer}.to_json
    response =  HTTParty.post(url, body: data)
    validate_response(response, url, 'POST')
    response
  end

  def get_task
    url = "#{@endpoint}task/#{@token}"
    response =  HTTParty.get(url)
    validate_response(response, url, 'POST')
    response
  end

  private 

  def validate_response(response, url, method)
    return if response.code.to_s.match?(/^200$/)
    raise ResponseError.new("#{Time.now} RESPONSE ERROR", response, url, @log, method)
  end

  def get_token
    url = "#{@endpoint}token/#{@task_name}"
    data = { "apikey": "#{@api_key}"}.to_json
    response =  HTTParty.post(url, body: data)
    validate_response(response, url, 'POST')
    @token = response['token']
  end

end
