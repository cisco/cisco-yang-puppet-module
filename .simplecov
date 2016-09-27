SimpleCov.root(File.expand_path('..', __FILE__))
SimpleCov.coverage_dir(File.expand_path('../tests/minitest/coverage', __FILE__))
SimpleCov.command_name("test:#{ENV['COV_TEST_SUITE']}")
SimpleCov.merge_timeout(3600) # one hour
SimpleCov.start do
  add_filter '/tests/'
end
