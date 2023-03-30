module SlnProject
  class Assignment
    attr_accessor :key, :value

    def initialize(line)
      parts = line.split("=")

      if parts.empty?
        self.key = ""
        self.value = ""
        return
      end

      self.key = parts[0].strip
      self.value = parts[1].strip
    end
  end

  class InnerBlockResult
    attr_accessor :block, :is_end
  end

  class BaseBlock
    def parse(block_str)
      nil
    end

    protected(:parse)
  end
end
