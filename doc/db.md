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
- type: room | building
- colour: int (24 bit integer with 8 bit for each colour channel)
- subject: nullable string (null if type == building)
- number: nullable string (null if type == building)
- label: nullable string 

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
- latitude: decimal(8,6)
- longitude: decimal(9,6)