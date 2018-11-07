package main

import (
    "fmt"
    "strconv"
    "json"

    "github.com/hyperledger/fabric/core/chaincode/shim"
    pb "github.com/hyperledger/fabric/protos/peer"
)

type TxCC struct {
}

type Record struct {
    Buyer   string  `json:Buyer`
    Seller  string  `json:Seller`
    Price   int     `json:Price`
    Time    string  `json:Time`
    Hash    string  `json:Hash`
}

// 初始化
// args: 0-{}
func (t *TxCC) Init(stub shim.ChaincodeStubInterface) pb.Response {
    fmt.Println("init Success")
    return shim.Success(nil)
}

// 写入记录
// args: 0-{address},1-{Buyer},2-{Seller},3-{Price},4-{Time},5-{Hash}
func (t *TxCC) PutRecord(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    fmt.Println("PutRecord: address=>" + args[0])
    price, err := strconv.Atoi(args[3])
    record := Record{args[1], args[2], price, args[4], args[5]}

    r, _ := json.Marshal(record)
    error := stub.PutState(args[0], r)
    if error != nil {
        shim.Error("PutState failed!")
    }
    return shim.Success(nil)
}

// 查询记录
// args: 0-{address}
func (t *TxCC) GetRecord(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    r, error := stub.GetState(args[0])
    if error != nil {
        shim.Error("GetState failed!")
    }


    return shim.Success(nil)
}

// 查询历史
// args: 0-{address}
func (t *TxCC) GetHistory(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    cipherdata, error := stub.GetState(address)
    if error != nil {
        return shim.Error("query failed!")
    }

    return shim.Success([]byte(plaintext))
}

// Invoke
func (t *TxCC) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
    function, args := stub.GetFunctionAndParameters()
    if function == "PutRecord" {
        return t.PutRecord(stub, args)
    } else if function == "GetRecord" {
        return t.GetRecord(stub, args)
    } else if function == "GetHistory" {
        return t.GetHistory(stub, args)
    }

    return shim.Error("Invalid invoke function name. Expecting \"invoke\" \"query\"")
}

func main(){
    err := shim.Start(new(TxCC))
    if err != nil {
        fmt.Printf("Error starting TxCC chaincode: %s", err)
    }
}
