module RackSegment
  class Bucket
    attr_reader :name

    def initialize(name, str_block)
      @name = name
      @str_block = str_block
    end

    def value
      @str_block.try(:call) || @str_block.to_s
    end
  end
end