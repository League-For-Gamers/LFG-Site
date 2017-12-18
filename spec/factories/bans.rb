FactoryBot.define do
  factory :ban do
    reason "Is a dick."
    end_date 2.weeks.from_now
    banner administrator_user
  end

end
