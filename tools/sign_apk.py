"""Signs an APK with APK Signature Scheme v2 (what Android 7+ checks), using
only Python and the `cryptography` package, for machines without the
Android SDK's apksigner. Godot already zip-aligns the APK it exports.

   python3 tools/sign_apk.py in.apk out.apk [--key key.pem]

The key file (RSA key + self-signed certificate, PEM) is created on first use.
Keep the same key for every build of a test APK, or Android refuses to update
the installed app ("signatures don't match") and you must uninstall first.
For a store release, sign with your real release key instead.
"""
import argparse
import datetime
import hashlib
import os
import struct
import sys

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa
from cryptography.x509.oid import NameOID

CHUNK = 1024 * 1024
V2_ID = 0x7109871A
ALGO_RSA_PKCS1_SHA256 = 0x0103
MAGIC = b"APK Sig Block 42"


def lp(b):
    """uint32 little-endian length prefix."""
    return struct.pack("<I", len(b)) + b


def load_or_make_key(path):
    if os.path.exists(path):
        data = open(path, "rb").read()
        key = serialization.load_pem_private_key(data, None)
        cert = x509.load_pem_x509_certificate(data[data.index(b"-----BEGIN CERTIFICATE-----"):])
        return key, cert
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "Neon Puck debug")])
    now = datetime.datetime.now(datetime.timezone.utc)
    cert = (x509.CertificateBuilder().subject_name(name).issuer_name(name)
            .public_key(key.public_key()).serial_number(x509.random_serial_number())
            .not_valid_before(now - datetime.timedelta(days=1))
            .not_valid_after(now + datetime.timedelta(days=365 * 30))
            .sign(key, hashes.SHA256()))
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    with open(path, "wb") as f:
        f.write(key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8, serialization.NoEncryption()))
        f.write(cert.public_bytes(serialization.Encoding.PEM))
    os.chmod(path, 0o600)
    return key, cert


def find_eocd(data):
    start = max(0, len(data) - 65557)
    i = data.rfind(b"PK\x05\x06", start)
    if i < 0:
        sys.exit("not a zip: no end of central directory")
    cd_size, cd_off = struct.unpack("<II", data[i + 12:i + 20])
    return i, cd_off, cd_size


def digest(sections):
    chunks = []
    for sec in sections:
        for o in range(0, len(sec), CHUNK):
            part = sec[o:o + CHUNK]
            chunks.append(hashlib.sha256(b"\xa5" + struct.pack("<I", len(part)) + part).digest())
    return hashlib.sha256(b"\x5a" + struct.pack("<I", len(chunks)) + b"".join(chunks)).digest()


def sign(data, key, cert):
    eocd, cd_off, cd_size = find_eocd(data)
    if data[cd_off - 16:cd_off] == MAGIC:
        sys.exit("already has an APK Signing Block")
    if cd_off + cd_size != eocd:
        sys.exit("unexpected data between central directory and EOCD")
    entries, cd, end = data[:cd_off], data[cd_off:eocd], data[eocd:]
    dig = digest([entries, cd, end])
    cert_der = cert.public_bytes(serialization.Encoding.DER)
    pub_der = key.public_key().public_bytes(serialization.Encoding.DER, serialization.PublicFormat.SubjectPublicKeyInfo)
    digests = lp(lp(struct.pack("<I", ALGO_RSA_PKCS1_SHA256) + lp(dig)))
    signed_data = digests + lp(lp(cert_der)) + lp(b"")
    sig = key.sign(signed_data, padding.PKCS1v15(), hashes.SHA256())
    signer = lp(signed_data) + lp(lp(struct.pack("<I", ALGO_RSA_PKCS1_SHA256) + lp(sig))) + lp(pub_der)
    value = lp(lp(signer))
    pair = struct.pack("<Q", 4 + len(value)) + struct.pack("<I", V2_ID) + value
    size = len(pair) + 8 + 16
    block = struct.pack("<Q", size) + pair + struct.pack("<Q", size) + MAGIC
    new_end = bytearray(end)
    struct.pack_into("<I", new_end, 16, cd_off + len(block))
    return entries + block + cd + bytes(new_end)


def verify(apk, cert):
    """Re-reads the signed APK the way Android does and checks the v2 block."""
    eocd, cd_off, cd_size = find_eocd(apk)
    assert apk[cd_off - 16:cd_off] == MAGIC, "no signing block"
    size = struct.unpack("<Q", apk[cd_off - 24:cd_off - 16])[0]
    bstart = cd_off - size - 8
    assert struct.unpack("<Q", apk[bstart:bstart + 8])[0] == size
    p = bstart + 8
    v2 = None
    while p < cd_off - 24:
        ln, pid = struct.unpack("<QI", apk[p:p + 12])
        if pid == V2_ID:
            v2 = apk[p + 12:p + 8 + ln]
        p += 8 + ln
    assert v2 is not None, "no v2 pair"

    def rd(b, o):
        n = struct.unpack("<I", b[o:o + 4])[0]
        return b[o + 4:o + 4 + n], o + 4 + n

    signers, _ = rd(v2, 0)
    signer, _ = rd(signers, 0)
    sd, o = rd(signer, 0)
    sigs, o = rd(signer, o)
    pub, _ = rd(signer, o)
    s1, _ = rd(sigs, 0)
    algo = struct.unpack("<I", s1[:4])[0]
    sigbytes, _ = rd(s1, 4)
    pk = serialization.load_der_public_key(pub)
    pk.verify(sigbytes, sd, padding.PKCS1v15(), hashes.SHA256())
    dgs, o = rd(sd, 0)
    d1, _ = rd(dgs, 0)
    want, _ = rd(d1, 4)
    # Digest with the EOCD's CD offset pointing at the block start.
    end = bytearray(apk[eocd:])
    struct.pack_into("<I", end, 16, bstart)
    got = digest([apk[:bstart], apk[cd_off:eocd], bytes(end)])
    assert got == want, "content digest mismatch"
    assert algo == ALGO_RSA_PKCS1_SHA256
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("inp")
    ap.add_argument("out")
    ap.add_argument("--key", default=os.path.expanduser("~/.local/share/neon-puck/debug_key.pem"))
    a = ap.parse_args()
    key, cert = load_or_make_key(a.key)
    out = sign(open(a.inp, "rb").read(), key, cert)
    verify(out, cert)
    open(a.out, "wb").write(out)
    print("signed (v2) and verified:", a.out, len(out), "bytes")


if __name__ == "__main__":
    main()
