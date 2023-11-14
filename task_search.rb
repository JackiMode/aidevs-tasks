#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'

require 'ai_task.rb'
require 'llm.rb'
require 'qdrant'
require 'dotenv/load'
require 'json' 
require 'securerandom'
require 'mysql2'

COLLECTION_NAME = 'aidevs_task_search'

def create_collection(client)
  client.collections.create(
    collection_name: COLLECTION_NAME,
    vectors: { size: 1536, distance: 'Cosine', on_disk: true },
  )
end

def create_points(points, qdrant_client)
  qdrant_client.points.upsert(
      collection_name: COLLECTION_NAME,
      batch: {
        ids: points.map { |point| point[:id] }, 
        vectors: points.map { |point| point[:vectors] }, 
        payloads: points.map { |point| point[:payload] }
      },
      wait: true
    ) if points.size > 0
    end

sql_client = Mysql2::Client.new(:host => "localhost", :username => ENV['SQL_USER'], :password => ENV['SQL_PASSWORD'], :database => ENV['SQL_TABLE'])

qdrant_client = Qdrant::Client.new(
  url: ENV['QDRANT_URL'],
  api_key: ENV['QDRANT_API_KEY']
)

create_collection(qdrant_client) unless qdrant_client.collections.list.include? COLLECTION_NAME
qdrant_client.collections.get(collection_name: COLLECTION_NAME)

llm = LLM.new
data = JSON.load File.open('archiwum.json', 'r')

# No need to read data if thay ar all proceeded
data = []

# Process each JSON row, create a corresponding SQL record, and add a point to the vector database.
i = 0
points = []
data.each do |row|
  # Payload creation and SQL checks for MariaDB
  payload = {url: row['url'], title: row['title'], info: row['info'], date: row['date']}
  begin
    sql_payload = sql_client.escape(payload.to_json)
    results = sql_client.query("select * from archiwum where payload = '#{sql_payload}';")
    if(results.count > 0) 
      qr = qdrant_client.points.get(
        collection_name: COLLECTION_NAME,
        id: results.first['id']
      )
      next if qr.result

      uuid = results.first['id']
      puts results.first['id']
    end

  # Generate UUID, Calculate vector using llm, and insert into MariaDB and Qdrant
    uuid = SecureRandom.uuid unless uuid
    v = llm.embedding("#{payload[:title]} #{payload[:info]}")
    sql_client.query("insert into archiwum (id, payload) values ('#{uuid}', '#{sql_payload}')")
  rescue StandardError => e
    # puts e
    # puts payload
    # puts sql_payload
  end
  points << { payload: payload, vectors: v, id: uuid }
  i += 1

  # Display progress, creating Qdrant points and sleep to avoid embedding api rate limiting
  if i % 100 == 0
    # Creating Qdrant points
    create_points(points, qdrant_client)
    points = []
    puts i
    sleep 30
  end
  printf '.'
end

create_points(points, qdrant_client)

ai = AiTask.new('search')
task = ai.task
puts "Question: #{task['question']}"

v = llm.embedding(task['question'])

rs = qdrant_client.points.search(
    collection_name: COLLECTION_NAME, # required
    limit: 1,              # required
    vector: v,           # required
    with_payload: true,
    with_vector: true
    # score_threshold: "float"
)

answer = rs['result'][0]['payload']['url']
puts "Answer: #{answer}"
puts ai.send_answer(answer)

