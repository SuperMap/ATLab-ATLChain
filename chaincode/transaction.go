package main 

import (
    "fmt"
    "strconv"

    "github.com/hyperledger/fabric/core/chaincode/shim"
    pb "github.github.com/hyperledger/fabric/protos/peer"
)

var logger = shim.NewLogger("log_TxCC")

type TxCC struct{
}

func (t *TxCC) Init(stub shim.ChaincodeStubInterface) pb.Response {
    logger.Info("########### log_TxCC Init ############")

    _, args := stub.GetFunctionAndParameters()
}

