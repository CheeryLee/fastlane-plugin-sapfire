require_relative "project_block"
require_relative "global_block"
require_relative "block"

module SlnProject
  class RootBlock < BaseBlock
    TOKENS = {
      VisualStudioVersionToken: "VisualStudioVersion",
      MinimumVisualStudioVersionToken: "MinimumVisualStudioVersion"
    }.freeze

    START_TOKENS = {
      ProjectToken: "Project",
      GlobalToken: "Global"
    }.freeze

    END_TOKENS = {
      ProjectToken: "EndProject",
      GlobalToken: "EndGlobal"
    }.freeze

    attr_accessor :visual_studio_version, :min_visual_studio_version, :projects, :global

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
      self.visual_studio_version = Assignment.new(line).value if line.start_with?(TOKENS[:VisualStudioVersionToken])
      self.min_visual_studio_version = Assignment.new(line).value if line.start_with?(TOKENS[:MinimumVisualStudioVersionToken])

      inner_block = ProjectBlock.new if line.start_with?("#{START_TOKENS[:ProjectToken]}(")
      inner_block = GlobalBlock.new if line.start_with?(START_TOKENS[:GlobalToken])

      inner_block
    end

    def check_end_token(line, inner_block, inner_block_str)
      return inner_block unless END_TOKENS.any? { |_, v| line == v }

      inner_block.parse(inner_block_str)

      if line.start_with?(END_TOKENS[:ProjectToken])
        self.projects = [] if self.projects.nil?
        self.projects.append(inner_block)
      elsif line.start_with?(END_TOKENS[:GlobalToken])
        self.global = inner_block
      end

      nil
    end

    public(:parse)
    private(:check_start_token)
    private(:check_end_token)
    private(:visual_studio_version=)
    private(:min_visual_studio_version=)
    private(:projects=)
    private(:global=)
  end
end
