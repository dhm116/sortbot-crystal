require "http/client"
require "uri"
require "./sortbot/exam"
include Sortbot

Domain = "https://api.noopschallenge.com"

uri = URI.parse(Domain)
client = HTTP::Client.new(uri)

response = client.post(
  "/sortbot/exam/start",
  headers: HTTP::Headers{"Content-Type" => "application/json"},
  body: {login: "dhm116"}.to_json
)

exam_response = Exam::Response.from_json(response.body)

while !exam_response.nextSet.nil?
  # puts exam_response.to_pretty_json()

  response = client.get "#{exam_response.nextSet.as(String)}"

  question = Exam::Question.from_json(response.body)
  puts question.to_pretty_json()
  puts
  puts question.intention

  sorted = question.sort
  # puts "Sorted value: #{sorted}"

  response = client.post(
    question.setPath,
    headers: HTTP::Headers{"Content-Type" => "application/json"},
    body: {solution: sorted}.to_json
  )

  # puts response.body

  exam_response = Exam::SolutionResponse.from_json(response.body)
end
puts
puts exam_response.to_pretty_json()

client.close
