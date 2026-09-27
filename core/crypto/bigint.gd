class_name BigInt
extends RefCounted
## Arbitrary-precision integers: interface only (Act IV, The Court of Primes).
##
## GDScript ints are 64-bit signed. ModMath.mulmod keeps products safe for moduli up to
## 2^62, which covers toy RSA with ~30-bit primes. Real-looking RSA/DH (256..512-bit)
## needs this class. Open decision (docs/CURRICULUM.md, Act IV):
##   * representation: little-endian PackedInt64Array of 24-bit limbs, so a limb product
##     (< 2^48) plus carries stays far below 2^63;
##   * operations: from_string, to_string, add, sub, mul (schoolbook; Karatsuba if needed),
##     divmod (Knuth D), modpow (sliding window), modinv, cmp, is_probable_prime (Miller-Rabin);
##   * fallback: a GDExtension if modpow on 512-bit numbers takes over 50 ms on a
##     mid-range phone.
## Until implemented, callers must check is_available().

const LIMB_BITS: int = 24


static func is_available() -> bool:
	return false
