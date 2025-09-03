## Paths
- path_id: primary key
- name: nullable string
- label: nullable string

## Vertices
- vertex_id: primary key
- name: nullable string
- label: nullable string
- floor: integer
- latitude: decimal(8,6)
- longitude: decimal(9,6)

## Path Vertices
- path_vertex_id: primary key
- path_id: foreign key
- vertex_id: foreign key
- order: int (order of vertex in path)

## Rooms
- room_id: primary key
- name: string
- label: string

## Room Entrances
- room_entrance_id: primary key
- name: nullable string
- label: nullable string
- room_id: foreign key
- vertex_id: foreign key