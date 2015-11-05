FactoryGirl.define do
  factory :ban do
    reason "Is a dick."
    end_date 2.weeks.from_now
  end

end
