## Paths
- path_id: primary key
- name: nullable string
- label: nullable string

## Path Vertices
- path_vertex_id: primary key
- path_id: foreign key
- order: int (order of vertex in path)
- coordinates_id: foreign key
- floor: integer

## Rooms
- room_id: primary key
- type: room | building
- colour: int (24 bit integer with 8 bit for each colour channel)
- name: string
- label: string

## Room Vertices
- room_vertex_id: primary key
- room_id: foreign key
- order: int (order of vertex in room)
- coordinates_id: foreign key

## Room Entrances
- room_entrance_id: primary key
- name: nullable string
- label: nullable string
- room_id: foreign key
- coordinates_id: foreign key

## Coordinates
- coordinates_id: primary key
- latitude: decimal(8,6)
- longitude: decimal(9,6)