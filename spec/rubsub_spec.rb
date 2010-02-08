require 'rubsub'

describe RubSub do
  it "should have the appropriate constants" do
    RubSub::DIR.should_not be_nil
    RubSub::BIN_DIR.should_not be_nil
    RubSub::SESSION_DIR.should_not be_nil
  end
end
