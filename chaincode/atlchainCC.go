package main

import (
    "strconv"
    "encoding/json"
    "fmt"

    "github.com/hyperledger/fabric/core/chaincode/shim"
    pb "github.com/hyperledger/fabric/protos/peer"
)

type atlchainCC struct {
}

// DataType Enums
const {
    FILEPATH = 'filepath'
    DBRECORD = 'dbrecord'
    TEXT = 'text'
    LICENSE = 'license'
    OTHER = 'other'
}

// PositionType Enums
const {
    NONE = 'none'
    COORDINATE = 'coordinate'
    GEOHASH = 'geohash'
}

type record struct{
    RecordType  rType    `json:RecordType`
    AddrSend    string  `json:AddrSend`
    AddrRec     string  `json:AddrRec`
    Price       int     `json:Price`
    Datetime    string  `json:Datetime`
    ParentID    string  `json:ParentID`
    Data        string  `json:Data`
    Position    position  `josn:Position`
    Signature   string  `json:Signature`
    Certificate     string  `json:Certificate`
}

type rType struct {
    DataType    bool    `json:DataType`
    IsEncrypt   bool    `json:IsEncrypt`
    Format      string  `json:Format`
    Length      int     `json:Length`
}

type position struct {
    PositionType    string  `json:PositionType`
    Coordinate      coordinate  `json:Coordinate`
    GEOHash         string  `json:GEOHash`
}

type coordinate struct {
    Longitude   double  `json:Longitude`
    Latitude    double  `json:Latitude`
    Altitude    double  `json:Altitude`
}

func (a *AtlchainCC) Init(stub shim.ChaincodeStubInterface) pb.Response {
    return shim.Success(nil)
}

// 写入账本，key => BuyerAddr
// args: 0-{DataType},1-{IsEncrypt},2-{Format},3-{Length},4-{AddrSend},5-{AddrRec},6-{Price},7-{Datetime},8-{ParentID},9-{Data},10-{PositioniJsonStr},11-{Signature},12-{Certificate},13-{DataID},14-{DataName},15-{DataProp1},16-{DataProp2},17-{DataProp3}
func (a *AtlchainCC) putRecord(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    argsNeed := 13
    argsLength := len(args)
	if argsLength != argsNeed {
		return shim.Error(strconv.Itoa(argsNeed) + " args wanted, but given " + strconv.Itoa(argsLength))
	}

    recordType := rType{args[0], args[1], args[2], args[3]}

    var pos position
    json.Unmarshal([]byte(args[10]), &pos);

    rcd := record{recordType, args[4], args[5]，args[6], args[7], args[8], args[9], pos, args[11], args[12]}
    rcdByte, err := json.Marshal(rcd)
    if err != nil {
        fmt.Printf("Marshal json error: %s", err)
    }

    err := stub.PutState(args[4], rcdByte)
    if err != nil {
        return shim.Error("Put record error: %s", err)
    }

    return shim.Success(nil)
}

// 根据各种条件查询交易历史
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
    function, args : stub.GetFunctionAndParameters()
    switch function {
    case "putRecord":
        return a.putRecord(stub, args)
    case "fcn":
        return a.fcn()
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
