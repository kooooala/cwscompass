```mermaid
classDiagram
    %% Abstract Base Class
    class SQLRow {
        <<abstract>>
        +get_sql_query()* str
    }

    %% Generic Table Class
    class Table~T SQLRow~ {
        +dict~int, T~ table
        +__init__()
        +append(item: T)
        +exists(item: T) bool
        +commit(cursor: sqlite3.Cursor)
    }

    %% Enums
    class StructureType {
        <<enumeration>>
        room
        building
        inaccessible
        toilet
    }

    class ToiletType {
        <<enumeration>>
        non_toilet
        male
        female
        gender_neutral
        accessible
        staff
    }

    %% Concrete Dataclasses inheriting from SQLRow
    class Path {
        +str fid
        +int floor
        +str name
        +get_sql_query() str
        +__hash__() int
    }

    class Coordinates {
        +int floor
        +float latitude
        +float longitude
        +get_sql_query() str
        +__str__() str
        +__eq__(other) bool
        +__hash__() int
    }

    class PathVertex {
        +int path
        +int coordinates
        +int sequence
        +get_sql_query() str
        +__lt__(other) bool
        +__gt__(other) bool
        +__hash__() int
    }

    class Structure {
        +str fid
        +int floor
        +StructureType type
        +ToiletType toilet_type
        +int colour
        +str subject
        +str number
        +str name
        +get_sql_query() str
        +__hash__() int
    }

    class StructureVertex {
        +int room
        +int coordinates
        +int sequence
        +get_sql_query() str
        +__hash__() int
    }

    class Entrance {
        +int structure
        +int coordinates
        +str name
        +get_sql_query() str
        +__hash__() int
    }

    class Staircase {
        +str label
        +list~int~ landings
        +__init__(label: str)
        +get_sql_query() str
        +__hash__() int
    }

    %% Inheritance Relationships
    SQLRow <|-- Path
    SQLRow <|-- Coordinates
    SQLRow <|-- PathVertex
    SQLRow <|-- Structure
    SQLRow <|-- StructureVertex
    SQLRow <|-- Entrance
    SQLRow <|-- Staircase

    %% Dependency/Generic Relationship
    Table ..> SQLRow : manages T bound to

    %% Composition Relationships (Enums)
    Structure *-- StructureType
    Structure *-- ToiletType

    %% Logical Associations (Foreign Key References via Hash IDs)
    PathVertex --> Path : references (path hash)
    PathVertex --> Coordinates : references (coordinates hash)

    StructureVertex --> Structure : references (room hash)
    StructureVertex --> Coordinates : references (coordinates hash)

    Entrance --> Structure : references (structure hash)
    Entrance --> Coordinates : references (coordinates hash)

    Staircase --> Coordinates : references (landings hash)
    
