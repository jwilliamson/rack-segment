module RackSegment
  class Bucket
    attr_reader :name

    def initialize(name, str_block)
      @name = name
      @str_block = str_block
    end

    def value
      return nil if @str_block.nil?
      @str_block.try(:call) || @str_block
    end
  end
end
