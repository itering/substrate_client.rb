# SubstrateClient

This is a library of interfaces for communicating with Substrate nodes. It provides application developers the ability to query a node and interact with the Substrate chains using Ruby.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'substrate_client'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install substrate_client

## Usage

### Supported rpc methods

```ruby
require "substrate_client"

client = SubstrateClient.new("wss://kusama-rpc.polkadot.io/")
client.methods
```
returns like:
```shell
[
	"account_nextIndex",
  "author_hasKey",
  ...
	"chain_getBlock",
	"chain_getBlockHash",
	...
]
```

The rpc methods can be dynamically called by its name, so you can call it like:

```ruby
client.chain_getBlockHash(1024)
```

### Origin rpc methods

- `client.chain_getFinalisedHead`
- `client.chain_getHead`
- `client.chain_getHeader(block_hash = nil)`
- `client.chain_get_block(block_hash = nil)`
- `client.chain_get_block_hash(block_id)`
- `client.chain_get_runtime_version(block_hash = nil)`
- `client.state_get_metadata(block_hash = nil)`

- `client.state_get_storage(storage_key, block_hash = nil)`
- `client.system_name`
- `client.system_version`

### Wrap methods

These methods will encode the parameters and decode the returned data

- `client.get_block_number(block_hash)`

- `client.get_metadata(block_hash)`

- `client.get_block(block_hash=nil)`

- `client.get_block_events(block_hash)`

- `client.get_storage(module_name, storage_name, params = nil, block_hash = nil)`

  ```ruby
  client.get_storage("Balances", "TotalIssuance", nil, nil)
  client.get_storage("System", "Account", ["0xd43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d"], nil)
  client.get_storage("ImOnline", "AuthoredBlocks", [2818, "0x749ddc93a65dfec3af27cc7478212cb7d4b0c0357fef35a0163966ab5333b757"], nil) 
  ```
  
- `compose_call(module_name, call_name, params, block_hash=nil)`

  ```ruby
  client.compose_call "Balances", "Transfer", { dest: "0x586cb27c291c813ce74e86a60dad270609abf2fc8bee107e44a80ac00225c409", value: 1_000_000_000_000 }, nil
  ```

## Docker

1. update to latest image

   `docker pull itering/substrate_client:latest`

2. Run image:

   `docker run -it itering/substrate_client:latest`

   This  will enter the container with a linux shell opened. 

   ```shell
   /usr/src/app # 
   ```

3. Type `rspec` to run all tests

   ```shell
   /usr/src/app # rspec
   ...................
   
   Finished in 0.00883 seconds (files took 0.09656 seconds to load)
   5 examples, 0 failures
   ```

4. Or, type `./bin/console` to enter the ruby interactive environment and run any decode or encode code

   ```shell
   /usr/src/app # ./bin/console
   [1] pry(main)> client = SubstrateClient.new("wss://kusama-rpc.polkadot.io/")
   => #<SubstrateClient:0x000055a78f124f58 ...
   [2] pry(main)> client.methods
   => ...
   [3] pry(main)> client.chain_getHead
   => "0xb3c3a220d4639b7c62f179f534b3a66336a115ebc18f13db053f0c57437c45fc"
   ```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/substrate_client. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SubstrateClient project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/substrate_client/blob/master/CODE_OF_CONDUCT.md).
