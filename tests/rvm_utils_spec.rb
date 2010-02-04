require 'rvm'
require 'tmpdir'

describe RVM do

  it "should unpack the test tarball" do
    testball = File.join(File.dirname(__FILE__), 'test.tar.gz')
    old_dir = Dir.pwd
    Dir::mktmpdir do |dir|
      RVM.unpack testball, dir
      File.exists? File.join(dir, 'test.txt')
    end
    Dir.pwd.should == old_dir
  end

end
