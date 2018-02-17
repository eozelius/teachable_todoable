require 'base64'
require 'json'

def create_auth_header(email, password)
  user_pass_digest = Base64.encode64("#{email}:#{password}")
  header 'Authorization', "Basic #{user_pass_digest}"
end

def create_token_header(token)
  token_header = "Token token=\"#{Base64.encode64(token)}\""
  header 'Authorization', token_header
end

def create_list(list, token)
  create_token_header(token)
  post '/lists', JSON.generate(list)
  expect(last_response.status).to eq(201)
  expect(parsed_response).to match({ id: a_kind_of(Integer) })
  parsed_response[:id] ? parsed_response[:id] : false
end

def parsed_response
  return '' if last_response.body == ''
	JSON.parse(last_response.body, { symbolize_names: true })
end