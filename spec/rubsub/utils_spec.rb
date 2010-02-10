require 'rubsub'
require 'tmpdir'

describe RubSub do

  it "should unpack the test tarball" do
    testball = File.join(File.dirname(__FILE__), 'test.tar.gz')
    old_dir = Dir.pwd
    Dir::mktmpdir do |dir|
      RubSub.unpack testball, dir
      File.exists? File.join(dir, 'test.txt')
    end
    Dir.pwd.should == old_dir
  end

  it "should be able to generate legit flags" do
    f = RubSub.get_flags
    f.has_key?(:configure).should be_true
    f.has_key?(:cflags).should be_true
    f.has_key?(:ldflags).should be_true
  end

  it "should get all the Ruby versions" do
    p "NARF"
    p RubSub.get_ruby_versions
  end

end
