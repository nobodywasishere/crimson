module Crimson::Commands
  class List < Base
    private class Result
      getter version : String
      property alias : String?
      property path : String?

      def initialize(@version)
      end
    end

    def setup : Nil
      @name = "list"
      @summary = "list installed Crystal versions"

      add_usage "list [-a|--alias] [-p|--path]"

      add_option 'a', "alias", description: "include the version alias"
      add_option 'p', "path", description: "include the compiler path"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      installed = ENV.get_installed_versions.sort.reverse!
      return if installed.empty?

      unless options.has?("alias") || options.has?("path")
        installed.each { |version| stdout << version << '\n' }
        return
      end

      config = Config.load
      _alias = options.has? "alias"
      path = options.has? "path"
      results = installed.map { |version| Result.new version }

      if _alias && !config.aliases.empty?
        results.each do |result|
          if value = config.aliases[result.version]?
            result.alias = value
          end
        end
      end

      if path
        results.each do |result|
          result.path = (ENV::CRYSTAL_PATH / result.version).to_s
        end
      end

      results.each do |result|
        stdout << result.version << "  "
        stdout << result.alias if _alias
        stdout << result.path if path
        stdout << '\n'
      end
    rescue File::NotFoundError
      error "Crimson config not found"
      error "Run '#{"crimson setup".colorize.bold}' to create"
    rescue INI::ParseException
      error "Cannot parse Crimson config"
      error "Run '#{"crimson setup".colorize.bold}' to restore"
      system_exit
    end
  end
end
