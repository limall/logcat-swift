# logcat-swift

A plan to print log messages observably in apple platform

##  特性

* 对日志进行基本的分级打印，以及过滤筛选

* 打印端基于electron开发，可在windows、macOS、linux上运行

* 打印端通过Udp协议来接收日志消息，方便移植到其它平台

* 通过Udp接收消息的好处还有，不需要将调试设备连接到mac上，仅通过局域网便可打印日志

* 可同时打印多个设备发送来的日志，可通过logid筛选各个设备的日志

logcat-swift分为打印端和发送端两部分，打印端是一个单独的app，它基于electron开发，通过udp协议接收发送端发来的log信息并分条理地打印出来；发送端是一些swift文件，将它们复制到你的swift项目中，调用其api将log信息发送给打印端打印。

##  打印端的使用

打印端效果如下

![a.png](https://pic.images.ac.cn/image/5e8f309cf0fa0)



#####  打印段接收消息的端口为20131，请务必保证该端口没有被占用。

#### 使用已打包好了的app

打印端可以直接使用打包好了的app,链接: https://pan.baidu.com/s/1Sl6XUkuzucoYkmcATucJrA 提取码: 6vks

#### 自己动手使用electron_app

位于根目录下的electron_app文件夹就是打印端的electron项目，如何启动它以及如何打包请参考链接：[https://www.jianshu.com/p/5812572a5e66](https://www.jianshu.com/p/5812572a5e66)

#### 使用细节

打印端的显示顺序为新收到的消息打印在顶部而不是底部，这里需要注意一下。打印的消息上面是五个交互控件，它们的功能如下：

* clear按钮用于清除所有记录

* level选项卡选择显示日志的最低级别

* tag输入框，筛选tag为输入值的日志

* logid输入框，筛选logid为输入值的日志(logid用来分辨发送消息的设备)

* key输入框，筛选消息主体含有输入值的日志

## 发送端

直接将根目录下的swift文件夹里的文件复制到你的项目中即可引入发送端。

#### 设置发送目的地

发送日志到打印端前务必设置发送目的地，代码如下：

```
UdpLog.resetDst(toIp: "127.0.0.1", toPort: 20131, logId: 1234567890)
```

#### 分别打印各级level的日志：

```
UdpLog.i("Hello,world!你好，世界！")

UdpLog.d("Hello,world!你好，世界！")

UdpLog.w("Hello,world!你好，世界！")

UdpLog.e("Hello,world!你好，世界！")
```

#### 当项目为release时取消打印

```
UdpLog.outputKind = .None
```

