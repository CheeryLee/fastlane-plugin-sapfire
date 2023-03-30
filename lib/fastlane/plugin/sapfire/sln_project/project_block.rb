require_relative "block"

module SlnProject
  class ProjectBlock < BaseBlock
    START_TOKENS = {
      ProjectSectionToken: "ProjectSection"
    }.freeze

    END_TOKENS = {
      ProjectSectionToken: "EndProjectSection"
    }.freeze

    attr_accessor :guid, :name, :path

    def parse(block_str)
      is_header_passed = false
      inner_block = nil
      inner_block_str = ""
      content_reader = StringIO.new(block_str)

      content_reader.each_line do |line|
        trim_line = line.strip

        unless is_header_passed
          is_header_passed = true if parse_header(trim_line)
        end

        inner_block = check_start_token(trim_line, inner_block)
        inner_block = check_end_token(trim_line, inner_block, inner_block_str)

        inner_block_str += "#{trim_line}\n" unless inner_block.nil?
        inner_block_str = "" if inner_block.nil?
      end
    end

    def to_s
      name
    end

    def check_start_token(line, inner_block)
      inner_block = ProjectSectionBlock.new if line.start_with?("#{START_TOKENS[:ProjectSectionToken]}(")
      inner_block
    end

    def check_end_token(line, inner_block, inner_block_str)
      return inner_block unless END_TOKENS.any? { |_, v| line == v }

      inner_block.parse(inner_block_str)
      nil
    end

    def parse_header(line)
      assignment = Assignment.new(line)
      parts = assignment.value.split(",")
      return false if parts.empty?

      self.name = parts[0].strip.delete("\"")
      self.path = parts[1].strip.delete("\"")
      self.guid = parts[2].strip
                          .delete("\"")
                          .delete("{")
                          .delete("}")

      true
    end

    public(:parse)
    public(:to_s)
    private(:check_start_token)
    private(:check_end_token)
    private(:parse_header)
    private(:guid=)
    private(:name=)
    private(:path=)
  end

  class ProjectSectionBlock < BaseBlock
    def parse(block_str)
      nil
    end
  end
end
