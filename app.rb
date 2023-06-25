# frozen_string_literal: true

# Usage: ruby app.rb train

require 'benchmark'
require 'colorize'

require_relative 'src/neural_network'

case ARGV[0]
when 'train'
  neural_network = NeuralNetwork.new

  puts '...Start training...'.blue
  time = Benchmark.measure do
    neural_network.train
  end
  puts "\n...Training finished in #{time.real.round(2)} seconds...".blue

  puts '...Start running...'.blue
  time = Benchmark.measure do
    neural_network.run
  end
  puts "\n...Running finished in #{time.real.round(2)} seconds...".blue

  neural_network.display_results
else
  puts 'Usage: ruby app.rb train'
end
