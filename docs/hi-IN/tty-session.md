---
title: TTY session
description: आभासी टर्मिनल से मैन्युअली ARGVUS शुरू करें।
---

TTY पर लॉग इन करने के बाद, सत्र इस प्रकार शुरू करें:

```sh
argvus --start-desktop
```

यह `argvus session` से समर्थित मैनुअल एंट्री पॉइंट है। यह वही `argvus start` और उपयोगकर्ता-सेवा जीवनचक्र का उपयोग करता है जो ग्राफिकल लॉगिन करता है।

परिणामस्वरूप सेशन को निरीक्षण या पुनः प्रारंभ करने के लिए, `argvus sessionctl status`, `argvus sessionctl reload` या `argvus sessionctl logs` का उपयोग करें।

## `exec argvus-tty` से माइग्रेट करना

पहले के संस्करणों ने `argvus-tty` को `/usr/bin` में स्थापित किया, और कुछ उपयोगकर्ताओं ने `~/.profile` से `exec argvus-tty` के साथ सत्र शुरू किया। वह फ़ाइल अब निजी है और अब `PATH` पर नहीं है, इसलिए उन्नयन के बाद यह लाइन विफल हो जाती है। इसे समर्थित एंट्री प्वाइंट से बदलें:

```sh
exec argvus --start-desktop
```

`argvus tty` वही प्रवेश बिंदु है। अगले TTY लॉगिन से पहले `~/.profile`, `~/.zprofile` या `~/.bash_profile` में लाइन को हटा दें या अपडेट करें।
