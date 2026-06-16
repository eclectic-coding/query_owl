require_relative "lib/query_owl/version"

Gem::Specification.new do |spec|
  spec.name        = "query_owl"
  spec.version     = QueryOwl::VERSION
  spec.authors     = ["Chuck Smith"]
  spec.email       = ["eclectic-coding@users.noreply.github.com"]
  spec.homepage    = "https://github.com/eclectic-coding/query_owl"
  spec.summary     = "Structured N+1 and slow query warnings for Rails development."
  spec.description = "A leaner alternative to Bullet. Detects N+1 queries and slow queries in development, logging structured warnings to your Rails logger without the noise."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.3"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/eclectic-coding/query_owl"
  spec.metadata["changelog_uri"]   = "https://github.com/eclectic-coding/query_owl/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.1"
  spec.add_dependency "importmap-rails"
  spec.add_dependency "turbo-rails"
end
