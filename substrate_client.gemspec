
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "substrate_client/version"

Gem::Specification.new do |spec|
  spec.name          = "substrate_client"
  spec.version       = SubstrateClient::VERSION
  spec.authors       = ["Wu Minzhe"]
  spec.email         = ["wuminzhe@gmail.com"]

  spec.summary       = %q{Ruby Substrate RPC Client}
  spec.description   = %q{Ruby Substrate RPC Client}
  spec.homepage      = "https://github.com/itering/substrate_client.rb"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.or"

    spec.metadata["homepage_uri"] = spec.homepage
    # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
    # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "substrate_common.rb", "~> 0.1.5"
  spec.add_dependency "faye-websocket", "~> 0.10.9"
  spec.add_dependency "eventmachine", "~> 1.2.7"

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"
end
