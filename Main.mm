#include <Cocoa/Cocoa.h>
#include <Metal/Metal.h>
#include <MetalKit/MetalKit.h>
#include <string>
id<MTLDevice> device;
id<MTLCommandQueue> commandQueue;
id<MTLRenderPipelineState> pipelineState;
@interface AppDelegate : NSObject <NSApplicationDelegate> @end
@implementation AppDelegate
- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSNotification *)sender { return YES; }
@end
@interface ViewDelegate : NSObject <MTKViewDelegate>
- (id) init:(MTKView *)view;
@end
@implementation ViewDelegate
- (id)init:(MTKView *)view {
    commandQueue = [device newCommandQueue];
    std::string shaders = R"(
    #include <metal_stdlib>
    using namespace metal;
    struct VertexIn {
        packed_float3 position;
        packed_float3 color;
    };
    struct VertexOut {
        float4 position [[position]];
        float4 color;
    };
    vertex VertexOut vertexMain(device const VertexIn *vertices [[buffer(0)]], uint vertexId [[vertex_id]]) { return {float4(vertices[vertexId].position, 1), float4(vertices[vertexId].color, 1)}; }
    fragment float4 fragmentMain(VertexOut in [[stage_in]]) { return in.color; })";
    id<MTLLibrary> library = [device newLibraryWithSource:@(shaders.c_str()) options: nil error: nil];
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.vertexFunction = [library newFunctionWithName:@"vertexMain"];
    pipelineStateDescriptor.fragmentFunction = [library newFunctionWithName:@"fragmentMain"];
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
    pipelineState = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error: nil];
    return self;
}
- (void)drawInMTKView:(MTKView *)view {
  id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
  MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
  id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor: renderPassDescriptor];
  float vertexData[3 * 6] = { -0.5, -0.5 , 0.0, 1.0, 1.0, 0.0, 0.5, -0.5 , 0.0, 0.0, 1.0, 1.0, 0.0,  0.5 , 0.0, 1.0, 0.0, 1.0 };
  [encoder setVertexBytes:&vertexData length:sizeof(vertexData) atIndex: 0];
  [encoder setRenderPipelineState:pipelineState];
  [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
  [encoder endEncoding];
  [commandBuffer presentDrawable: view.currentDrawable];
  [commandBuffer commit];
}
- (void) mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {}
@end
int main() {
  [NSApplication sharedApplication];
  [NSApp setDelegate: [AppDelegate alloc]];
  device = MTLCreateSystemDefaultDevice();
  NSWindow *window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0.0, 0.0, 800.0, 600.0) styleMask: NSWindowStyleMaskClosable | NSWindowStyleMaskTitled | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable backing: NSBackingStoreBuffered defer: NO];  
  MTKView *view = [[MTKView alloc] initWithFrame: CGRectMake(0.0, 0.0, 800.0, 600.0) device: device];
  view.delegate = [[ViewDelegate alloc] init: view];
  [window setContentView: view];
  [window center];
  [window makeKeyAndOrderFront: nil];
  [NSApp run];
}