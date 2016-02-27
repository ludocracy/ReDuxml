require_relative 'component/component'

module DocObjects
  class DocObject < Component
    def initialize

    end

    def to_dita
      # do nothing
    end
  end

  # pull this out as an extension of Patterns for CRR
  class RegFigure < DocObject

  end

  class Table < DocObject
    def initialize

    end

    def merge

    end

    def split

    end

    def to_dita

    end
  end

  class Description < DocObject

  end

  class Map < DocObject

  end
end