package main

import(
    // "fmt"
    "strings"
    "crypto/sha256"
    // "encoding/json"
    // "encoding/pem"
    // "crypto/ecdsa"
)

//TODO verify record signature
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
