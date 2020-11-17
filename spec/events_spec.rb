
RSpec.describe SubstrateClient do
  before(:all) {
    @client = SubstrateClient.new "wss://cc1.darwinia.network", spec_name: "darwinia-8"
  }

  it "can decode events" do
    data = "0x3400000000000000881b990900000000020000000100000000000000000000000000020000000200000008013cda691649651a83b4c47bda9e2cafabf7ac62fff3bb57c4540d1af1283fc255100d18ec1700000000000000000000000000020000000801080de5b241f51bfaff6d703b1ceded9552b5212074231d7c2225b055b6d1f51ca3cd3d34650000000000000000000000000002000000080126b55f5f5379abf732d2f22593b1b588bde3b7786f744b88ba16c3caeed4832b20150fa83300000000000000000000000000020000000801360e3f78cdb845b8d4ede8f4a6b4935e80c80059d046b9911ad1330228212e381b4e163729010000000000000000000000000200000008019c2e628f201ef39275bfad428a4790685c65953aaa825c76481f8bd411fff00b518b10b51900000000000000000000000000020000000801360e3f78cdb845b8d4ede8f4a6b4935e80c80059d046b9911ad1330228212e38648e1c601f01000000000000000000000000020000000801328502245eebfbe3b33631411086f1765939814af7fa668d9f5a6398b0e7077ee677c949c40000000000000000000000000002000000160100000200000014067a3d1e030000000000000000000000000000020000000404b62d88e3f439fe9b5ea799b27bf7c6db5e795de1784f27b1bc051553499e420f5f8fc70000000000000000000000000000000200000000001809c3520f000000000000"

    scale_bytes = Scale::Bytes.new data

    @client.init_runtime

    length = Scale::Types::Compact.decode(scale_bytes).value
    expect(length).to eq(13)

    event = Scale::Types.get("EventRecord").decode(scale_bytes).value
    expect(event).to eq({:extrinsic_idx=>0, :params=>[{:name=>"ExtrinsicSuccess", :type=>"DispatchInfo", :value=>{"weight"=>161029000, "class"=>"Mandatory", "paysFee"=>"Yes"}}], :topics=>[]})

    event = Scale::Types.get("EventRecord").decode(scale_bytes).value
    expect(event).to eq({:extrinsic_idx=>1, :params=>[{:name=>"ExtrinsicSuccess", :type=>"DispatchInfo", :value=>{"weight"=>0, "class"=>"Mandatory", "paysFee"=>"Yes"}}], :topics=>[]})

    event = Scale::Types.get("EventRecord").decode(scale_bytes).value
    expect(event).to eq({:extrinsic_idx=>2, :params=>[{:name=>"Reward", :type=>"AccountId", :value=>"0x3cda691649651a83b4c47bda9e2cafabf7ac62fff3bb57c4540d1af1283fc255"}, {:name=>"Reward", :type=>"RingBalance", :value=>102745246992}], :topics=>[]})

    event = Scale::Types.get("EventRecord").decode(scale_bytes).value
    expect(event).to eq({:extrinsic_idx=>2, :params=>[{:name=>"Reward", :type=>"AccountId", :value=>"0x080de5b241f51bfaff6d703b1ceded9552b5212074231d7c2225b055b6d1f51c"}, {:name=>"Reward", :type=>"RingBalance", :value=>434668162467}], :topics=>[]})

    event = Scale::Types.get("EventRecord").decode(scale_bytes).value
    expect(event).to eq({:extrinsic_idx=>2, :params=>[{:name=>"Reward", :type=>"AccountId", :value=>"0x26b55f5f5379abf732d2f22593b1b588bde3b7786f744b88ba16c3caeed4832b"}, {:name=>"Reward", :type=>"RingBalance", :value=>221862892832}], :topics=>[]})

    event = Scale::Types.get("EventRecord").decode(scale_bytes).value
    expect(event).to eq({:extrinsic_idx=>2, :params=>[{:name=>"Reward", :type=>"AccountId", :value=>"0x360e3f78cdb845b8d4ede8f4a6b4935e80c80059d046b9911ad1330228212e38"}, {:name=>"Reward", :type=>"RingBalance", :value=>1276529495579}], :topics=>[]})

    event = Scale::Types.get("EventRecord").decode(scale_bytes).value
    expect(event).to eq({:extrinsic_idx=>2, :params=>[{:name=>"Reward", :type=>"AccountId", :value=>"0x9c2e628f201ef39275bfad428a4790685c65953aaa825c76481f8bd411fff00b"}, {:name=>"Reward", :type=>"RingBalance", :value=>110411942737}], :topics=>[]})

    event = Scale::Types.get("EventRecord").decode(scale_bytes).value
    expect(event).to eq({:extrinsic_idx=>2, :params=>[{:name=>"Reward", :type=>"AccountId", :value=>"0x360e3f78cdb845b8d4ede8f4a6b4935e80c80059d046b9911ad1330228212e38"}, {:name=>"Reward", :type=>"RingBalance", :value=>1234268098148}], :topics=>[]})

    event = Scale::Types.get("EventRecord").decode(scale_bytes).value
    expect(event).to eq({:extrinsic_idx=>2, :params=>[{:name=>"Reward", :type=>"AccountId", :value=>"0x328502245eebfbe3b33631411086f1765939814af7fa668d9f5a6398b0e7077e"}, {:name=>"Reward", :type=>"RingBalance", :value=>843051530214}], :topics=>[]})

    event = Scale::Types.get("EventRecord").decode(scale_bytes).value
    expect(event).to eq({:extrinsic_idx=>2, :params=>[], :topics=>[]})

    event = Scale::Types.get("EventRecord").decode(scale_bytes).value
    expect(event).to eq({:extrinsic_idx=>2, :params=>[{:name=>"DepositRing", :type=>"RingBalance", :value=>52313466}], :topics=>[]})

    event = Scale::Types.get("EventRecord").decode(scale_bytes).value
    expect(event).to eq({:extrinsic_idx=>2, :params=>[{:name=>"Deposit", :type=>"AccountId", :value=>"0xb62d88e3f439fe9b5ea799b27bf7c6db5e795de1784f27b1bc051553499e420f"}, {:name=>"Deposit", :type=>"Balance", :value=>13078367}], :topics=>[]})

    event = Scale::Types.get("EventRecord").decode(scale_bytes).value
    expect(event).to eq({:extrinsic_idx=>2, :params=>[{:name=>"ExtrinsicSuccess", :type=>"DispatchInfo", :value=>{"weight"=>65813023000, "class"=>"Normal", "paysFee"=>"Yes"}}], :topics=>[]})
  end
end
