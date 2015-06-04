require 'test_helper'

class UserFriendshipTest < ActiveSupport::TestCase
  should belong_to(:user)
  should belong_to(:friend)


  test "that creating a friendship works without raisind an exception" do
    assert_nothing_raised do
      UserFriendship.create user: users(:mezbah), friend: users(:mez)
    end
  end

  test "that creating a friendship based on user id and friend id works" do
    UserFriendship.create user_id: users(:mezbah).id, friend_id: users(:mez).id
    assert users(:mezbah).pending_friends.include?(users(:mez))
  end

  context "a new instance" do
    setup do
      @user_friendship = UserFriendship.new user: users(:mezbah), friend: users(:mez)
    end

    should "have a pending state" do
      assert_equal 'pending', @user_friendship.state
    end
  end

  context "#send_request_email" do

    setup do
      @user_friendship = UserFriendship.create user: users(:mezbah), friend: users(:mez)
    end

    should "send an email" do
      assert_difference 'ActionMailer::Base.deliveries.size', 1 do
        @user_friendship.send_request_email
      end
    end
  end

  context "#mutual_friendship" do
    setup do
      UserFriendship.request users(:mezbah), users(:mezba)

      @friendship1 = users(:mezbah).user_friendships.where(friend_id: users(:mezba).id).first
      @friendship2 = users(:mezba).user_friendships.where(friend_id: users(:mezbah).id).first
    end

    should "correctly find the mutual friendship" do
      assert_equal @friendship2, @friendship1.mutual_friendship
    end

  end

  context "#accept_mutual_friendship!" do
    setup do
      UserFriendship.request users(:mezbah), users(:mezba)
    end

    should "accept the mutual friendship" do
      friendship1 = users(:mezbah).user_friendships.where(friend_id: users(:mezba).id).first
      friendship2 = users(:mezba).user_friendships.where(friend_id: users(:mezbah).id).first

      friendship1.accept_mutual_friendship!
      friendship2.reload
      assert_equal 'accepted', friendship2.state
    end

  end

  context "#accept!" do
    setup do
      @user_friendship = UserFriendship.request users(:mezbah), users(:mez)
    end

    should "set the state to accepted" do
      @user_friendship.accept!
      assert_equal "accepted", @user_friendship.state
    end

    should "set an acceptance email" do
      assert_difference 'ActionMailer::Base.deliveries.size', 1 do
        @user_friendship.accept!
      end
    end

    should "include the friend in the list of friends" do
      @user_friendship.accept!
      users(:mezbah).friends.reload
      assert users(:mezbah).friends.include?(users(:mez))
    end

    should "accept the mutual friendship" do
      @user_friendship.accept!
      assert_equal 'accepted', @user_friendship.mutual_friendship.state
    end
  end

  context ".request" do
    should "create two user friendships" do
      assert_difference 'UserFriendship.count', 2 do
        UserFriendship.request(users(:mezbah), users(:mez))
      end
    end

    should "send a friend request email" do
      assert_difference 'ActionMailer::Base.deliveries.size', 1 do
        UserFriendship.request(users(:mezbah), users(:mez))
      end
    end
  end

  context "#delete_mutual_friendship!" do
    setup do
      UserFriendship.request users(:mezbah), users(:mezba)
      @friendship1 = users(:mezbah).user_friendships.where(friend_id: users(:mezba).id).first
      @friendship2 = users(:mezba).user_friendships.where(friend_id: users(:mezbah).id).first
    end

    should "delete the mutual friendship" do
      assert_equal @friendship2, @friendship1.mutual_friendship
      @friendship1.delete_mutual_friendship!
      assert !UserFriendship.exists?(@friendship2.id)
    end
  end

  context "on destroy" do
    setup do
      UserFriendship.request users(:mezbah), users(:mezba)
      @friendship1 = users(:mezbah).user_friendships.where(friend_id: users(:mezba).id).first
      @friendship2 = users(:mezba).user_friendships.where(friend_id: users(:mezbah).id).first
    end

    should "delete the mutual friendship" do
      @friendship1.destroy
      assert !UserFriendship.exists?(@friendship2.id)
    end
  end

  context "#block!" do
    setup do
      @user_friendship = UserFriendship.request users(:mezbah), users(:mez)
    end

    should "set the state to blocked" do
      @user_friendship.block!
      assert_equal 'blocked', @user_friendship.state
      assert_equal 'blocked', @user_friendship.mutual_friendship.state
    end

    should "not allow new requests once blocked" do
      @user_friendship.block!
      uf = UserFriendship.request users(:mezbah), users(:mez)
      assert !uf.save
    end
  end
end