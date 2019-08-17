require "json"

SORT_EXPRESSION = /Sort these (?<type>\w+) (?:by (?:the )?(?<field>.+), )?(?:(?:from|in) (?<from>\w+)) (?:(?:\w+ )?to (?<to>\w+))?/
VOWELS = ['a', 'e', 'i', 'o', 'u']

module Sortbot
  module Exam
    class ExampleSolution #(T)
      JSON.mapping(
        solution: Array(JSON::Any) # T)
      )

      def sort_direction() #forall T
        (@solution[0] <=> @solution[-1]).as(Int32)
      end
    end

    class Response
      JSON.mapping(
        message: String,
        nextSet: String?,
      )
    end

    class Question < Response
      JSON.mapping(
        exampleSolution: ExampleSolution, #(Int32) | ExampleSolution(Int64) | ExampleSolution(String),
        message: String,
        name: String,
        question: Array(JSON::Any), #Array(Int32) | Array(Int64) | Array(String),
        setPath: String,
      )

      def intention() : SortIntention
        # Regex:
        # Sort these (\w+) (?:by (\w+), )?(?:(?:from|in) (\w+)) (?:to (\w+))?
        # /a(?<grp>sd)f/.match("_asdf_").try &.["grp"] # => "sd"
        result = SortIntention.new

        if match = SORT_EXPRESSION.match(@message)
          unless match["type"]?.nil?
            result.type = match["type"]
          end

          unless match["field"]?.nil?
            result.field = match["field"]
          end

          unless match["from"]?.nil?
            result.from = match["from"]
          end

          unless match["to"]?.nil?
            result.to = match["to"]
          end
        end

        result
      end

      def sort()
        intention = self.intention

        if intention.type === "numbers"
          if @question[0].as_i?
            @question.map {|i| i.as_i }.sort
          else @question[0].as_f?
            @question.map {|f| f.as_f }.sort
          end
        else
          if intention.field === "length"
            direction = 1
            if intention.from === "longest"
              direction = -1
            end
            @question.map {|s| s.as_s }.sort_by {|word| word.size * direction}
          elsif intention.field === "number of vowels"
            direction = 1
            if intention.from === "most"
              direction = -1
            end
            @question.map {|s| s.as_s }.sort_by {|word| word.count {|c| VOWELS.includes?(c) } * direction }
          elsif intention.field === "number of consonants"
            direction = 1
            if intention.from === "most"
              direction = -1
            end
            @question.map {|s| s.as_s }.sort_by {|word| word.count {|c| !VOWELS.includes?(c) } * direction }
          elsif intention.field === "number of words"
            direction = 1
            if intention.from === "most"
              direction = -1
            end
            @question.map {|s| s.as_s }.sort_by {|sentence| sentence.split(' ', remove_empty: true).size * direction }
          else
            @question.map {|s| s.as_s }.sort
          end
        end
      end
    end

    enum SortDirection
      Ascending = -1
      Descending = 1
      Any = 0
    end

    struct SortIntention
      property type : String?
      property field : String?
      property from : String?
      property to : String?
    end

    class SolutionResponse < Response
      JSON.mapping(
        elapsed: Int32?,
        message: String,
        nextSet: String?,
        result: String,
      )
    end
  end
end
