FactoryGirl.define do
  factory :user do
    name {"Человек_#{rand(999)}" }

    sequence(:email) {|n| "email_#{n}@example.com"}
    is_admin false
    balance 0

    #после того как объект в Руби создан, но еще не сохранен в базу
    #по аналогии с devise зададим ему логин и пароль
    after(:build) {|u| u.password_confirmation = u.password = "123456"}
  end
end