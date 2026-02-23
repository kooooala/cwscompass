```mermaid
classDiagram 
    class BoundingBox {
        Point topLeft
        Point bottomRight

        contains(Point piont) bool
    }

    class Coordinates {
        int floor 
        double latitude
        double longitude
        Point point

        toString()
    }

    class Polygon {
        List~Coordinates~ coordinates
        BoundingBox BoundingBox

        intersects(Point point) bool
    }

    Polygon *-- Coordinates
    Polygon *-- BoundingBox

    class Structure {
        int floor
        Colour colour
        Point centroid 

        distanceFrom(Coordinates coordinates, bool precise) double
    }

    Structure --|> Polygon

    class Entrance {
        String label
    }

    class BuildingEntrance {
        Building building
    }

    BuildingEntrance --|> Entrance

    class Interactable~T~ {
        <<Abstract>>
        String name
        String description
        String shortDescription
        List~Entrance~ entrances
        MapEntry~String, T~ searchEntry
    }

    Interactable *-- Entrance
    Interactable --|> Structure

    class Room {
        String subject
        String number
        String label
    }

    Room --|> Interactable

    class ToiletType{
        <<Enumeration>>
        gents
        ladies
        genderNeutral
        accessible
        staff
    }

    class Toilet {
        ToiletType type

        toiletName(ToiletType type) String$
        toiletTypeIcon(ToiletType type) IconData$
        toiletTypeColour(ToiletType type) Colour$
        toiletTypeString(ToiletType type) String$
    }

    Toilet *-- ToiletType
    Toilet --|> Interactable

    class Inaccessible {}

    Inaccessible --|> Structure

    class Building {
        List~BuildingEntrance~ entrances
        String name
    }

    Building *-- BuildingEntrance
    Building --|> Structure

    class Edge {
        List~Coordinates~ coordinaets
        double distance

        calculateDistance() double$
    }

    class EdgeWithLabel {
        String label
    }

    EdgeWithLabel --|> Edge

    class Graph {
        Map~Coordinates_List~EdgeWithLabel~~ simplified
        Map~Coordinates, Edge~ intermediateNodeEdge
    }

    Graph --> Edge
    Graph --> EdgeWithlabel
    Graph --> Coordinates

    class Floor {
        List~Structure~ structures
        Graph graph

        floorChar(int floor) String$
        floorString(int floor) String$
    }

    Floor *-- Structure
    Floor *-- Graph

    class Path {
        String label
        int floor
        List~Coordinates~ vertices
    }

    Path *-- Coordinates

    class School {
        Graph graph
        List~Floor~ floors
        List~Staircase~ staircases

        -simplifyGraph(AdjacencyList fullGraph) Graph$
        -floorGraph(List~Structure~ structures, List~Path~ paths) Graph$
        -getDirectionSameFloor(Coordinates previous, Coordinates current, Coordinates next) Direction 
        -getdirectionElevation(Coordinates current, Coordinates next) Direction
        -getDirection(coordinates previous, Coordinates current, Coordinates next) Direction
        -heuristic(Coordinates c1, Coordinates c2) double
        -reconstruct(Map<Coordinates, Coordinates> cameFrom, Coordinates start, Coordinates end) Route
        shortestRoute(Coordinates start, Coordinates end) Route
        closestNode(Coordinatnes point) Coordinates
        closestIntermediateNode(Coordinates point) Coordinates
        shortestRoutePairing(List~Coordinates~ startNodes, List~Coordinates~ endNodes) Route
        -intermediateToregular(Coordinates intermediate, Coordinates regular) List~Coordinates~
        -shortestRouteFromIntermediateNode(Coordinates start, List~Coordinates~ endNodes) Route
        adjustRouteDisplay(Coordinates location, Route route) Route
        locationToInteractable(Coordinates location, Interactable interactable) Route
    }

    School *-- Floor
    School *-- Staircase
    School *-- Graph

    class Landing {
        String label
    }

    Landing --|> Coordinates

    class Staircase {
        double cost$
    }

    Staircase --|> EdgeWithLabel
    Staircase *-- Landing

    class MapData {
        String dbName
        School school

        -Database database
        -List~Coordinates~ coordinates
        
        -parseCoordinates()
        -parseStructure(Map~String, Object~ structureData) Structure
        -parseEntrances(int structureId, String structureLabel) List~Entrance~
        -parseRoom(Map~String, Object~ roomData) Room
        -parseToilet(Map~String, Object~ toiletData) Toilet
        -parseBuilding(Map~String, Object~ buildingData) Building
        -parseStructures() List~Structure~
        load()
    }

    MapData *-- School 
    MapData *-- Coordinates