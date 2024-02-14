---
title: "Python - Generator"
subtitle: Iterable, Iterator, Generator 啥鬼東西
date: 2019-11-10
tags: ["iterable", "iterator", "generator"]
draft: false
---

![Generator](/images/2019/11/generator.png)

本文要來說明 `generator` 這東西, 但在了解這個東西之前, 最好先對 `iterable` 及 `iterator` 有所了解, 會容易理解它.

<!--more-->


## 名詞定義 (自己消化吸收出來的)

- Iterable: 可迭代物件(介面), 它實作了 `__iter__()`, 它可回傳 Iterator.
- Iterator: 迭代器物件. 它實作了上述的 **Iterable 介面**, 並且額外實作了 `__next__()`. 它的作用是:
    - 將指標指向下一個, 讓下次可以繼續調用.
    - 返回當前結果.
- Generator: 一種比較特殊的 Iterator(繼承), 但內部實作了 `yield` 與 `send()`


```python
# Iterable 與 Iterator
from collections import Iterable, Iterator
a = [1, 2, 3]
b = iter(a)  # <list_iterator object at 0x10b705890>

print(isinstance(a, Iterator))  # False
print(isinstance(b, Iterator))  # True
print(isinstance(a, Iterable))  # True
print(isinstance(b, Iterable))  # True

# 因為 a 是個 iterable, 所以透過 iter(a) 取得它的 Iterator
# 它可以透過 next(b) 一個一個慢慢取出來 (b 內部 container 儲存得值隱含著被 pop 掉了)
# 也可透過 list(b) 一口氣取出來 (b 內部 container 瞬間被抽乾)
c = list(b)     # [1, 2, 3]
d = list(b)     # []

b == None       # False

e = iter(a)     # <list_iterator object at 0x10b705850>
next(e)  # 1
next(e)  # 2
next(e)  # 3
next(e)  # Exception StopIteration
```

`for a in b` 的原理, 其實就是先調用 `iter(b)`, 取得 Iterator. 如此便可使用 next 方法, 一個一個叫出來處理, 直到 StopIteration.


## 該死的 Generator (產生器, 生成器)

> `generator`: A function which returns a generator iterator. It looks like a normal function except that it contains yield expressions for producing a series of values usable in for-loop or that can be retrieved at a time with the next() function.

> `generator iterator`: An object created by a generator function.

> `generator expression`: An expression that returns an iterator.

自己理解的白話文:

- generator 就是個會 yield `generator iterator` 的 function.
- generator iterator: 被 generator function 回傳的東西
- 如果一個 function 裡面有 yield, 那麼這個 function 就稱為 generator, 它會透過 `yield` 回傳 generator.

```python
# Generator
a = (elem for elem in [1, 2, 3])  # <generator object <genexpr> at 0x10b842950>

def fib():
  a, b = 0, 1
  while True:
    yield b
    a, b = b, a + b

g = fib()  # <generator object fib at 0x10b842850>
```

> Python's generators provide a convenient way to implement the iterator protocol.

因為 generator 就是個 iterator (得實作 `__iter__()` 與 `__next()__`). 但是 generator 只需要使用 `yield`, 它幫忙實現了 generator 的 `__next()__`.


```python
# Generator 與 Iterator
def g():
  print('第1次')
  yield 1
  print('第2次')
  yield 2
  print('第3次')
  yield 3

f = g()  # <generator object g at 0x10b842850>
next(f)  # '第1次'  收到 1
next(f)  # '第2次'  收到 2
next(f)  # '第3次'  收到 3
next(f)  # StopIteration
```

`generator` 在遇到了 yield 就將程式的`執行流程返回給了呼叫端` & `返回當前的值`. 下次進入的時候, 會接在上次中斷的地方繼續...  這樣的概念就如同 generator 的 `將指標指向下一個, 方便下次迭代` & `返回當前的值`

generator 的 yield 可理解成 `中斷服務子程序的斷點`. 爾後每次對 generator 調用 `next()` 時, 就會回到斷點之後繼續執行


## References

- [Python之生成器詳解](https://kissg.me/2016/04/09/python-generator-yield)
- 圖片來源自本文參考之文章
