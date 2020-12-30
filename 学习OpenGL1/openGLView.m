

//
//  openGLView.m
//  学习OpenGL1
//
//  Created by liter on 16/10/20.
//  Copyright © 2016年 liter. All rights reserved.
//

#import "openGLView.h"
#import <OpenGLES/ES2/gl.h>
#import "GLProgram.h"

@interface openGLView ()

@property(nonatomic , strong) CAEAGLLayer *myLayer;
@property(nonatomic , strong) EAGLContext *myContext;


@property(nonatomic , strong) GLProgram *myProgram;

@property(nonatomic , assign) GLuint myRenderBuffer;
@property(nonatomic , assign) GLuint myFrameBuffer;

@property(nonatomic , assign) GLuint glTexture;

@end

@implementation openGLView
{
    GLuint textureUniform ;
}
+ (Class)layerClass {
    return [CAEAGLLayer class];
}


- (void)customInit{
    [self setupLayer];
    [self setupContext];
    [self destoryRenderAndFrameBuffer];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self setupProgram];
    [self setupData];
    [self setupDraw:[UIImage imageNamed:@"2"]];
}
- (void)setupDraw:(UIImage *)image{
    [self setupTexture:image];
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.glTexture);
    glUniform1i(textureUniform, 0);
    
    
    glClearColor(0, 0, 0, 0.0);
    glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
}

//- (void)setImageBuffer:(CVPixelBufferRef) bufferRef {
//    CGFloat width = CVPixelBufferGetWidth(bufferRef);
//    CGFloat height = CVPixelBufferGetHeight(bufferRef);
//
//    CFTypeRef colorAtachments = CVBufferGetAttachment(bufferRef, kCVImageBufferYCbCrMatrixKey, NULL);
//    CVReturn err;
//    glActiveTexture(GL_TEXTURE0);
//    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
//    _videoTextureCache,
//    bufferRef,
//    NULL,
//    GL_TEXTURE_2D,
//    GL_RED_EXT,
//    width,
//    height,
//    GL_RED_EXT,
//    GL_UNSIGNED_BYTE,
//    0, &_glTexture);
//
//}






- (UIImage *)getImagefromScreen{
    
    glFinish();
    CGFloat dataWidth = self.frame.size.width*[[UIScreen mainScreen] scale];
    CGFloat dataHeight = self.frame.size.height*[[UIScreen mainScreen] scale];

    GLint pixelDataLength =dataHeight*dataWidth*4;
    GLubyte* pPixelData = (GLubyte *)malloc(pixelDataLength *sizeof(GLubyte));
    glPixelStorei(GL_PACK_ALIGNMENT, 4);

    glReadPixels(0, 0,dataWidth,dataHeight, GL_RGBA,GL_UNSIGNED_BYTE,  pPixelData);

    CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, pPixelData, pixelDataLength, NULL);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();

    CGImageRef iref = CGImageCreate(dataWidth, dataHeight, 8, 32, dataWidth * 4,  CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,
                                    ref, NULL, true, kCGRenderingIntentDefault);

    UIImage *finalImage = [UIImage imageWithCGImage:iref ];

    CGImageRelease(iref);
    CGDataProviderRelease(ref);
    CGColorSpaceRelease(colorspace);
    
    return finalImage;

}
- (void)setupTexture:(UIImage *)image{
    glDeleteTextures(1, &_glTexture);
    // 1获取图片的CGImageRef
    CGImageRef spriteImage = image.CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image " );
        exit(1);
    }
    
    // 2 读取图片的大小
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte * spriteData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte)); //rgba共4个byte
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,
                                                       CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    //翻转图片
//        CGContextClearRect( spriteContext, CGRectMake( 0, 0, width, height ) );
//        CGContextTranslateCTM (spriteContext, 0, height);
//        CGContextScaleCTM (spriteContext, 1.0, -1.0);
    
    // 3在CGContextRef上绘图
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    
    glActiveTexture(GL_TEXTURE0);
    glEnable(GL_TEXTURE_2D);
    glGenTextures(1, &_glTexture);
    glBindTexture(GL_TEXTURE_2D, _glTexture);
    
    
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    float fw = width, fh = height;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);

}

