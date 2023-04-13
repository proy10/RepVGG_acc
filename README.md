# Plan
Implement a block of RepVGG. The implement of convolution layer can refer to "*VWA: Hardware Efficient Vectorwise Accelerator for Convolutional Neural Network*".  
### Hardware  
tree adder; fix point multiplier;  

# Design
## 1. (Data Reuse)conv3\*3 and conv1\*1 use different module 
Use 8 PEs for 3\*3 conv. The PE is a 7\*3 array, hence 8 PEs consist of a 56\*3 array. A 3\*3 PE computes MAC of 3 weights and 7 data of feature map at a time, so this array can complete 1 column of kernel(3 weights) and 1 column of feature map(56 data) in one cycle.  
### HOW TO DEAL PADDING?  
Buffer1 stores the sum of product of the 2nd weight and the 1st feature and the product of 3rd weight and 2nd feature. It's equal to that the 1st weight multiplie zero, which is the padding. It's the same with Buffer7. 
As a result, take padding into consideration, it takes 3\*56-2 cycles for one channel of feature map to complete 3\*3 conv(don't consider the cost for sum).  

Use 8 PEs for 1*1 conv. It takes 56 cycles for one channel.  

We use a ser2par module and a par2ser module to process feature map input and output. For a ser2par module, its memory capacity is 56\*4B=224B.   
We use a reg of 9\*4B=36B to store 3\*3 kernel weights.  

## 2. (Module Reuse)conv3\*3 and conv1*1 use the same module(VWA) 
Use 8 general PEs, which can process both 3\*3 conv and 1\*1 conv.  


