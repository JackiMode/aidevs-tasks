#!/usr/bin/env ruby
# frozen_string_literal: true

require 'dotenv/load'
require 'httparty'
require 'json'

class AiTask
  attr_reader :api_key, :endpoint
  attr_accessor :task_name, :token

  def initialize(task_name)
    @api_key = ENV['apikey']
    @endpoint = 'https://zadania.aidevs.pl/'
    @task_name = task_name
    @token = get_token
  end

  def send_answer(answer)
    return unless @token
    url = "#{@endpoint}answer/#{@token}"
    data = { "answer": "#{answer}", "author": "jacki" }.to_json
    response =  HTTParty.post(url, body: data)
    puts response
  end

  def get_task
    return unless @token
    url = "#{@endpoint}task/#{@token}"
    response =  HTTParty.get(url)
  end

  private 

  def get_token
    url = "#{@endpoint}token/#{@task_name}"
    data = { "apikey": "#{@api_key}", "author": "jacki" }.to_json
    response =  HTTParty.post(url, body: data)
    token = response['code'].zero? ? response['token'] : nil
  end

end
