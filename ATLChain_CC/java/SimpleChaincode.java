package org.hyperledger.fabric.example;

import java.util.List;
import java.util.Iterator;

import com.google.protobuf.ByteString;
import io.netty.handler.ssl.OpenSsl;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.hyperledger.fabric.shim.ChaincodeBase;
import org.hyperledger.fabric.shim.ChaincodeStub;
import org.hyperledger.fabric.shim.ledger.KeyValue;
import org.hyperledger.fabric.shim.ledger.QueryResultsIterator;
import org.hyperledger.fabric.shim.ledger.KeyModification;

import static java.nio.charset.StandardCharsets.UTF_8;

public class SimpleChaincode extends ChaincodeBase {

    private static Log _logger = LogFactory.getLog(SimpleChaincode.class);

    @Override
    public Response init(ChaincodeStub stub) {
        return newSuccessResponse();
    }

    @Override
    public Response invoke(ChaincodeStub stub) {
        try {
            _logger.info("Invoke java simple chaincode");
            String func = stub.getFunction();
            List<String> params = stub.getParameters();
            if (func.equals("Put")) {
                return Put(stub, params);
            }
            if (func.equals("PutBin")) {
                return PutBin(stub, params);
            }
            if (func.equals("Get")) {
                return Get(stub, params);
            }
            if (func.equals("GetHistoryByKey")) {
                return GetHistoryByKey(stub, params);
            }
            if (func.equals("GetRecordByKey")) {
                return GetRecordByKey(stub, params);
            }
            return newErrorResponse("Invalid invoke function name. Expecting one of: [\"Put\", \"Get\", \"getHistoryByKey\"]");
        } catch (Throwable e) {
            return newErrorResponse(e);
        }
    }

    // TODO verify record signature
    private boolean verify(String jsonStr, String signatureStr, String pubkeyPemStr){
        // String hash = hashCal(jsonStr);
        return true;
    }

    // TODO calculate string hash value
    private String hashCal(String str){
        return "Hash String";
    }

    private Response Put(ChaincodeStub stub, List<String> args){
        int argsNeeded = 4;
        if (args.size() != 4){
            return newErrorResponse("Incorrect number of arguments. Expecting " + argsNeeded);
        }
        String putKey = args.get(0);
        String jsonStr = args.get(1);
        String signatureStr = args.get(2);
        String pubkeyPemStr = args.get(3);

        if (!verify(jsonStr, signatureStr, pubkeyPemStr)){
            return newErrorResponse("Incorrect number of arguments. Expecting " + argsNeeded);
        }

        stub.putStringState(putKey, jsonStr);
        _logger.info("Transfer complete");
        return newSuccessResponse("invoke finished successfully");
    }
    
    // Put binary string data on chain
    private Response PutBin(ChaincodeStub stub, List<String> args){
        int argsNeeded = 4;
        if (args.size() != 4){
            return newErrorResponse("Incorrect number of arguments. Expecting " + argsNeeded);
        }
        String putKey = args.get(0);
        String jsonStr = args.get(1);
        String signatureStr = args.get(2);
        String pubkeyPemStr = args.get(3);

        String binary = "1100001 1100010 1100011";
        jsonStr = BinToString(binary);

        if (!verify(jsonStr, signatureStr, pubkeyPemStr)){
            return newErrorResponse("Incorrect number of arguments. Expecting " + argsNeeded);
        }

        stub.putStringState(putKey, jsonStr);
        _logger.info("Transfer complete");
        return newSuccessResponse("invoke finished successfully");
    }
    // query callback representing the query of a chaincode
    private Response Get(ChaincodeStub stub, List<String> args) {
        if (args.size() != 1) {
            return newErrorResponse("Incorrect number of arguments. Expecting name of the person to query");
        }
        String key = args.get(0);
        StringBuilder strBuilder = new StringBuilder("");
        strBuilder.append("[");
        boolean shouldAddComma = false;
        QueryResultsIterator<KeyValue> resultsIterator = stub.getQueryResult("{\"selector\":" + key + "}");
        Iterator<KeyValue> iter = resultsIterator.iterator();

        while(iter.hasNext())
        {
            if(shouldAddComma){
                strBuilder.append(",");
            }
            KeyValue kval = iter.next();
            strBuilder.append("{\"Key\":\"" + kval.getKey() + "\",\"Record\":" + kval.getStringValue() + "}");
            _logger.info(String.format("result Key: %s, value: %s", kval.getKey(), kval.getStringValue()));
            shouldAddComma = true;
        }
        strBuilder.append("]");

        _logger.info("total result: " + strBuilder.toString());
        return newSuccessResponse(ByteString.copyFrom(strBuilder.toString(), UTF_8).toByteArray());
    }

