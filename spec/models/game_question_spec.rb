require 'rails_helper'

RSpec.describe GameQuestion, type: :model do

  let(:game_question) {FactoryGirl.create(:game_question, a: 2, b: 1, c: 4, d: 3)}

  #Проверяем корректность методов связанных с ответами
  describe '#variants' do
    it 'get correct answer variants' do
      expect(game_question.variants).to eq(
                                          {
                                            'a' => game_question.question.answer2,
                                            'b' => game_question.question.answer1,
                                            'c' => game_question.question.answer4,
                                            'd' => game_question.question.answer3
                                          }
                                        )
    end
  end

  describe '#answer_correct?' do
    context 'when answer is correct' do
      it 'return true' do
        expect(game_question.answer_correct?('b')).to be_truthy
      end
    end
  end

  describe '#correct_answer_key' do
    it 'get correct answer key' do
      expect(game_question.correct_answer_key).to eq 'b'
    end
  end

  #проверяем delegate методы
  describe 'delegate methods' do
    describe '#text' do
      it 'there is' do
        expect {game_question.text}.not_to raise_exception
      end
    end
    describe '#level' do
      it 'there is' do
        expect {game_question.level}.not_to raise_exception
      end
    end
  end

  # проверяем user_helpers
  describe '#add_audience_help' do
    it 'add ":audience_help" in help_hash' do
      expect(game_question.help_hash).not_to include(:audience_help)

      game_question.add_audience_help

      expect(game_question.help_hash).to include(:audience_help)
      expect(game_question.help_hash[:audience_help].keys).to contain_exactly(
                                                                'a', 'b', 'c', 'd'
                                                              )
    end
  end
end
