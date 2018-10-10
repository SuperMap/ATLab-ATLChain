package main

import (
    "encoding/pem"
    "encoding/base64"
    "crypto/x509"
    "crypto/rsa"
    "crypto/rand"
    "crypto/sha256"
    "fmt"

    "github.com/hyperledger/fabric/core/chaincode/shim"
    pb "github.com/hyperledger/fabric/protos/peer"
)

var privatekey = []byte(`-----BEGIN RSA PRIVATE KEY-----
MIICXQIBAAKBgQCz+PeAz/FHi2FpdxWkRz12/WbOItZtOl479dMs4O5BAOwERBqJ
mEjnL7STL30X630mZal6hMjM5N8K6LTRA2YCqaIdLvrXQSAHbmQ7Dt79ETnrNztY
zcNz926+P402toOpWGcLP3AtJ6Oc8cRSFFTiF33HDaBIQxRnnVO7FdXFzwIDAQAB
AoGAFFqwA02BSEonNjpVpEK6XN7D5cRi4++aAMYIoCbAS3HDP6hEKBOlCyCGF69j
QnVLrjAJPuYNn76yyxUOfiUYQDw96Ij6oGBhO2KvKswXBU/V2XipUUF4C21/EGdk
FtVTHCEPJ6ciaFUUcVGuMRWt2H3z9Jk0xXpCxgGMeTRgTaECQQDgQM00marIVE09
EIHXnXBJJAueNXCOnft4JCrSE5jv/UX8yNNjHeKSJkbRfw5oxSZ8OClSyy9qdjJA
eOSMbWDFAkEAzXNiQLqmonZ+g010lCvPsBNXbdKV8tcbMJht5ywI7zafcv2og/g7
rlSi3dXRAasmi4HDZ+R6R0VdsVHU/NpNgwJBAK3sFDrTY0zzdOQDRXCAPnG7bvdI
4v75L+tBwaQkZtzaRcmDx857gxlubkZUkExZezukIwh/ZUrgWKEAIeF3gzECQErT
lFxY3qnbGFbAFg6FKl5JnRUdlolceMWpLpX8fsCJF2etJPvzo+DpaGv9HONLr30t
5LppB3P/upEDadwxsfsCQQDCBOHd3ydJXWXftNyAqorDdQ0AVdU6f9pcfacKkD5K
cUoVOemDN5dcyfF4sHhkt484nFTfvKaACeEcgrJGIsuf
-----END RSA PRIVATE KEY-----`)
var publickey = []byte(`-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCz+PeAz/FHi2FpdxWkRz12/WbO
ItZtOl479dMs4O5BAOwERBqJmEjnL7STL30X630mZal6hMjM5N8K6LTRA2YCqaId
LvrXQSAHbmQ7Dt79ETnrNztYzcNz926+P402toOpWGcLP3AtJ6Oc8cRSFFTiF33H
DaBIQxRnnVO7FdXFzwIDAQAB
-----END PUBLIC KEY-----`)


type TxCC struct {
}

func makeAddress(publicKey []byte) string {
    h := sha256.New()
    h.Write(publickey)
    addr := base64.StdEncoding.EncodeToString(h.Sum(nil))
    return addr
}

func Encryption(plaintext []byte, publickey []byte) []byte {
    pemkey, _ := pem.Decode(publickey)
    publickeyInterf, _ := x509.ParsePKIXPublicKey(pemkey.Bytes)
    newpublickey := publickeyInterf.(*rsa.PublicKey)
    cipherdata, _ := rsa.EncryptPKCS1v15(rand.Reader, newpublickey, plaintext)
    return cipherdata
}

func Decryption(ciphertext []byte, privatekey []byte) string {
   // 获取pem格式的私钥
   pemkey,_ := pem.Decode(privatekey)
   // 解析PKCS1格式的私钥
   newprivatekey,_ := x509.ParsePKCS1PrivateKey(pemkey.Bytes)
   // 解密
   plaintext, _ := rsa.DecryptPKCS1v15(rand.Reader,newprivatekey,ciphertext)
   return string(plaintext)
}

func (t *TxCC) Init(stub shim.ChaincodeStubInterface) pb.Response {
    // TODO:初始化时给账户A赋值
    var plaintext = []byte(`A账户的文件`)
    addressA := makeAddress(publickey)
    cipherdata := Encryption(plaintext, publickey)
    stub.PutState(addressA, cipherdata)
    return shim.Success(nil)
}

func (t *TxCC) invoke(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    // TODO:解密账户A的数据，同时将数据用B的公钥加密，存入B的地址

    return shim.Success(nil)
}

func (t *TxCC) query(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    // TODO:根据公钥找到地址，查询记录，同时使用私钥解密
    return shim.Success(nil)
}

func (t *TxCC) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
    function, args := stub.GetFunctionAndParameters()
    if function == "invoke" {
        return t.invoke(stub, args)
    } else if function == "query" {
        return t.query(stub, args)
    }

    return shim.Error("Invalid invoke function name. Expecting \"invoke\" \"query\"")
}

func main(){
    err := shim.Start(new(TxCC))
    if err != nil {
        fmt.Printf("Error starting TxCC chaincode: %s", err)
    }
}
