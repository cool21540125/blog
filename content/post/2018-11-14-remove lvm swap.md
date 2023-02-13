---
title: 移除 LVM-SWAP
# subtitle: 移除 LVM-SWAP
date: 2018-11-14
tags: ["centos7", "lvm"]
draft: false
---

> 自己一開始在安裝 CentOS7 的時候, 懶得動腦, 而在磁區劃分時, 就選用 `讓我自訂磁區劃分`, 然後再選擇使用 `預設方式規劃檔案系統`, 於是就被分配了 512M 的 swap
  現在問題來了, 512MB 的空間我不想要用在 swap 之上, 怎麼把它從系統上要回來勒!?
  一開始想得很單純, 先把 swap 拿掉, 再從 fstab 移除, 最後再把 Logical Volume 移除即可, 但悲劇就發生了... 無法開機 ><

<!--more-->

# Prerequest

- mount
- LVM
- grub2
- swap
- fstab

*如果以上的東西你看不懂 或 看了無感, 請勿浪費您寶貴的時間繼續往下看~*

*本章節操作若有閃失, 可能導致將來無法正常開機*


# Implementation

1. 從 fstab 取消掛載 swap
2. 從 grup 取消使用 swap

## 1. 從 fstab 取消掛載 swap

```sh
$# free -m
              total        used        free      shared  buff/cache   available
Mem:           2782         448        1983           7         351        2234
Swap:           511           0         511
# 一開始大概 0.5G 的 swap 在那邊

$# lsblk -f
NAME                         FSTYPE      LABEL UUID                                   MOUNTPOINT
sda
├─sda1                       xfs               84a28da6-b8d7-4c78-898e-c52959cf9c7d   /boot
└─sda2                       LVM2_member       gFK1m6-tGsh-1Ekz-yN3N-PPt4-7dNp-0tQbzb
  ├─centos_5720--pw2215-root xfs               cee53bff-d4f5-41c5-8a4e-8f1e8de25003   /
  ├─centos_5720--pw2215-swap swap              077873c2-f581-46ed-aa12-1f5f9f4df22b   [SWAP]    # 準備把它拔掉
  └─centos_5720--pw2215-var  xfs               907ff2d3-12f3-49d1-bb6e-9de6eb97943c   /var

$# swapoff /dev/mapper/centos_5720--pw2215-swap # 卸載 swap

$# free -m
              total        used        free      shared  buff/cache   available
Mem:           2782         449        1981           7         351        2232
Swap:             0           0           0
# 拔掉了

$# vim /etc/fstab
/dev/mapper/centos_5720--pw2215-root /                       xfs     defaults        0 0
UUID=84a28da6-b8d7-4c78-898e-c52959cf9c7d /boot                   xfs     defaults        0 0
/dev/mapper/centos_5720--pw2215-var /var                    xfs     defaults        0 0
# /dev/mapper/centos_5720--pw2215-swap swap                    swap    defaults        0 0    # 然後我把這行註解掉

# 緊接著, 移除 logical volume
$# lvremove /dev/centos_5720-pw2215/swap
Do you really want to remove active logical volume centos_5720-pw2215/swap? [y/n]: y
  Logical volume "swap" successfully removed

$# vgs
  VG                 #PV #LV #SN Attr   VSize  VFree
  centos_5720-pw2215   1   2   0 wz--n- 12.50g 512.00m  # ← 512m 的空間已經釋放出來了~
# 耶~  我就以為我完成了!!

$# systemctl reboot     # 等等!!! 現在重啟, 電腦就居居惹~
```

第一次作業時, 重新開機後, 就沒辦法正常開機了...

上述的作法, 跟 [小紅帽官網](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/storage_administration_guide/s1-swap-removing#) 的解法一樣

[爬文後](https://www.refmanual.com/2016/01/08/completely-remove-swap-on-ce7/#.W-vHzZMzaUk), 才意識到我忽略到一個重要的細節!!

我還不確定該怎麼正確的解釋, 但概念大概就是

系統開機時, 會依照 `開機選單(grub)` 先幫我把 swap 掛載上去了~ 結果導致找不到, 然後就 Do-Until-Die!!!

(疑! 原來 swap 的掛載動作也被寫入到 grup!?)

所以, 另外得把 swap 從開機選單中移除

## 2. 從 grup 取消使用 swap

```sh
$# vim /etc/default/grub
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
# GRUB_CMDLINE_LINUX="rd.lvm.lv=centos_5720-pw2215/root rd.lvm.lv=centos_5720-pw2215/swap rhgb quiet audit=1" # 原本
GRUB_CMDLINE_LINUX="rd.lvm.lv=centos_5720-pw2215/root rhgb quiet audit=1"  # 改成這樣
GRUB_DISABLE_RECOVERY="true"
# 存檔後離開

# 重建 grub.cfg(grub2的 主設定檔)
$# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-862.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.el7.x86_64.img
Found linux image: /boot/vmlinuz-0-rescue-18fe822a5d51433d99a546058606962a
Found initrd image: /boot/initramfs-0-rescue-18fe822a5d51433d99a546058606962a.img
done

$# systemctl reboot
```

重新開機之後

```sh
# Volume Group 有新鮮的 512m 可以用了
$# vgs
  VG                 #PV #LV #SN Attr   VSize  VFree
  centos_5720-pw2215   1   2   0 wz--n- 12.50g 512.00m

# Logical Volume 也確實移除了~
$# lvs
  LV   VG                 Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  root centos_5720-pw2215 -wi-ao---- 11.00g
  var  centos_5720-pw2215 -wi-ao----  1.00g

# 不再有 swap 了
$# free -m
              total        used        free      shared  buff/cache   available
Mem:           2682         433        1907           7         341        2151
Swap:             0           0           0

# 確實也沒 swap 掛載著了~
$# lsblk -f
NAME                         FSTYPE      LABEL UUID                                   MOUNTPOINT
fd0
sda
├─sda1                       xfs               84a28da6-b8d7-4c78-898e-c52959cf9c7d   /boot
└─sda2                       LVM2_member       gFK1m6-tGsh-1Ekz-yN3N-PPt4-7dNp-0tQbzb
  ├─centos_5720--pw2215-root xfs               cee53bff-d4f5-41c5-8a4e-8f1e8de25003   /
  └─centos_5720--pw2215-var  xfs               907ff2d3-12f3-49d1-bb6e-9de6eb97943c   /var
```
