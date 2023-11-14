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

COLLECTION_NAME = 'aidevs_task_people'
SQL_TABLE = 'aidevs_people'

@llm = LLM.new

@qdrant_client = Qdrant::Client.new(
  url: ENV['QDRANT_URL'],
  api_key: ENV['QDRANT_API_KEY']
)

def create_collection(client)
  client.collections.create(
    collection_name: COLLECTION_NAME,
    vectors: { size: 1536, distance: 'Cosine', on_disk: true },
  )
end

create_collection(@qdrant_client) unless @qdrant_client.collections.list.include? COLLECTION_NAME
@qdrant_client.collections.get(collection_name: COLLECTION_NAME)

def create_memory
  people = JSON.load File.open('people.json', 'r')
  sql_client = Mysql2::Client.new(:host => "localhost", :username => ENV['SQL_USER'], :password => ENV['SQL_PASSWORD'], :database => SQL_TABLE)
  people.each_with_index do |person, index|
    next if index > 2000

    embedding_text = %Q(
      Nazywam się #{person['imie']} #{person['nazwisko']}.
      O mnie: #{person['o_mnie']}
      Ulubiona postać z Kapitana bomby: #{person['ulubiona_postac_z_kapitana_bomby']}
      Ulubiony film: #{person['ulubiony_film']}
      Ulubiony serial: #{person['ulubiony_serial']}
      Ulubiony kolor: #{person['ulubiony_kolor']}
    )
    sql_payload = sql_client.escape(person.to_json)

    # Check if data is in database, skip if exists
    result = sql_client.query("select id from people where payload = '#{sql_payload}';")
    next if result.count.positive?
    v = @llm.embedding(embedding_text)
    points = []
    uuid = SecureRandom.uuid
    points << { payload: {info: "#{person['imie']} #{person['nazwisko']}"}, vectors: v, id: uuid }
    begin
      sql_client.query("insert into people (id, payload) values ('#{uuid}', '#{sql_payload}');")
      r = @qdrant_client.points.upsert(
        collection_name: COLLECTION_NAME,
        batch: {
          ids: points.map { |point| point[:id] }, 
          vectors: points.map { |point| point[:vectors] }, 
          payloads: points.map { |point| point[:payload] }
        },
        wait: true
      )
      raise StandardError.new "Qdrant upsert failed with status #{r['status']}" unless r['status'] == 'ok'
    rescue StandardError => e
      puts "Creating row data failed with error: #{e}"
      puts "UUID: #{uuid}"
      @qdrant_client.points.delete(
        collection_name: COLLECTION_NAME,
        points: ["id": "#{uuid}"]
      )
      sql_client.query("delete people where id = '#{uuid}' ;")
      next
    end
    printf '.'
    if index % 10 == 0 
      puts " #{index}/#{people.size} (sleep for 10s. avoiding qdrant api limiting)"
      sleep 10
    end
  end
end

ai = AiTask.new('people')
task = ai.task
puts "-- QUESTION: #{task['question']}"

v = @llm.embedding(task['question'])
rs = @qdrant_client.points.search(
    collection_name: COLLECTION_NAME, # required
    limit: 3,              # required
    vector: v,           # required
    with_payload: true,
    with_vector: true
    # score_threshold: "float"
)
if rs['status'] == 'ok'
  memory = []
  rs['result'].size.times do |i|
    uuid = rs['result'][i]['id']
    sql_client = Mysql2::Client.new(:host => "localhost", :username => ENV['SQL_USER'], :password => ENV['SQL_PASSWORD'], :database => SQL_TABLE)
    result = sql_client.query("select * from people where id = '#{uuid}' limit 1;").first
    person = JSON.parse(result['payload'])
    record = %Q(
      Lp. #{i}
      Info o użytkowniku: #{person['imie']} #{person['nazwisko']}.
      Informacje: #{person['o_mnie']}
      Ulubiona postać z Kapitana bomby: #{person['ulubiona_postac_z_kapitana_bomby']}
      Ulubiony film: #{person['ulubiony_film']}
      Ulubiony serial: #{person['ulubiony_serial']}
      Ulubiony kolor: #{person['ulubiony_kolor']}
    )
    memory << record
  end
  system_prompt = %Q(
    Odpowiedź na pytanie dotyczące użytkownika na podstawie bazy wiedzy o nim możliwie zwięźle zgodnie z przykłądami.

    baza wiedzy:###
    #{memory.join('---')}
    ###
    Example 1: 
    User: Gdzie mieszka Donald Tusk?
    Assistant: Donald Tusk mieszka w Gdańsku
    Example 2: 
    User: Jaki jest ulubiony kolor Donalda Tuska?
    Assistant: Uluionym kolorem Donalda Tuska jest kolor czerwony
  )
  messages = [
    {role: "system", content: system_prompt},
    {role: "user", content: task['question']},
  ]
  # puts system_prompt
  answer = @llm.chat(:messages => messages)
  puts "-- ANSWER: #{answer}"
  puts rs['result'][0]['payload']
  puts ai.send_answer(answer)
end