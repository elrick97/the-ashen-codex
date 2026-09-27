#!/usr/bin/env python3
"""Independent Python reference for vectors used in tests/unit (run: python3 tests/reference/crypto_ref.py).

Written separately from the GDScript core so the unit tests compare two implementations.
"""

M64 = (1 << 64) - 1


class Pcg32:
    def __init__(self, seed, seq):
        self.state = 0
        self.inc = ((seq << 1) | 1) & M64
        self.next()
        self.state = (self.state + seed) & M64
        self.next()

    def next(self):
        old = self.state
        self.state = (old * 6364136223846793005 + self.inc) & M64
        xs = (((old >> 18) ^ old) >> 27) & 0xFFFFFFFF
        rot = old >> 59
        return ((xs >> rot) | (xs << ((-rot) & 31))) & 0xFFFFFFFF


SBOX = [0xE, 0x4, 0xD, 0x1, 0x2, 0xF, 0xB, 0x8, 0x3, 0xA, 0x6, 0xC, 0x5, 0x9, 0x0, 0x7]


def round_keys(k):
    out = []
    for r in range(5):
        rot = ((k << (4 * r)) | (k >> (32 - 4 * r))) & 0xFFFFFFFF if r else k
        out.append((rot >> 16) & 0xFFFF)
    return out


def sub(x):
    return sum(SBOX[(x >> (4 * n)) & 0xF] << (4 * n) for n in range(4))


def perm(x):
    out = 0
    for i in range(4):
        for j in range(4):
            if (x >> (4 * i + j)) & 1:
                out |= 1 << (4 * j + i)
    return out


def spn_encrypt(block, key):
    ks = round_keys(key)
    x = block
    for r in range(3):
        x = perm(sub(x ^ ks[r]))
    x = sub(x ^ ks[3])
    return x ^ ks[4]


def toy_hash(data):
    p = bytearray(data) + b"\x80"
    while (len(p) + 2) % 2:
        p.append(0)
    bits = (len(data) * 8) & 0xFFFF
    p += bytes([bits >> 8, bits & 0xFF])
    h = 0x3A5C
    for i in range(0, len(p), 2):
        m = (p[i] << 8) | p[i + 1]
        h = spn_encrypt(h, (m << 16) | m) ^ h
    return h


def repeating_xor(data, key):
    return bytes(b ^ key[i % len(key)] for i, b in enumerate(data))


def vigenere(text, key):
    out, k = [], 0
    for ch in text:
        if ch.isalpha():
            base = 65 if ch.isupper() else 97
            out.append(chr(base + (ord(ch) - base + ord(key[k % len(key)].upper()) - 65) % 26))
            k += 1
        else:
            out.append(ch)
    return "".join(out)


if __name__ == "__main__":
    r = Pcg32(42, 54)
    print("pcg32(42,54):", [hex(r.next()) for _ in range(6)])
    r = Pcg32(20260927, 7)
    print("pcg32(20260927,7):", [r.next() for _ in range(4)])
    print("spn(0x1234, 0xDEADBEEF):", hex(spn_encrypt(0x1234, 0xDEADBEEF)))
    print("spn(0x0000, 0x00000000):", hex(spn_encrypt(0x0000, 0)))
    print("hash(b''):", hex(toy_hash(b"")))
    print("hash(b'TITHE'):", hex(toy_hash(b"TITHE")))
    cp5 = b"Burning 'em, if you ain't quick and nimble\nI go crazy when I hear a cymbal"
    print("cryptopals s1c5:", repeating_xor(cp5, b"ICE").hex())
    print("vigenere ATTACKATDAWN/LEMON:", vigenere("ATTACKATDAWN", "LEMON"))
