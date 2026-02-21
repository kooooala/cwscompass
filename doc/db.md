## Paths
- path_id: primary key
- label: nullable string

## Path Vertices
- path_vertex_id: primary key
- path: foreign key
- sequence: int (order of vertex in path)
- coordinates: foreign key

## Structures
- structure_id: primary key
- floor: int
- type: room | toilet | building | inaccessible
- toilet_type: toilet type 
- colour: int (24 bit integer with 8 bit for each colour channel)
- subject: nullable string (null if type != classroom)
- number: nullable string (null if type != classroom)
- label: nullable string 

### Structure type 
- room
- toilet
- building
- inaccessible

### Toilet type
- non_toilet structures
- male
- female
- gender_neutral
- accessible
- staff

## Structure Vertices
- structure_vertex_id: primary key
- structure: foreign key
- sequence: int (order of vertex in structure)
- coordinates: foreign key

## Entrances
- entrance_id: primary key
- label: nullable string
- structure: foreign key
- coordinates: foreign key

## Coordinates
- coordinates_id: primary key
- floor: int
- latitude: real
- longitude: real

## Staircase
- staircase_id: primary key
- label: nullable string
- landing1: coordinates
- landing2: coordinates