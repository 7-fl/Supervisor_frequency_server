I added one supervisor process to the frequency server:

```
()   process
<->  link


(supervisor) trap server 'EXIT'
     ^     
     |
     V     
  (server)   trap supervisor, client 'EXIT'
   ^    ^  
   |    |
   V    | 
(client)|
        V
     (client)
```

### Observer results:

* **Kill supervisor**:  Server receives 'EXIT' message from supervisor, and the server executes `exit(shutdown)`, which kills itself
                  as well as the clients `link()`ed to the server. 
                 
* **Kill server**:      The clients that are linked to the server are killed.  The supervisor receives an 'EXIT' message 
                  from the server and in response the supervisor starts a new server and registers it under the same name
                  as the old server. 

* **Kill client**:      The server receives an 'EXIT' message from the client and deallocates any frequency held by that client.


### Potential Problems:  
If the server is killed, a client without a frequency will remain alive, and it could send an allocate request to the server while the server is down causing the client to crash.

I did not understand the "discussion" about the state of the server.  If the server is killed directly it can't execute any code to preserve state or otherwise.  If the server is killed indirectly, it deallocates any frequency
