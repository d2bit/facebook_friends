class WebController < ApplicationController
  def login
    redirect_to :friends if cookies["fbsr_#{ENV['FACEBOOK_ID']}"].present?
  end

  def friends
    return redirect_to :login if cookies["fbsr_#{ENV['FACEBOOK_ID']}"].blank?

    if fb_user = FacebookConnect.new(cookies)
      fb_user_data = fb_user.get_user_info
      @user = User.where(email: fb_user_data[:email]).first_or_create(fb_user_data)
      @friends = fb_user.get_friends_info
    else
      cookies.delete "fbsr_#{ENV['FACEBOOK_ID']}"
      redirect_to :login
    end
  end
end
