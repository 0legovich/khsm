require 'rails_helper'

RSpec.describe 'users/index', type: :view do
  before(:each) do
    assign(:users, [
      FactoryGirl.build_stubbed(:user, name: 'Рома', balance: 5000),
      FactoryGirl.build_stubbed(:user, name: 'Максим', balance: 3000)
    ])

    render
  end

  it 'render player names' do
    expect(rendered).to match 'Рома'
    expect(rendered).to match 'Максим'
  end

  it 'render player balances' do
    expect(rendered).to match '5 000 ₽'
    expect(rendered).to match '3 000 ₽'
  end

  it 'render player names in right order' do
    expect(rendered).to match /Рома.*Максим/m
  end
end