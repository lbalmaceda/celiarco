class ApplicationController < ActionController::Base
protect_from_forgery with: :exception

before_filter :authenticate_user!

def authenticate_user!
	render :file => "public/401", :status => :unauthorized unless (params[:token]=="tokenloco")
end

  # before_filter :foobar, only :show

  # def foobar
  # 	@foo = "bar"
  # end

end