- (void)setupData{
    GLuint position = [_myProgram attributeIndex:@"position"];
    GLuint textcoordinate = [_myProgram attributeIndex:@"textCoordinate"];
    
    textureUniform = [_myProgram uniformIndex:@"myTexture"];
    
    
    [self.myProgram use];
    glEnableVertexAttribArray(position);
    glEnableVertexAttribArray(textcoordinate);
    
    
    //2 顶点位置 2 纹理坐标
    //前两个是顶点坐标【笛卡尔坐标系，原点是屏幕中心点】， 后面两个是纹理坐标【与屏幕坐标类似（镜像关系），原点是屏幕左下角】
    //openGL顶点位置坐标 【笛卡尔坐标系，原点是屏幕中心点】注意点：坐标被映射到（-1, 1）之间
    //openGL纹理位置坐标 【与屏幕坐标类似（镜像关系），原点是屏幕左下角】注意点：坐标被映射到（0, 1）之间（有上下翻转操作【1.处理图片 2.处理纹理坐标】）
    //iOS屏幕位置坐标    【屏幕坐标系，原点在屏幕左上角】
    GLfloat attrArr[] =
    {
        -0.5f, 0.5f, 0.0f, 0.0f,//左上-左下
        0.5f, 0.5f, 1.0f, 0.0f,//右上-右下
        -0.5f, -0.5f, 0.0, 1.0f,//左下-左上
        0.5f, -0.5f, 1.0f, 1.0f,//右下-右上
    };
    
    //翻转图片
//        CGContextClearRect( spriteContext, CGRectMake( 0, 0, width, height ) );
//        CGContextTranslateCTM (spriteContext, 0, height);
//        CGContextScaleCTM (spriteContext, 1.0, -1.0);
    
    GLuint attrBuffer;
    /// 申请标识符 1是数量 第二个参数是一个指针 ，指向生成的标识符的内存保持位置
    glGenBuffers(1, &attrBuffer);
    /// 绑定
    /*
     第一个参数是一个常量 指定要绑定的是哪一种缓存 有2个GL_ARRAY_BUFFER 和GL_ELEMENT_ARRAY_BUFFER  GL_ARRAY_BUFFER 用于指定一个顶点数组
    
     第二个参数 是要绑定的缓存的标识符
     */
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    /// 申请 内存空间
    /*
     复制应用的顶点数据到当前上下文所 定的顶点缓 存中。 
     第一个参数用于指定要更新当前上下文中所绑定的是哪一个缓存
     第二个参数指定要复制进这个缓存字节的数量
     第三个参数是要复制的字节地址
     第四个参数提示了缓存在未来的运算中可能被怎样使用GL_STATIC_ DRAW 提示会告诉上下文,缓存中的内容适合复制到 GPU  制的内存,因为很少对其 进行 改。这个信息可以帮助 OpenGL ES 优化内存使用。使用 GL_DYNAMIC_DRAW 作为提示会告诉上下文,缓存内的数据会频繁改变,同时提示 OpenGL ES 以不同的方 式来处理缓存的存 。
     */
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_STATIC_DRAW);
    
    glVertexAttribPointer(position, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*4, NULL);
    glEnableVertexAttribArray(position);
    
    glVertexAttribPointer(textcoordinate, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*4, (float *)NULL +2);
    glEnableVertexAttribArray(textcoordinate);
    
    
}

- (void)setupProgram{
    
    CGFloat scale =[[UIScreen mainScreen] scale];
    /*
     X，Y————以像素为单位，指定了视口的左下角（在第一象限内，以（0，0）为原点的）位置。
     width，height————表示这个视口矩形的宽度和高度，根据窗口的实时变化重绘窗口。
     */
    glViewport(0, 0, self.frame.size.width*scale, self.frame.size.height*scale);

    NSString *vsh = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"];
    NSString *fsh = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"fsh"];
    _myProgram = [[GLProgram alloc] initWithVertexShaderString:[NSString stringWithContentsOfFile:vsh encoding:NSUTF8StringEncoding error:nil] fragmentShaderString:[NSString stringWithContentsOfFile:fsh encoding:NSUTF8StringEncoding error:nil]];
    
    if (self.myProgram.initialized == NO ) {
        [_myProgram addAttribute:@"position"];
        [_myProgram addAttribute:@"textCoordinate"];
        if ([_myProgram link] == NO) {
            NSLog(@"错误");
            exit(0);
        }
    }
}

- (void)setupFrameBuffer{
    glGenFramebuffers(1, &_myFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _myFrameBuffer);
    /// 将renderbuffer装配到GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _myRenderBuffer);
}
- (void)setupRenderBuffer{
    /// 申请缓存 标识符
    glGenRenderbuffers(1, &_myRenderBuffer);
    /// 绑定  告诉OpenGLes 为接下来的运算使用一个缓存
    glBindRenderbuffer(GL_RENDERBUFFER, _myRenderBuffer);
    /// 为颜色缓存区 分配存储空间
    [_myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_myLayer];
}

- (void)destoryRenderAndFrameBuffer{
    glDeleteBuffers(1, &_myFrameBuffer);
    _myFrameBuffer = 0;
    glDeleteBuffers(1, &_myRenderBuffer);
    _myRenderBuffer = 0;
}

- (void)setupContext{
    _myContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    /// 设置为当前上下文
    [EAGLContext setCurrentContext:_myContext];
}


- (void)setupLayer{
    _myLayer = (CAEAGLLayer *)self.layer;
    /// 放大倍数
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    /// 不透明
    _myLayer.opaque = NO;
    /// 设置描绘属性
    _myLayer.drawableProperties =[NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}





@end






























