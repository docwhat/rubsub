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
    (RVM::makeVersion 'ruby-1.8.7-p123').to_s.should == 'ruby-1.8.7-p123'
    (RVM::makeVersion 'ruby-1.9.1-p1').to_s.should == 'ruby-1.9.1-p1'
  end

  it "should properly compare patch levels" do
    a = RVM::makeVersion('ruby-1.8.7-p1')
    b = RVM::makeVersion('ruby-1.8.7-p2')
    a.should be < b
    b.should be > a
  end

  it "should understand approximations" do
    a = RVM::makeVersion('ruby-1.8.7-p123')
    b = RVM::makeVersion('ruby-1.8.7-p123')
    a.should == b
  end

  it "should not allow comparisons with different interpreters" do
    a = RVM::makeVersion('jruby-1.8.7-p123')
    b = RVM::makeVersion('ruby-1.8.7-p123')
    a.should be < b
    b.should be > a
  end

  it "should add ruby as a prefix if it doesn't have one" do
    RVM::makeVersion('1.8.7').to_s[0,10].should == 'ruby-1.8.7'
    RVM::makeVersion('1.9.1').to_s[0,10].should == 'ruby-1.9.1'
  end

  it "should be able to take a RubyVersion as an argument to new." do
    RVM::makeVersion(RVM::makeVersion('1.8.7'))
  end

  it "should accept default as an argument." do
    RVM::makeVersion('default').is_a?(RVM::RubyVersion).should be_true
  end

  it "should accept 'internal' as an argument." do
    rv = RVM::makeVersion('internal')
    rv.is_a?(RVM::RubyVersion).should be_true
    File.basename(rv.path).should == 'myruby'
  end

#  it "should understand the interpreter ruby" do
#    (RVM::makeVersion '1.8.7').interpreter.should == 'ruby'
#    (RVM::makeVersion '1.9.1').interpreter.should == 'ruby'
#    (RVM::makeVersion 'ruby-1.8.7').interpreter.should == 'ruby'
#    (RVM::makeVersion 'ruby-1.9.1').interpreter.should == 'ruby'
#  end
#
#  it "should get the version" do
#    (RVM::makeVersion '1.9.1').version.should == 1
#    (RVM::makeVersion 'ruby-2.0.0').version.should == 2
#    (RVM::makeVersion 'ruby-3.8.7-p123').version.should == 3
#    (RVM::makeVersion '4.8.7-p123').version.should == 4
#  end
#
#  it "should get the major" do
#    (RVM::makeVersion '1.9.1').major.should == 9
#    (RVM::makeVersion 'ruby-2.0.0').major.should == 0
#    (RVM::makeVersion 'ruby-3.8.7-p123').major.should == 8
#    (RVM::makeVersion '3.4.7-p123').major.should == 4
#  end
#
#  it "should get the minor" do
#    (RVM::makeVersion '1.9.1').minor.should == 1
#    (RVM::makeVersion 'ruby-2.0.0').minor.should == 0
#    (RVM::makeVersion 'ruby-3.8.7-p123').minor.should == 7
#    (RVM::makeVersion '3.8.6-p123').minor.should == 6
#  end
#
#  it "should get the patch" do
#    (RVM::makeVersion '1.9.1').patch.should == nil
#    (RVM::makeVersion '2.0.0-p123').patch.should == 123
#    (RVM::makeVersion 'ruby-3.8.7-p376').patch.should == 376
#  end
#
#  it "should understand shortcuts for 1.9" do
#    r19 = RVM::makeVersion '1.9'
#    r19.interpreter.should == 'ruby'
#    r19.major.should == 1
#    r19.minor.should == 1
#    r19.patch.should be_nil
#  end

#  it "should be able to detect existing rubies" do
#    fakedir {|dir|
#      Dir.mkdir File.dir(RVM_RUBIES_DIR, 'ruby-1.8.7-p237')
#      (RVM::makeVersion '1.8.7-p237').exists?.should be_true
#    }
#  end
end
