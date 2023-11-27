#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'

require 'ai_task.rb'
require 'llm.rb'
require 'faker'
require 'awesome_print'

def convert_phrase(s, tag)
  etag = Regexp.escape(tag)
  if ['*', '**'].include? tag
    {:md => s, :html => s} if s.match("^#{etag}[^#{etag}]") || s.match("[^#{etag}]#{etag}$")
  end
  result = case tag
  when "#"
    {:md => "# #{s}", :html => "<h1>#{s}</h1>"}
  when "##"
    {:md => "## #{s}", :html => "<h2>#{s}</h2>"}
  when "###"
    {:md => "### #{s}", :html => "<h3>#{s}</h3>"}
  when "**"
    {:md => "**#{s}**", :html => "<strong>#{s}</strong>"}
  when "*"
    {:md => "*#{s}*", :html => "<i>#{s}</i>"}
  when "_"
    {:md => "_#{s}_", :html => "<u>#{s}</u>"}
  when "<"
    {:md => "< #{s}", :html => "<blockquote>#{s}</blockquote>"}
  else
    {:md => s, :html => s}
  end
end

def generate_sentence()
  start_tags = ['#', '##', '###', '<', '', '']
  middle_tags = ['**', '*', '_', '', '']
  chunks = []
  s = ''

  # Sentence lenght mus be beetween 20 and 100 characters
  while(s.size > 100 || s.size < 20) do
    s = rand(2) == 0 ? Faker::Quote.famous_last_words : Faker::Movies::Hobbit.quote
  end

  # Remove " and ' chars from sentence and slice it in groups of 3 words
  s.gsub('"', '').gsub("'", "").split(' ').each_slice(3) do |chunk|
    random_tag_index = rand(0..(middle_tags.length - 1))
    chunks << convert_phrase(chunk.join(' '), middle_tags[random_tag_index])
  end
  
  # Combining two array fields on larger sentences at random point
  if chunks.length > 3
    random_index = rand(0..(chunks.length - 2))
    merged_md = chunks[random_index][:md] + ' ' + chunks[random_index + 1][:md]
    merged_html = chunks[random_index][:html] + ' ' + chunks[random_index + 1][:html]
    if rand(2) == 0
      random_tag_index = rand(0..(middle_tags.length - 1))
      merged_md = convert_phrase(merged_md, middle_tags[random_tag_index])[:md]
      merged_html = convert_phrase(merged_html, middle_tags[random_tag_index])[:html]
    end
    merged_string = {:md => merged_md, :html => merged_html}

    # remove combined elements and add new one
    chunks.slice!(random_index, 2)
    chunks.insert(random_index, merged_string)

  end

  #
  md_combined = chunks.map { |item| item[:md] }.join(' ')
  html_combined = chunks.map { |item| item[:html] }.join(' ')
  random_tag_index = rand(0..(start_tags.length - 1))
  final_md = convert_phrase(md_combined, start_tags[random_tag_index])[:md]
  final_html = convert_phrase(html_combined, start_tags[random_tag_index])[:html]
  sentence = {:md => final_md, :html => final_html}
  sentence
end

def create_training_data(file)
  f = File.open(file, 'w')
  50.times do 
    s = generate_sentence()
    puts "X" if s[:md] == s[:html]
    line = "{\"messages\":[{\"role\":\"system\",\"content\":\"Convert md to html\"},{\"role\":\"user\",\"content\":\"#{s[:md]}\"},{\"role\":\"assistant\",\"content\":\"#{s[:html]}\"}]}"
    puts line
    f << "#{line}\n"
  end
  
end

create_training_data('task_md2html.jsonl')
