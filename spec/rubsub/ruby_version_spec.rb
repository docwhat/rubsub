require 'rubsub'

# Alas, this requires 1.9.1 for Dir.mktmpdir - CGH
#def fakedir &block
#  Dir.mktmpdir {|dir|
#    old_rubsub_dir = RubSub::DIR
#    RubSub.set_const 'RubSub::DIR', dir
#    Dir.mkdir RubSub::RUBIES_DIR
#    block dir
#    RubSub.set_const 'RubSub::DIR', old_rubsub_dir
#  }
#end

describe RubSub::RubyVersion do

  it "should pass a sunny day test" do
    (RubSub::makeVersion 'ruby-1.8.7-p123').to_s.should == 'ruby-1.8.7-p123'
    (RubSub::makeVersion 'ruby-1.9.1-p1').to_s.should == 'ruby-1.9.1-p1'
  end

  it "should properly compare patch levels" do
    a = RubSub::makeVersion('ruby-1.8.7-p1')
    b = RubSub::makeVersion('ruby-1.8.7-p2')
    a.should be < b
    b.should be > a
  end

  it "should understand approximations" do
    a = RubSub::makeVersion('ruby-1.8.7-p123')
    b = RubSub::makeVersion('ruby-1.8.7-p123')
    a.should == b
  end

  it "should not allow comparisons with different interpreters" do
    a = RubSub::makeVersion('jruby-1.8.7-p123')
    b = RubSub::makeVersion('ruby-1.8.7-p123')
    a.should be < b
    b.should be > a
  end

  it "should add ruby as a prefix if it doesn't have one" do
    ['1.8.7', '1.9.1'].each do |s|
      v = RubSub::makeVersion(s)
      v.complete?.should be_true
      s2 = "ruby-#{s}"
      v.to_s[0,s2.length].should == s2
    end
  end

  it "should be able to take a RubyVersion as an argument to new." do
    RubSub::makeVersion(RubSub::makeVersion('1.8.7'))
  end

  it "should accept default as an argument." do
    RubSub::makeVersion('default').is_a?(RubSub::RubyVersion).should be_true
  end

  it "should accept 'internal' as an argument." do
    rv = RubSub::makeVersion('internal')
    rv.is_a?(RubSub::RubyVersion).should be_true
    File.basename(rv.path).should == 'myruby'
  end

#  it "should understand the interpreter ruby" do
#    (RubSub::makeVersion '1.8.7').interpreter.should == 'ruby'
#    (RubSub::makeVersion '1.9.1').interpreter.should == 'ruby'
#    (RubSub::makeVersion 'ruby-1.8.7').interpreter.should == 'ruby'
#    (RubSub::makeVersion 'ruby-1.9.1').interpreter.should == 'ruby'
#  end
#
#  it "should get the version" do
#    (RubSub::makeVersion '1.9.1').version.should == 1
#    (RubSub::makeVersion 'ruby-2.0.0').version.should == 2
#    (RubSub::makeVersion 'ruby-3.8.7-p123').version.should == 3
#    (RubSub::makeVersion '4.8.7-p123').version.should == 4
#  end
#
#  it "should get the major" do
#    (RubSub::makeVersion '1.9.1').major.should == 9
#    (RubSub::makeVersion 'ruby-2.0.0').major.should == 0
#    (RubSub::makeVersion 'ruby-3.8.7-p123').major.should == 8
#    (RubSub::makeVersion '3.4.7-p123').major.should == 4
#  end
#
#  it "should get the minor" do
#    (RubSub::makeVersion '1.9.1').minor.should == 1
#    (RubSub::makeVersion 'ruby-2.0.0').minor.should == 0
#    (RubSub::makeVersion 'ruby-3.8.7-p123').minor.should == 7
#    (RubSub::makeVersion '3.8.6-p123').minor.should == 6
#  end
#
#  it "should get the patch" do
#    (RubSub::makeVersion '1.9.1').patch.should == nil
#    (RubSub::makeVersion '2.0.0-p123').patch.should == 123
#    (RubSub::makeVersion 'ruby-3.8.7-p376').patch.should == 376
#  end
#
#  it "should understand shortcuts for 1.9" do
#    r19 = RubSub::makeVersion '1.9'
#    r19.interpreter.should == 'ruby'
#    r19.major.should == 1
#    r19.minor.should == 1
#    r19.patch.should be_nil
#  end

#  it "should be able to detect existing rubies" do
#    fakedir {|dir|
#      Dir.mkdir File.dir(RubSub::RUBIES_DIR, 'ruby-1.8.7-p237')
#      (RubSub::makeVersion '1.8.7-p237').exists?.should be_true
#    }
#  end
end
