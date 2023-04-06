#note
实验仿真用的sram模型sirv_sim_ram.v放在general/目录下；
这两个文件是综合用的sram模型，综合时将仿真模型替换成综合模型，并读入两个sram的db文件；
其他相关参数参考library中两个sram的lib文件；
综合与物理设计时，sram均作为macro处理，故在物理设计阶段，需要在sram周围设置keepout margin以及dont touch；
