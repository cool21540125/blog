---
title: Promise 極簡版之不專業學習筆記
date: 2020-01-26T23:50:00+08:00
tags: ["javascript", "promise", "nodejs"]
draft: false
---

![JsPromise](/images/2020/01/js_promise.png)

<!--more-->

## 白話文範例

你現在是個公司的小員工, 老闆 `promise(承諾)` 大家, 如果月底他心情好, 要幫大家加薪

因此大家拿到的是個 `promise`, 目前處於 **等待一種不確定狀態的狀態**, 這個 promise 有 3 種狀態

- `pending`: 結果發生之前的一種等待, 尚未發生的狀態.
- `resolved`: 完成了 `promise(履約承諾)`
- `rejected`: 拒絕了 `promise(履約承諾)`

簡單的來說, 這個 promise 目前是 `pending`, 時間到了的話

- 可能為 `resolved(fulfilled)`, 真的加薪了
- 可能為 `rejected`, 你還是一樣窮. 呵呵, 因為這裡是台灣
- ~~可能依舊 `pending`(老闆又改條件)~~ *現實生活應該存在這種結果, 但程式裡頭似乎沒這選項*


## 程式範例

上述範例的程式

```js
let isPerformanceOK = false;

// 底下這包不會馬上執行, 而是得 "經由其他事情再來觸發執行"
let willRaiseSalary = new Promise(function(resolve, reject) {
    if (isPerformanceOK) {
        let additionalPayments = {
            newPay: 10000,
            currency: 'NTD'
        }
        resolve(additionalPayments);
    } else {
        let reason = new Error("Don't cry, you can do better");
        reject(reason);
    }
});
```

> Promise 所表達的是 `非同步操作的結果`, 可能為 `resolved` 或 `rejected`

拿到 promise 的後續操作

```js
var askYourBoss = function() {
    // 這時候再來看看履約的結果
    willRaiseSalary.then(function(fulfilled) {  // fulfilled 為 成功的結果
        console.log(fulfilled);
    }).catch(function(err) {  // err 為 失敗的結果
        console.log(err.message);
    });
}

// 月底了, 去問候你老闆吧
askYourBoss();
```


## 鏈式調用 Promise

承接上面的故事, 你也對你女朋友(醒醒吧,你沒有!) 履約說, 如果有加薪, 要請她吃大餐

```js

var eatBigMealWithRightHand = function(additionalPayments) {
    return new Promise(function(resolve, reject) {
        let restaurant = 'Lu-Biean-Tan';
        resolve(restaurant);
    });
}
```

而以程式流程的觀點, 上面的 `eatBigMealWithRightHand` 要放在 `willRaiseSalary` 裏頭

但因為這樣寫有點不直覺, 所以上述程式可以串連 promise

```js
var askYourBoss = function() {
    willRaiseSalary
        .then(eatBigMealWithGF)
        .then(function(fulfilled) {
            console.log("吃完大餐後要做的事情2...");
        })
        .then(function(fulfilled) {
            console.log("吃完大餐後要做的事情3...");
        })
        .catch(function(error) {
            console.log(error.message);
        });
}
```

## Summary

以上只簡單紀錄 Promise 這東東, 以及他的基本概念

至於 ES6, ES7, async, await, Observables 等等比較近代化一點的寫法, 就去參考 Reference 那篇

我覺得他寫的還蠻不錯的(其實我只改範例... 內文幾乎都是 Copy 他的觀念)


## Reference

- [MDN-Promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise)
- [Promise 學習筆記](https://andyyou.github.io/2017/06/27/js-promise/)
