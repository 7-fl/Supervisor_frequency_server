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

  
