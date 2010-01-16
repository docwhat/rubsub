$: << 'vendor_ruby'

require 'rvm'
CONFFILE = 'test-#{Process::pid}.store'

class Test < ConfigStore
  @@defaults = {
    :one   => 1,
    :two   => 2,
    :three => 3
  }.freeze
  def filename
    CONFFILE
  end
end

describe ConfigStore do
  before(:each) do
    @conf = Test.new
  end

  after(:each) do
    File.unlink CONFFILE if File.exists? CONFFILE
  end

  it "should have the correct defaults" do
    @conf.one.should   == 1
    @conf.two.should   == 2
    @conf.three.should == 3
  end

  it "should accept new values" do
    @conf.one   = 21
    @conf.two   = 22
    @conf.three = 23
    @conf.one.should   == 21
    @conf.two.should   == 22
    @conf.three.should == 23
  end

  it "should store and restore values" do
    @conf.one   = 3.1
    @conf.two   = 32
    @conf.three = "string"
    @conf.save

    # Load a new object
    conf2 = Test.new

    conf2.one.should   == 3.1
    conf2.two.should   == 32
    conf2.three.should == "string"
  end
end
