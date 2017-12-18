require 'rails_helper'
RSpec.describe FeedHelper, type: :helper do
  describe '#post_time_ago' do
    let(:bobby) { FactoryBot.create(:user) }
    let(:post) {FactoryBot.create(:post, user: bobby)}
    context 'when post has not been updated' do
      it 'should return a string that does not reflect an edited post' do
        expect(helper.post_time_ago(post).downcase).to_not include("edited")
      end
    end
    context 'when post has been updated' do
      before do
        post.updated_at = post.created_at + 1.days
      end
      it 'should return a string that reflects an edited post' do
        expect(helper.post_time_ago(post).downcase).to include("edited")
      end
    end
  end
end
