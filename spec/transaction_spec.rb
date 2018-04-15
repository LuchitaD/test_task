require_relative './spec_helper'
require_relative '../transaction'

RSpec.describe Transaction do
  context "to_hash" do
    it "serializes data as needed" do
      expect(described_class.new("2018-02-20", "description", 30.5).to_hash).to eq({
        date: "2018-02-20 00:00:00.000000000 +0200",
        description: "description",
        amount: 30.5
      })
    end
  end
end
