require_relative '../../../../app/models/user'

module Todoable
  RSpec.describe User, :db do
    describe 'email' do
      it 'should be present' do
        user = User.new(email: '',
                        password: 'asdfasdf')
        expect(user.valid?).to eq(false)
        user.email = 'asdf@ASDF.com'
        user.save
        expect(user.valid?).to eq(true)
      end

      it 'should be unique', :db do
        asdf_email = 'asdf@asdf.com'
        user = User.new(email: asdf_email,
                        password: 'asdfasdf')
        user.save
        user_2 = User.new(email: asdf_email,
                          password: 'asdfasdf')
        expect(user_2.valid?).to eq(true)
      end

      it 'should automatically downcase the email', :db do
        user = User.new(email: 'ASDF@ASDF.COM',
                        password: 'asdfasdf')
        user.save
        expect(user.email).to eq('asdf@asdf.com')
      end

      it 'should have a password_digest' do
        user = User.new(email: 'asdf@asdf.com')
        expect(user.valid?).to eq(false)
        user.set(password: 'asdfasdf')
        expect(user.valid?).to eq(true)
      end

      it 'should generate a token after', :db do
        user = User.new(email: 'asdf@asdf.com',
                        password: 'asdfasdf')
        expect(user.token).to eq(nil)
        user.save
        expect(user.token).not_to eq(nil)
      end
    end
  end
end