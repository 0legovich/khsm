# КЛЮЧЕВЫЕ КОНСТРУКЦИИ FEATURE SPEC
#
# visit - посетить страницу
# click_on - нажать на кнопку
# fill_in ..., with - заполнить поля формы данными
# expect(page).to - проверить какая страница вернулась

require 'rails_helper'

RSpec.feature 'USER creates game', type: :feature do
  let(:user) {FactoryGirl.create :user}

  let!(:questions) do
    (0..14).to_a.map do |i|
      FactoryGirl.create(
        :question,
        level: i,
        text: "В каком году была косм. оддисея? #{i}",
        answer1: '1380', answer2: '1381', answer3: '1382', answer4: '1383'
      )
    end
  end

  before(:each) do
    login_as user
  end

  scenario 'success' do
    visit '/'

    click_link 'Новая игра'

    expect(page).to have_content('В каком году была косм. оддисея? 0')
    expect(page).to have_content('1380')
    expect(page).to have_content('1381')
    expect(page).to have_content('1382')
    expect(page).to have_content('1383')

    save_and_open_page
  end
end