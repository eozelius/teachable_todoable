include Rack::Test::Methods

def parsed
  JSON.parse(last_response.body, { symbolize_names: true })
end

def post_list(list)
  post '/lists', JSON.generate(list)
  expect(last_response.status).to eq(201)
  parsed = JSON.parse(last_response.body, { symbolize_names: true })
  expect(parsed).to match({ id: a_kind_of(Integer) })
end


