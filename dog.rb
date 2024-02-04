# A class that defines a dog
class Dog
    attr_reader :message

    def initialize name: "Firulais"
      @name = name
    end

    def bark
      puts "Woof!"
    end

  end
