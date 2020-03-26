# logcat-swift
A plan to print log messages observably in apple platform

它的特性有

* 对日志进行基本的分级打印，提供过滤筛选功能
* 打印端基于electron开发，可在windows、macOS、linux上运行
* 打印端通过Udp协议来接收日志消息，方便移植到其它平台
* 通过Udp接收消息的好处还有，不需要将调试设备连接到mac上，仅通过局域网便可打印日志
* 可同时打印多个设备发送来的日志，通过logid筛选各个设备的日志

中文指引：https://www.jianshu.com/p/8e3979e94db6
