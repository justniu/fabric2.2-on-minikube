### generate msp materials and channel configtx

cryptogen generate --config=./crypto-config.yaml


configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock ./channel-artifacts/genesis.block
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID "mychannel"
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/org1Anchors.tx  -channelID "mychannel" -asOrg Org1MSP
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/org2Anchors.tx  -channelID "mychannel" -asOrg Org2MSP


kubectl get po -n hyperledger

peer channel create -o orderer:7050 -c mychannel -f ./scripts/channel-artifacts/channel.tx --tls true --cafile $ORDERER_CA


peer channel fetch 0 mychannel.block -c mychannel -o orderer:7050 --tls --cafile $ORDERER_CA
peer channel join -b mychannel.block

### 更新锚节点
peer channel update -o orderer:7050 --ordererTLSHostnameOverride orderer -c mychannel -f ./scripts/channel-artifacts/org1Anchors.tx --tls --cafile $ORDERER_CA
peer channel update -o orderer:7050 --ordererTLSHostnameOverride orderer -c mychannel -f ./scripts/channel-artifacts/org2Anchors.tx --tls --cafile $ORDERER_CA


### without private data collections
peer lifecycle chaincode package fabcar.tar.gz --path /opt/gopath/src/github.com/marbles/fabcar/go/ --lang golang --label fabcar_1

peer lifecycle chaincode install fabcar.tar.gz


export CC_PACKAGE_ID=fabcar_1:ce2aac24e943dcc809a4451569dc17e89b85b0a727aa2aa3aefd3bccbf5edc58
peer lifecycle chaincode approveformyorg -o orderer:7050 --ordererTLSHostnameOverride orderer --channelID mychannel --name fabcar --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile $ORDERER_CA


peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name fabcar --version 1.0 --sequence 1 --tls --cafile $ORDERER_CA --output json

### commit to channel 
peer lifecycle chaincode commit -o orderer:7050 --ordererTLSHostnameOverride orderer --channelID mychannel --name fabcar --version 1.0 --sequence 1 --tls --cafile $ORDERER_CA --peerAddresses peer0-org1:7051 --tlsRootCertFiles ${PWD}/crypto/peerOrganizations/org1/peers/peer0-org1/tls/ca.crt --peerAddresses peer0-org2:9051 --tlsRootCertFiles ${PWD}/crypto/peerOrganizations/org2/peers/peer0-org2/tls/ca.crt

peer lifecycle chaincode querycommitted --channelID mychannel --name fabcar --cafile $ORDERER_CA

## invoke
peer chaincode invoke -o orderer:7050 --ordererTLSHostnameOverride orderer --tls --cafile $ORDERER_CA -C mychannel -n fabcar --peerAddresses peer0-org1:7051 --tlsRootCertFiles ${PWD}/crypto/peerOrganizations/org1/peers/peer0-org1/tls/ca.crt --peerAddresses peer0-org2:9051 --tlsRootCertFiles ${PWD}/crypto/peerOrganizations/org2/peers/peer0-org2/tls/ca.crt -c '{"function":"initLedger","Args":[]}'


peer chaincode query -C mychannel -n fabcar -c '{"Args":["queryAllCars"]}'




### with private data collections
peer lifecycle chaincode package marblespv.tar.gz --path /opt/gopath/src/github.com/marbles/mycc/go/ --lang golang --label marblespv1
peer lifecycle chaincode install marblespv.tar.gz

export CC_PACKAGE_ID=marblespv1:c23a0cc4d2117dab456b616a55b48c5858c6c3d5a6532d85eb84edf886a9e686

peer lifecycle chaincode approveformyorg -o orderer:7050 --ordererTLSHostnameOverride orderer --channelID mychannel --name marblesp --version 1.0 --collections-config /opt/gopath/src/github.com/marbles/mycc/collections_config.json --signature-policy "OR('Org1MSP.member','Org2MSP.member')" --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile $ORDERER_CA

peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name marblesp --version 1.0 --sequence 1 --collections-config /opt/gopath/src/github.com/marbles/mycc/collections_config.json --signature-policy "OR('Org1MSP.member','Org2MSP.member')" --tls --cafile $ORDERER_CA --output json



peer lifecycle chaincode commit -o orderer:7050 --ordererTLSHostnameOverride orderer --channelID mychannel --name marblesp --version 1.0 --sequence 1 --collections-config /opt/gopath/src/github.com/marbles/mycc/collections_config.json --signature-policy "OR('Org1MSP.member','Org2MSP.member')" --tls --cafile $ORDERER_CA --peerAddresses peer0-org1:7051 --tlsRootCertFiles ${PWD}/crypto/peerOrganizations/org1/peers/peer0-org1/tls/ca.crt --peerAddresses peer0-org2:9051 --tlsRootCertFiles ${PWD}/crypto/peerOrganizations/org2/peers/peer0-org2/tls/ca.crt

peer lifecycle chaincode querycommitted --channelID mychannel --name marblesp --cafile $ORDERER_CA

export DATA=$(echo -n "{\"key\":\"name\",\"value\":\"niuzhuang\"}" | base64 | tr -d \\n)
peer chaincode invoke -o orderer:7050 --ordererTLSHostnameOverride orderer --tls --cafile $ORDERER_CA -C mychannel -n marblesp -c '{"Args":["publicAsset"]}' --transient "{\"Data\":\"$DATA\"}"

export DATA=$(echo -n "{\"key\":\"passwd\",\"value\":\"iamn\"}" | base64 | tr -d \\n)
peer chaincode invoke -o orderer:7050 --ordererTLSHostnameOverride orderer --tls --cafile $ORDERER_CA -C mychannel -n marblesp -c '{"Args":["privateAsset"]}' --transient "{\"Data\":\"$DATA\"}"


peer chaincode query -C mychannel -n marblesp -c '{"Args":["readPrivateAsset","passwd"]}'
peer chaincode query -C mychannel -n marblesp -c '{"Args":["readPublicAsset","name"]}'
