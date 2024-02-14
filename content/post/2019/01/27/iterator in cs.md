---
title: Iterator in C#
# subtitle: Iterator in C#
date: 2019-01-27
tags: ["Design Pattern", "CS"]
draft: true
---

> 對於 `迭代器(Iterator)` IEnumerable, IEnumerator 的一些筆記...

<!-- <img src="/images/2019/01/IteratorPattern.png" style="display: block; margin-left: auto; margin-right: auto;"> -->
![](/images/2019/01/IteratorPattern.png)

<!--more-->

# Concepts

迭代器設計模式(Iterator Pattern) 提供了一組介面, 能夠有順序的從一個聚合物件(Aggregation object)之中, 逐一取得裡面的元素, 而不用理會裡面的結構.

C# 已經為此設計模式定義好介面:

- IEnumerator: 存取元素的 Iterator
- IEnumerable: 產生 Iterator

C# 中, Array && 大多數 System.Collections && System.Collections.Generic 都已經實作好了 `IEnumerable`, 將來可透過 `GetEnumerator()` 來取得之中的元素.


# Source Code

原始版本:

```cs
// System.Collections
public interface IEnumerator
{
    object Current { get; }
    bool MoveNext();
    void Reset();
}

public interface IEnumerable
{
    IEnumerator GetEnumerator();
}
```

泛型版本:

```cs
// System.Collections.Generic
public interface IEnumerable<out T> : IEnumerable
{
    IEnumerator<T> GetEnumerator();
}

public interface IEnumerator<out T> : IEnumerator, IDisposable
{
    T Current { get; }
}
```


# Review

目前對這東西還非常無感, 或許將來得去讀讀資料結構才能知曉其中奧秘吧...=口=


# Reference

- [Introduction to Generics](https://docs.microsoft.com/zh-tw/dotnet/csharp/programming-guide/generics/introduction-to-generics)
- [迭代器模式(Iterator Pattern)](https://windperson.wordpress.com/2013/06/09/%E8%BF%AD%E4%BB%A3%E5%99%A8%E6%A8%A1%E5%BC%8Fiterator-pattern/)
- [C# IEnumerator, IEnumerable, and Yield](https://dev.twsiyuan.com/2016/03/csharp-ienumerable-ienumerator-and-yield-return.html)

