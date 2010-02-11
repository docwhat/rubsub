require 'rubsub'
require 'tmpdir'

def silently(&block)
  warn_level = $VERBOSE
  begin
    $VERBOSE = nil
    result = block.call
  ensure
    $VERBOSE = warn_level
  end
  result
end

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
    RubSub.get_ruby_versions.first.is_a?(RubSub::RubyVersion).should be_true
  end

end

describe RubSub do

  it "should be able to catch multi-line output" do
    Dir::mktmpdir do |dir|
      silently { RubSub.const_set("LOG_DIR", dir) }
      RubSub.logrun "spec", "yes fishy | head -n 20"
      count = 0
      File.open(File.join dir, 'spec.log') do |f|
        while (line = f.gets)
          count = count + 1 if line.chomp == 'fishy'
        end
      end
      count.should == 20
    end
  end

  it "should be able to catch multi-line error output" do
    Dir::mktmpdir do |dir|
      silently { RubSub.const_set("LOG_DIR", dir) }
      RubSub.logrun "spec", "yes fishy | head -n 20 1>&2"
      count = 0
      File.open(File.join dir, 'spec.log') do |f|
        while (line = f.gets)
          count = count + 1 if line.chomp == 'fishy'
        end
      end
      count.should == 20
    end
  end

end
