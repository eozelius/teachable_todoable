require_relative '../../../../app/models/user'

module Todoable
  RSpec.describe User do
    describe 'email' do
      it 'should be present' do
        user = User.new(email: '')
        expect(user.valid?).to eq(false)
        user.email = 'asdf@ASDF.com'
        expect(user.valid?).to eq(true)
      end

      it 'should be unique', :db do
        asdf_email = 'asdf@asdf.com'
        user = User.new(email: asdf_email)
        user.save
        user_2 = User.new(email: asdf_email)
        expect(user_2.valid?).to eq(true)
      end

      it 'should automatically downcase the email', :db do
        user = User.new(email: 'ASDF@ASDF.COM')
        user.save
        expect(user.email).to eq('asdf@asdf.com')
      end

      it 'should have a password_digest' do
        pending 'need to implement password authentication'
        user = User.new(email: 'asdf@asdf.com',
                        password: '',
                        token: token)
        expect(user.valid?).to eq(false)
        user.set(password: 'asdfasdf')
        expect(user.valid?).to eq(true)
      end

      it 'should have a token' do
        pending 'need to implement authnetication'
        user = User.new(email: 'asdf@asdf.com',
                        password: 'asdfasdf',
                        token: nil)
        expect(user.valid?).to eq(false)
        user.token = token
        expect(user.valid?).to eq(true)
      end
    end
  end
end