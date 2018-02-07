def create_list(list)
  post '/lists', JSON.generate(list)
  expect(last_response.status).to eq(201)
  expect(parsed).to match({ id: a_kind_of(Integer) })
  parsed[:id] ? parsed[:id] : false
end