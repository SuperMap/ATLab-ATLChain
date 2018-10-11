package main

import (
    "encoding/pem"
    "encoding/base64"
    "crypto/x509"
    "crypto/rsa"
    "crypto/rand"
    "crypto/sha256"
    "io/ioutil"
    "fmt"

    "github.com/hyperledger/fabric/core/chaincode/shim"
    pb "github.com/hyperledger/fabric/protos/peer"
)

type TxCC struct {
}

func readFileAsByte(filePath string) []byte {
    b, _ := ioutil.ReadFile(filePath)
    return b
}

func makeAddress(publickey []byte) string {
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

func Decryption(cipherdata []byte, privatekey []byte) string {
    // 获取pem格式的私钥
    pemkey,_ := pem.Decode(privatekey)
    // 解析PKCS1格式的私钥
    newprivatekey,_ := x509.ParsePKCS1PrivateKey(pemkey.Bytes)
    // 解密
    plaintext, _ := rsa.DecryptPKCS1v15(rand.Reader,newprivatekey,cipherdata)
    return string(plaintext)
}

// 初始化
// args: 0-{pubkey_file_address},1-{plaintext}
func (t *TxCC) Init(stub shim.ChaincodeStubInterface) pb.Response {
    _, args := stub.GetFunctionAndParameters()
    // TODO:初始化时给账户A赋值
    publickey := readFileAsByte(args[0])
    plaintext := []byte(args[1])
    addressA := makeAddress(publickey)
    cipherdata := Encryption(plaintext, publickey)
    error := stub.PutState(addressA, cipherdata)
    if error != nil {
        shim.Error("PutState failed!")
    }
    return shim.Success(nil)
}

// 交易
// args: 0-{pubkey_file_addressA},1-{pubkey_file_addressB},2-{prikey_file_addressA}
func (t *TxCC) invoke(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    // TODO:解密账户A的数据，同时将数据用B的公钥加密，存入B的地址
    publickeyA := readFileAsByte(args[0])
    publickeyB := readFileAsByte(args[1])
    privatekeyA := readFileAsByte(args[2])
    addressA := makeAddress(publickeyA)
    addressB := makeAddress(publickeyB)
    cipherdataA, error := stub.GetState(addressA)
    if error != nil {
        shim.Error("GetState failed!")
    }
    plaintext := Decryption(cipherdataA, privatekeyA)
    cipherdataB := Encryption([]byte(plaintext), publickeyB)

    error = stub.PutState(addressB, cipherdataB)
    if error != nil {
        shim.Error("PutState failed!")
    }

    return shim.Success(nil)
}

// 查询
// args: 0-{pubkey_file_address},1-{prikey_file_address}
func (t *TxCC) query(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    // TODO:根据公钥找到地址，查询记录，同时使用私钥解密
    publickey := readFileAsByte(args[0])
    privatekey := readFileAsByte(args[1])
    address := makeAddress(publickey)
    cipherdata, error := stub.GetState(address)
    if error != nil {
        return shim.Error("qurey failed!")
    }

    plaintext := Decryption(cipherdata, privatekey)
    fmt.Println(plaintext)
    return shim.Success([]byte(plaintext))
}

// Invoke
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
