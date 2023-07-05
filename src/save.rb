# frozen_string_literal: true

require 'byebug'
require 'JSON'
require 'sqlite3'

require_relative 'database'

class Save

  attr_accessor :id, :cost_average, :success_rate, :layers, :batch_count, :batch_size, :completed_training

  def initialize(attributes = {})
    @id = attributes[:id]
    @cost_average = attributes[:cost_average] || 0.0
    @success_rate = attributes[:success_rate] || 0.0
    @layers = attributes[:layers]
    @batch_count = attributes[:batch_count]
    @batch_size = attributes[:batch_size]
    @completed_training = attributes[:completed_training] || false
  end

  def save
    if id.nil?
      create
    else
      update
    end
  end

  def self.find(id)
    rows = Database.instance.execute <<-SQL
      SELECT * FROM neural_networks WHERE id = #{id};
    SQL

    raise 'Neural network not found' if rows.empty?

    row = rows.first
    new(
      id: row[0],
      cost_average: row[1],
      success_rate: row[2],
      layers: JSON.parse(row[3], symbolize_names: true),
      batch_count: row[4],
      batch_size: row[5],
      completed_training: row[6]
    )
  end

  def self.last_not_trained
    rows = Database.instance.execute <<-SQL
      SELECT * FROM neural_networks WHERE completed_training = FALSE ORDER BY id DESC LIMIT 1;
    SQL

    return nil if rows.empty?

    row = rows.first
    new(
      id: row[0],
      cost_average: row[1],
      success_rate: row[2],
      layers: JSON.parse(row[3], symbolize_names: true),
      batch_count: row[4],
      batch_size: row[5],
      completed_training: row[6]
    )
  end

  def self.all
    rows = Database.instance.execute <<-SQL
      SELECT * FROM neural_networks;
    SQL

    rows.map do |row|
      new(
        id: row[0],
        cost_average: row[1],
        success_rate: row[2],
        layers: JSON.parse(row[3], symbolize_names: true),
        batch_count: row[4],
        batch_size: row[5],
        completed_training: row[6]
      )
    end
  end

  def completed_training?
    @completed_training == 1
  end

  private

  def create
    Database.instance.execute <<-SQL
      INSERT INTO neural_networks (cost_average, success_rate, layers, batch_count, batch_size, completed_training)
      VALUES (#{cost_average}, #{success_rate}, '#{JSON.dump(layers)}', #{batch_count}, #{batch_size}, #{completed_training});
    SQL
    self.id = Database.instance.last_insert_row_id
  end

  def update
    Database.instance.execute <<-SQL
      UPDATE neural_networks
      SET cost_average = #{cost_average}, success_rate = #{success_rate}, layers = '#{JSON.dump(layers)}', batch_count = #{batch_count}, batch_size = #{batch_size}, completed_training = #{completed_training}
      WHERE id = #{id};
    SQL
  end
end
