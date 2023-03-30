require_relative "block"

module SlnProject
  class GlobalBlock < BaseBlock
    START_TOKENS = {
      GlobalSectionToken: "GlobalSection"
    }.freeze

    END_TOKENS = {
      GlobalSectionToken: "EndGlobalSection"
    }.freeze

    attr_accessor :solution_configuration_platforms, :solution_properties

    def parse(block_str)
      inner_block = nil
      inner_block_str = ""
      content_reader = StringIO.new(block_str)

      content_reader.each_line do |line|
        trim_line = line.strip
        inner_block = check_start_token(trim_line, inner_block)
        inner_block = check_end_token(trim_line, inner_block, inner_block_str)

        inner_block_str += "#{trim_line}\n" unless inner_block.nil?
        inner_block_str = "" if inner_block.nil?
      end
    end

    def check_start_token(line, inner_block)
      inner_block = GlobalSectionFactory.create(line) if line.start_with?("#{START_TOKENS[:GlobalSectionToken]}(")
      inner_block
    end

    def check_end_token(line, inner_block, inner_block_str)
      return inner_block unless END_TOKENS.any? { |_, v| line == v }

      inner_block.parse(inner_block_str)

      case inner_block.type
      when GlobalSectionBlock::TYPES[:SolutionConfigurationPlatforms]
        self.solution_configuration_platforms = inner_block
      when GlobalSectionBlock::TYPES[:SolutionProperties]
        self.solution_properties = inner_block
      end

      nil
    end

    public(:parse)
    private(:check_start_token)
    private(:check_end_token)
    private(:solution_configuration_platforms=)
    private(:solution_properties=)
  end

  class GlobalSectionFactory
    def self.create(line)
      type = parse_header(line)

      case type
      when GlobalSectionBlock::TYPES[:SolutionConfigurationPlatforms]
        SolutionConfigurationPlatformsBlock.new(type)
      when GlobalSectionBlock::TYPES[:SolutionProperties]
        SolutionPropertiesBlock.new(type)
      else
        GlobalSectionBlock.new(GlobalSectionBlock::TYPES[:Unknown])
      end
    end

    def self.parse_header(line)
      key = Assignment.new(line).key
      pattern = /\((.*?)\)/
      key.match(pattern)[1]
    end

    private_class_method(:parse_header, :new)
    public_class_method(:create)
  end

  class GlobalSectionBlock < BaseBlock
    TYPES = {
      SolutionConfigurationPlatforms: "SolutionConfigurationPlatforms",
      SolutionProperties: "SolutionProperties",
      Unknown: "Unknown" # must be always the last
    }.freeze

    attr_accessor :type

    def initialize(type)
      self.type = type
    end

    private(:type=)
  end

  class SolutionConfigurationPlatformsBlock < GlobalSectionBlock
    attr_accessor :platforms

    def parse(block_str)
      is_header = false
      content_reader = StringIO.new(block_str)
      self.platforms = {}

      content_reader.each_line do |line|
        unless is_header
          is_header = true
          next
        end

        assignment = Assignment.new(line).key
        assignment_parts = assignment.split("|")
        configuration = assignment_parts[0]
        platform = assignment_parts[1]

        self.platforms[configuration] = [] unless self.platforms[configuration].is_a?(Array) && !self.platforms[configuration].empty?
        self.platforms[configuration].append(platform)
      end
    end

    public(:parse)
    private(:platforms=)
  end

  class SolutionPropertiesBlock < GlobalSectionBlock
    attr_accessor :entries

    def parse(block_str)
      is_header = false
      content_reader = StringIO.new(block_str)
      self.entries = {}

      content_reader.each_line do |line|
        unless is_header
          is_header = true
          next
        end

        assignment = Assignment.new(line)
        self.entries[assignment.key] = assignment.value
      end
    end

    public(:parse)
    private(:entries=)
  end
end
