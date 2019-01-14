package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

type txCC struct {
}

type record struct {
	Buyer  string `json:Buyer`
	Seller string `json:Seller`
	Price  int    `json:Price`
	Time   string `json:Time`
	Hash   string `json:Hash`
}

// 初始化
// args: 0-{}
func (t *txCC) Init(stub shim.ChaincodeStubInterface) pb.Response {
	fmt.Println("init Success")
	return shim.Success(nil)
}

// 写入记录,key=>BuyerAddr
// args: 0-{BuyerAddr},1-{SellerAddr},2-{Price},3-{Time},4-{Hash}
func (t *txCC) putRecord(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	argsNeed := 5
	argsLength := len(args)
	if argsLength != argsNeed {
		return shim.Error(strconv.Itoa(argsNeed) + " args wanted, but given " + strconv.Itoa(argsLength))
	}
	fmt.Println("putRecord: address=>" + args[0])

	price, _ := strconv.Atoi(args[2])
	record := record{args[0], args[1], price, args[3], args[4]}

	recordByte, _ := json.Marshal(record)
	error := stub.PutState(args[0], recordByte)
	if error != nil {
		shim.Error("PutState failed!")
	}
	return shim.Success(nil)
}

// 根据买方地址查询交易记录
// args: 0-{address}
func (t *txCC) getRecordByBuyerAddr(stub shim.ChaincodeStubInterface, args []string) pb.Response {
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

// 根据买方地址查询交易历史
// args: 0-{address}
func (t *txCC) getHistoryByBuyerAddr(stub shim.ChaincodeStubInterface, args []string) pb.Response {
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

// 根据hash查询交易历史
// args: 0-{hash}
func (t *txCC) getHistoryByHash(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) < 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	hash := strings.ToLower(args[0])

	queryString := fmt.Sprintf("{\"selector\":{\"Hash\":\"%s\"}}", hash)
	queryResults, err := getQueryResultForQueryString(stub, queryString)
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(queryResults)
}

// 根据卖方地址查询交易历史
// args: 0-{address}
func (t *txCC) getHistoryBySellerAddr(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) < 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	seller := args[0]

	queryString := fmt.Sprintf("{\"selector\":{\"Seller\":\"%s\"}}", seller)
	queryResults, err := getQueryResultForQueryString(stub, queryString)
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(queryResults)
}


// 根据hash和买方地址查询交易历史
// args: 0-{hash}, 1-{addr}
func (t *txCC) getHistoryByHashAndBuyerAddr(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) < 2 {
		return shim.Error("Incorrect number of arguments. Expecting 2")
	}

	hash := strings.ToLower(args[0])
	buyer := args[1]

	queryString := fmt.Sprintf("{\"selector\":{\"Hash\":\"%s\", \"Buyer\":\"%s\"}}", hash, buyer)
	queryResults, err := getQueryResultForQueryString(stub, queryString)
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(queryResults)
}

// 执行查询条件
func getQueryResultForQueryString(stub shim.ChaincodeStubInterface, queryString string) ([]byte, error) {
	resultsIterator, err := stub.GetQueryResult(queryString)
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	buffer, err := constructQueryResponseFromIterator(resultsIterator)
	if err != nil {
		return nil, err
	}

	fmt.Printf("- getQueryResultForQueryString queryResult:\n%s\n", buffer.String())

	return buffer.Bytes(), nil
}

// 格式化输出结果
func constructQueryResponseFromIterator(resultsIterator shim.StateQueryIteratorInterface) (*bytes.Buffer, error) {
	// buffer is a JSON array containing QueryResults
	var buffer bytes.Buffer
	buffer.WriteString("[")

	bArrayMemberAlreadyWritten := false
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}
		// Add a comma before array members, suppress it for the first array member
		if bArrayMemberAlreadyWritten == true {
			buffer.WriteString(",")
		}
		buffer.WriteString("{\"Key\":")
		buffer.WriteString("\"")
		buffer.WriteString(queryResponse.Key)
		buffer.WriteString("\"")
		buffer.WriteString(", \"Record\":")
		// Record is a JSON object, so we write as-is
		buffer.WriteString(string(queryResponse.Value))
		buffer.WriteString("}")
		bArrayMemberAlreadyWritten = true
	}
	buffer.WriteString("]")
	return &buffer, nil
}

// Invoke
func (t *txCC) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	function, args := stub.GetFunctionAndParameters()
	if function == "putRecord" {
		return t.putRecord(stub, args)
	} else if function == "getRecordByBuyerAddr" {
		return t.getRecordByBuyerAddr(stub, args)
	} else if function == "getHistoryByBuyerAddr" {
		return t.getHistoryByBuyerAddr(stub, args)
	} else if function == "getHistoryByHash" {
		return t.getHistoryByHash(stub, args)
	} else if function == "getHistoryBySellerAddr" {
		return t.getHistoryBySellerAddr(stub, args)
	}
	return shim.Error("Invalid invoke function name")
}

func main() {
	err := shim.Start(new(txCC))
	if err != nil {
		fmt.Printf("Error starting txCC chaincode: %s", err)
	}
}
