#! /bin/bash

# Exit on any error
set -e

# These steps can be followed to simulate a certificate request from a
# hardware device.
#
# This test scenario calls `make_csr_cbor.go`, which takes a
# certificate signing request (CSR) file, and converts it into a CBOR
# file that can be sent to the CA server using the REST API.  The
# encoded CSR file can then be sent to the CA server using `wget`,
# which will return the generated certificate as a CBOR payload.

# Please follow the steps in `README.md` and make sure the linaroca
# server is running (`run-server.sh`), before running this script.

: ${CAHOSTNAME:=$(hostname)}

# Generate a device ID.  BSD's uuidgen outputs uppercase, so conver
# that here.
DEVID=$(uuidgen | tr '[:upper:]' '[:lower:]')
DEVPATH=certs/$DEVID

echo New device: $DEVID

# Generate a private user key for this device.
openssl ecparam -name prime256v1 -genkey -out $DEVPATH.key

# Generate the CSR for this key.
openssl req -new \
	-key $DEVPATH.key \
	-out $DEVPATH.csr \
	-subj "/O=$CAHOSTNAME/CN=$DEVID/OU=LinaroCA Device Cert - Signing"

# Convert this CSR to cbor.
go run make_csr_cbor.go -in $DEVPATH.csr -out $DEVPATH.cbor

# Submit the CSR.
wget --ca-certificate=certs/SERVER.crt \
	--certificate=certs/BOOTSTRAP.crt \
	--private-key=certs/BOOTSTRAP.key \
	--post-file $DEVPATH.cbor \
	--header "Content-Type: application/cbor" \
	https://$CAHOSTNAME:1443/api/v1/cr \
	-O $DEVPATH.rsp

# When this is successfully processed by the CA, it will return a DER
# encoded certificate enclosed in a CBOR wrapper.  The following
# commands will convert this to a PEM-encoded certificate file.
go run get_cert_cbor.go -in $DEVPATH.rsp -out $DEVPATH.crt

# Display the certificate
openssl x509 -in $DEVPATH.crt -noout -text

# Verify the generated certificate against the CA.
openssl verify -CAfile certs/CA.crt $DEVPATH.crt

# Delete the files that aren't needed
rm $DEVPATH.csr
rm $DEVPATH.cbor
rm $DEVPATH.rsp
