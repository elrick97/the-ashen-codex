class_name CipherModes
extends RefCounted
## Block cipher modes over BlockCipher (2-byte blocks) for Act II: PKCS#7, ECB, CBC.
## ECB leaks repeats (identical blocks -> identical ciphertext); CBC chains blocks.


static func pkcs7_pad(data: PackedByteArray, block: int = BlockCipher.BLOCK_BYTES) -> PackedByteArray:
	var out: PackedByteArray = data.duplicate()
	var n: int = block - (data.size() % block)
	for _i: int in range(n):
		out.append(n)
	return out


## Returns {"ok": bool, "data": PackedByteArray}. ok is false for invalid padding
## (this yes/no answer is exactly what a padding oracle leaks).
static func pkcs7_unpad(data: PackedByteArray, block: int = BlockCipher.BLOCK_BYTES) -> Dictionary:
	if data.is_empty() or data.size() % block != 0:
		return {"ok": false, "data": PackedByteArray()}
	var n: int = data[data.size() - 1]
	if n < 1 or n > block:
		return {"ok": false, "data": PackedByteArray()}
	for i: int in range(data.size() - n, data.size()):
		if data[i] != n:
			return {"ok": false, "data": PackedByteArray()}
	return {"ok": true, "data": data.slice(0, data.size() - n)}


static func ecb_encrypt(data: PackedByteArray, key32: int) -> PackedByteArray:
	var p: PackedByteArray = pkcs7_pad(data)
	var out: PackedByteArray = PackedByteArray()
	for i: int in range(0, p.size(), 2):
		_append_block(out, BlockCipher.encrypt_block(_block_at(p, i), key32))
	return out


static func ecb_decrypt(data: PackedByteArray, key32: int) -> Dictionary:
	if data.is_empty() or data.size() % BlockCipher.BLOCK_BYTES != 0:
		return {"ok": false, "data": PackedByteArray()}
	var out: PackedByteArray = PackedByteArray()
	for i: int in range(0, data.size() - 1, 2):
		_append_block(out, BlockCipher.decrypt_block(_block_at(data, i), key32))
	return pkcs7_unpad(out)


static func cbc_encrypt(data: PackedByteArray, key32: int, iv: int) -> PackedByteArray:
	var p: PackedByteArray = pkcs7_pad(data)
	var out: PackedByteArray = PackedByteArray()
	var prev: int = iv & 0xFFFF
	for i: int in range(0, p.size(), 2):
		prev = BlockCipher.encrypt_block(_block_at(p, i) ^ prev, key32)
		_append_block(out, prev)
	return out


static func cbc_decrypt(data: PackedByteArray, key32: int, iv: int) -> Dictionary:
	if data.is_empty() or data.size() % BlockCipher.BLOCK_BYTES != 0:
		return {"ok": false, "data": PackedByteArray()}
	var out: PackedByteArray = PackedByteArray()
	var prev: int = iv & 0xFFFF
	for i: int in range(0, data.size() - 1, 2):
		var c: int = _block_at(data, i)
		_append_block(out, BlockCipher.decrypt_block(c, key32) ^ prev)
		prev = c
	return pkcs7_unpad(out)


static func _block_at(data: PackedByteArray, i: int) -> int:
	return (data[i] << 8) | data[i + 1]


static func _append_block(out: PackedByteArray, block: int) -> void:
	out.append((block >> 8) & 0xFF)
	out.append(block & 0xFF)
