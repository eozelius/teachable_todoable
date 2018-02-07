def create_list(list)
  post '/lists', JSON.generate(list)
  expect(last_response.status).to eq(201)
  expect(parsed_response).to match({ id: a_kind_of(Integer) })
  parsed_response[:id] ? parsed_response[:id] : false
end

def parsed_response
	JSON.parse(last_response.body, { symbolize_names: true })
end