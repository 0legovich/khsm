require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe Game, type: :model do
  #создаем пользователя
  let(:user) {FactoryGirl.create(:user)}

  #используем пользователя, которого создали для данного теста, так как
  #если не пропишем `user: user`, то user создастся новый user
  let(:game_w_questions) {FactoryGirl.create(:game_with_questions, user: user)}

  #тесты на создание новой игры
  context 'Game Factory' do
    it 'Game.create_game_for_user! new correct game' do
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

  #тесты на основную игру
  context 'game mechanics' do
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

    it '.take_money! finishes the game and get money' do
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

    it '.status get correct status game' do
      #игру только начали - она в процесе
      expect(game_w_questions.status).to eq(:in_progress)

      #игру закончили, но не зафейлили и время не вышло
      game_w_questions.finished_at = Time.now
      expect(game_w_questions.status).to eq(:money)

      #игру закончили и ответили на 15 вопросов
      game_w_questions.current_level = 15
      expect(game_w_questions.status).to eq(:won)

      #игру закончили, но зафейлили (не смотря на то, что теоретически ответили на 15 вопросов)
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:fail)

      #игру закончили при этом время уже вышло
      game_w_questions.created_at = 2.days.ago
      expect(game_w_questions.status).to eq(:timeout)
    end

    it 'current level get correctly answer' do
      game_w_questions.current_level = 2
      #у игры 2 уровня должен быть сейчас доступен 2 вопрос
      expect(game_w_questions.current_game_question).to eq(game_w_questions.game_questions[2])
      #у игры 2 уровня НЕ должен быть сейчас доступен 3 вопрос
      expect(game_w_questions.current_game_question).not_to eq(game_w_questions.game_questions[3])
      #предыдущий уровень - это "текущий уровень" - 1
      expect(game_w_questions.previous_level).to eq(1)
    end
  end
end
