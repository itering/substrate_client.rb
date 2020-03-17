RSpec.describe SubstrateClient do
  it "has a version number" do
    expect(SubstrateClient::VERSION).not_to be nil
  end

  it "can generate correct storage hash" do
    address = "5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY"
    account_id = Address.decode(address)
    storage_hash = SubstrateClient.generate_storage_hash("Balances", "FreeBalance", account_id, "black2_256", 9)
    expect(storage_hash).to eq("0xc2261276cc9d1f8598ea4b6a74b15c2f6482b9ade7bc6657aaca787ba1add3b42e3fb4c297a84c5cebc0e78257d213d0927ccc7596044c6ba013dd05522aacba")
  end
end
