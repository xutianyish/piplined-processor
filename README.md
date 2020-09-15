# piplined-processor
This project is a pipelined processor consisting of four stages: fetch, decode, execute and write back.

## implementation details
The pipelined processor has two instuction cache. One predicts the next instruction for all branch instructions.
The other predicts whether the next instruction is a branch instruction. 

## Performance
IPC: 1.5</br>
Fmax: 200MHz on cycloneV FPGA

## Note
To prevent academic offence, only part of the code is committed
