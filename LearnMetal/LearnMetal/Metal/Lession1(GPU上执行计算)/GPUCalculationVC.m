//
//  GPUCalculation.m
//  LearnMetal
//
//  Created by yfm on 2022/7/5.
//

/**
 GPU执行计算步骤：
 1、找到一个GPU；
 2、创建管道准备MSL（Metal shading Language）函数以在GPU运行；
 3、创建GPU可访问的数据对象；
 4、针对数据管道创建一个命令缓冲区；
 5、将命令写入其中；
 6、将缓冲区提交到命令队列。
 Metal将命令发送到GPU执行。
 
 Metal将其他与GPU相关的实体表示成对象，像着色器、内存缓冲、纹理等。
 通过调用MTLDevice的方法创建这些GPU的特定对象。由MTLDevice对象直接或间接创建的对象仅可以在此MTLDevice对象上作用。
 使用多个GPU的应用程序将使用多个MTLDevice对象，并为每个对象创建类似的Metal对象层次结构。
 */

#import "GPUCalculationVC.h"
#import <Metal/Metal.h>

const unsigned int arrayLength = 1 << 24;
const unsigned int bufferSize = arrayLength * sizeof(float);

@interface GPUCalculationVC () {
    id<MTLDevice> _mDevice; // GPU对象
    id<MTLComputePipelineState> _mAddFunctionPSO; // 管线：指定GPU为完成特定任务而执行的步骤
    id<MTLCommandQueue> _mCommandQueue; // 命令队列
    id<MTLBuffer> _mBufferA; // 缓冲区
    id<MTLBuffer> _mBufferB;
    id<MTLBuffer> _mBufferResult;
}
@end

@implementation GPUCalculationVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initDevice];
    [self prepareData];
    [self sendComputeCommand];
    NSLog(@"Execution finished");
}

#pragma mark - C compute
void add_arrays(const float* inA,
                const float* inB,
                float* result,
                int length) {
    for (int index = 0; index < length ; index++) {
        result[index] = inA[index] + inB[index];
    }
}

#pragma mark - metal compute
- (void)initDevice {
    /**
     当编译工程时，Xcode编译add_arrays函数并且将它加入到默认的Metal library
     */
    
    // 1、查找GPU，MTLDevice表示GPU的抽象，使用它与GPU通信。
    _mDevice = MTLCreateSystemDefaultDevice();
    
    NSError *error = nil;
    
    // 默认Metal函数库，加载工程中以.metal为后缀的shader文件
    id<MTLLibrary> defaultLibrary = [_mDevice newDefaultLibrary];
    if(defaultLibrary == nil) {
        NSLog(@"Failed to find the default library.");
        return;
    }
    
    // 加载函数准备在GPU上使用
    id<MTLFunction> addFunction = [defaultLibrary newFunctionWithName:@"add_arrays"];
    if(addFunction == nil) {
        NSLog(@"Failed to find the added function.");
        return;
    }
    
    // 创建计算管线（方法是同步执行的，不要在性能敏感的代码中同步创建管线对象）
    _mAddFunctionPSO = [_mDevice newComputePipelineStateWithFunction:addFunction error:&error];
    if(_mAddFunctionPSO == nil) {
        NSLog(@"Failed to created pipeline state object, error %@", error);
        return;
    }
    
    // 创建命令队列，Metal使用命令队列来调度命令。
    _mCommandQueue = [_mDevice newCommandQueue];
    if(_mCommandQueue == nil) {
        NSLog(@"Failed to find the command queue.");
        return;
    }
}

