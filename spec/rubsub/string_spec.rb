
require 'rubsub'

describe String do
  it "should correctly detect starting strings" do
    "foo bar".starts_with?("foo").should be_true
    "Mousing Cat".starts_with?("Mousin").should be_true
  end

  it "should correctly fail to detect incorrect starting strings" do
    "foo bar".starts_with?("Foo").should be_false
    "foo bar".starts_with?("bar").should be_false
  end
end
