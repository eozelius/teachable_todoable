require_relative '../../../app/models/user'

module Todoable
  RSpec.describe User do
    describe 'email' do
      it 'should be present' do
        user = User.new(email: '', password: 'asdfasdf')
        expect(user.valid?).to eq(false)
        user.email = 'asdf@asdf.com'
        expect(user.valid?).to eq(true)
      end

      it 'should be unique', :db do
        asdf_email = 'asdf@asdf.com'
        user_1 = User.create(email: asdf_email, password: 'asdfasdf')
        expect(user_1.valid?).to eq(true)
        begin
          User.create(email: asdf_email, password: 'asdfasdf')
        rescue Exception => e
          expect(e.class).to eq(Sequel::UniqueConstraintViolation)
        end
      end

      it 'should automatically downcase the email', :db do
        user = User.create(email: 'ASDF@ASDF.COM',
                        password: 'asdfasdf')
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