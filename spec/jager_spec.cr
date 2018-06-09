require "./spec_helper"

describe Jager do
  describe "#generate" do
    # Make sure engine generates matching string
    it "generates US Phone" do
      regex = /\d{3}-\d{3}-\d{4}/
      engine = Jager::Engine.new

      input = engine.generate(regex)

      if md = input.match(regex)
        match = md[0]
      end

      match.should eq input
    end

    it "generates UUID" do
      regex = /[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/
      engine = Jager::Engine.new

      input = engine.generate(regex)

      if md = input.match(regex)
        match = md[0]
      end

      match.should eq input
    end

    it "generates JSON Number" do
      regex = /-?[1-9]\d+(.\d+)?([eE][+-]?\d+)?/
      engine = Jager::Engine.new

      input = engine.generate(regex)

      if md = input.match(regex)
        match = md[0]
      end

      match.should eq input
    end

    it "generates US Dollar amount" do
      regex = /\$([1-9]{1}[0-9]{0,2})(,\d{3}){0,4}(.\d{2})?/
      engine = Jager::Engine.new

      input = engine.generate(regex)

      if md = input.match(regex)
        match = md[0]
      end

      match.should eq input
    end
  end
end
