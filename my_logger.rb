#!/usr/bin/env ruby
# frozen_string_literal: true

class MyLogger 
  attr_accessor :file
  def initialize(filename)
    @file = File.open(filename, 'a')
    @file.sync = true
  end

  def write(msg)
    @file << "#{Time.now}: #{msg}\n"
  end

end
