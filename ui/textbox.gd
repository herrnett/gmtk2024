extends MarginContainer

@onready var label = $MarginContainer/Label
@onready var timer = $LetterDisplayTimer
@onready var audio_player = $AudioStreamPlayer
@onready var next_indicator = $NinePatchRect/Control/NextIndicator

const MAX_WIDTH = 256 #size limit in pixel
const DISTANCE_FROM_SPEAKER = 24 #in pixel
const PITCH_VARIATION = 0.1 #+-pitch of speech-sfx
const VOWEL_VARIATION = 0.2 #pitch added to speech-sfx for vowels

var text = ""
var letter_index = 0

var letter_time = 0.03
var space_time = 0.06
var puctuation_time = 0.2

signal finished_displaying()

func _ready():
	scale = Vector2.ZERO

func display_text(text_to_display : String, speech_sfx: AudioStream):
	text = text_to_display
	label.text = text_to_display
	audio_player.stream = speech_sfx
	
	await resized
	custom_minimum_size.x = min(size.x, MAX_WIDTH)
	
	if size.x > MAX_WIDTH:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		await resized #wait for resize x
		await resized #wait for resize y
		custom_minimum_size.y = size.y
		
	global_position.x -= (size.x / 2) * scale.x
	global_position.y -= (size.y + DISTANCE_FROM_SPEAKER) * scale.y
	
	label.text = ""
	
	pivot_offset = Vector2(size.x / 2, size.y)
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2(1,1), 0.15).set_trans(Tween.TRANS_BACK)
	
	_display_letter()
	
func _display_letter():
	label.text += text[letter_index]
	
	letter_index += 1
	if letter_index >= text.length():
		finished_displaying.emit()
		next_indicator.visible = true
		return
	
	match text[letter_index]:
		"!", ".", ",", "?": 
			timer.start(puctuation_time)
		" ": 
			timer.start(space_time)
		_: 
			timer.start(letter_time)
			
			var new_audio_player = audio_player.duplicate()
			new_audio_player.pitch_scale += randf_range(-PITCH_VARIATION, PITCH_VARIATION)
			if text[letter_index] in ["a", "e", "i", "o", "u"]:
				new_audio_player.pitch_scale += VOWEL_VARIATION
			get_tree().root.add_child(new_audio_player)
			new_audio_player.play()
			await new_audio_player.finished
			new_audio_player.queue_free()

func _on_letter_display_timer_timeout():
	_display_letter()
