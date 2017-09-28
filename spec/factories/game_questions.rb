FactoryGirl.define do
  factory :game_question do
    #проставляем поля поумолчанию
    a 4
    b 3
    c 2
    d 1

    #проставляем связи. связующие объекты поумолчанию будут искаться из папаки factories
    association :user
    association :game
  end
end