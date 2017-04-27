I added one supervisor process to the frequency server:

```
()   process
<->  link


(supervisor) trap 'EXIT' from server
     ^     
     |
     V     
  (server)   trap 'EXIT' from supervisor, client
   ^    ^  
   |    |
   V    | 
(client)|
        V
     (client)
```

### Observer results:

* **Kill supervisor**:  Because the server is linked to the supervisor and the server is trapping exits, the server receives an 'EXIT' message from the supervisor.  In response to the 'EXIT' message, the server executes `exit(shutdown)`, which kills itself, and because the clients are linked to the server, the clients are sent an exit signal and immediately die. 
                 
* **Kill server**:      The clients that are linked to the server are killed.  Because the supervisor is linked to the server and the supervisor is trapping exits, the supervisor receives an 'EXIT' message from the server.  In response to the 'EXIT' message, the supervisor starts a new server and registers it under the same name as the old server. 

* **Kill client**:      Because the client is linked to the server and the server is trapping exits, the server receives an 'EXIT' message from the client and deallocates any frequency held by that client.


### Potential Problems:  
If the server is killed, a client without a frequency will remain alive, and the client could send an allocate request to the server while the server is down causing the client to crash.

I did not understand the "discussion" about the state of the server.  As far as I can tell,  when the server dies the state of the server is exactly the same as the state of the server when it was initially started, so I didn't take any special steps when restarting the server.
