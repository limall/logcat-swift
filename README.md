# logcat-swift

## 中文

一个在苹果平台更醒目地打印日志的方案，目前仅在ios上测试通过

##  特性

* 对日志进行基本的分级打印，以及过滤筛选
* 打印端基于electron开发，可在windows、macOS、linux上运行
* 不需要将调试设备连接到mac上，仅通过局域网便可打印日志
* 可同时打印多个设备发送来的日志，可通过logid筛选各个设备的日志
* 可以将日志输出到设备文件中，上传后可再用打印端打印

logcat-swift分为打印端和发送端两部分，打印端是一个单独的app，它基于electron开发，通过tcp协议接收发送端发来的log信息并分条理地打印出来；发送端是一些swift文件，将它们复制到你的swift项目中，调用其api将log信息发送给打印端打印。

##  打印端的使用

打印端效果如下

![a.png](https://pic.images.ac.cn/image/5e8f309cf0fa0)



**打印端接收消息的端口为20131，请务必保证该端口没有被占用。**

#### 使用已打包好了的app

打印端可以直接使用打包好了的app,链接: https://pan.baidu.com/s/1Sl6XUkuzucoYkmcATucJrA 提取码: 6vks

#### 自己动手使用electron_app

位于根目录下的electron_app文件夹就是打印端的electron项目，如何启动它以及如何打包请参考链接：[https://www.jianshu.com/p/5812572a5e66](https://www.jianshu.com/p/5812572a5e66)

#### 使用细节

打印端的显示顺序为**新收到的消息打印在顶部而不是底部**，这里需要注意一下。打印的消息上面是六个交互控件，它们的功能如下：

* clear按钮用于清除所有记录
* level选项卡选择显示日志的最低级别
* tag输入框，筛选tag为输入值的日志
* logid输入框，筛选logid为输入值的日志(logid用来分辨发送消息的设备)
* key输入框，筛选消息主体含有输入值的日志
* open file按钮，用于打印设备上传的日志

## 发送端

直接将根目录下的swift文件夹里的文件复制到你的项目中即可引入发送端。

#### 设置发送目的地

发送日志到打印端前务必设置发送目的地，代码如下：

```
Logcat.resetDst(toIp: "127.0.0.1", toPort: 20131, logId: 1234567890)
```

#### 分别打印各级level的日志：

```
Logcat.i("Hello,world!你好，世界！")
Logcat.d("Hello,world!你好，世界！")
Logcat.w("Hello,world!你好，世界！")
Logcat.e("Hello,world!你好，世界！")
```

#### 当项目为release时取消打印

```
Logcat.outputKind = .None
```

设置最低打印级别

```
Logcat.setOutputLevel(level: .warning)
```

## 输出到文件

当调用以下代码后，日志就会输出到设备的本地文件：

```
Logcat.setSave2Local(appName: "test")
```

*appName*参数用来以后适配mac应用，这里随便传个字符串即可

```setSave2Local```函数调用时会创建一个文件夹，之后打印的日志都会存放在该文件夹。建议在app启动后就调用该函数，这样文件夹的命名规则为首次运行命名为0，第二次为1，依此类推。

当日志非常多时，日志会存放在多个文件中，文件名起始为0，接着是1、2、3...，日志文件依次存放在这些文件中。

所以，如果要查看最新的日志，就找命名最大的文件夹里的命名最大的文件。

## 发送日志文件

输出到设备本地的日志文件，需要上传到服务器才能查看。这里提供了简单的方案来上传日志文件，用户也可以使用更成熟的方案来收发日志文件。

#### 上传

使用以下代码上传单个文件

```
let localSender=LocalSender(toIP: "192.168.31.243", appName: "test")
localSender.sendSingleFile(holderId: 0, fileId: 0, completeCallback: {
    debugPrint("send log file success!")
})
```

*toIP*参数设置服务器地址；*appName*参数用来适配mac应用，暂时随便传个字符串；*holderId*参数为日志所在文件夹名转为Int(上文提到过文件夹名及文件名为数字)；*fileId*参数为文件名转为Int；*completeCallback*为上传完成后的回调。

使用以下代码上传全部文件

```
let localSender=LocalSender(toIP: "192.168.31.243", appName: "test")
localSender.sendAllFiles {
  debugPrint("all file sent")
}
```

*每个*LocalSender*实例只能执行一次任务，要执行多次任务就要创建多个实例。*

#### 接收

首先需要安装Node.js，不了解的可自行百度

将项目目录下的localReceiver.js文件复制到用来接收日志文件的目录中，终端cd到该目录，运行以下命令运行服务器程序：

```node localReceiver```

每个连接都会创建一个文件夹，该连接中的日志都保存在该文件夹中，文件夹名字也是数字，不过和上面不同，数字大小并不表示日志的先后顺序。

#### 查看

点击打印端app的open file按钮，选择上传的日志文件。

