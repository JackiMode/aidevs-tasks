#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

class ResponseError < StandardError
  attr_reader :uri, :res
  def initialize(msg, res, uri, log, method)
    @uri = uri
    @res = res
    super("#{msg}: #{method} #{uri} return #{res.code} #{res.message} #{JSON.parse(res.body)}")
    log.write("#{msg}: #{method} #{uri} return #{res.code} #{res.message} \"#{JSON.parse(res.body)['msg']}\"")
  end
end
