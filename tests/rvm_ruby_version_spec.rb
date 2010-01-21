require 'rvm'

# Alas, this requires 1.9.1 for Dir.mktmpdir - CGH
#def fakedir &block
#  Dir.mktmpdir {|dir|
#    old_rvm_dir = RVM_DIR
#    RVM.set_const 'RVM_DIR', dir
#    Dir.mkdir RVM_RUBIES_DIR
#    block dir
#    RVM.set_const 'RVM_DIR', old_rvm_dir
#  }
#end

describe RVM::RubyVersion do

  it "should pass a sunny day test" do
    (RubyVersion.new 'ruby-1.8.7-p123').to_s.should == 'ruby-1.8.7-p123'
    (RubyVersion.new 'ruby-1.9.1-p1').to_s.should == 'ruby-1.9.1-p1'
  end

  it "should properly compare patch levels" do
    a = RubyVersion.new('ruby-1.8.7-p1')
    b = RubyVersion.new('ruby-1.8.7-p2')
    a.should be < b
    b.should be > a
  end

  it "should understand approximations" do
    a = RubyVersion.new('ruby-1.8.7-p123')
    b = RubyVersion.new('ruby-1.8.7-p123')
    a.should == b
  end

  it "should not allow comparisons with different interpreters" do
    a = RubyVersion.new('jruby-1.8.7-p123')
    b = RubyVersion.new('ruby-1.8.7-p123')
    a.should be < b
    b.should be > a
  end

  it "should add ruby as a prefix if it doesn't have one" do
    (RubyVersion.new '1.8.7').to_s[0,10].should == 'ruby-1.8.7'
    (RubyVersion.new '1.9.1').to_s[0,10].should == 'ruby-1.9.1'
  end

#  it "should understand the interpreter ruby" do
#    (RubyVersion.new '1.8.7').interpreter.should == 'ruby'
#    (RubyVersion.new '1.9.1').interpreter.should == 'ruby'
#    (RubyVersion.new 'ruby-1.8.7').interpreter.should == 'ruby'
#    (RubyVersion.new 'ruby-1.9.1').interpreter.should == 'ruby'
#  end
#
#  it "should get the version" do
#    (RubyVersion.new '1.9.1').version.should == 1
#    (RubyVersion.new 'ruby-2.0.0').version.should == 2
#    (RubyVersion.new 'ruby-3.8.7-p123').version.should == 3
#    (RubyVersion.new '4.8.7-p123').version.should == 4
#  end
#
#  it "should get the major" do
#    (RubyVersion.new '1.9.1').major.should == 9
#    (RubyVersion.new 'ruby-2.0.0').major.should == 0
#    (RubyVersion.new 'ruby-3.8.7-p123').major.should == 8
#    (RubyVersion.new '3.4.7-p123').major.should == 4
#  end
#
#  it "should get the minor" do
#    (RubyVersion.new '1.9.1').minor.should == 1
#    (RubyVersion.new 'ruby-2.0.0').minor.should == 0
#    (RubyVersion.new 'ruby-3.8.7-p123').minor.should == 7
#    (RubyVersion.new '3.8.6-p123').minor.should == 6
#  end
#
#  it "should get the patch" do
#    (RubyVersion.new '1.9.1').patch.should == nil
#    (RubyVersion.new '2.0.0-p123').patch.should == 123
#    (RubyVersion.new 'ruby-3.8.7-p376').patch.should == 376
#  end
#
#  it "should understand shortcuts for 1.9" do
#    r19 = RubyVersion.new '1.9'
#    r19.interpreter.should == 'ruby'
#    r19.major.should == 1
#    r19.minor.should == 1
#    r19.patch.should be_nil
#  end

#  it "should be able to detect existing rubies" do
#    fakedir {|dir|
#      Dir.mkdir File.dir(RVM_RUBIES_DIR, 'ruby-1.8.7-p237')
#      (RubyVersion.new '1.8.7-p237').exists?.should be_true
#    }
#  end
end
