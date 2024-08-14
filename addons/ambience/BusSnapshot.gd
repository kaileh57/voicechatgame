extends Resource
class_name BusSnapshot

## The target bus to affect
@export
var Name : StringName

## The Volume in DB to fade towards.
@export
var Volume : float

## The Effects to be faded towards.
## Effects that arent on the bus will be added,
## Effects on the bus that arent here will be removed.
@export
var Effects : Array[AudioEffect]

## The Effect States to be applied.
## No transitioning, as bools can't be interpolated.
@export
var States : Array[bool]
