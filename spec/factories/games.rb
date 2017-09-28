FactoryGirl.define do
  factory :game do
    association :user

    finished_at nil
    current_level 0
    is_failed false
    prize 0

    #создаем еще одну фабрику, которая унаследована от родительской
    factory :game_with_questions do
      after(:build) { |game|
        15.times do |i|
          q = create(:question, level: i)
          create(:game_question, game: game, question: q)
        end
      }
    end
  end
end