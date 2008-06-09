require File.dirname(__FILE__) + '/../spec_helper'

describe CachedPagesHelper do
  include Stubby
  
  describe '#cached_page_date' do
    before :each do
      scenario :cached_page
      
      @time_now = Time.zone.now
      @yesterday = Time.zone.now.yesterday
      
      Time.zone.stub!(:now).and_return @time_now
      Time.zone.now.stub!(:yesterday).and_return @yesterday
      Date.stub!(:today).and_return Time.zone.now.to_date
    end
    
    it 'returns a variant of time_ago_in_words if the cached page was updated no more than 4 hours ago' do
      @page.stub!(:updated_at).and_return @time_now - 55.minutes
      helper.cached_page_date(@page).should == '~ 1 hour ago'
    end
    
    it "returns a formatted date preceeded with 'Today' if the cached page was updated earlier today" do
      @page.stub!(:updated_at).and_return @time_now - 6.hours
      helper.cached_page_date(@page).should =~ /Today, /
    end
    
    it "returns a formatted date if the cached page was updated before today" do
      @page.stub!(:updated_at).and_return Time.local(2008, 1, 1)
      helper.cached_page_date(@page).should == 'Jan 01, 2008'
    end
  end
end