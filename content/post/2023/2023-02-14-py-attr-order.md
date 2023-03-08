---
title: "Python 取值的順序"
date: 2023-02-14T13:05:26+08:00
tags: ["python"]
draft: false
---

本文屬於比較扎實的 python Coding 觀念

談論 python 從 `物件/類別` 取得 `屬性/方法`(以下有時候會統稱為 取值) 的順序

了解這篇的觀念, 將有助於:

- 可強對於遇到 AttributeError 的除錯能力
- 從多重繼承取值的時候, 拿到得值經常不符合你預期的那樣的除錯能力

<!--more-->

---

以下直接切入正題吧

```py
### Sample Code

class C(D, E, F):
    name = "XX"

C.name  # 從類別取得屬性

x = C()
x.name  # 從物件取得屬性
```


# 從類別取得屬性

類別屬性(name) 的查找順序:

1. 若 `'name' in C.__dict__`, 則從 `C.__dict__['name']` 取出它的值 v, 然後若
    - v 為 Descriptor, 則回傳 `type(v).__get__(v, None, C)` 的結果
    - v 非 Descriptor, 則回傳 C.name 的值, 即 v
2. 若 `'name' not in C.__dict__`, 則 `C.name` 的動作會 委派(delegate) 到它的父類別們(依照MRO)去尋找.
3. 若無, 拋出 AttributeError


# 從物件取得屬性

物件屬性(name) 的查找順序:

1. 若 'name' 出現在 C(或父類別們)裡頭, 且 name 的值(v) 恰巧為 覆寫式描述器, 則 `x.name` 會得到 `type(v).__get__(v, x, C)` 的結果
2. 若 `'v' in x.__dict__`, 則回傳 `x.__dict__['name']` 的結果
3. `C.name` 的動作會 委派(delegate) 到他的父類別們去尋找, 當其結果 'v' 被找到, 且:
    - v 為 Descriptor, 則回傳 `type(v).__get__(v, x, C)`
    - v 非為 Descriptor, 則回傳 v 的值
4. 看是否有定義 `__getattr__(x, 'name')`, 若有則從中取值
5. 拋出 AttributeError
