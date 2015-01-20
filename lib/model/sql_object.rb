require_relative 'db_connection'
require_relative 'relation.rb'
require_relative 'associatable'
require 'active_support/inflector'
require 'byebug'

class SQLObject
  extend Associatable

  def self.columns
    unless @column_list
      table = DBConnection.execute2(<<-SQL)
        SELECT
          *
        FROM
          #{table_name}
        LIMIT 1
      SQL

      @column_list = []

      table.first.each do |name|
        columns << name.to_sym
      end
    end

    @column_list
  end

  def self.finalize!
    columns.each do |column|
      define_method("#{column}") do
        attributes[column]
      end

      define_method("#{column}=") do |val|
        attributes[column] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL

    parse_all(results)
  end

  def self.parse_all(results)
    results.map do |row|
      self.new(row)
    end
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, Integer(id))
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL

    result.empty? ? nil : self.new(result.first)
  end

  def initialize(params = {})
    params.each do |key, value|
      if self.class.columns.include?(key.to_sym)
        send( "#{key}=", value )
      else
        raise "unknown attribute '#{key}'"
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map do |column|
      send(column)
    end
  end

  def insert
    table = self.class.table_name
    col_names = self.class.columns.join(", ")
    question_marks = (["?"]*self.class.columns.count).join(", ")

    DBConnection.execute2(<<-SQL, *attribute_values)
      INSERT INTO
        #{table} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_string = self.class.columns.join(" = ?, ") + " = ?"

    DBConnection.execute2(<<-SQL, *attribute_values, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_string}
      WHERE
        id = ?
    SQL
  end

  def save
    id.nil? ? insert : update
  end

  def self.where(params)

    result = Relation.new(self)
    result.select_options["*"] = true
    result.from_options[table_name] = true
    result.where_options.merge!(params)

    result
  end
end
