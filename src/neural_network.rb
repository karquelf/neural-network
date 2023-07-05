# frozen_string_literal: true

require 'byebug'
require 'chunky_png'
require 'colorize'
require 'securerandom'

require_relative 'data_loader'

class NeuralNetwork
  attr_reader :id, :cost_average, :success_rate

  LAYERS_DESIGN = [784, 16, 16, 10].freeze
  MIN_BIAS = 0.0
  MAX_BIAS = 1.0
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

    training_correction = initialize_training_correction

    @data_loader.each_label_with_image(kind: :training) do |label, image, i|
      activate_neurons(image)
      image_correction = backpropagation(label.to_i)
      average_corrections(training_correction, image_correction, i)
      print "\r#{i + 1} / #{@data_loader.data_size} images".light_magenta
    end

    apply_training_correction(training_correction)
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
      bias = index.positive? ? neuron_count.times.map { rand(MIN_BIAS..MAX_BIAS) } : nil
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
    @value = sigmoid(calc_z(inputs, weights, bias))
  end

  def calc_z(inputs, weights, bias)
    sum = bias
    weights.each_with_index do |weight, i|
      sum += weight * inputs[i].to_f
    end
    sum
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

  def average(array)
    array.sum / array.size.to_f
  end

  def recursive_derivative(all_layers, layer, layer_index, expected, neuron, neuron_index)
    if layer_index.positive?
      average(
        all_layers[layer_index - 1][:neurons].each_with_index.map do |prev_neuron, prev_neuron_index|
          z1 = calc_z(
            all_layers[layer_index + 1][:neurons],
            layer[:weights][neuron_index],
            layer[:bias][neuron_index]
          )

          weight = all_layers[layer_index - 1][:weights][prev_neuron_index][neuron_index]

          sigmoid_derivative(z1) * weight * recursive_derivative(all_layers, all_layers[layer_index - 1], layer_index - 1, expected, prev_neuron, prev_neuron_index)
        end
      )
    else
      y = neuron_index + 1 == expected ? 1.0 : 0.0
      z = calc_z(
        all_layers[layer_index + 1][:neurons],
        layer[:weights][neuron_index],
        layer[:bias][neuron_index]
      )

      sigmoid_derivative(z) * 2 * (neuron - y)
    end
  end

  def backpropagation(expected)
    reversed_layers = @layers.reverse
    corrections = reversed_layers.each_with_index.map do |layer, layer_index|
      next if layer_index == @layers.size - 1

      @layer_corrections = layer[:neurons].each_with_index.map do |neuron, neuron_index|
        weights = layer[:weights][neuron_index].each_with_index.map do |_weight, weight_index|
          far_a = reversed_layers[layer_index + 1][:neurons][weight_index]
          far_a * recursive_derivative(reversed_layers, layer, layer_index, expected, neuron, neuron_index)
        end

        bias = recursive_derivative(reversed_layers, layer, layer_index, expected, neuron, neuron_index)

        {
          bias:,
          weights:
        }
      end

      {
        bias: @layer_corrections.map { |correction| correction[:bias] },
        weights: @layer_corrections.map { |correction| correction[:weights] }
      }
    end
    corrections.reverse
  end

  def initialize_training_correction
    LAYERS_DESIGN.each_with_index.map do |neuron_count, index|
      if index.positive?
        {
          bias: Array.new(neuron_count, 0),
          weights: Array.new(neuron_count) { Array.new(LAYERS_DESIGN[index - 1], 0) }
        }
      else
        []
      end
    end
  end

  def average_corrections(training, image, image_index)
    training.each_with_index do |layer, layer_index|
      next if layer_index.zero?

      layer[:bias].each_with_index do |bias, bias_index|
        training[layer_index][:bias][bias_index] = (bias + image[layer_index][:bias][bias_index]) / (image_index + 1)
      end

      layer[:weights].each_with_index do |weights, weights_index|
        weights.each_with_index do |weight, weight_index|
          training[layer_index][:weights][weights_index][weight_index] = (weight + image[layer_index][:weights][weights_index][weight_index]) / (image_index + 1)
        end
      end
    end
  end

  def apply_training_correction(training_correction)
    @layers.each_with_index do |layer, layer_index|
      next if layer_index.zero?

      layer[:bias].each_with_index do |bias, bias_index|
        layer[:bias][bias_index] += training_correction[layer_index][:bias][bias_index]
      end

      layer[:weights].each_with_index do |weights, weights_index|
        weights.each_with_index do |weight, weight_index|
          layer[:weights][weights_index][weight_index] += training_correction[layer_index][:weights][weights_index][weight_index]
        end
      end
    end
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
