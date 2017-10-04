require 'rails_helper'
require 'spec_helper'

RSpec.describe GamesController, type: :controller do
  # обычный пользователь
  let(:user) {FactoryGirl.create(:user)}
  let(:another_user) {FactoryGirl.create(:user)}

  # админ
  let(:admin) {FactoryGirl.create(:user, is_admin: true)}

  # игра с вопросами
  let(:game_w_questions) {FactoryGirl.create(:game_with_questions, user: user)}
  let(:another_game) {FactoryGirl.create(:game_with_questions, user: another_user)}

  before(:each) do |example|
    sign_in user unless example.metadata[:skip_before]
  end

  describe 'GET #show' do
    # если пользователь не залогинен
    context 'when user is anon' do
      it 'redirect to the login page', :skip_before do
        get :show, id: game_w_questions.id

        expect(response.status).not_to eq 200
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end
    end

    # если пользователь залогинен
    context 'when user is autorise' do
      it 'shows his game' do
        get :show, id: game_w_questions.id
        game = assigns(:game)

        expect(game.finished?).to be_falsey
        expect(game.user).to eq user

        expect(response.status).to eq 200
        expect(response).to render_template('show')
      end

      it 'not shows another game' do
        get :show, id: another_game.id
        expect(response.status).to eq 302
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to be
      end
    end
  end

  describe 'POST #create' do
    before(:each) do
      generate_questions(60)
      post :create
    end

    # если пользователь не залогинен
    context 'when user is anon' do
      it 'redirect to the login page', :skip_before do

        expect(response.status).not_to eq 200
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end
    end

    # если пользователь залогинен
    context 'when user is autorize' do
      it 'creates the game' do
        game = assigns(:game)

        expect(game.finished?).to be_falsey
        expect(game.user).to eq(user)
        expect(response).to redirect_to game_path(game)
        expect(flash[:notice]).to be
      end

      it 'not to creates the second game' do
        game = assigns(:game)
        expect(game.finished?).to be_falsey

        # создаем новую игру при том, что старая еще не завершена
        post :create

        expect(response).to redirect_to game_path(game)
        expect(flash[:alert]).to be
      end
    end
  end

  describe 'PUT #answer' do
    # если пользователь не залогинен
    context 'when user is anon' do
      it 'redirect to the login page', :skip_before do
        put :answer, {
          id: game_w_questions.id,
          letter: game_w_questions.current_game_question.correct_answer_key
        }

        expect(response.status).not_to eq 200
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end
    end

    # когда пользователь залогинен
    context 'when user is autorize' do
      context 'when answer is correct' do
        it 'the game continues' do
          put :answer, {
            id: game_w_questions.id,
            letter: game_w_questions.current_game_question.correct_answer_key
          }
          game = assigns(:game)

          expect(game.finished?).to be_falsey
          expect(game.current_level).to be > 0
          expect(response).to redirect_to(game_path(game))
          expect(flash.empty?).to be_truthy
        end
      end

      context 'when answer is not correct' do
        it 'the game finishes' do
          put :answer, {
            id: game_w_questions.id,
            letter: 'b'
          }
          game = assigns(:game)

          expect(game.finished?).to be_truthy
          expect(game.current_level).to eq 0
          expect(game.status).to eq :fail
          expect(response).to redirect_to(user_path(user))
          expect(flash[:alert]).to be
        end
      end
    end
  end

  describe 'PUT #take_money' do
    # если пользователь не залогинен
    context 'when user is anon' do
      it 'redirect to the login page', :skip_before do
        put :take_money, id: game_w_questions.id

        expect(response.status).not_to eq 200
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end
    end

    # когда пользователь залогинен
    context 'when user is autorize' do
      # когда приза нет - начало игры
      context 'when prize is nil' do
        before(:each) do
          put :take_money, id: game_w_questions.id

          expect(response).to redirect_to user_path(user)
        end

        it 'user take 0' do
          game = assigns(:game)
          user = game.user

          expect(response).to redirect_to user_path(user)
          expect(game.prize).to eq 0
          expect(user.balance).to eq 0
        end

        it 'game is finished' do
          game = assigns(:game)

          expect(game.finished?).to be_truthy
          expect(game.status).to eq :money
        end
      end
      # когда приз существует, то есть это не начало игры
      context 'when prize is present' do
        before(:each) do
          game_w_questions.update_attributes(current_level: 2)
          put :take_money, id: game_w_questions.id

          expect(response).to redirect_to user_path(user)
        end

        it 'user take money' do
          game = assigns(:game)
          user = game.user

          expect(game.prize).to eq 200
          expect(user.balance).to eq 200
        end

        it 'game is finished' do
          game = assigns(:game)

          expect(game.finished?).to be_truthy
          expect(game.status).to eq :money
        end
      end
    end
  end

  describe 'PUT #help' do
    it 'used audience help' do
      expect(game_w_questions.audience_help_used).to be_falsey
      expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be

      put :help, id: game_w_questions.id, help_type: :audience_help
      game = assigns(:game)

      expect(game.finished?).to be_falsey
      expect(game.audience_help_used).to be_truthy
      expect(game.current_game_question.help_hash[:audience_help]).to be
      expect(
        game.current_game_question.help_hash[:audience_help].keys
      ).to contain_exactly('a', 'b', 'c', 'd')
    end
  end
end
