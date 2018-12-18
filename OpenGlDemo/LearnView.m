//
// Created by mr.zhou on 2018-12-18.
// Copyright (c) 2018 ___FULLUSERNAME___. All rights reserved.
//

#import "LearnView.h"
#import <GLKit/GLKit.h>
@interface LearnView ()

@property(nonatomic, strong) EAGLContext *mContext;

@property(nonatomic, strong) CAEAGLLayer *myEaglLayer;
@property(nonatomic, assign) GLuint mProgram;

@property(nonatomic, assign) GLuint myColorRenderBuffer;
@property(nonatomic, assign) GLuint myColorFrameBuffer;
@end

@implementation LearnView {

}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)layoutSubviews {
    [self setupLayer];

    [self setupContext];

    [self destoryRenderAndFrameBuffer];

    [self setupRenderBuffer];

    [self setupFrameBuffer];

    [self render]; }

- (void)setupLayer {
    self.myEaglLayer = (CAEAGLLayer *)self.layer;
    // 设置放大倍数
    [self setContentScaleFactor:[UIScreen mainScreen].scale];
    // CALayer默认是透明的,必须设为不透明才能看见
    self.myEaglLayer.opaque = YES;
    // 设置描绘属性,在这里设置不维持渲染内容以及颜色格式
    self.myEaglLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking: @(NO),kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8};

}

- (void)setupContext {
    // 指定api版本
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:api];
    if (!context) {
        NSLog(@"failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    // 设置为当前的上下文
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"failed to set context");
        exit(1);
    }
    self.mContext = context;
}


- (void)destoryRenderAndFrameBuffer {
    glDeleteFramebuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
    glDeleteRenderbuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
}
- (void)setupRenderBuffer {
    GLuint buffer;
    glGenRenderbuffers(1, &buffer);
    self.myColorRenderBuffer = buffer;
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    // 为 颜色缓冲区 分配存储空间
    [self.mContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEaglLayer];
}


- (void)setupFrameBuffer {
    GLuint buffer;
    glGenFramebuffers(1, &buffer);
    self.myColorFrameBuffer = buffer;
    // 设置为当前 framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
            GL_RENDERBUFFER, self.myColorRenderBuffer);
}

- (void)render {
    glClearColor(0,1.0,0,1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    CGFloat scale = [UIScreen mainScreen].scale;

    // 读取文件
    NSString *vertFile = [[NSBundle mainBundle] pathForResource:@"shaderf.fsh" ofType:nil];
    NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"shaderv.vsh" ofType:nil];

    // 加载shader
    self.mProgram = [self loadShaders:vertFile frag:fragFile];

    // 链接
    glLinkProgram(self.mProgram);
    GLint linkSuccess;
    glGetProgramiv(self.mProgram, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar message[256];
        glGetProgramInfoLog(self.mProgram, sizeof(message), 0, &message[0]);
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSLog(@"error %@",messageString);
        return;
    } else {
        NSLog(@"link ok");
        glUseProgram(self.mProgram);
    }

    // 前三个是顶点/ 后面连个纹理坐标
    GLfloat attrArr[] =
            {
                    0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
                    -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
                    -0.5f, -0.5f, -1.0f,    0.0f, 0.0f,
                    0.5f, 0.5f, -1.0f,      1.0f, 1.0f,
                    -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
                    0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
            };
    GLuint attrbuffer;
    glGenBuffers(1, &attrbuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attrbuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);


    GLuint position = glGetAttribLocation(self.mProgram, "position");
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
    glEnableVertexAttribArray(position);

    GLuint textCoor = glGetAttribLocation(self.mProgram, "textCoordinate");
    glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (float *)NULL + 3);
    glEnableVertexAttribArray(textCoor);


    //加载纹理
    [self setupTexture:@"111"];

    //获取shader里面的变量，这里记得要在glLinkProgram后面，后面，后面！
    GLuint rotate = glGetUniformLocation(self.mProgram, "rotateMatrix");

    float radians = 10 * 3.14159f / 180.0f;
    float s = sin(radians);
    float c = cos(radians);

    //z轴旋转矩阵
    GLfloat zRotation[16] = { //
            c, -s, 0, 0.2, //
            s, c, 0, 0,//
            0, 0, 1.0, 0,//
            0.0, 0, 0, 1.0//
    };

    //设置旋转矩阵
    glUniformMatrix4fv(rotate, 1, GL_FALSE, (GLfloat *)&zRotation[0]);

    glDrawArrays(GL_TRIANGLES, 0, 6);

    [self.mContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (GLuint)loadShaders:(NSString *)vert frag:(NSString *)frag {
    GLuint verShader, fragShader;
    GLint program = glCreateProgram();

    // 编译
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];

    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);

    // 释放
    glDeleteShader(verShader);
    glDeleteShader(fragShader);

    return program;
}


- (void)compileShader:(GLuint*)shader type:(GLenum)type file:(NSString *)file {

    NSString *content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar * source = (GLchar*)[content UTF8String];

    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);

    glCompileShader(*shader);


}

- (GLuint)setupTexture:(NSString *)fileName {
    // 1获取图片的CGImageRef
    UIImage *image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"111.jpg" ofType:nil]];
    CGImageRef spriteImage = image.CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }

    // 2 读取图片的大小
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);

    GLubyte * spriteData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte)); //rgba共4个byte

    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,
            CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);

    // 3在CGContextRef上绘图
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);

    CGContextRelease(spriteContext);

    // 4绑定纹理到默认的纹理ID（这里只有一张图片，故而相当于默认于片元着色器里面的colorMap，如果有多张图不可以这么做）
    glBindTexture(GL_TEXTURE_2D, 0);


    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    float fw = width, fh = height;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);

    glBindTexture(GL_TEXTURE_2D, 0);

    free(spriteData);
    return 0;
}

@end