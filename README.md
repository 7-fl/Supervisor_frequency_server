I added one supervisor process to the frequency server:

```
()   process
<->  link


(supervisor) trap server
     ^     
     |
     V     
  (server)   trap supervisor, client
   ^    ^  
   |    |
   V    | 
(client)|
        V
     (client)
```

  
