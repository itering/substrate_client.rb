RSpec.describe SubstrateClient do
  it "has a version number" do
    expect(SubstrateClient::VERSION).not_to be nil
  end

  # {
  #   "name": "TotalIssuance",
  #   "type": {
  #     "Plain": "Balance"
  #   },
  #   ...
  # },
  it "can generate correct storage hash for plain type" do
    storage_hash = SubstrateClient::Helper.generate_storage_hash("Balances", "TotalIssuance", nil, nil, nil, 11)
    expect(storage_hash).to eq("0xc2261276cc9d1f8598ea4b6a74b15c2f57c875e4cff74148e4628f264b974c80")
  end

  # {
  #   "name": "Account",
  #   "type": {
  #     "Map": {
  #       "hasher": "Blake2_128Concat",
  #       "key": "AccountId",
  #       "value": "AccountInfo<Index, AccountData>",
  #       "linked": false
  #     }
  #   },
  #   ...
  # },
  it "can generate correct storage hash for map type" do
    storage_hash = SubstrateClient::Helper.generate_storage_hash("System", "Account", ["0x30599dba50b5f3ba0b36f856a761eb3c0aee61e830d4beb448ef94b6ad92be39"], "Blake2_128Concat", nil, 11)
    expect(storage_hash).to eq("0x26aa394eea5630e07c48ae0c9558cef7b99d880ec681799c0cf30e8886371da9b006ad531e054edf786780ebfc7ac78030599dba50b5f3ba0b36f856a761eb3c0aee61e830d4beb448ef94b6ad92be39")
  end


    # {
    #   "name": "AuthoredBlocks",
    #   "type": {
    #     "DoubleMap": {
    #       "hasher": "Twox64Concat",
    #       "key1": "SessionIndex",
    #       "key2": "ValidatorId",
    #       "value": "U32",
    #       "key2Hasher": "Twox64Concat"
    #     }
    #   },
    # },
    it "can generate correct storage hash for double map type" do
      storage_hash = SubstrateClient::Helper.generate_storage_hash("ImOnline", "AuthoredBlocks", ["0x020b0000", "0x749ddc93a65dfec3af27cc7478212cb7d4b0c0357fef35a0163966ab5333b757"], "Twox64Concat", "Twox64Concat", 11)
      expect(storage_hash).to eq("0x2b06af9719ac64d755623cda8ddd9b94b1c371ded9e9c565e89ba783c4d5f5f93b6390c9afa3500d020b0000b0f0b3ac307cd751749ddc93a65dfec3af27cc7478212cb7d4b0c0357fef35a0163966ab5333b757")
    end

    it "can encode balances transfer payload" do
      client = SubstrateClientSync.new("wss://kusama-rpc.polkadot.io/", spec_name: "kusama")

      payload = client.compose_call(
        "balances",
        "transfer",
        { dest: "0x586cb27c291c813ce74e86a60dad270609abf2fc8bee107e44a80ac00225c409", value: 1_000_000_000_000 }
      )
      expect(payload).to eql("0xa8040400ff586cb27c291c813ce74e86a60dad270609abf2fc8bee107e44a80ac00225c409070010a5d4e8")
    end
end
