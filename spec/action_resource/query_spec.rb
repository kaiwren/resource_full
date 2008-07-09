require File.dirname(__FILE__) + '/../spec_helper'

describe "ActionResource::Query", :type => :controller do
  controller_name "users"
  
  before :all do
    User.delete_all
    @users = [
      User.create!(:address_id => 1, :income => 70_000, :first_name => "guybrush"),
      User.create!(:address_id => 1, :income => 30_000, :first_name => "toothbrush"),
      User.create!(:address_id => 2, :income => 70_000, :first_name => "guthrie"),
    ]
  end
  attr_reader :users
  
  before :each do
    UsersController.queryable_params = []
  end
  
  it "isn't queryable on any parameters by default" do
    controller.class.queryable_params.should be_empty
  end
  
  it "allows you to specify queryable parameters" do
    controller.class.queryable_with :address_id, :income
    controller.class.queryable_params.collect(&:name).should include(:address_id, :income)
  end
  
  it "retrieves objects based on a queried condition" do
    controller.class.queryable_with :address_id
    get :index, :address_id => 1
    assigns(:users).should include(users[0], users[1])
    assigns(:users).should_not include(users[2])
  end
  
  it "retrieves no objects if the queried condition is not matched" do
    controller.class.queryable_with :address_id
    get :index, :address_id => 3
    assigns(:users).should be_empty
  end
  
  it "queries on the intersection of multiple conditions" do
    controller.class.queryable_with :address_id, :income
    get :index, :address_id => 1, :income => 70_000
    assigns(:users).should == [ users[0] ]
  end
  
  it "queries multiple values in a comma-separated list" do
    controller.class.queryable_with :address_id, :income
    get :index, :address_id => "1,2"
    assigns(:users).should include(*users)
  end
  
  it "retrieves objects given pluralized forms of queryable parameters" do
    controller.class.queryable_with :address_id
    get :index, :address_ids => "1,2"
    assigns(:users).should include(*users)
  end
  
  it "uses LIKE clauses to query if the fuzzy option is specified" do
    controller.class.queryable_with :first_name, :fuzzy => true
    get :index, :first_name => "gu"
    assigns(:users).should include(users[0], users[2])
    assigns(:users).should_not include(users[1])
  end
  
  it "allows a queryable parameter to map to a different column" do
    controller.class.queryable_with :address, :column => :address_id
    get :index, :address => 1
    assigns(:users).should include(users[0], users[1])
    assigns(:users).should_not include(users[2])
  end
  
  it "appends to rather than replaces queryable values" do
    controller.class.queryable_with :address_id
    controller.class.queryable_with :income
    
    get :index, :address_id => 1, :income => 70_000
    assigns(:users).should include(users[0])
    assigns(:users).should_not include(users[1], users[2])
  end
  
  it "counts the requested number of objects based on the supplied parameters" do
    controller.class.queryable_with :address_id
    
    get :count
    response.body.to_i.should == 3
    
    get :count, :address_id => 1
    response.body.to_i.should == 2
    
    get :count, :address_id => 15
    response.body.to_i.should == 0
  end
  
  describe "more complex queries" do
    controller_name :users
    
    before :all do
      User.delete_all
      @users = [
        User.create!(:first_name => "guybrush", :last_name => "threepwood"),
        User.create!(:first_name => "herman",   :last_name => "guybrush"),
        User.create!(:first_name => "ghost_pirate", :last_name => "le_chuck")
      ]
    end
    attr_reader :users
    
    before :each do
      UsersController.queryable_params = []
    end
  
    it "allows a queryable parameter to map to multiple columns" do    
      controller.class.queryable_with :name, :columns => [:first_name, :last_name]
      get :index, :name => "guybrush"
      assigns(:users).should include(users[0], users[1])
      assigns(:users).should_not include(users[2])
    end
  
    it "queries fuzzy values across multiple columns" do
      controller.class.queryable_with :name, :columns => [:first_name, :last_name], :fuzzy => true
      get :index, :name => "gu"
      assigns(:users).should include(users[0], users[1])
      assigns(:users).should_not include(users[2])
    end
  end
  
  describe "with joins" do
    controller_name :addresses
    
    it "filters addresses by the appropriate column and join if a :from relationship is defined" do
      User.delete_all
      Address.delete_all
      
      user = User.create! :email => "gthreepwood@melee.gov"
      address_1 = user.addresses.create!
      address_2 = user.addresses.create!
      address_3 = Address.create!
      
      AddressesController.queryable_with :email, :from => :user
      
      get :index, :user_id => user.email
      assigns(:addresses).should include(address_1, address_2)
      assigns(:addresses).should_not include(address_3)
    end
    
    it "filters addresses by the User resource identifier if a :from is specified along with :resource_identifier" do
      User.delete_all
      Address.delete_all
      
      user = User.create! :email => "gthreepwood@melee.gov"
      address_1 = user.addresses.create!
      address_2 = user.addresses.create!
      address_3 = Address.create!
      
      UsersController.resource_identifier = :email
      AddressesController.queryable_with :user_id, :from => :user, :resource_identifier => true
      
      get :index, :user_id => user.email
      assigns(:addresses).should include(address_1, address_2)
      assigns(:addresses).should_not include(address_3)
    end    
  end
  
end