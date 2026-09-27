# Curriculum Map

Every attack in the game exploits something that repeats. Prerequisites name the concepts that must already be taught.

## Act I: The Tithe Letters (built)
| Puzzle | Objective (player can...) | Prerequisites | Codex entry |
|---|---|---|---|
| 1 | Explain a key; decrypt a Caesar shift with a wheel | none | `a1_key` |
| 2 | Break Caesar by matching the tallest cipher letter to E; say why 25 keys is a tiny key space | 1 | `a1_keyspace`, `a1_frequency` |
| 3 | Tell ROT13 from Atbash; state Kerckhoffs's principle and why a keyless scheme is not encryption | 1 | `a1_kerckhoffs` |
| 4 | Break monoalphabetic substitution with frequency and word patterns; explain why 26! keys did not save it | 2 | `a1_substitution` |
| 5 | Place a crib by letter-pattern consistency and use it to pin a key | 4 | `a1_cribs` |
| 6 | Use bigrams and trigrams (TH, HE, THE, ING) when single-letter counts are flattened | 4 | `a1_ngrams` |
| 7 | Split Vigenere ciphertext into columns and solve each as a Caesar | 2 | `a1_vigenere` |
| 8 | Find a Vigenere period from spacings of repeated trigrams (Kasiski) | 7 | `a1_kasiski` |
| 9 | Find the period with the index of coincidence | 7 | `a1_ioc` |
| 10 | Convert between bits, hex and ASCII; use XOR's self-inverse; break single-byte XOR by English scoring | 2 | `a1_xor`, `a1_single_xor` |
| 11 | Find a repeating-key XOR key size with normalized Hamming distance; transpose and solve columns | 7, 10 | `a1_repeating_xor` |
| 12 | Explain why a one-time pad fails when reused; crib-drag C1 xor C2 | 10 | `a1_otp` |

## Act II: The Stained Glass (stub)
- **Toy block cipher (SPN, "AES-lite")**: substitution-permutation rounds, key schedule. Prereq: Act I XOR.
- **ECB patterns**: identical plaintext blocks give identical ciphertext blocks; the "stained glass" image shows the outline through ECB. Prereq: block cipher. *Repeats: identical blocks.*
- **CBC and bit-flipping**: flipping a ciphertext bit flips the same bit in the next plaintext block. Prereq: XOR, CBC.
- **Padding oracle ("the confessor who only says yes or no")**: recover plaintext byte by byte from a validity oracle. Prereq: CBC, PKCS#7.

## Act III: Blood Sigils (stub)
- **Hashes**: preimage, second preimage and collision resistance with a toy hash. Prereq: bytes.
- **Birthday attack**: collisions after about 2^(n/2) tries on an n-bit hash. Prereq: hashes.
- **Length extension**: Merkle-Damgard hash(secret || msg) lets anyone append. Prereq: hash internals.
- **HMAC**: why the nested construction fixes length extension. Prereq: length extension.

## Act IV: The Court of Primes (stub)
- **Modular arithmetic**: mulmod, modpow, extended Euclid, inverses, CRT (`core/crypto/modmath.gd`, implemented and tested for 64-bit-safe operands).
- **RSA**: small e with no padding (cube root), common modulus, Wiener's attack. *Repeats: reused moduli.*
- **Diffie-Hellman, discrete log**: baby-step giant-step on small groups.
- **ECC intuition**: point addition on a tiny curve.
- **Open decision:** arbitrary-precision integers. `core/crypto/bigint.gd` defines the interface only. Plan: limb-based BigInt in GDScript (base 2^24 limbs so limb products fit in 64-bit ints) for teaching-size numbers (<= 512 bits), with a GDExtension fallback if profiling on a mid-range phone shows modpow over 512-bit numbers above 50 ms.

## Act V: The Ward and the Whisper (stub)
- **Replay and man-in-the-middle** on a toy key exchange.
- **Timing side channels**: early-exit comparisons leak by duration.
- **ECDSA nonce reuse**: two signatures with the same k reveal the private key. *The theme's final form.*
- **Zero-knowledge proof** as the redemption mechanic: prove knowledge without revealing it.
