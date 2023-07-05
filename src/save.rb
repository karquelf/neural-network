# frozen_string_literal: true

require 'JSON'
require 'sqlite3'

class Save

  attr_accessor :id, :cost_average, :success_rate, :layers, :training_count, :batch_size

  def initialize(attributes = {})
    @db = SQLite3::Database.new 'db/neural_network.db'
    # create table if not exists
    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS neural_networks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cost_average FLOAT,
        success_rate FLOAT,
        layers TEXT,
        training_count INTEGER,
        batch_size INTEGER
      );
    SQL

    @id = attributes[:id]
    @cost_average = attributes[:cost_average]
    @success_rate = attributes[:success_rate]
    @layers = attributes[:layers]
    @training_count = attributes[:training_count]
    @batch_size = attributes[:batch_size]
  end

  def create
    @db.execute <<-SQL
      INSERT INTO neural_networks (cost_average, success_rate, layers, training_count, batch_size)
      VALUES (#{cost_average}, #{success_rate}, '#{layers.to_json}', #{training_count}, #{batch_size});
    SQL
  end

  def load(id)
    rows = @db.execute <<-SQL
      SELECT * FROM neural_networks WHERE id = #{id};
    SQL

    raise 'Neural network not found' if rows.empty?

    row = rows.first
    @id = row[0]
    @cost_average = row[1]
    @success_rate = row[2]
    @layers = JSON.parse(row[3], symbolize_names: true)
    @training_count = row[4]
    @batch_size = row[5]
  end
end