    private Response GetHistoryByKey(ChaincodeStub stub, List<String> args) {
        if (args.size() != 1) {
            return newErrorResponse("Incorrect number of arguments. Expecting 1");
        }
        String key = args.get(0);
        StringBuilder strBuilder = new StringBuilder("");
        strBuilder.append("[");
        boolean shouldAddComma = false;
        QueryResultsIterator<KeyModification> resultsIterator = stub.getHistoryForKey(key);
        Iterator<KeyModification> iter = resultsIterator.iterator();
 
        while(iter.hasNext())
        {
            if(shouldAddComma){
                strBuilder.append(",");
            }
            KeyModification kval = iter.next();
            strBuilder.append("{\"TxId\":\"" + kval.getTxId() + "\",\"Record\":" + kval.getStringValue() + ",\"Timestamp\":\""+ kval.getTimestamp() + "\",\"IsDeleted\":\"" + kval.isDeleted() + "\"}");
            _logger.info(String.format("result TxId: %s, value: %s", kval.getTxId(), kval.getStringValue()));
            shouldAddComma = true;
        }
        strBuilder.append("]");

        _logger.info("total result: " + strBuilder.toString());
        return newSuccessResponse(ByteString.copyFrom(strBuilder.toString(), UTF_8).toByteArray());
    }

    private Response GetRecordByKey(ChaincodeStub stub, List<String> args) {
        if (args.size() != 1) {
            return newErrorResponse("Incorrect number of arguments. Expecting name of the person to query");
        }
        String key = args.get(0);
        String val = stub.getStringState(key);
        if (val == null) {
            return newErrorResponse(String.format("Error: state for %s is null", key));
        }
        _logger.info(String.format("Query Response:\nName: %s, Amount: %s\n", key, val));
        return newSuccessResponse(val, ByteString.copyFrom(val, UTF_8).toByteArray());
    }

    // 二进制转换为字符串
    private static String BinToString(String binary) { 
        String[] tempStr = binary.split(" "); 
        char[] tempChar = new char[tempStr.length]; 
        for(int i = 0; i < tempStr.length; i++) { 
            tempChar[i] = BinstrToChar(tempStr[i]); 
        } 
        return String.valueOf(tempChar); 
    }

    //将二进制字符串转换成int数组   
    private static int[] BinstrToIntArray(String binStr) { 
        char[] temp = binStr.toCharArray(); 
        int[] result = new int[temp.length];  
        for(int i = 0; i < temp.length; i++) {  
            result[i] = temp[i] - 48;       
        } 
        return result; 
    }
    
    //将二进制转换成字符 
    private static char BinstrToChar(String binStr){ 
        int[] temp = BinstrToIntArray(binStr); 
        int sum = 0; 
        for(int i = 0; i < temp.length; i++){ 
            sum += temp[temp.length - 1 - i] << i; 
        } 
        return (char)sum; 
    }


    public static void main(String[] args) {
        System.out.println("OpenSSL avaliable: " + OpenSsl.isAvailable());
        new SimpleChaincode().start(args);
    }

}
