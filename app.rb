# frozen_string_literal: true

# Usage: ruby app.rb list|train

require 'benchmark'
require 'colorize'

require_relative 'src/neural_network'
require_relative 'src/save'

case ARGV[0]
when 'list'
  puts '...List of saved neural networks...'.blue
  Save.all.each do |save|
    puts "ID: #{save.id} - Success rate: #{save.success_rate}% - Cost average: #{save.cost_average} - Batch count: #{save.batch_count} - Batch size: #{save.batch_size} - Completed training: #{save.completed_training}"
  end
when 'train'
  training_count = [1, ARGV[1].to_i].max

  training_count.times do |i|
    neural_network = NeuralNetwork.new(id: ARGV[2])

    puts "...Start training [#{i + 1}/#{training_count}]...".blue
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
  end
else
  puts 'Usage: ruby app.rb list|train( [training_count] [save_id])'
end
