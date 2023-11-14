#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'

require 'dotenv/load'
require 'httparty'
require 'json'
require 'response_error.rb'
require 'my_logger.rb'
require 'openai' #https://github.com/alexrudall/ruby-openai

class LLM 
  attr_reader :api_key, :organization_id, :log, :client, :models
  attr_accessor :model

  def initialize(options = {})
    @log = MyLogger.new('logs/open_ai.log')
    @api_key = ENV['OPENAI_ACCESS_TOKEN']
    @organization_id = ENV['OPENAI_ORGANIZATION_ID']
    OpenAI.configure do |config|
      config.access_token = @api_key
      config.organization_id = @organization_id
      config.request_timeout = 720
    end
    @client = OpenAI::Client.new

    # Hardcoded model names
    @models = ['gpt-3.5-turbo', 'gpt-3.5-turbo-0613', 'gpt-4', 'gpt-4-0613']
    @model = {}
    @model[:audio] = 'whisper-1'
    @model[:embedding] = 'text-embedding-ada-002'

    # Set default model name for chat 'gpt-3.5-turbo' unless specified
    options = {} if options.class != Hash
    options.merge!(default_model_name: 'gpt-3.5-turbo') { |key, important, default| important }
    set_default_model(options[:default_model_name])
  end

  def set_default_model(model_name)
    @model[:chat] = model_name if @models.include? model_name
    return @model[:chat] == model_name
  end

  def functions_chat(options = {})
    messages = options[:messages] ? options[:messages] : [{role: "user", content: "Hi Bot!"}] 
    model_name = @model[:chat] unless options[:model_name]
    temperature = 0.5 unless options[:temperature]
    begin
      response = @client.chat(
      parameters: {
          model: model_name,
          messages: messages,
          temperature: temperature,
          functions: options[:functions] 
      })
    rescue StandardError => e
      puts e
    end
    # puts '---'
    # puts response
    # puts '==='
    # puts response.dig("choices", 0, "message", "function_call")
    # puts '$$$'
    response.dig("choices", 0, "message", "function_call")
  end

  def chat(options = {})
    messages = options[:messages] ? options[:messages] : [{role: "user", content: "Hi Bot!"}] 
    return functions_chat(options) if options[:functions] 

    model_name = @model[:chat] unless options[:model_name]
    temperature = 0.5 unless options[:temperature]
    begin
      response = @client.chat(
      parameters: {
          model: model_name,
          messages: messages,
          temperature: temperature,
      })
    rescue StandardError => e
      puts e
    end
    response.dig("choices", 0, "message", "content")
  end

  def embedding(sentence)
    response = @client.embeddings(
      parameters: {
          model: @model[:embedding],
          input: sentence
      }
    )
    response.dig("data", 0, "embedding")
  end

  def transcribe(file_name)
    response = @client.audio.transcribe(
    parameters: {
        model: @model[:audio],
        file: File.open(file_name, "rb"),
    })
    response["text"]
  end

end