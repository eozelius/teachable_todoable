require_relative '../../../app/models/list'

module Todoable
  RSpec.describe List do
    let(:src) { 'http://todoable.teachable.tech/api/lists/1' }

    describe 'validates' do
      it 'name' do
        my_list = List.new(name: '', user_id: 1)
        expect(my_list.valid?).to eq(false)
        my_list.set(name: 'my hobbies')
        expect(my_list.valid?).to eq(true)
      end

      it 'should belong to a user' do
        list = List.new(name: 'my hobbies', user_id: nil)
        expect(list.valid?).to eq(false)
        list.user_id = 1
        expect(list.valid?).to eq(true)
      end
    end

    describe 'callbacks' do
      it 'should assign a src after_save', :db do
        list = List.create(name: 'my hobbies', user_id: 1)
        expect(list.src).to eq("http://todoable.teachable.tech/api/lists/#{list.id}")
      end
    end

    describe 'json_response' do
      it 'returns a JSON element of itself', :db do
        list = List.create(name: 'my hobbies', user_id: 1)
        expect(list.json_response).to eq({
          :list=> {
            :id=>1,
            :name=>"my hobbies",
            :items=>[]
          }
        })
      end

      it 'returns its Items in JSON format', :db do
        list = List.create(name: 'my hobbies', user_id: 1)
        list.add_item(name: 'cooking')
        json_list = list.json_response
        expect(json_list).to eq({
          :list => {
            :id=>1,
            :name=>"my hobbies",
            :items=>[
              {
                :id=>1,
                :name=>"cooking",
                :finished_at=>nil
              }
            ]
          }
        })
      end
    end
  end
end