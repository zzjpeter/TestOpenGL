//
//  openGLController.m
//  学习OpenGL1
//
//  Created by liter on 16/10/20.
//  Copyright © 2016年 liter. All rights reserved.
//


//// 生成（Generate） 绑定(bind) 缓存数据(buffer data) 启用(enable)/禁止(disable) 设置指针(set pointers) 绘图(draw) 删除(dekete)
#import "openGLController.h"


@interface openGLController ()

@property(nonatomic , strong) EAGLContext *mContext;
@property(nonatomic , strong) GLKBaseEffect *meffect;

@property(nonatomic , assign) int mCount;

@end

@implementation openGLController


- (void)viewDidLoad{
    [super viewDidLoad];
    
    _mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    GLKView *view = (GLKView *)self.view;
    view.context = _mContext;
    view.drawableColorFormat = GLKViewDrawableColorFormatSRGBA8888;/// 颜色缓存区
    [EAGLContext setCurrentContext:_mContext];
    
    //顶点数据，前三个是顶点坐标，后面两个是纹理坐标
    GLfloat squareVertexData[] =
    {
        0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
        -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
        -0.5, -0.5, 0.0f,   0.0f, 0.0f, //左下
        0.5, 0.5, -0.0f,    1.0f, 1.0f, //右上
    };
    
    //顶点索引
    GLuint indices[] =
    {
        0, 1, 2,
        0,  3,  1
    };
    _mCount = sizeof(indices) / sizeof(GLuint);
   
    /// 顶点数据缓存
    GLuint buffer;
    /// 申请表示符
    glGenBuffers(1, &buffer);
    /// 绑定 告诉OpenGLes 为接下来的运算使用一个缓存
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    /// 初始化缓存
    glBufferData(GL_ARRAY_BUFFER, sizeof(squareVertexData), squareVertexData, GL_STATIC_DRAW);
    
    
    /// 纹理数据缓冲
    GLuint index;
    
    glGenBuffers(1, &index);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index);
    
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    
    
    
//    由glEnableVertexAttribArray启用指定属性，才可在顶点着色器中访问逐顶点的属性数据
    /// 启用顶点缓存
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, (GLfloat *)NULL+0);
    
    /// 启用纹理缓存
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, (GLfloat *)NULL+3);
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@(1),GLKTextureLoaderOriginBottomLeft, nil];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"2" ofType:@"png"];
    
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:path options:options error:nil];
    
    /// 做色漆
    self.meffect = [[GLKBaseEffect alloc] init];
    self.meffect.texture2d0.enabled = GL_TRUE;
    self.meffect.texture2d0.name = textureInfo.name;
    
    
  
    
  
}

/// 渲染
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    ///
    glClearColor(1.0,1.0,0.0,   1.0);
    glClear(GL_COLOR_BUFFER_BIT );
    /// 启动作色器
    [self.meffect prepareToDraw];
    glDrawElements(GL_TRIANGLES, _mCount, GL_UNSIGNED_INT, 0);
}


- (void)dealloc{
}
@end























































