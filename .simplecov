SimpleCov.root(File.expand_path("..", __FILE__))
SimpleCov.coverage_dir(File.expand_path("../tests/minitest/coverage", __FILE__))
SimpleCov.start do
  add_filter '/tests/'
end
