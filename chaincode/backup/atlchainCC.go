/*
 *  Chaincode atlchainCC version 0.4.1 
 *  Support get history by key
 *  modify insertion args, add arg[0]=>key
 *  Support get state by key for debug  
 *
 *  Author: chengyang@supermap.com
 *  Date:   2019-01-26
 *  Log:    update
 *
 */


package main

import (
    "bytes"
    "strconv"
    // "encoding/json"
    "fmt"
    "strings"
    "crypto/sha256"
    "time"

    "github.com/hyperledger/fabric/core/chaincode/shim"
    pb "github.com/hyperledger/fabric/protos/peer"
)

type AtlchainCC struct {
}

func (a *AtlchainCC) Init(stub shim.ChaincodeStubInterface) pb.Response {
    return shim.Success(nil)
}

// Put into ledger
// args: 0-{key},1-{jsonStr},2-{signatureStr},3-{pubkeyPemStr}
// key => for traceablity, key should always be the hash or id of the data for transaction.
// jsonStr => content string in json format
// eg:"{"AddrReceive":"addrA", "AddrSend":"addrB"}"
func (a *AtlchainCC) Put(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    argsNeed := 4
    argsLength := len(args)
	if argsLength != argsNeed {
		return shim.Error("Incorrect number of arguments. Expecting " + strconv.Itoa(argsNeed) + ", given " + strconv.Itoa(argsLength))
	}

    var putKey = args[0]
    var jsonStr = args[1]
    var signatureStr = args[2]
    var pubkeyPemStr = args[3]

    fmt.Println("++++++++++++++++jsonStr+++++++++++++++++++++++++++++")
    fmt.Print(jsonStr)

    if !verify(jsonStr, signatureStr, pubkeyPemStr) {
        return shim.Error("Invalid signature")
    }

    // var putKey = getPutKeyFromJsonStr(jsonStr)

    recordByte := []byte(jsonStr)

    err := stub.PutState(putKey, recordByte)
    if err != nil {
        return shim.Error(err.Error())
    }

    return shim.Success(nil)
}

// Query by any conditions
// args: 0-{queryJsonString} 
// eg: {"hash":"hashstring", "AddrSend":"addressstring"}
func (t *AtlchainCC) Get(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    argsNeed := 1
    argsLength := len(args)
	if len(args) != argsNeed {
		return shim.Error("Incorrect number of arguments. Expecting " + strconv.Itoa(argsNeed) + ", given " + strconv.Itoa(argsLength))
	}

	//queryString := "{\"selector\":{\"Hash\":\"" + hash + "\"}}"
	queryString := "{\"selector\":" + args[0]+ "}"
	queryResults, err := getQueryResult(stub, queryString)
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(queryResults)
}

func (t *AtlchainCC) getRecordByKey(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    argsNeed := 1
    argsLength := len(args)
	if len(args) != argsNeed {
		return shim.Error("Incorrect number of arguments. Expecting " + strconv.Itoa(argsNeed) + ", given " + strconv.Itoa(argsLength))
	}

	queryResult, err := stub.GetState(args[0])
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(queryResult)
}

// Get history by key
func (t *AtlchainCC) getHistoryByKey(stub shim.ChaincodeStubInterface, args []string) pb.Response {
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

func getQueryResult(stub shim.ChaincodeStubInterface, queryString string) ([]byte, error) {
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

//TODO verify record signature, now this function is in node SDK API
func verify(json string, signature string, pubkeyPem string) bool {
    // hash := hash(json)

    return true
}

func hash(str string) string {
    hash := sha256.Sum256([]byte(str))
    return string(hash[:])
}

func getPutKeyFromJsonStr(jsonString string) string {

    _str := strings.Replace(jsonString, "\"", " ", -1)
    _str2 := strings.Split(_str, " ")

    key := _str2[3]

    return key
}

func (a *AtlchainCC) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
    function, args := stub.GetFunctionAndParameters()
    switch function {
    case "Put":
        return a.Put(stub, args)
    case "Get":
        return a.Get(stub, args)
    case "getHistoryByKey":
        return a.getHistoryByKey(stub, args)
    case "getRecordByKey":
        return a.getRecordByKey(stub, args)
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