/**
 创建数据缓冲区并加载数据
 
 初始化Metal对象后，加载数据供GPU执行。
 GPU可以拥有自己的专门内存，也可以与操作系统共享内存。Metal和操作系统内核需要执行额外的工作才能让将
 数据存储在内存中并使这些数据可供GPU使用。Metal使用资源对象（MTLResource）抽象了这种内存管理。资源
 是GPU在运行命令时可访问的内存分配。使用MTLDevice为GPU创建资源。
 
 此示例中的资源是MTLBuffer对象，它们没有预定义格式的内存分配。Metal将每个缓冲区作为不透明的字节集合
 进行管理。但是，在着色器中使用缓冲区时要指定格式。这意味着着色器和应用程序要对来回传递的任何数据的格式
 达成一致。
 
 当分配一个缓冲区时，提供一种存储模式来确定它的一些特性是否可以使用CPU或GPU访问。此示例使用CPU和GPU
 都可以访问的共享内存（MTLResourceStorageModeShared）。
 */
- (void)prepareData {
    _mBufferA = [_mDevice newBufferWithLength:bufferSize options:MTLResourceStorageModeShared];
    _mBufferB = [_mDevice newBufferWithLength:bufferSize options:MTLResourceStorageModeShared];
    _mBufferResult = [_mDevice newBufferWithLength:bufferSize options:MTLResourceStorageModeShared];
    
    // 为A缓冲区生成随机数
    [self generateRandomFloatData:_mBufferA];
    // 为B缓冲区生成随机数
    [self generateRandomFloatData:_mBufferB];
}

- (void)sendComputeCommand {
    // 创建命令缓冲区
    id<MTLCommandBuffer> commandBuffer = [_mCommandQueue commandBuffer];
    assert(commandBuffer != nil);
    
    // 创建命令编码器（将命令写入命令缓冲区）
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    assert(computeEncoder != nil);
    
    // 对计算过程进行编码
    [self encodeAddCommand:computeEncoder];
    
    // 结束编码
    [computeEncoder endEncoding];
    
    // 提交到命令队列来运行命令缓冲区的命令
    [commandBuffer commit];
    
    // 使用waitUntilCompleted方法等待计算完成，或者通过addCompletedHandler:status方法监听执行完成的回调
    [commandBuffer waitUntilCompleted];
    
    [self verifyResults];
}

// 对计算过程进行编码。计算通道包含执行计算管线的命令列表。每个计算命令都会使GPU创建一个线程网格在GPU执行
- (void)encodeAddCommand:(id<MTLComputeCommandEncoder>)computeEncoder {
    // 编码器将所有状态变化和命令参数写入命令缓冲区
    [computeEncoder setComputePipelineState:_mAddFunctionPSO]; // 管线状态
    [computeEncoder setBuffer:_mBufferA offset:0 atIndex:0]; // 参数
    [computeEncoder setBuffer:_mBufferB offset:0 atIndex:1];
    [computeEncoder setBuffer:_mBufferResult offset:0 atIndex:2];
        
    // 创建一维网格
    MTLSize gridSize = MTLSizeMake(arrayLength, 1, 1);
    
    // 指定线程数
    NSUInteger threadGroupSize = _mAddFunctionPSO.maxTotalThreadsPerThreadgroup;
    if(threadGroupSize > arrayLength) {
        threadGroupSize = arrayLength;
    }
    MTLSize threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);
    
    // 对命令进行编码以调度线程网格
    [computeEncoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
}

- (void)generateRandomFloatData:(id<MTLBuffer>)buffer {
    float* dataPtr = buffer.contents;
    
    for(unsigned long index = 0; index < arrayLength; index++) {
        dataPtr[index] = (float)rand()/(float)(RAND_MAX);
    }
}

- (void)verifyResults {
    // 从缓冲区获取GPU的计算值
    float* a = _mBufferA.contents;
    float* b = _mBufferB.contents;
    float* result = _mBufferResult.contents;
    
    for(unsigned long index = 0; index < arrayLength; index++) {
        // GPU的计算结果是否与CPU计算的结果相同
        if (result[index] != (a[index] + b[index])) {
            // 如果计算结果不相同分别打印GPU和CPU的计算结果，中断执行
            printf(@"Compute ERROR: index=%lu result=%g vs %g=a+b\n",
                   index, result[index], a[index] + b[index]);
            assert(result[index] == (a[index] + b[index]));
        }
    }
}

#pragma mark -
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
