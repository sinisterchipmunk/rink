# -*- encoding: utf-8 -*-

require File.expand_path("lib/rink/version", File.dirname(__FILE__))

Gem::Specification.new do |s|
  s.name = %q{rink}
  s.version = Rink::Version::STRING

  s.authors = ["Colin MacKenzie IV"]
  s.date = %q{2010-08-07}
  s.description = %q{Makes interactive consoles awesome.}
  s.email = %q{sinisterchipmunk@gmail.com}
  s.extra_rdoc_files = [ "LICENSE", "README.rdoc" ]
  s.homepage = %q{http://www.thoughtsincomputation.com}
  s.summary = %q{Makes interactive consoles awesome.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency 'rspec', "~> 2.6.0"
  s.add_development_dependency 'rcov', '~> 0.9.11' unless ENV['WITHOUT_RCOV']
  s.add_development_dependency 'rake', '~> 0.9.2'
end

