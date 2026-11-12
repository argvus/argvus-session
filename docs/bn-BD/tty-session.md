---
title: TTY অধিবেশন
description: ভার্চুয়াল টার্মিনাল থেকে ম্যানুয়ালি ARGVUS শুরু করুন।
---

একটি TTY-তে লগইন করার পরে, সেশনটি দিয়ে শুরু করুন:

```sh
argvus --start-desktop
```

এটি `argvus session` থেকে সমর্থিত ম্যানুয়াল এন্ট্রি পয়েন্ট। এটি গ্রাফিকাল লগইনের মতো একই `argvus start` এবং ব্যবহারকারী-সেবা লাইফসাইকেল ব্যবহার করে।

ফলস্বরূপ সেশন পরীক্ষা বা পুনরায় শুরু করতে, `argvus sessionctl status`, `argvus sessionctl reload` বা `argvus sessionctl logs` ব্যবহার করুন।

## `exec argvus-tty` থেকে স্থানান্তর।

আগের সংস্করণগুলি `argvus-tty` ইনস্টল করেছিল `/usr/bin` তে, এবং কিছু ব্যবহারকারী `~/.profile` থেকে `exec argvus-tty` দিয়ে সেশন শুরু করেছিল। সেই ফাইলটি এখন ব্যক্তিগত এবং আর `PATH` তে নেই, তাই আপগ্রেডের পরে লাইনটি ব্যর্থ হয়। এটি সমর্থিত এন্ট্রি পয়েন্ট দিয়ে প্রতিস্থাপন করুন:

```sh
exec argvus --start-desktop
```

`argvus tty` একই এন্ট্রি পয়েন্ট। পরবর্তী TTY লগইনের আগে `~/.profile`, `~/.zprofile` বা `~/.bash_profile`-তে লাইনটি মুছে দিন বা আপডেট করুন।
