const ipfsAPI = require('ipfs-api')
const fs = require("fs")
const path = require("path")

class Ipfs {

    constructor(ip) {
        this.ipfsClient = ipfsAPI(ip, '5001', { protocol: 'http' })
    }

    add(filePath, callback) {
        var data = fs.readFileSync(filePath);
        var extname = path.extname(filePath);
        var buffer = Buffer.from(data.toString());
        this.ipfsClient.add(buffer)
            .then(rsp => callback(rsp[0].path))
            .catch(err => console.error(err))
        return extname;
    }

    cat(hash) {
        this.ipfsClient.cat(hash, function (err, content) {
            if (err) {
                throw err
            }
            console.log(content.toString('utf8'));
        })
    }

    get(hash, savePath, extname) {
        this.ipfsClient.get(hash, function (err, files) {
            files.forEach((file) => {
                fs.writeFile(savePath + extname, file.content.toString('utf8'), function (err) {
                    if (err) {
                        throw err
                    }
                });
            })
        })
    }

    addPin(hash) {
        this.ipfsClient.pin.add(hash, function (err) {
            if (err) {
                throw err
            }
         })
    }

    rmPin(hash) {
        this.ipfsClient.pin.rm(hash, function (err, pinset) {
            if (err) {
                throw err
            }
        })
    }
}
module.exports = Ipfs;
