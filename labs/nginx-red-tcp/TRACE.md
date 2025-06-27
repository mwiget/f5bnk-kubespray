## Packet capture of a web request

Taken on enp193s0f1np1:

```
ip -br a |grep enp

enp193s0f0np0    UP             192.0.2.62/24 fe80::5e25:73ff:fee6:3844/64 
enp193s0f1np1    UP             198.18.100.62/24 fe80::5e25:73ff:fee6:3845/64 
```

```
kubectl get services -n red

NAME                 TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE                                                                              
nginx-app-nodeport   NodePort   10.43.244.154   <none>        80:30080/TCP   5s                                                                               

ssh lake1 curl http://198.19.19.50                                                                                                                                                              
Test with curl from client lake1 ...                                                                                                                          
                                                                                                                                                              
HTTP/1.1 200 OK                                                                                                                                               
Server: nginx/1.27.5                                                                                                                                          
Date: Wed, 21 May 2025 05:49:04 GMT                                                                                                                           
Content-Type: text/html                                                                                                                                       
Content-Length: 615                                                                                                                                           
Last-Modified: Wed, 16 Apr 2025 12:01:11 GMT                                                                                                                  
Connection: keep-alive                                                                                                                                        
ETag: "67ff9c07-267"                                                                                                                                          
Accept-Ranges: bytes                                                                                                                                          
                                                                                                                                                              


Downloading 512kb payload from 198.18.100.62 ...

ssh lake1 curl http://198.19.19.50/test/512kb

Time: 0.002354s
Speed: 222722175 bytes/s
```

```
tcpdump -n -i enp193s0f1np1 -s0 -w tcp.pcap
tcpdump: listening on enp193s0f1np1, link-type EN10MB (Ethernet), snapshot length 262144 bytes
^C90 packets captured
90 packets received by filter
0 packets dropped by kernel
```

Analyze with tshark:

```
tshark -r tcp.pcap -Y 'http.request.method == "GET" || http.request.method == "HEAD"' -T fields -e ip.src -e ip.dst -e http.host -e http.request.uri
198.18.100.201  10.42.253.139   198.19.19.50    /
198.18.100.201  10.42.253.157   198.19.19.50    /test/512kb
```
