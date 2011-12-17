require 'spec_helper'

describe 'Home' do
  it "should display my name" do
  	visit "/"
  	page.should have_content "Nikalyukin Mikhail"
  end
end