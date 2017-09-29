require 'rails_helper'

RSpec.describe GameQuestion, type: :model do

  let(:game_question) {FactoryGirl.create(:game_question, a: 2, b: 1, c: 4, d: 3)}

  #Проверяем корректность методов связанных с ответами
  context 'check methods' do
    it 'correct .variants' do
      expect(game_question.variants).to eq(
                                          {
                                            'a' => game_question.question.answer2,
                                            'b' => game_question.question.answer1,
                                            'c' => game_question.question.answer4,
                                            'd' => game_question.question.answer3
                                          }
                                        )
    end

    it 'correct .answer_correct?' do
      expect(game_question.answer_correct?('b')).to be_truthy
      end
    it 'correct .correct_answer_key' do
      expect(game_question.correct_answer_key).to eq 'b'
    end
  end

  #проверяем delegate методы
  context 'check delegate methods' do
    it 'there is .text .level' do
      expect {game_question.text}.not_to raise_exception
      expect {game_question.level}.not_to raise_exception
    end
  end
end
