require_relative "root_block"

module SlnProject
  def self.open(path)
    path = path.to_s
    raise "Path to SLN-file can't be empty or null" unless path && !path.empty?
    raise "The SLN-file at path #{path} doesn't exist" unless File.exist?(path)

    content = File.read(path)
    root_block = RootBlock.new
    root_block.parse(content)
    root_block
  end
end
