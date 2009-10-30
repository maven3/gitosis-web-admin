class GitosisConfig

  attr_accessor :config_file, :structure

  def initialize
    config_file_path = File.join(configatron.gitosis_admin_root, configatron.gitosis_config)
    if !File.readable?(config_file_path)
      raise Errno::EACCES, "#{config_file_path} is not readable"
    else
      @config_file_path = config_file_path
      @locked = false
      self.parse
    end
  end

  def parse
    section = nil
    @structure = {}

    File.open(@config_file_path).each do |line|
      line.chomp
      unless (/^\#/.match(line))
        if line =~ /\s*\[(.*)\]\s*/
          section = $1
          @structure[section] = {}
        end
        if(/\s*=\s*/.match(line))
          param, value = line.split(/\s*=\s*/, 2)
          var_name = "#{param}".chomp.strip
          value = value.chomp.strip.gsub(/^['"](.*)['"]$/, '\1')

          if section.nil?
            @structure[var_name] = value
          else
            @structure[section][var_name] = value
          end
        end
      end
    end
  end

  def add_section(section)
    @structure[section] = {}
  end

  def remove_section(section)
    @structure.delete(section)
  end

  def add_param_to_section(section, param, value)
    @structure[section][param] = value
  end

  def output
    out = []
    @structure.each do |key, value|
      if value.is_a?(Hash)
        # is a section
        out << "\n[#{key}]\n"
        value.each do |k, v|
          # param in section
          out << "#{k} = #{v}\n"
        end
      else
        # is a param
        out << "#{key} = #{value}\n"
      end
    end
    out.join()
  end

  def save
    raise "When saving changes, the file should be locked while parsing, modifying and saving. Use the lock method of this class." unless @locked
    @config_file.truncate(0)
    @config_file.puts(self.output)
  end

  def lock
    @config_file = File.new(@config_file_path, 'r+')
    @config_file.flock(File::LOCK_EX)
    @locked = true
    begin
      yield
    ensure
      @config_file.flock(File::LOCK_UN)
      @config_file.close
      @locked = false
    end
  end

end