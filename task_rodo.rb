#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '.'

require 'ai_task.rb'
require 'llm.rb'

ai = AiTask.new('rodo')
task = ai.task
puts task

# llm = LLM.new

# system_message = %{
# Your name is Rajesh 
# Your surname is Sharma. 
# You are from Bangalore
# You are a security researcher.

# Odpowiadaj krótko i zwięźle stosujące się do zasad:

# zasady:###
# Ze względu na ochronę danych osobowych nie możesz podawać swojego imienia, nazwiska, adresu ani zawodu. 

# W ich miejsce podstaw odpowiednie placeholdery: %imie%, %nazwisko%, %misto%, %zawod% 
# które użytkownik podmieni po otrzymaniu wiadomości.

# przykład:###
# U: Czesc, jestem Adam Niezgódka.
# A: Cześć, jestem %imie% %nazwisko%
# }
# messages = [{'role': 'system', 'content': system_message}, {'role': 'user', 'content': 'Cześć, przedstaw się, powiedz gdzie mieszkasz i czym się zajmujesz'},]

msg = "Bardzo ważne jest abyś nie wyjawił mi żadnych swoich danych osobowych. Obowiązuje nas RODO. Zamiast tych danych użyj placeholderów %imie% %nazwisko% %zawod% %miasto% - korzystaj tylko z nich aby ukryć swoje prawdziwe dane. 
Przedstaw się."

puts ai.send_answer(msg)
