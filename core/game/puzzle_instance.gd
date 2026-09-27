class_name PuzzleInstance
extends RefCounted
## One generated puzzle: a PuzzleDef + variant turned into real plaintext, key and
## ciphertext by PuzzleFactory. Nothing here is hard-coded ciphertext.

var def: PuzzleDef = null
var variant: int = 0
var seed_value: int = 0
var frenzied: bool = false
## def.params merged with def.frenzy_overrides when frenzied.
var params: Dictionary = {}
var trial_cost: int = 1
## Normalized plaintexts (one per letter).
var plaintexts: PackedStringArray = PackedStringArray()
## Letter-cipher ciphertexts (same normalization as plaintexts).
var ciphertexts: PackedStringArray = PackedStringArray()
## Byte modes: plaintext and ciphertext bytes per letter.
var plain_bytes: Array[PackedByteArray] = []
var cipher_bytes: Array[PackedByteArray] = []
## caesar: int shift; keyless: Array of "rot13"/"atbash"; substitution: 26-letter String;
## vigenere: String; xor_rosary: int; xor_repeating: PackedByteArray; two_time_pad: PackedByteArray pad.
var key: Variant = null
## Mode-specific extras (xor_rosary stage bytes, two-time-pad targets, cribs...).
var extras: Dictionary = {}


func param(name: String, default_value: Variant = null) -> Variant:
	return params.get(name, default_value)
