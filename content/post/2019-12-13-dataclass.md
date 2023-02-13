---
title: Python3.7 - dataclass - 類別屬性, 實例屬性 傻傻分不清楚
subtitle:
date: 2019-12-13
tags: ["Python"]
draft: true
---

<!--more-->

## 問題範例


```py
from dataclasses import dataclass


@dataclass
class MonitorBase:
    monitor_status: str = "0"
    is_enabled: bool = False

    def remove_monitor_status(self):
        self.monitor_status = None

    def remove_is_enabled(self):
        self.is_enabled = None


@dataclass
class SubMonitorSSH(MonitorBase):
    ssh_is_all_day: bool = False


@dataclass
class MonitorContainer:
    hostname: str = ''


@dataclass
class MonitorContainerHost(MonitorContainer):
    id: str = ''
    ssh: SubMonitorSSH = SubMonitorSSH()

    def data_format(self, all: bool = False):
        if all:
            self.ssh.remove_monitor_status()
        else:
            self.ssh.remove_is_enabled()
```

以上程式碼看似沒有問題, 各種 「監控項目(MonitorBase) 子類別」 都會裝在一個 「監控容器(MonitorContainer)」 裏頭

```py
### all=False
>>> setting = {'id': '123'}
>>> monitor = MonitorContainerHost(**setting)
>>> monitor.data_format(all=False)
>>> print(monitor)
# 預期 && 結果:
MonitorContainerHost(hostname='', id='123', ssh=SubMonitorSSH(monitor_status='0', is_enabled=None, ssh_is_all_day=False))



### all=True
>>> setting = {'id': '123'}
>>> monitor = MonitorContainerHost(**setting)
>>> monitor.data_format(all=True)
>>> monitor
# 結果:
MonitorContainerHost(hostname='', id='123', ssh=SubMonitorSSH(monitor_status=None, is_enabled=None, ssh_is_all_day=False))
# 預期:
# MonitorContainerHost(hostname='', id='123', ssh=SubMonitorSSH(monitor_status=None, is_enabled=False, ssh_is_all_day=False))
```

疑!? 天殺的, 如果在執行一次實例化 MonitorContainerHost, 會發現 monitor_status 與 is_enabled 都變成 None 了


## 解法

```py
# dataclass 無法直接實例化. 需在 __post_init__() 裏頭做
@dataclass
class MonitorContainerHost(MonitorContainer):
    id: str = ''
    ssh: SubMonitorSSH = None

    def __post_init__(self):
        self.ssh = SubMonitorSSH()

    def data_format(self, all: bool = False):
        if all:
            self.ssh.remove_monitor_status()
        else:
            self.ssh.remove_is_enabled()

setting = {'id': '123'}
monitor = MonitorContainerHost(**setting)
monitor.data_format(all=True)

monitor2 = MonitorContainerHost(**setting)
monitor2.data_format(all=True)
```

如此一來, 都可以符合預期了. 至於原理是啥...

目前我還不曉得......= =

改天心血來潮再來補了orz
