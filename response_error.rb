#!/usr/bin/env ruby
# frozen_string_literal: true

class ResponseError < StandardError
  attr_reader :uri, :res
  def initialize(msg, res, uri, log)
    @uri = uri
    @res = res
    super("#{msg}: #{uri} return #{res.code} #{res.message} #{res.body}")
    log.write("#{uri} return #{res.code} #{res.message}")
    puts "LOG: #{uri} return #{res.code} #{res.message}"
  end
end
