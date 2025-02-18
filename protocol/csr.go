package protocol // github.com/microbuilder/linaroca/protocol

type CSRRequest struct {
	_   struct{} `cbor:",toarray"`
	CSR []byte
}

type CSRResponse struct {
	Status  int    `cbor:"1,keyasint"`
	Cert    []byte `cbor:"2,keyasint"`
	Hubname string `cbor:"3,keyasint"`
	Port    int    `cbor:"4,keyasint"`
}
