$: << 'vendor_ruby'

require 'rvm'

describe RVM do
  it "should have the appropriate constants" do
    RVM::RVM_DIR.should_not be_nil
    RVM::RVM_BIN_DIR.should_not be_nil
    RVM::RVM_SESSION_DIR.should_not be_nil
  end
end
