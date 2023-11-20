# frozen_string_literal: true

require 'byebug'
require 'chunky_png'
require 'colorize'
require 'securerandom'

require_relative 'data_loader'
require_relative 'save'

class NeuralNetwork
  LAYERS_DESIGN = [784, 16, 16, 10].freeze
  MIN_BIAS = 0.0
  MAX_BIAS = 10.0
  MIN_WEIGHT = -1.0
  MAX_WEIGHT = 1.0

  def initialize(id: nil, batch_size: 100)
    @data_loader = DataLoader.new

    if id
      Save.find(id)
      @layers = @save.layers
    else
      @save = Save.last_not_trained || Save.new(batch_size:, batch_count: 0)
      @layers = @save.layers || generate_new_neurons_with_random_weights_and_biases
    end
  end

  def train
    puts "Network #{@save.id} already trained.".red and return if @save.completed_training?

    training_correction = initialize_training_correction

    @data_loader.each_label_with_image(kind: :training, batch_size: @save.batch_size, offset: @save.batch_count) do |label, image, i|
      forward_propagation(image)

      image_correction = backpropagation(label.to_i)
      average_corrections(training_correction, image_correction, i)
      print "\r#{i + 1} / #{@data_loader.data_size} images".light_magenta
    end

    apply_training_correction(training_correction)

    @save.batch_count += 1
    @save.completed_training = true if @save.batch_count * @save.batch_size >= @data_loader.data_size
    @save.layers = @layers
    @save.save
  end

  def run
    rights_guesses = 0
    @data_loader.each_label_with_image(kind: :run) do |label, image, i|
      expected = label.to_i

      forward_propagation(image)

      cost = cost_function(expected, @layers.last[:neurons])
      @save.cost_average = (cost + (@save.cost_average * i)) / (i + 1)

      rights_guesses += 1 if guessed(@layers.last[:neurons]) == expected

      print "\r#{i + 1} / #{@data_loader.data_size} images".light_magenta
    end
    @save.success_rate = (rights_guesses / @data_loader.data_size.to_f) * 100
    @save.save
  end

  def display_results
    puts 'Results:'
    puts "ID: #{@save.id}"
    puts "Batch count: #{@save.batch_count}"
    puts "Batch size: #{@save.batch_size}"
    puts "Cost average: #{@save.cost_average}".green
    puts "Success rate: #{@save.success_rate}%".green
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

  def forward_propagation(image)
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
    sum = -bias
    weights.each_with_index do |weight, i|
      sum += weight * inputs[i].to_f
    end
    sum
  end

  def sigmoid(x)
    1 / (1 + Math.exp(-x))
  end

  def sigmoid_derivative(x)
    # sigmoid(x) * (1 - sigmoid(x))
    x * (1 - x)
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
        training[layer_index][:bias][bias_index] = (bias + (image[layer_index][:bias][bias_index] * image_index)) / (image_index + 1)
      end

      layer[:weights].each_with_index do |weights, weights_index|
        weights.each_with_index do |weight, weight_index|
          training[layer_index][:weights][weights_index][weight_index] = (weight + (image[layer_index][:weights][weights_index][weight_index] * image_index)) / (image_index + 1)
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
