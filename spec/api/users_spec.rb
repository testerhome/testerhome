require 'spec_helper'

describe RubyChina::API, "users" do
  describe "GET /api/users/:user.json" do
    it "should be ok" do
      get "/api/users.json"
      response.status.should == 200
    end

    it "should get user details with list of topics" do
      user = Factory(:user, :name => "test user", :login => "test_user", :email_public => true)
      topics = (1..10).map {|n| Factory(:topic, :title => "new topic #{n}", :user_id => user.id) }
      Factory(:reply, :topic_id => topics.last.id, :body => "let me tell", :user_id => user.id)
      get "/api/v2/users/test_user.json"
      response.status.should == 200
      json = JSON.parse(response.body)
      json["name"].should == user.name
      json["login"].should == user.login
      json["email"].should == user.email
      json["topics"].size.should == 5
      (6..10).reverse_each {|n| json["topics"][10 - n]["title"].should == "new topic #{n}" }
      json["topics"].first["replies_count"].should == 1
      json["topics"].first["last_reply_user_login"].should == user.login
    end
  end

  describe 'GET /api/v3/users/:login.json' do
    it 'should get user details with list of topics' do
      user = create(:user, name: 'test user', login: 'test_user', email: 'foobar@gmail.com', email_public: true)
      get '/api/v3/users/test_user.json'
      expect(response.status).to eq 200
      fields = %w(id name login email avatar_url location company twitter github website bio tagline
                  topics_count replies_count following_count followers_count favorites_count
                  level level_name)
      expect(json['user']).to include(*fields)
      fields.reject { |f| f == 'avatar_url' }.each do |field|
        expect(json['user'][field]).to eq user.send(field)
      end
    end

    it 'should hidden email when email_public is false' do
      create(:user, name: 'test user',
             login: 'test_user',
             email: 'foobar@gmail.com',
             email_public: false)
      get '/api/v3/users/test_user.json'
      expect(response.status).to eq 200
      expect(json['user']['email']).to eq ''
    end

    it 'should not hidden email when current_user itself' do
      login_user!
      get "/api/v3/users/#{current_user.login}.json"
      expect(response.status).to eq 200
      expect(json['user']['email']).to eq current_user.email
    end
  end
end