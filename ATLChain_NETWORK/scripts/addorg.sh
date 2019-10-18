#!/bin/bash

peer channel fetch config config_block.pb -o orderer0.orga.example.com:7060 -c atlchannel --tls --cafile $ORDERER_CA

configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > "config.json"

jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"OrgC":.[1]}}}}}' config.json ./channel-artifacts/orgc.json > modified_config.json

configtxlator proto_encode --input config.json --type common.Config > orgginal_config.pb

configtxlator proto_encode --input modified_config.json --type common.Config > modified_config.pb

configtxlator compute_update --channel_id atlchannel --original orgginal_config.pb --updated modified_config.pb > config_update.pb

configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate > config_update.json

 echo '{"payload":{"header":{"channel_header":{"channel_id":"atlchannel", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json

configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope > orgc_update_in_envelope.pb

peer channel signconfigtx -f orgc_update_in_envelope.pb

peer channel update -f orgc_update_in_envelope.pb -c atlchannel -o orderer0.orga.example.com:7060 --tls --cafile $ORDERER_CA
