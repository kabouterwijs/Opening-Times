require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GeocodeCache do
  before(:each) do
    @valid_attributes = {
        :location => "Hailsham",
        :lat => "5.1",
        :lng => "3.1"
    }
  end

  it "should create a new instance given valid attributes" do
    GeocodeCache.create!(@valid_attributes)
  end
  
  describe "geocode" do
    it "should return a lat lng when passed a lat lng" do
      result = Geokit::LatLng.new(@valid_attributes[:lat], @valid_attributes[:lng])
      GeocodeCache.geocode("5.1 3.1").should == result
    end
  end
  
end
