# COP5615P1
DOSP first project
## Goal
* SHA 256 implementation
* Supervisor Module
* Worker Module
* Distributed Implementation

### SHA256
To use it in the shell, compile it first and then type in the string you want to convert.
```
c(hashFunction).
hashFunction:encode("aayushsr").

Output:"09A8219370AB18746D44B54BF626B30605DB2CCB3FC52E4E3A58E63F336B4609"
```
### How to use
Only need to compile test.erl and master.erl. The rest of the files are references.  
## Example
```
//compile two file
c(master).
c(test).

//open two terminal windows or shells and type in following commands

//shell 1

erl -sname earth(random name)//your localhost will be something like earth@macbookpro if you are using mac, check it on your own

//shell 2
erl -sname moon

//shell 1
master:start(5).//how many zero ahead

//shell 2
test:start(earth@macbookpro).

```

# TODO:
* Expected input in the fsx file
* bentchmarking, CPU time and real time
* Readme file
 
### due on 09/24
