# frozen_string_literal: true

require 'byebug'
require 'chunky_png'
require 'colorize'
require 'securerandom'

require_relative 'data_loader'

class NeuralNetwork
  attr_reader :id, :cost_average, :success_rate

  LAYERS_DESIGN = [784, 16, 16, 10].freeze
  MIN_BIAS = 0
  MAX_BIAS = 10
  MIN_WEIGHT = -1.0
  MAX_WEIGHT = 1.0

  def initialize(id: nil)
    @data_loader = DataLoader.new
    @id = id
    @cost_average = 0.0
    @success_rate = 0.0

    if @id
      # TODO: Load weights and biases from file
    else
      @layers = generate_new_neurons_with_random_weights_and_biases
    end
  end

  def train
    puts "Network #{@id} already trained.".red and return unless id.nil?

    # corrections = []

    @data_loader.each_label_with_image(kind: :training) do |label, image, i|
      activate_neurons(image)
      # corrections << backpropagation(label.to_i)
      print "\r#{i + 1} / #{@data_loader.data_size} images".light_magenta
    end
  end

  def save
    puts 'Saving...'
  end

  def run
    rights_guesses = 0
    @data_loader.each_label_with_image(kind: :run) do |label, image, i|
      expected = label.to_i

      activate_neurons(image)

      cost = cost_function(expected, @layers.last[:neurons])
      @cost_average = (cost + (@cost_average * i)) / (i + 1)

      rights_guesses += 1 if guessed(@layers.last[:neurons]) == expected

      print "\r#{i + 1} / #{@data_loader.data_size} images".light_magenta
    end
    @success_rate = (rights_guesses / @data_loader.data_size.to_f) * 100
  end

  def display_results
    puts 'Results:'
    puts "Success rate: #{@success_rate}%".green
  end

  private

  def generate_new_neurons_with_random_weights_and_biases
    LAYERS_DESIGN.each_with_index.map do |neuron_count, index|
      neurons = Array.new(neuron_count, 0)
      bias = index.positive? ? rand(MIN_BIAS..MAX_BIAS) : nil
      weights =
        if index.positive?
          neuron_count.times.map do
            LAYERS_DESIGN[index - 1].times.map do
              rand(MIN_WEIGHT..MAX_WEIGHT)
            end
          end
        end
      {
        neurons:,
        bias:,
        weights:
      }
    end
  end

  def activate_neurons(image)
    @layers.each_with_index do |layer, layer_index|
      if layer_index.zero?
        layer[:neurons] = image.flatten.map { |pixel| pixel / 255.0 }
      else
        layer[:neurons] = layer[:neurons].size.times.map do |neuron_index|
          activate_neuron(
            @layers[layer_index - 1][:neurons],
            layer[:weights][neuron_index],
            layer[:bias][neuron_index]
          )
        end
      end
    end
  end

  def activate_neuron(inputs, weights, bias)
    sum = bias
    weights.each_with_index do |weight, i|
      sum += weight * inputs[i].to_f
    end
    @value = sigmoid(sum)
  end

  def sigmoid(x)
    1 / (1 + Math.exp(-x))
  end

  def sigmoid_derivative(x)
    sigmoid(x) * (1 - sigmoid(x))
  end

  def cost_function(expected, output)
    output.map.with_index do |value, index|
      if index + 1 == expected
        (value - 1)**2
      else
        value**2
      end
    end.sum
  end

  def guessed(output)
    output.index(output.max) + 1
  end

  def backpropagation(expected)
    corrections = @layers.reverse.each_with_index.map do |layer, layer_index|
      layer[:neurons].each_with_index.map do |neuron, neuron_index|
        if layer_index.zero?
          error = (expected == neuron_index + 1 ? 1 : 0) - neuron
        else

        end
      end
    end
    corrections.reverse
  end

  def generate_png(label, image)
    png = ChunkyPNG::Image.new(image.first.size, image.size, ChunkyPNG::Color::TRANSPARENT)
    image.each_with_index do |row, y|
      row.each_with_index do |pixel, x|
        png[x, y] = ChunkyPNG::Color.rgb(pixel, pixel, pixel)
      end
    end
    png.save("tmp/#{label}.png", interlace: true)
  end
end
