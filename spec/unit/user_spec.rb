require_relative '../../app/models/user'

module Todoable
  RSpec.describe User do
    describe 'validates' do
      it 'email presence' do
        user = User.new(email: '', password: 'asdfasdf')
        expect(user.valid?).to eq(false)
        user.email = 'asdf@asdf.com'
        expect(user.valid?).to eq(true)
      end

      it 'email uniqueness', :db do
        asdf_email = 'asdf@asdf.com'
        user_1 = User.create(email: asdf_email, password: 'asdfasdf')
        expect(user_1.valid?).to eq(true)
        begin
          User.create(email: asdf_email, password: 'asdfasdf')
        rescue Exception => e
          expect(e.class).to eq(Sequel::UniqueConstraintViolation)
        end
      end

      it 'email downcase-ness', :db do
        user = User.create(email: 'ASDF@ASDF.COM',
                           password: 'asdfasdf')
        expect(user.email).to eq('asdf@asdf.com')
      end

      it 'password_digest presence' do
        user = User.new(email: 'asdf@asdf.com')
        expect(user.valid?).to eq(false)
        user.set(password: 'asdfasdf')
        expect(user.valid?).to eq(true)
      end
    end

    describe 'callbacks' do
      it 'should generate a token after', :db do
        user = User.create(email: 'asdf@asdf.com', password: 'asdfasdf')
        expect(user.token).not_to eq(nil)
      end
    end
  end
end
