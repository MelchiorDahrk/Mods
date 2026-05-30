# Iterable Types

# Iterable types

API v129

## List Iterable

An iterable with defined size and order.

` -- can iterate over the list with pairs
for i , v in pairs ( list ) do
-- ...
end
`

` -- can iterate over the list with ipairs
for i , v in ipairs ( list ) do
-- ...
end
`

` -- can get total size with the size # operator
local length = # list
`

` -- can index the list with numbers
for i = 1 , length do
list [ i ]
end
`

## Map Iterable

An iterable with undefined order.

` -- can iterate over the map with pairs
for k , v in pairs ( map ) do
-- ...
end
`

` -- can index the map by key
map [ key ]
`

Events

Teal

On this page

- List Iterable

- Map Iterable
