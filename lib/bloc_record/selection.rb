require 'sqlite3'

module Selection
  def all
    sql = <<-SQL
      SELECT #{columns.join ","} FROM #{table};
      SQL
      puts sql
      rows = connection.execute sql
      rows_to_array(rows)
    end

  def find(*ids)
    unless ids.is_a?(Integer) || ids.is_a?(Array)
      newError
    end

    if ids.length == 1
      find_one(ids.first)
    else
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE id IN (#{ids.join(",")});
      SQL

    rows_to_array(rows)
  end
end

  def find_one(id)
    unless id.is_a?(Integer) || id < 0
      newError
    end

    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE id = #{id};
    SQL

    init_object_from_row(row)
  end

  def find_by(attribute, value)
    sql = <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
    SQL
    puts sql
    row = connection.get_first_row sql

    #unless attribute.is_a? String
    #  newError
    #end

    init_object_from_row(row)
  end

  def self.method_missing(method_sym)
    if method_sym.to_s =~ /^find_by(.*)$/
      find_by($1.to_sym, arguments.first)
    else
      super
    end
  end

  def self.respond_to?(method_sym, include_private = false)
    if method_sym.to_s =~ /^find_by(.*)$/
      true
    else
      super
    end
  end

  def find_each(options = {}, &block)
    batch_size = options.delete(:batch_size) || 2000

    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      LIMIT #{batch_size}
    SQL

    rows_to_array(rows).each { |row| yeild(row) }
  end

  def find_in_batches(options = {}, &block)
    batch_size = options.delete(:batch_size) || 4000

    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      LIMIT #{batch_size}
    SQL

    yield(rows_to_array(rows), :batch_size)
  end

  def take(num=1)
    unless num > 0
    newError
  end

    if num > 1
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        ORDER BY random()
        LIMIT #{num};
      SQL

      rows_to_array(rows)
    else
      take_one
    end
  end

  def take_one
    sql = <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY random()
      LIMIT 1;
    SQL
    row = connection.get_first_row sql
    init_object_from_row(row)
  end

  def first

    sql = <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id ASC
      LIMIT 1;
    SQL
    puts sql
    row = connection.get_first_row
    init_object_from_row(row)
  end

  def last
    sql = <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id DESC
      LIMIT 1;
    SQL
    puts sql
    row = connection.get_first_row sql
    init_object_from_row(row)
  end

  def all
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table};
    SQL

    rows_to_array(rows)
  end

  def where(*args)
    if args.count > 1
      expression = args.shift
      params = args
    else
      case args.first
      when String
        expression = args.first
      when Hash
        expression_hash = BlocRecord::Utility.convert_keys(args.first)
        expression = expression_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
      end
    end

    sql = <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{expression};
    SQL

    rows = connection.execute(sql, params)
    rows_to_array(rows)
  end

  def order(*args)
    if args.count > 1
      order = args.join(",")
    else
      order = args.first.to_s
    end

    sql = <<-SQL
      SELECT * FROM #{table}
      ORDER BY #{order};
    SQL
    row = connection.get_first_row(sql)
    rows_to_array(rows)
  end

  def join(*args)
    if arg.count > 1
      joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
      sql = <<-SQL
        SELECT * FROM #{table} #{joins}
      SQL
    else
      case arg.first
      when String
        sql = <<-SQL
          SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(args.first)};
        SQL
      when Symbol
        sql = <<-SQL
          SELECT * FROM #{table}
          INNER JOIN INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id
        SQL
      end
    end
    rows = connection.execute sql
    rows_to_array(rows)
  end

  private
  def init_object_from_row(row)
      new(Hash[columns.zip(row)]) if row
  end

  def rows_to_array(rows)
    collection = BlocRecord::Collection.new
    rows.each { |row| collection << new(Hash[columns.zip(row)]) }
    collection
    end

  def newError
    puts "Error: Incorrect Input"
    return false
  end

end
