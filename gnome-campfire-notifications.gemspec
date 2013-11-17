Gem::Specification.new do |s|
  s.name        = "db-rotator"
  s.version     = "0.0.1"
  s.summary     = "Easy MySQL database rotation and pruning"
  s.description = "Easy MySQL database rotation and pruning"
  s.authors     = ["Michael Nelson"]
  s.email       = "michael@nelsonware.com"
  s.executables << "db-rotator"
  s.files       = `git ls-files`.split
  s.test_files  = `git ls-files -- test/*`.split
  s.homepage    = "https://github.com/mcnelson/db-rotator"
  s.license     = "LGPL-2.0"

  s.add_development_dependency  'minitest'
end
