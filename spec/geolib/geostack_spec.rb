require 'spec_helper'
require 'geolib'

describe Geolib::GeoStack do

    
  describe "a stack created from an ip address" do
      
        it "should have a country if possible" do
          stub_locator = mock()
          stub_locator.expects(:centre_of_country).with('US').returns({"lat"=>37,"lon"=>-96})
          Geolib.stubs(:default_locations).returns(stub_locator)
          stub_mapper = stub(:remote_location => {'country' => 'US'})
          Geolib.expects(:default_ip_mapper).returns(stub_mapper)
  
          stack = Geolib::GeoStack.new_from_ip('173.203.129.90')
          stack.country.should == "US"
          stack.fuzzy_point.lon.should be_within(0.5).of(-96)
          stack.fuzzy_point.lat.should be_within(0.5).of(37)
          stack.fuzzy_point.accuracy.should == :country
        end
  
        it "should be specific if no country available" do
          stub_mapper = mock()
          stub_mapper.expects(:remote_location).with('127.0.0.1').returns(nil)
          Geolib.stubs(:default_ip_mapper).returns(stub_mapper)
          stack = Geolib::GeoStack.new_from_ip('127.0.0.1')
          stack.country.should be_nil
          stack.fuzzy_point.lon.should == 0
          stack.fuzzy_point.lat.should == 0
          stack.fuzzy_point.accuracy.should == :planet
        end
  
    end
  
  describe "a stack created from an existing hash" do
      
      it "should only have known params" do
        lambda { Geolib::GeoStack.new_from_hash("galaxy" => "Andromeda") }.should raise_error(ArgumentError)
      end
  
      it "should refuse creation if no fuzzy point" do
        lambda { Geolib::GeoStack.new_from_hash("country" => "US") }.should raise_error(ArgumentError)
      end
  
      it "should always truncate postcode" do
        stack = Geolib::GeoStack.new_from_hash("postcode"=>"SE10 8UG","country" => "UK","fuzzy_point" => {"lat"=>"37","lon"=>"-96","accuracy"=>"postcode"})
        stack.postcode.should == "SE10 8"
      end
  
      it "should ignore invalid postcodes" do
        stack = Geolib::GeoStack.new_from_hash("postcode"=>"NOTAPOSTCODE","country" => "UK","fuzzy_point" => {"lat"=>"37","lon"=>"-96","accuracy"=>"postcode"})
        stack.postcode.should be_nil
      end
  
   end
  
  describe "a stack with accuracy of postcode" do
  
    describe "when updated with different country" do
      
      xit "should remove all other fields" do
      end
  
    end
  end

  describe "a stack with an accuracy of country" do
      
      let :stack do
        Geolib::GeoStack.new_from_hash("country" => "US","fuzzy_point" => {"lat"=>"37","lon"=>"-96","accuracy"=>"country"})
      end

      it "should have a fuzzy point of level country" do
        stack = Geolib::GeoStack.new_from_hash("country" => "US","fuzzy_point" => {"lat"=>"37","lon"=>"-96","accuracy"=>"country"})
        stack.fuzzy_point.accuracy.should be :country
      end
      
      describe "when updated with the same country" do
          
        xit "should not change" do
          new_stack = stack.update("country" => "US")
          new_stack.should === stack
        end
      
      end
      
      describe "when updated with different country" do
      
        before(:each) do
          stub_locator = mock()
          stub_locator.stubs(:centre_of_country).with('UK').returns({"lat"=>56,"lon"=>-2})
          Geolib.stubs(:default_locations).returns(stub_locator)
        end
      
        it "should replace the country" do
          new_stack = stack.update("country" => "UK")
          new_stack.country.should == "UK"
        end
      
        it "should return a new stack" do
          new_stack = stack.update("country" => "UK")
          new_stack.should_not === stack
        end
      
        it "should recalculate the fuzzy point" do
          new_stack = stack.update("country" => "UK")
          new_stack.fuzzy_point.lon.should be_within(0.5).of(-2)
          new_stack.fuzzy_point.lat.should be_within(0.5).of(56)
          new_stack.fuzzy_point.accuracy.should == :country
        end
      
      end

      describe "when updated with a postcode" do
           
        before(:each) do
          @new_stack = stack.update("postcode"=>"SE108UG")
        end
      
        it "should calculate stack levels down to ward level" do
          {:country => 'UK', :nation => 'England'}.each do |method, expected|
            @new_stack.send(method).should == expected
          end
          {:wmc => 'Greenwich and Woolwich', :council => 'Greenwich Borough Council', :ward => 'Greenwich West'}.each do |method, expected|
            @new_stack.send(method)[0]['name'].should == expected
          end
        end
      
        it "should truncate postcode" do
          @new_stack.postcode.should == "SE10 8"
        end
      
        it "should set fuzzy point to centroid of truncated postcode" do
          f = @new_stack.fuzzy_point
          f.lon.should be_within(0.5).of(-0.024503132501)
          f.lat.should be_within(0.5).of(51.4877939062)
          f.accuracy.should == :postcode_district
        end
      
        it "should have a friendly location name set" do
          @new_stack.friendly_name.should == "Greenwich"
        end
      
      end

      describe "when updated with a longitude and latitude" do
        before(:each) do
          @new_stack = stack.update("lon"=>"-0.015875421010387608", "lat"=>"51.476441375971447")
        end

        it "should calculate stack levels down to ward level" do
          {:country => 'UK', :nation => 'England'}.each do |method, expected|
            @new_stack.send(method).should == expected
          end
          {:wmc => 'Greenwich and Woolwich', :council => 'Greenwich Borough Council', :ward => 'Greenwich West'}.each do |method, expected|
            @new_stack.send(method)[0]['name'].should == expected
          end
        end

        it "should set fuzzy point precisely" do
          f = @new_stack.fuzzy_point
          f.lon.should == -0.015875421010387608
          f.lat.should == 51.476441375971447
          f.accuracy.should == :point
        end

        it "should have a friendly location name set" do
          @new_stack.friendly_name.should == "Greenwich"
        end
      end
  end
end
