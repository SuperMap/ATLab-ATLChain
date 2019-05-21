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
            List<byte[]> paramsByte = stub.getArgs();
            if (func.equals("Put")) {
                return Put(stub, params);
            }
            if (func.equals("Get")) {
                return Get(stub, params);
            }
            if (func.equals("PutBin")) {
                return PutBin(stub, params);
            }
            if (func.equals("GetBin")) {
                return GetBin(stub, params);
            }
            if (func.equals("PutByteArray")) {
                return PutByteArray(stub, paramsByte);
            }
            if (func.equals("GetByteArray")) {
                return GetByteArray(stub, params);
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

    // API:Put records
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
    
    // Put byte array data to ledger
    private Response PutByteArray(ChaincodeStub stub, List<byte[]> args){
        int argsNeeded = 4;
        if (args.size() != 4){
            return newErrorResponse("Incorrect number of arguments. Expecting " + argsNeeded);
        }
        String putKey = args.get(0).toString();
        _logger.info("putKey:" + putKey);
        String binary = "PutByteArray";

        byte[] byteArray = args.get(1);
        _logger.info("byteArray:" + byteArray.toString());

        stub.putState(putKey, byteArray);
        _logger.info("Transfer complete");
        return newSuccessResponse("invoke finished successfully");
    }
    
    // Get byte array data from ledger
    private Response GetByteArray(ChaincodeStub stub, List<String> args) {
        if (args.size() != 1) {
            return newErrorResponse("Incorrect number of arguments. Expecting name of the person to query");
        }
        String key = args.get(0);
        byte[] byteArray = stub.getState(key);


        _logger.info("total result: " + byteArray.toString());
        return newSuccessResponse(byteArray);
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

    // Query callback representing the query of a chaincode
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

    // Query record by key, and change the binary string to string
    private Response GetBin(ChaincodeStub stub, List<String> args) {
        if (args.size() != 1) {
            return newErrorResponse("Incorrect number of arguments. Expecting name of the person to query");
        }
        String key = args.get(0);
        String val = stub.getStringState(key);
        String binVal = StrToBinstr(val);
        if (val == null) {
            return newErrorResponse(String.format("Error: state for %s is null", key));
        }
        _logger.info(String.format("Query Response:\nName: %s, Amount: %s\n", key, binVal));
        return newSuccessResponse(binVal, ByteString.copyFrom(binVal, UTF_8).toByteArray());
    }

    // API:Get the history of a key
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

    // API:Get record by key
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

    // Binary String to string
    private static String BinToString(String binary) { 
        String[] tempStr = binary.split(" "); 
        char[] tempChar = new char[tempStr.length]; 
        for(int i = 0; i < tempStr.length; i++) { 
            tempChar[i] = BinstrToChar(tempStr[i]); 
        } 
        return String.valueOf(tempChar); 
    }

    // Binary String to int array
    private static int[] BinstrToIntArray(String binStr) { 
        char[] temp = binStr.toCharArray(); 
        int[] result = new int[temp.length];  
        for(int i = 0; i < temp.length; i++) {  
            result[i] = temp[i] - 48;       
        } 
        return result; 
    }
    
    // Binary to char
    private static char BinstrToChar(String binStr){ 
        int[] temp = BinstrToIntArray(binStr); 
        int sum = 0; 
        for(int i = 0; i < temp.length; i++){ 
            sum += temp[temp.length - 1 - i] << i; 
        } 
        return (char)sum; 
    }

    // String to Binary String, splited by space
	private static String StrToBinstr(String str) {
		char[] strChar = str.toCharArray();
		String result = "";
		for (int i = 0; i < strChar.length; i++) {
			result += Integer.toBinaryString(strChar[i]) + " ";
		}
		return result;
	}

    public static void main(String[] args) {
        System.out.println("OpenSSL avaliable: " + OpenSsl.isAvailable());
        new SimpleChaincode().start(args);
    }

}
