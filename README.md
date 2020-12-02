# fabric2.2-on-minikube
deploy fabric2.2.0 on minikube(v1.13.0,aliyun edition)

## tips
when you want to mount host path to minikube vm, you need exec `minikube mount "</hostpaht>:</hostname>"`in another shell and maintain it during your minikube runtime.
in china,docker resource may blocked  
`minikube start --registry-mirror=https://4y7mtmnv.mirror.aliyuncs.com` add aliyun docker accelerate service

## reference
[hyperledger fabric](https://hyperledger-fabric.readthedocs.io/en/release-2.2/test_network.html)
