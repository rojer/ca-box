# A simple "CA in a box"

This is a simple way of managing CA using OpenSSL.

It can be used to issue client and server certificates with minimum effort.

## Initialize the CA

`make ca` will set up the trappings of a CA:

```
 make ca CN="My Root CA"
 make ca DN="/C=IE/L=Dublin/O=ACME Ltd./OU=IT Dept/CN=Root CA"
```

This only needs to be done once.

### Optional Parameters

 * `DAYS` - validity for the root certificate, in days. The default is 3653 (~10 years).
 * `KT` - key type. Specifies the key type to use when generating certificate, see documentation for the `-newkey` argument of [openssl req](https://www.openssl.org/docs/manmaster/man1/openssl-req.html) command. The default is to use P-384 ECDSA keys.

## Issuing certificates

To issue a certificate use `make XXX.crt` target. `XXX` becomes the common name of the certificate subject, the private key is written to `XXX.key`.

### Optional Parameters

There are a few optional parameters as well:
 * Subject:
   * `CN` - Common name of the certificate (instead of taking one from the file's name).
   * `DN` - Fully specify the certificate's subject.
 * Validity:
   * `DAYS=n` - certificate validity. Default is 365 for regular certs, 3653 for the root.
   * `END_DATE=YYYYmmddHHMMSSZ` to set the end date explicitly.
   * `START_DATE` also set the startdate, default is current time.
 * Alternative names:
   * `ALTN1`, `ALTN2`, `ALTN3` - subject aletrnative DNS names.
 * Key usage:
   * `CLIENT=1` - generate a client authentication certificate. The default is to generate server certificates.
   * Set `SERVER=1` to generate a certificate for both client and server auth.
 * `CA=1` - generate an intermediate CA certificate, you can later use this with `SIGN_CERT`.
 * `SIGN_CERT`, `SIGN_KEY` - signing certificate and key. By default certificate is signed with root CA but can be changed to a different one, e.g. previosuly generated with `CA=1`.
 * `KT` - key type. Specifies the key type to use when generating certificate, see documentation for the `-newkey` argument of [openssl req](https://www.openssl.org/docs/manmaster/man1/openssl-req.html) command. The default is to use P-256 ECDSA keys.

## Examples
 * `make example.org.crt`
   * Generates a server certificate for `example.org`
 * `make server.crt CN=example.org ALTN1=example.org ALTN1=www.example.org DAYS=730`
   * Generates a server certificate for `example.org` and `www.example.org`, valid for 2 years.
   * Note that alterantive names supercede the CN, so it must be repeated among them.
 * `make client.crt CN=client001 CLIENT=1`
   * Generates a client certififcate for `client001`.
 * `make device001.crt CLIENT=1 SERVER=1`
   * Generates a certififcate for `device001`, suitable for both client and server authentication.
 * `make sub.crt CA=1 DAYS=1826`
   * Generates an intermediate CA cert.
 * `make server.crt SIGN_CERT=sub.crt START_DATE=20240801010000Z END_DATE=20320801010000Z`
   * Generates server certificate signed by `sub.key` with specified validity period.
 ```
