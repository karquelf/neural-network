# frozen_string_literal: true

# Usage: ruby app.rb train|run

require_relative 'src/neural_network'

case ARGV[0]
when 'train'
  NeuralNetwork.new.train
when 'run'
  NeuralNetwork.new.run
else
  puts 'Usage: ruby app.rb train|run'
end
