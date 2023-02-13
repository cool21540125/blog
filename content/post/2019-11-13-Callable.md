---
title: python callable
subtitle:
date: 2019-11-13
tags: ["callable", "python"]
draft: false
---

本文不扯 `__call__` 與 `callable` 這些定義, 自己去看官網.

但用一個自己可以理解的範例來示範...

<!--more-->

官方對於 `callable` 的解說 (下面那個別鳥它)

> Return True if the object argument appears callable, False if not. If this returns True, it is still possible that a call fails, but if it is False, calling object will never succeed. Note that classes are callable (calling a class returns a new instance); instances are callable if their class has a __call__() method.


## Spec:

車主去買車, 車子需要插對鑰匙才能發動. 如果差錯鑰匙, 就沒辦法啟動


## Example

```python
class Car:
    def __init__(self, owner: str = None):
        self.owner = owner
        self.ready = False
        self._car_key = f"{self.owner}'s car key"

    def __start(self):
        print('引擎啟動')
        self.ready = True

    def go(self):
        if self.ready:
            print(f'{self.owner} 的車開始狂飆')
        else:
            print(f'沒反應')

    def __call__(self, car_key: str):
        if car_key != self._car_key:
            print('插不進去')
        else:
            self.__start()
```

關於 `__call__`, 如果它定義在類別裡面, 表示這個類別建立出來的實例可以被調用. 所謂的 `調用` 這個詞, 就是某個變數後面加上 `.()` 的概念啦(甚至還可以接參數)!!

接續上面的範例:

```py
toyota1 = Car('tony')
toyota1("tony's car key")   # 引擎啟動
toyota1.go()                # tony 的車開始狂飆

toyota2 = Car('tony')
toyota2("home_key")         # 插不進去
toyota2.go()                # 沒反應
```


## Reference

- [Python __call__详解](https://www.jianshu.com/p/e1d95c4e1697)
