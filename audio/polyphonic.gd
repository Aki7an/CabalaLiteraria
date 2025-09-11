# res://singletons/SfxPlayerConfig.gd
extends AudioStreamPlayer2D

@export var sound_name: String = ""   # si está vacío, usará el nombre del nodo
@export var polyphonic: bool = true   # true = puede solaparse (duplica el nodo)
