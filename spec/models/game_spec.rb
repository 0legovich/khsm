require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe Game, type: :model do
  #создаем пользователя
  let(:user) {FactoryGirl.create(:user)}

  #используем пользователя, которого создали для данного теста, так как
  #если не пропишем `user: user`, то user создастся новый user
  let(:game_w_questions) {FactoryGirl.create(:game_with_questions, user: user)}

  #тесты на создание новой игры
  describe '#Game.create_game_for_user!' do
    it 'create new correct game' do
      generate_questions(60)

      game = nil
      expect {
        game = Game.create_game_for_user!(user)
      }.to change(Game, :count).by(1).and(
        change(GameQuestion, :count).by(15)
      )

      #проверяем статус и поля
      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)
      #проверяем корректность массива игровых вопросов
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq((0..14).to_a)
    end
  end

  # тестируем игру: если ответили на правильный вопрос, то:
  # игра не завершилась;
  # уровень поднялся;
  # вопрос сменился;
  describe 'game mechanics' do
    it 'correct answer continue game' do
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      expect(game_w_questions.current_level).to eq(level + 1)

      expect(game_w_questions.current_game_question).not_to eq q

      expect(game_w_questions.status).to eq (:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end
  end

  #тестируем методы

  #тест метода #take_money!
  describe '#take_money!' do
    it 'finishes the game and get money' do
      #сразу изменяем левел игры (на каком вопросе находимся)
      game_w_questions.current_level = 2

      #проверяем, что метод .take_money! изменяет поля игры finished_at и prize
      expect {game_w_questions.take_money!}.to(
        change(game_w_questions, :finished_at).from(nil).and(
          change(game_w_questions, :prize).from(0))
      )

      #проверяем что игра закончилась, статус :money и приз присвоился игроку
      expect(game_w_questions.status).to eq(:money)
      expect(game_w_questions.finished?).to be_truthy
      expect(user.balance).to eq (game_w_questions.prize)
    end
  end

  # тест метода #status
  describe '#status' do
    it 'get correct status game' do
      # игру только начали - она в процесе
      expect(game_w_questions.status).to eq(:in_progress)

      # игру закончили, но не зафейлили и время не вышло
      game_w_questions.finished_at = Time.now
      expect(game_w_questions.status).to eq(:money)

      # игру закончили и ответили на 15 вопросов
      game_w_questions.current_level = 15
      expect(game_w_questions.status).to eq(:won)

      # игру закончили, но зафейлили (не смотря на то, что теоретически ответили на 15 вопросов)
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:fail)

      # игру закончили при этом время уже вышло
      game_w_questions.created_at = 2.days.ago
      expect(game_w_questions.status).to eq(:timeout)
    end
  end

  # тест метода #current_game_question
  describe '#current_game_question' do

    # возвращает корректный вопрос в соответствии с текущим уровнем
    it 'return correct question in accordance current_level' do
      game_w_questions.current_level = 2
      #у игры 2 уровня должен быть сейчас доступен 2 вопрос
      expect(game_w_questions.current_game_question).to eq(game_w_questions.game_questions[2])
    end
  end

  #тест метода #previous_level
  describe '#previous_level' do
    it 'get correctly answer' do
      game_w_questions.current_level = 2
      #предыдущий уровень - это "текущий уровень" - 1
      expect(game_w_questions.previous_level).to eq(1)
    end
  end

  # тест метода #answer_current_question!
  describe '#answer_current_question!' do

    before(:suite) {game_w_questions.current_level = 2}

    context 'when the answer is correct' do
      it 'method return true' do
        expect(game_w_questions.answer_current_question!('d')).to be_truthy
      end

      it 'level up' do
        level = game_w_questions.current_level
        game_w_questions.answer_current_question!('d')

        expect(game_w_questions.current_level).to eq(level + 1)
      end

      it 'finished game' do
        game_w_questions.current_level = 14
        game_w_questions.answer_current_question!('d')

        expect(game_w_questions.finished_at).not_to eq(nil)
        expect(game_w_questions.is_failed).to be_falsey
      end
    end

    context 'when the answer is not correct' do
      it 'method return false' do
        expect(game_w_questions.answer_current_question!('a')).to be_falsey
      end

      it 'game is failed' do
        game_w_questions.answer_current_question!('a')

        expect(game_w_questions.finished_at).not_to eq(nil)
        expect(game_w_questions.is_failed).to be_truthy
      end
    end

    context 'when game is finished' do

      # даже с правильным ответом метод вернет false
      it 'method return false' do
        game_w_questions.finished_at = Time.now
        expect(game_w_questions.answer_current_question!('d')).to be_falsey
      end
    end

    context 'when time is out' do

      # моделируем истечение времени игры подменой возвращаемого
      # значения метода time_out!
      # даже с правильным ответом метод вернет false
      it 'method return false' do
        allow(game_w_questions).to receive(:time_out!).and_return(true)
        expect(game_w_questions.answer_current_question!('d')).to be_falsey
      end
    end
  end
end
