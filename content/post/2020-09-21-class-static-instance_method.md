---
title: classmethod, staticmethod, instance method in Python
date: 2020-09-21T20:00:00+08:00
tags: ["Python3.7"]
draft: false
---

超多超多的文章都在討論究竟 Python 裡頭的 staticmethod && staticmethod && instance method 差在哪邊?

可以參考 [這篇](https://stackoverflow.com/questions/136097/difference-between-staticmethod-and-classmethod), [這篇](https://stackoverflow.com/questions/12179271/meaning-of-classmethod-and-staticmethod-for-beginner) 或 [這篇](https://stackoverflow.com/questions/12179271/meaning-of-classmethod-and-staticmethod-for-beginner/12179752#12179752)...(以上都是好幾千個 upvote 的 Q&A), 半夜睡不著覺 而且對於知識狂熱的份子可以去好好讀它...

底下就用 "我自己的理解" ~~來湊熱鬧~~ 寫篇文章解說解說

<!--more-->


## Prerequest

- 對於 Python 物件導向要有某種程度的熟悉
- 對於 `@staticmethod` & `@classmethod` 多多少少有種模糊的認識


## 範例

底下範例我打算寫個元件(類別), 你只要給它 'date 物件', 他就能告訴你:

- 這天所在的那個月的第一天
- 這天所在的那個月的最後一天
- 這天所在的那週的第一天的日期
- 這天所在的那週的最後一天的日期

```python
from datetime import timedelta, date

class DateTimeTools:
    def first_day_of_month(self, dt: date) -> date:
        return date(dt.year, dt.month, 1)
    
    def last_day_of_month(self, dt: date) -> date:
        dt2 = date(dt.year + 1, 1, 1) if dt.month == 12 else date(dt.year, dt.month + 1, 1)
        return date(dt2.year, dt2.month, 1) - timedelta(days=1)
    
    def first_day_of_week(self, dt: date) -> date:
        return dt - timedelta(days=dt.isoweekday() % 7)
    
    def last_day_of_week(self, dt: date) -> date:
        return self.first_day_of_week(dt=dt) + timedelta(days=6)

dd = date(2021, 9, 21)

a = DateTimeTools()
print(a.first_day_of_month(dt=dd))  # 2020-09-01
print(a.last_day_of_month(dt=dd))   # 2020-09-30
print(a.first_day_of_week(dt=dd))   # 2020-09-20
print(a.last_day_of_week(dt=dd))    # 2020-09-26
```

因為上面的範例使用上有點不方便(每次都要傳參數給裡頭的方法), 稍微修改一下後變成下面這樣

```python
from datetime import timedelta, date

class DateTimeTools:
    def __init__(self, dt: date):
        self._dt = dt

    def first_day_of_month(self) -> date:
        return date(self._dt.year, self._dt.month, 1)
    
    def last_day_of_month(self) -> date:
        dt2 = date(self._dt.year + 1, 1, 1) if self._dt.month == 12 else date(self._dt.year, self._dt.month + 1, 1)
        return date(dt2.year, dt2.month, 1) - timedelta(days=1)
    
    def first_day_of_week(self) -> date:
        return self._dt - timedelta(days=self._dt.isoweekday() % 7)
    
    def last_day_of_week(self) -> date:
        return self.first_day_of_week() + timedelta(days=6)

dd = date(2020, 9, 21)

a = DateTimeTools(dt=dd)
print(a.first_day_of_month())  # 2020-09-01
print(a.last_day_of_month())   # 2020-09-30
print(a.first_day_of_week())   # 2020-09-20
print(a.last_day_of_week())    # 2020-09-26
```

善用 實例屬性, 將來呼叫方法時, 就不用再輸入參數

然而使用上, 或許你會覺得不必這麼麻煩, 

我們還是回到最一開始的那種情況, 我需要把什麼樣的日期作轉換, 當下再給他日期就好

只是每次都得實例化很不直覺, 改成更好用的方式不就好了?

```python
from datetime import timedelta, date


class DateTimeTools:

    @classmethod
    def first_day_of_month(cls, dt: date) -> date:
        return date(dt.year, dt.month, 1)
    
    @classmethod
    def last_day_of_month(cls, dt: date) -> date:
        dt2 = date(dt.year + 1, 1, 1) if dt.month == 12 else date(dt.year, dt.month + 1, 1)
        return date(dt2.year, dt2.month, 1) - timedelta(days=1)
    
    @classmethod
    def first_day_of_week(cls, dt: date) -> date:
        return dt - timedelta(days=dt.isoweekday() % 7)
    
    @classmethod
    def last_day_of_week(cls, dt: date) -> date:
        return DateTimeTools.first_day_of_week(dt=dt) + timedelta(days=6)


dd = date(2020, 9, 21)

print(DateTimeTools.first_day_of_month(dt=dd))  # 2020-09-01
print(DateTimeTools.last_day_of_month(dt=dd))   # 2020-09-30
print(DateTimeTools.first_day_of_week(dt=dd))   # 2020-09-20
print(DateTimeTools.last_day_of_week(dt=dd))    # 2020-09-26
```

現在全透過 類別方法 來呼叫即可, 而類別名稱就只剩下把這些方法歸類到同一個地方的作用而已

此外, 也可以改成 靜態方法, 讓程式碼再少一些

```python
from datetime import timedelta, date


class DateTimeTools:

    @staticmethod
    def first_day_of_month(dt: date) -> date:
        return date(dt.year, dt.month, 1)
    
    @staticmethod
    def last_day_of_month(dt: date) -> date:
        dt2 = date(dt.year + 1, 1, 1) if dt.month == 12 else date(dt.year, dt.month + 1, 1)
        return date(dt2.year, dt2.month, 1) - timedelta(days=1)
    
    @staticmethod
    def first_day_of_week(dt: date) -> date:
        return dt - timedelta(days=dt.isoweekday() % 7)
    
    @staticmethod
    def last_day_of_week(dt: date) -> date:
        return DateTimeTools.first_day_of_week(dt=dt) + timedelta(days=6)


dd = date(2020, 9, 21)

print(DateTimeTools.first_day_of_month(dt=dd))  # 2020-09-01
print(DateTimeTools.last_day_of_month(dt=dd))   # 2020-09-30
print(DateTimeTools.first_day_of_week(dt=dd))   # 2020-09-20
print(DateTimeTools.last_day_of_week(dt=dd))    # 2020-09-26
```

在這個範例裡面, `@staticmethod` & `@classmethod` 看起來只差一點點, 這並不意味著他們是一樣的


## 後記

最後不免會有疑問, 那什麼時候用 staticmethod? 又啥時用 classmethod

我的回答是(非專業見解), 其實我不是非常確定有沒有哪些情境, 其中一種方式是絕對優於另一者

目前書上, 網路上 東看西看的理解, 多半都只是在說 類別方法多了個 `cls`, 至於使用情境

目前依然是一頭霧水. 

因此我最終的結論是, 能正常使用就好. 符合需求就好. 習慣就好. 符合團隊要求就好.
