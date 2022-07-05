//
//  Add.metal
//  LearnMetal
//
//  Created by yfm on 2022/7/5.
//

/**
 kernel关键字声明函数为：
 1、一个公共GPU功能。公共函数是您的应用程序可以看到的唯一函数。公共函数不能被其他着色器函数调用。
 2、计算函数（也称为计算内核），它使用线程网格执行并行计算。
 
 device关键字表示指针的内存地址，MSL为内存定义了几个不想交的地址空间。每当在MSL中声明一个指针时，必须提供一个关键字来声明它的地址空间。
 使用地址空间来声明GPU可以读取和写入的持久内存。
 
 下面程序将被计算网格中的多个线程调用。此示例创建与数字尺寸完全匹配的一维线程网格，因此数组中的每个条目都将在不同的线程计算。
 每个值都是独立的，因此可以安全地同时计算这些值。
 */

#include <metal_stdlib>
using namespace metal;

kernel void add_arrays(device const float* inA,
                       device const float* inB,
                       device float* result,
                       uint index [[thread_position_in_grid]]) {
    result[index] = inA[index] + inB[index];
}
