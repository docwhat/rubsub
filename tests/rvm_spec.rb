$: << 'vendor_ruby'

require 'rvm'

describe RVM::Version do
  it "should add ruby as a prefix if it doesn't have one" do
    (RVM::Version.new '1.8.7').to_s[0,10].should == 'ruby-1.8.7'
    (RVM::Version.new '1.9.1').to_s[0,10].should == 'ruby-1.9.1'
    (RVM::Version.new 'ruby-1.8.7').to_s[0,10].should == 'ruby-1.8.7'
    (RVM::Version.new 'ruby-1.9.1').to_s[0,10].should == 'ruby-1.9.1'
  end

  it "should understand the interpreter" do
    (RVM::Version.new '1.8.7').interpreter.should == 'ruby'
    (RVM::Version.new '1.9.1').interpreter.should == 'ruby'
    (RVM::Version.new 'ruby-1.8.7').interpreter.should == 'ruby'
    (RVM::Version.new 'ruby-1.9.1').interpreter.should == 'ruby'
  end

  it "should get the version" do
    (RVM::Version.new '1.9.1').version.should == 1
    (RVM::Version.new 'ruby-2.0.0').version.should == 2
    (RVM::Version.new 'ruby-3.8.7-p123').version.should == 3
    (RVM::Version.new '4.8.7-p123').version.should == 4
  end

  it "should get the major" do
    (RVM::Version.new '1.9.1').major.should == 9
    (RVM::Version.new 'ruby-2.0.0').major.should == 0
    (RVM::Version.new 'ruby-3.8.7-p123').major.should == 8
    (RVM::Version.new '3.4.7-p123').major.should == 4
  end

  it "should get the minor" do
    (RVM::Version.new '1.9.1').minor.should == 1
    (RVM::Version.new 'ruby-2.0.0').minor.should == 0
    (RVM::Version.new 'ruby-3.8.7-p123').minor.should == 7
    (RVM::Version.new '3.8.6-p123').minor.should == 6
  end

  it "should get the patch" do
    (RVM::Version.new '1.9.1').patch.should == nil
    (RVM::Version.new '2.0.0-p123').patch.should == 123
    (RVM::Version.new 'ruby-3.8.7-p376').patch.should == 376
  end
end
