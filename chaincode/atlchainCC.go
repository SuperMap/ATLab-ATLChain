package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"strconv"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

type AtlchainCC struct {
}

func (a *AtlchainCC) Init(stub shim.ChaincodeStubInterface) pb.Response {
	return shim.Success(nil)
}

// 写入账本，key => AddrReceive
// args: 0-{AddrReceive},1-{jsonString}
// eg: peer chaincode invoke -o 127.0.0.1:7050 -C atlchannel -n atlchainCC -c '{"Args":["Put","addrA" , "{\"AddrReceive\":\"addrA\", \"AddrSend\":\"addrB\"}"]}'
func (a *AtlchainCC) Put(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	argsNeed := 2
	argsLength := len(args)
	if argsLength != argsNeed {
		return shim.Error("Incorrect number of arguments. Expecting " + strconv.Itoa(argsNeed) + ", given " + strconv.Itoa(argsLength))
	}

	recordByte := []byte(args[1])
	var f interface{}
	err := json.Unmarshal(recordByte, &f)
	if err != nil {
		return shim.Error(err.Error())
	}

	err = stub.PutState(args[0], recordByte)
	if err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success(nil)
}

// 根据各种条件查询交易历史
// args: 0-{queryJsonString} eg: {"hash":"hashstring", "AddrSend":"addressstring"}
// eg: peer chaincode query -C atlchannel -n atlchainCC -c '{"Args":["Query", "{\"AddrSend\":\"addrB\", \"AddrReceive\":\"addrA\"}"]}'
func (t *AtlchainCC) Query(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	argsNeed := 1
	argsLength := len(args)
	if len(args) != argsNeed {
		return shim.Error("Incorrect number of arguments. Expecting " + strconv.Itoa(argsNeed) + ", given " + strconv.Itoa(argsLength))
	}

	queryConditionByte := []byte(args[0])
	var f interface{}
	err := json.Unmarshal(queryConditionByte, &f)
	if err != nil {
		return shim.Error(err.Error())
	}

	//queryString := "{\"selector\":{\"Hash\":\"" + hash + "\"}}"
	queryString := "{\"selector\":" + args[0] + "}"
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

func (a *AtlchainCC) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	function, args := stub.GetFunctionAndParameters()
	switch function {
	case "Put":
		return a.Put(stub, args)
	case "Query":
		return a.Query(stub, args)
	default:
		return shim.Error("Invalid invoke function name")
	}
}

func main() {
	err := shim.Start(new(AtlchainCC))
	if err != nil {
		fmt.Printf("Error starting AtlchainCC chaincode: %s", err)
	}
}
