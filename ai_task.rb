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
    @endpoint = ENV['url']
    @task_name = task_name
    @token = api_token
  end

  def send_answer(answer)
    post("#{@endpoint}answer/#{@token}", { "answer": answer }.to_json)
  end

  def task
    get("#{@endpoint}task/#{@token}")
  end

  private 

  def validate_response(response, url, method)
    return if response.code.to_s.match?(/^200$/)
    
    raise ResponseError.new("#{Time.now} RESPONSE ERROR", response, url, @log, method)
  end

  def api_token
    response = post("#{@endpoint}token/#{@task_name}", { "apikey": @api_key.to_s }.to_json)
    @token = response['token']
  end

  def post(url, data)
    response = HTTParty.post(url, body: data)
    validate_response(response, url, 'POST')
    response
  end

  def get(url)
    response = HTTParty.get(url)
    validate_response(response, url, 'GET')
    response
  end
end
