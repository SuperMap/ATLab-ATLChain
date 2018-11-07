package main

import (
    "fmt"
    "strconv"
    "encoding/json"
    "bytes"
    "time"

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
// args: 0-{BuyerAddr},1-{SellerAddr},2-{Price},3-{Time},4-{Hash}
func (t *TxCC) PutRecord(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    argsNeed := 5
    argsLength := len(args)
    if argsLength != argsNeed {
        return shim.Error(strconv.Itoa(argsNeed) + " args wanted, but given " + strconv.Itoa(argsLength))
    }
    fmt.Println("PutRecord: address=>" + args[0])

    price, _:= strconv.Atoi(args[2])
    record := Record{args[0], args[1], price, args[3], args[4]}

    recordByte, _ := json.Marshal(record)
    error := stub.PutState(args[0], recordByte)
    if error != nil {
        shim.Error("PutState failed!")
    }
    return shim.Success(nil)
}

// 查询记录
// args: 0-{address}
func (t *TxCC) GetRecord(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    argsNeed := 1
    argsLength := len(args)
    if argsLength != argsNeed {
        return shim.Error(strconv.Itoa(argsNeed) + " args wanted, but given " + strconv.Itoa(argsLength))
    }

    recordByte, error := stub.GetState(args[0])
    if error != nil {
        shim.Error("GetState failed!")
    }

    return shim.Success(recordByte)
}

// 查询历史
// args: 0-{address}
func (t *TxCC) GetHistory(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    argsNeed := 1
    argsLength := len(args)
    if argsLength != argsNeed {
        return shim.Error(strconv.Itoa(argsNeed) + " args wanted, but given " + strconv.Itoa(argsLength))
    }

    resultsIterator, error := stub.GetHistoryForKey(args[0])
    if error != nil {
        return shim.Error(error.Error())
    }
    defer resultsIterator.Close()

    var buffer bytes.Buffer
    buffer.WriteString("[")

    bArrayMemberAlreadyWritten := false
    for resultsIterator.HasNext() {
        response, err := resultsIterator.Next()
        if err != nil {
            return shim.Error(err.Error())
        }
        // Add a comma before array members, suppress it for the first array member
        if bArrayMemberAlreadyWritten == true {
            buffer.WriteString(",")
        }
        buffer.WriteString("{\"TxId\":")
        buffer.WriteString("\"")
        buffer.WriteString(response.TxId)
        buffer.WriteString("\"")

        buffer.WriteString(", \"Value\":")
        // if it was a delete operation on given key, then we need to set the
        //corresponding value null. Else, we will write the response.Value
        //as-is (as the Value itself a JSON marble)
        if response.IsDelete {
            buffer.WriteString("null")
        } else {
            buffer.WriteString(string(response.Value))
        }

        buffer.WriteString(", \"Timestamp\":")
        buffer.WriteString("\"")
        buffer.WriteString(time.Unix(response.Timestamp.Seconds, int64(response.Timestamp.Nanos)).String())
        buffer.WriteString("\"")

        buffer.WriteString(", \"IsDelete\":")
        buffer.WriteString("\"")
        buffer.WriteString(strconv.FormatBool(response.IsDelete))
        buffer.WriteString("\"")

        buffer.WriteString("}")
        bArrayMemberAlreadyWritten = true
    }
    buffer.WriteString("]")

    fmt.Printf("- getHistoryForMarble returning:\n%s\n", buffer.String())

    return shim.Success(buffer.Bytes())
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

    return shim.Error("Invalid invoke function name")
}

func main(){
    err := shim.Start(new(TxCC))
    if err != nil {
        fmt.Printf("Error starting TxCC chaincode: %s", err)
    }
}
