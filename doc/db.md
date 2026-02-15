## Paths
- path_id: primary key
- label: nullable string

## Path Vertices
- path_vertex_id: primary key
- path: foreign key
- sequence: int (order of vertex in path)
- coordinates: foreign key

## Rooms
- room_id: primary key
- floor: int
- type: room | toilet | area | building | inaccessible
- toilet_type: toilet type enum
- colour: int (24 bit integer with 8 bit for each colour channel)
- subject: nullable string (null if type != classroom)
- number: nullable string (null if type != classroom)
- label: nullable string 

### Toilet type
- -1 - non-toilet structures
- 0 - male
- 1 - female
- 2 - gender_neutral
- 3 - accessible
- 4 - staff

## Room Vertices
- room_vertex_id: primary key
- room: foreign key
- sequence: int (order of vertex in room)
- coordinates: foreign key

## Room Entrances
- room_entrance_id: primary key
- label: nullable string
- room: foreign key
- coordinates: foreign key

## Coordinates
- coordinates_id: primary key
- floor: int
- latitude: decimal(8,6)
- longitude: decimal(9,6)

## Staircase
- staircase_id: primary key
- label: nullable string
- landing1: coordinates
- landing2: coordinates