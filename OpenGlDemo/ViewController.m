//
//  ViewController.m
//  OpenGLDemo
//
//  Created by mr.zhou on 2018-12-10.
//  Copyright © 2018 mr.zhou. All rights reserved.
//

#import "ViewController.h"
#import <GLKit/GLKit.h>

#import "LearnView.h"


@interface ViewController ()
@property (nonatomic , strong) EAGLContext* mContext;
@property (nonatomic , strong) GLKBaseEffect* mEffect;

@property (nonatomic , strong) LearnView*   myView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.myView = (LearnView *)self.view;

}

- (void)demo2 {
    // 不采用GLBaseEffect 自己编写着色器


}
- (GLuint)loadShaders:(NSString *)vert frag:(NSString *)frag {
    GLuint verShader, fragShader;
    GLint program = glCreateProgram();

    //编译
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];

    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);

    //释放不需要的shader
    glDeleteShader(verShader);
    glDeleteShader(fragShader);

    return program;
}

- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    //读取字符串
    NSString* content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar* source = (GLchar *)[content UTF8String];

    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
}



- (void)demo1 {
    [self setupConfig];
    [self uploadVertexArray];
    [self uploadTexture];
}

- (void)setupConfig {
    self.mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    GLKView *view = (GLKView *)self.view;
    view.context = self.mContext;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    [EAGLContext setCurrentContext:self.mContext];
}

- (void)uploadVertexArray {
    //顶点数据，前三个是顶点坐标（x、y、z轴），后面两个是纹理坐标（x，y）
    GLfloat vertexData[] =
            {
                    0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
                    0.5, 0.5, -0.0f,    1.0f, 1.0f, //右上
                    -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上

                    0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
                    -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
                    -0.5, -0.5, 0.0f,   0.0f, 0.0f, //左下
            };
    GLuint buffer;
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);

    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 0);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);

}

- (void)uploadTexture {
    // 纹理贴图
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"111" ofType:@"jpg"];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@(1),GLKTextureLoaderOriginBottomLeft,nil];
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];

    self.mEffect = [[GLKBaseEffect alloc] init];
    self.mEffect.texture2d0.enabled = GL_TRUE;
    self.mEffect.texture2d0.name = textureInfo.name;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClearColor(0.3, 0.6, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    [self.mEffect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, 6);
}


@end
