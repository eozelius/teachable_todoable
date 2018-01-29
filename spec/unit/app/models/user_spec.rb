require_relative '../../../../app/models/user'

module Todoable
  RSpec.describe User do
    let(:token) { SecureRandom.urlsafe_base64(nil, false) }

    it 'should have an email' do
      user = User.new(email: '',
                      password: 'asdfasdf',
                      token: token)
      expect(user.valid?).to eq(false)
      user.email = 'asdf@asdf.com'
      expect(user.valid?).to eq(true)
    end

    it 'should have a password_digest' do
      user = User.new(email: 'asdf@asdf.com',
                      password: '',
                      token: token)
      expect(user.valid?).to eq(false)
      user.password = 'asdfasdf'
      expect(user.valid?).to eq(true)
    end

    it 'should have a token' do
      user = User.new(email: 'asdf@asdf.com',
                      password: 'asdfasdf',
                      token: nil)
      expect(user.valid?).to eq(false)
      user.token = token
      expect(user.valid?).to eq(true)
    end
  end
end