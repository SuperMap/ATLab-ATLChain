package org.hyperledger.fabric.example;

import java.util.Iterator;
import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import com.google.protobuf.ByteString;
import io.netty.handler.ssl.OpenSsl;
import org.hyperledger.fabric.shim.ChaincodeBase;
import org.hyperledger.fabric.shim.ChaincodeStub;
import org.hyperledger.fabric.shim.ledger.KeyModification;
import org.hyperledger.fabric.shim.ledger.KeyValue;
import org.hyperledger.fabric.shim.ledger.QueryResultsIterator;
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
                return Put(stub, params, paramsByte);
            }
            if (func.equals("Get")) {
                return Get(stub, params);
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
    private Response Put(ChaincodeStub stub, List<String> args, List<byte[]> argsByte){
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
        return newSuccessResponse("invoke finished successfully. ");
    }
    
    // Put byte array data to ledger
    private Response PutByteArray(ChaincodeStub stub, List<byte[]> args){
        int argsNeeded = 4;
        if (args.size() != 4){
            return newErrorResponse("Incorrect number of arguments. Expecting " + argsNeeded);
        }
        String putKey = new String(args.get(0));
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


        _logger.info("total result: " + new String(byteArray));
        return newSuccessResponse(byteArray);
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

    // ============================== FastDFS Start ================================

    // private String fastDFSUploadFile(byte[] fileContent, String fileExtName) {
	// 	String fileIds[] = new String[2];
    //     StorageServer storageServer = null;
    //     TrackerServer trackerServer = null;
	// 	try {
    //         _logger.info("confURL.toString(): ");
	// 		// ClientGlobal.init(confURL.toURI().toString());
	// 		ClientGlobal.init("/fdfs_client.conf");
	// 		TrackerClient tracker = new TrackerClient();
	// 		trackerServer = tracker.getConnection();
	// 		StorageClient storageClient = new StorageClient(trackerServer, storageServer);
	// 		fileIds = storageClient.upload_file(fileContent, fileExtName, null);
	// 		if (fileIds == null) {
	// 			return "DFSUploadFile failed";
	// 		}
	// 	} catch (Exception e) {
	// 		e.printStackTrace();
	// 	} finally {
	// 		try {
	// 			if (storageServer != null)
	// 				storageServer.close();
	// 			if (trackerServer != null)
	// 				trackerServer.close();
	// 		} catch (IOException e) {
	// 			e.printStackTrace();
	// 		}
	// 	}
	// 	return "uploadfile path:" + fileIds[0] + "/" + fileIds[1];
	// }

	// private Response fastDFSDownloadFile(ChaincodeStub stub, List<String> args) { // 下载文件
	// 	if (args.size() != 3) {
	// 		return newErrorResponse("Incorrect number of arguments. Expecting 3");
	// 	}
	// 	TrackerServer trackerServer = null;
	// 	StorageServer storageServer = null;
	// 	String groupId = args.get(0);
	// 	String filepath = args.get(1);
	// 	String storePath = args.get(2);
	// 	try {
	// 		ClientGlobal.init(conf_filename);
	// 		TrackerClient tracker = new TrackerClient();
	// 		trackerServer = tracker.getConnection();
	// 		StorageClient storageClient = new StorageClient(trackerServer, storageServer);
	// 		byte[] bytes = storageClient.download_file(groupId, filepath);
	// 		if (bytes == null) {
	// 			newErrorResponse("DownloadFile is failed");
	// 		}
	// 		OutputStream out = new FileOutputStream(storePath);
	// 		out.write(bytes);
	// 		out.close();
	// 	} catch (Exception e) {
	// 		e.printStackTrace();
	// 	} finally {
	// 		try {
	// 			if (storageServer != null)
	// 				storageServer.close();
	// 			if (trackerServer != null)
	// 				trackerServer.close();
	// 		} catch (IOException e) {
	// 			// TODO Auto-generated catch block
	// 			e.printStackTrace();
	// 		} catch (Exception e) {
	// 			e.printStackTrace();
	// 		}
	// 	}
	// 	return newSuccessResponse("download file sucessful!");
	// }

	// public static Response fastDFSDeleteFile(ChaincodeStub stub, List<String> args) { // 删除文件
	// 	if (args.size() != 2) {
	// 		return newErrorResponse("Incorrect number of arguments. Expecting 2");
	// 	}
	// 	TrackerServer trackerServer = null;
	// 	StorageServer storageServer = null;
	// 	String groupId = args.get(0);
	// 	String Filepath = args.get(1);
	// 	Response deletemessage = newSuccessResponse("delete file failed");
	// 	int i = 0;
	// 	try {
	// 		ClientGlobal.init(conf_filename);
	// 		TrackerClient tracker = new TrackerClient();
	// 		trackerServer = tracker.getConnection();
	// 		StorageClient storageClient = new StorageClient(trackerServer, storageServer);
	// 		i = storageClient.delete_file(groupId, Filepath);
	// 	} catch (Exception e) {
	// 		e.printStackTrace();
	// 	} finally {
	// 		try {
	// 			if (storageServer != null)
	// 				storageServer.close();
	// 			if (trackerServer != null)
	// 				trackerServer.close();
	// 		} catch (IOException e) {
	// 			// TODO Auto-generated catch block
	// 			e.printStackTrace();
	// 		}
	// 	}
	// 	if (i == 0) {
	// 		deletemessage = newSuccessResponse("delete file sucessful!");
	// 	}
	// 	return deletemessage;
	// }

    // ============================== FastDFS End ================================

    public static void main(String[] args) {
        System.out.println("OpenSSL avaliable: " + OpenSsl.isAvailable());
        new SimpleChaincode().start(args);
    }

}
