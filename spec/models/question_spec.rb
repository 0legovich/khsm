require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe Question, type: :model do

  #проверяем валидации модели
  context 'check validations' do

    it {should validate_presence_of :text}
    it {should validate_presence_of :level}

    subject {FactoryGirl.build(:question)}
    it {should validate_uniqueness_of(:text)}

    it {should validate_inclusion_of(:level).in_range(0..14)}

    it {should allow_value(14).for(:level)}
    it {should_not allow_value(15).for(:level)}
  end

end
