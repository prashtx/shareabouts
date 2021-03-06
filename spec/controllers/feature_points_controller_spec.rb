require 'spec_helper'

describe FeaturePointsController do
  describe "GET index" do
    context "with format JSON" do
      it "is a success" do
        xhr :get, :index, :format => "json"
        response.should be_success
      end
      
      context "with no after param" do
        context "with invisible points" do        
          it "assigns feature_points to all visible points" do
            4.times { |i| create_feature_point :visible => false}
            xhr :get, :index, :format => "json"
            assigns(:feature_points).count.should == FeaturePoint.visible.count
          end
        end
      
        it "assigns feature_points to all visible points" do
          4.times { create_feature_point }
          xhr :get, :index, :format => "json"
          assigns(:feature_points).count.should == FeaturePoint.visible.count
        end
      end
      
      context "after a particular id" do
        attr_reader :feature_point
        
        before do
          4.times { create_feature_point }
          @feature_point = FeaturePoint.first
        end
        
        it "returns all visible points after that ID" do
          xhr :get, :index, :after => feature_point.id, :format => "json"
          assigns(:feature_points).count.should == FeaturePoint.visible.count - 1
        end
        
        it "does not return point with that ID" do
          xhr :get, :index, :after => feature_point.id, :format => "json"
          assigns(:feature_points).should_not include(feature_point)
        end
      end
    end
    
    context "with format HTML" do
      it "is a success" do
        get :index
        response.should be_success
      end
    end
  end
  
  describe "GET new" do
    context "with format JSON" do
      it "is assigns a new feature point" do
        xhr :get, :new, :format => "json"
        
        assigns(:feature_point).should be_new_record
      end
    end
  end
  
  describe "POST create" do
    attr_reader :params
    
    context "with format JSON" do  
      context "with good params" do  
        before do
          new_point = make_point_in_region(create_regions.first)
          @params = {:feature_point => {
            :name => "", 
            :feature_location_type_attributes => {:location_type_id=>""}, 
            :description=>""}, 
            :latitude => new_point.latitude, 
            :longitude => new_point.longitude}
        end
              
        it "is creates a feature point" do
          xhr :post, :create, params, :format => "json"
          
          assigns(:feature_point).should be_valid
          assigns(:feature_point).should_not be_new_record
        end
      end
      
      context "with bad params" do
        before do
          new_point = make_point_in_region(create_regions.first)
          @params = {:feature_point => {
            :name => "", 
            :feature_location_type_attributes => {:location_type_id=>""}, 
            :description=>""}, 
            :latitude => "", 
            :longitude => ""}
        end
        
        it "is instantiates an infeature point" do
          xhr :post, :create, params, :format => "json"
          assigns(:feature_point).should_not be_valid
        end
      end
    end
  end
  
  describe "PUT update" do
    attr_reader :feature_point, :valid_params
    
    before do
      @feature_point = create_feature_point
      @valid_params = {:feature_point => { :visible => "0" }, :id => feature_point.id}
    end
    
    context "for authorized updater" do
      attr_reader :admin
      before do
        @admin = create_admin
        sign_in(:admin, admin)
        Admin.current_admin = admin
      end
      it "updates the feature point" do
        xhr :put, :update, valid_params
        feature_point.reload.should_not be_visible
      end
    end
    
    context "for unauthorized visitor" do
      it "raises an authorization error" do
        lambda {
          xhr :put, :update, valid_params, :format => "json"
        }.should raise_error(CanCan::AccessDenied)        
      end
    end
  end
  
  describe "GET show" do
    attr_reader :feature_point
    
    before do
      @feature_point = create_feature_point
    end
    context "with format JSON" do
      it "assigns the feature point" do
        xhr :get, :show, :id => feature_point.id, :format => "json"
        assigns(:feature_point).should be
      end
      
      context "for an invisible point" do
        before do
          feature_point.update_attribute :visible, false
        end
        it "raises record not found" do
          lambda {
            xhr :get, :show, :id => feature_point.id, :format => "json"
          }.should raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end
