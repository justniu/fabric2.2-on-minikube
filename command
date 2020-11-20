cryptogen generate --config=./crypto-config.yaml


configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock ./channel-artifacts/genesis.block
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID "mychannel"
onfigtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/org1Anchors.tx  -channelID "mychannel" -asOrg Org1MSP
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/org2Anchors.tx  -channelID "mychannel" -asOrg Org2MSP


kubectl get po -n hyperledger

peer channel create -o orderer:7050 -c mychannel -f ./scripts/channel-artifacts/channel.tx --tls true --cafile $ORDERER_CA


peer channel fetch 0 mychannel.block -c mychannel -o orderer:7050 --tls --cafile $ORDERER_CA
peer channel join -b mychannel.block
peer lifecycle chaincode package marble.tar.gz --path /opt/gopath/src/github.com/marbles/mycc/go/ --lang golang --label marblesp_v1
peer lifecycle chaincode install marble.tar.gz


peer lifecycle chaincode approveformyorg -o orderer:7050 --ordererTLSHostnameOverride orderer --channelID mychannel --name marblesp --version 1.0 --collections-config /opt/gopath/src/github.com/marbles/mycc/collections_config.json --signature-policy "OR('Org1MSP.member','Org2MSP.member')" --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile $ORDERER_CA

peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name marblesp --version 1.0 --sequence 1 --tls --cafile $ORDERER_CA --output json



peer lifecycle chaincode commit -o orderer:7050 --ordererTLSHostnameOverride orderer --channelID mychannel --name marblesp --version 1.0 --sequence 1 --tls --cafile $ORDERER_CA --peerAddresses peer0-org1:7051 --tlsRootCertFiles ${PWD}/crypto/peerOrganizations/org1/peers/peer0-org1/tls/ca.crt --peerAddresses peer0-org2:9051 --tlsRootCertFiles ${PWD}/crypto/peerOrganizations/org2/peers/peer0-org2/tls/ca.crt

