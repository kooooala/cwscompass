# QGIS Entity Attributes

## Room
### At least one of the following: 
- number
- name

## Toilet
### Required: 
- type 
### Toilet type
- 0 - male
- 1 - female
- 2 - gender_neutral
- 3 - accessible
- 4 - staff

## Room entrance
### Required:
- room (corresponds to either the room number or name - has to be exact)
### Optional: 
- name

## Building
### Required: 
- name 

## Path
### Optional:
- name

## Landing
### Required: 
- staircase (index in the list of staircases)