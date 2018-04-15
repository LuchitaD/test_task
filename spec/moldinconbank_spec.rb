require_relative './spec_helper'
require_relative '../moldinconbank'
require_relative '../transaction'

RSpec.describe Moldindconbank do
  before do
    expect(Watir::Browser).to receive(:new).and_return("BROWSER")
  end

  describe "parse_account" do
    let(:file) { File.open("./spec_data/operations.html","r") { |f| f.read } } # add your file
    let(:html) { Nokogiri::HTML.fragment(file).css("#contract-information") }

    it "parses account information" do
      expect(subject.send(:parse_account, html)).to eq({
        name: "Ivan Ivanov",
        balance: 0.51, 
        currency: "USD",
        description: "MasterCard Standard Contactless"
      })
    end
  end

  describe "parse_transaction" do
    let(:file) { File.open("./spec_data/transactions.html","r") { |f| f.read } } # add your file
    let(:body) { Nokogiri::HTML.fragment(file).css(".operation-details-body") }
    let(:header) { Nokogiri::HTML.fragment(file).css(".operation-details-header") }

    it "parses transaction" do
      transaction = subject.send(:parse_transaction, body, header)
      expect(transaction).to be_a_kind_of(Transaction)
      expect(transaction.to_hash).to eq({
        date: "2018-04-13 15:38:00.000000000 +0300",
        description: "Transfer între carduri MasterCard 535113******9700",
        amount: 500.0
      })
    end
  end
end
