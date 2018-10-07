# A simple "CA in a box"

This is a simple way of managing CA using OpenSSL.

It can be used to issue client and server certificates with minimum effort.

Note: ECDSA is used for keys.

## Initialize the CA

`make ca` will set up the trappings of a CA:

```
 make ca CA_DN="/C=IE/L=Dublin/O=ACME Ltd./OU=IT Dept/CN=Root CA"
```

Edit the certificate subject to suit your needs.

This only needs to be done once.

## Issuing certificates

To issue a certificate use `make XXX.crt CN=xxx` target. `XXX` is arbitrary and specifies the name of the output file. Along with `XXX.crt`, a key file `XXX.key` wil be generated. `CN` specifies the common name of the certificate subject and is mandatory.

### Optional Parameters

There are a few optional parameters as well:
 * `DAYS=n` - certificate validity. Default is 365.
 * `ALTN1`, `ALTN2`, `ALTN3` - subect aletrnative DNS names.
 * `CLIENT=1` - generate a client authentication certificate.The default is to generate server certificates.

## Examples
 * `make example.crt CN=example.org`
   * Generates a server certificate for `example.org`
 * `make example.crt CN=example.org ALTN1=www.example.org DAYS=730`
   * Generates a server certificate for `example.org` and `www.example.org`, valid for 2 years.
 * `make client001.crt CN=client001 CLIENT=1`
   * Generates a client certififcate for `client001`.
 ```
