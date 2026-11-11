---
title: Graphical session
description: ग्राफ़िकल लॉगिन फ़्लो के माध्यम से ARGVUS शुरू करें।
---

ग्राफिकल एंट्री पॉइंट `argvus session` है। यह सेशन वातावरण सेट करता है और `argvus start` को सौंपता है, जो इसे यूज़र मैनेजर में इम्पोर्ट करता है, पैकेज किए गए या यूज़र Hyprland Lua कॉन्फ़िगरेशन को वैलिडेट करता है, पता किए गए ग्राफिक्स संगतता सेटिंग्स लागू करता है, Hyprland लॉन्च करता है और कंपोज़िटर की तत्परता का इंतजार करता है।

लॉग्स `~/.local/state/argvus/session.log` में लिखे जाते हैं। ग्रीटर अपने उपयोगकर्ता के रूप में लॉगिन से पहले चलता है, इसलिए इसका प्री-लॉगिन आउटपुट `/run/argvus-greeter/session.log` में रखा जाता है और सेशन शुरू होने पर इसे `session.log` में जोड़ा जाता है। जब सेशन लॉग में Hyprland से स्टार्टअप चेतावनी नहीं दिखाई देती है, तो सबसे पहले इस फ़ाइल की जाँच करें।

सत्र यह सुनिश्चित करता है कि शेल `PATH` एन्वायरनमेंट वेरिएबल को एक समझदारीपूर्ण डिफॉल्ट पर सेट किया गया है, भले ही लॉगिन मैनेजर (जैसे कि greetd के साथ `source_profile=false`) कोई वेरिएबल एक्सपोर्ट न करे। यह गारंटी देता है कि `hyprland-dialog` जैसी यूटिलिटी, जो Hyprland द्वारा स्टार्टअप पर उपयोग की जाती है, चाइल्ड प्रोसेस द्वारा खोजी जा सकें।

हायपरलैंड तैयार होने के बाद, `argvus sessionctl` शुरू करता है `argvus-session.target`। यह लक्ष्य टास्कबार, कंट्रोल पैनल, नोटिफिकेशन, वॉलपेपर, आईडल हैंडलिंग, क्लिपबोर्ड, SSH एजेंट, सीक्रेट सर्विस प्रोवाइडर और संबंधित सेवाओं को शुरू करता है। एकल लोडिंग स्पिनर स्क्रीन पर तब तक रहता है जब तक कि लॉगिन हैंडऑफ से लेकर ये सेवाएं शुरू नहीं हो जातीं और वॉलपेपर तथा टास्कबार स्क्रीन पर नहीं आ जाते (अधिकतम 1.5 सेकंड और)। हायपरलैंड लॉन्च करने से पहले, `argvus-start` कॉन्फ़िगरेशन प्रोज़ेक्शन (`argvus-config.service`) को कतारबद्ध करता है, जो फिर कॉम्पोज़िटर स्टार्टअप के दौरान चलता है, और ग्रेटर के DRM हैंडऑफ सतह से डिस्प्ले रिलीज करने के लिए कहता है (`/usr/lib/argvus/greeter/handoff --send release`); जब वह सतह चल रही होती है, तो यह पहले `loginctl activate` के साथ सत्र को सक्रिय करता है, ताकि हायपरलैंड कभी भी बैकग्राउंड में VT पर न शुरू हो। सत्र स्पिनर तब सतह को हायपरलैंड के पहले फ्रेम्स को छिपाने वाले ओवरले को हटाने के लिए कहता है।

डेस्कटॉप तैयार होने के बाद, सत्र TTY, ARGVUS Greeter और अन्य लॉगिन प्रबंधकों के लिए `argvus welcome --if-needed` चलाता है। यह एकीकृत कंट्रोल सेंटर वेलकम पेज खोलता है जब तक कि प्रति-उपयोगकर्ता प्रगति रिकॉर्ड `opened`, पूर्णता या अस्वीकृति न हो। पहली सफल रेंडरिंग `opened` को `${XDG_STATE_HOME:-$HOME/.local/state}/argvus/welcome/progress.json` में सहेजती है, जिससे बाद के लॉगिन पर इसे पुनः खोलने से रोका जा सके। यह `/etc/skel` पर निर्भर नहीं करता। उस रिकॉर्ड के बिना मौजूदा खातों को भी एक स्वचालित खुलने की सुविधा मिलती है। रेंडरिंग से पहले की विफलताएं अगले लॉगिन पर एक और प्रयास की अनुमति देती हैं। मैनुअल `argvus welcome` उपलब्ध रहता है।

`PATH` उन स्थानों पर `~/.local/bin` और `~/.cargo/bin` भी अग्रभाग में प्राप्त करता है जब वे निर्देशिकाएँ मौजूद होती हैं, इसलिए वहाँ स्थापित उपकरण कंपोज़िटर और सेवाओं के लिए दिखाई देते हैं। `EDITOR` और `VISUAL` को कंट्रोल सेंटर डिफ़ॉल्ट ऐप्स (`TERMINAL_EDITOR`) से डिफ़ॉल्ट टर्मिनल संपादक के रूप में सेट किया जाता है, और इन्हें systemd उपयोगकर्ता प्रबंधक, D-Bus सक्रियण और Hyprland में निर्यात किया जाता है, ताकि सत्र से लॉन्च किए गए टर्मिनल और सेवाएँ इन्हें अपनाएँ। SSH एजेंट (`argvus-ssh-agent.service`, `openssh` से) `$XDG_RUNTIME_DIR/ssh-agent.socket` पर सुनता है और उपयोगकर्ता प्रबंधक को `SSH_AUTH_SOCK` प्रकाशित करता है। जब ARGVUS एजेंट शुरू होता है, यह उपयोगकर्ता प्रबंधक में `SSH_AUTH_SOCK` को बदल देता है। यदि किसी अन्य एजेंट जैसे gnome-keyring या gcr को सॉकेट का स्वामित्व लेना चाहिए, तो ARGVUS यूनिट को `systemctl --user mask argvus-ssh-agent.service` के साथ अक्षम करें। यह Hyprland के बाहर निकलने पर बंद हो जाता है, इसलिए ये सतहें लॉगआउट के बाद अनाथ प्रक्रियाओं के रूप में नहीं रहती हैं।

गुप्त सेवा प्रदाता `argvus-secret-service.service` है। यह अपस्ट्रीम `gnome-keyring-daemon.service` को केवल `secrets` घटक के साथ शुरू करता है, इसलिए यह SSH कुंजियों की सेवा नहीं करता और `SSH_AUTH_SOCK` `argvus-ssh-agent.service` के स्वामित्व में रहता है। जब `gnome-keyring` स्थापित नहीं होता, तो यूनिट को छोड़ दिया जाता है। पैकेज `gnome-keyring` को वैकल्पिक निर्भरता के रूप में घोषित करता है, और `argvus-taskbar-calendar` भी ऐसा ही करता है, जो वहां अपने CalDAV पासवर्ड संग्रहीत करता है। ARGVUS PAM को नहीं बदलता है, इसलिए लॉगिन पर कीरिंग अनलॉक नहीं होती: इसे उपयोग करने वाला पहला एप्लिकेशन कीरिंग पासवर्ड के लिए पूछता है, और तब लॉगिन संग्रह बनाया जाता है। स्थिति `argvus sessionctl secret-service-status` के साथ जांचें, जो गायब, रुका हुआ, चल रहा, लॉक किया हुआ या अनलॉक किया हुआ रिपोर्ट करता है। यदि आप चाहते हैं कि KWallet या KeePassXC गुप्त सेवा के स्वामी हों, तो ARGVUS यूनिट को `systemctl --user mask argvus-secret-service.service` के साथ अक्षम करें; सत्र बंद होने पर प्रदाता भी बंद हो जाता है।

सत्र अपने Wayland और डेस्कटॉप-पर्यावरण चर को systemd उपयोगकर्ता प्रबंधक में भी आयात करता है। चल रहे सत्र की जांच करने या उसे पुनः लोड करने के लिए:

```sh
argvus sessionctl status
argvus sessionctl logs
argvus sessionctl reload
```

 applies the generation that was already committed. If a command such as `reload`, `argvus config apply-theme`, `accent`/`set` or a widget-telemetry block change just projected the change, the reload restores the affected consumers from the projection manifest instead of projecting again. It only projects when no pending plan exists, for example at session startup. If no runtime-relevant section changed, it exits successfully without reloading Hyprland or restarting services. When changes exist, it reapplies session integration and reloads only the affected compositor and desktop surfaces. The splash covers a reload only when it recreates a surface: a restart of a Waybar bar (taskbar or Widget Telemetry) or of the Control Panel, or the fallback `patch` plan. Theme, accent, effects, fonts, window layout and wallpaper changes reload in place (`full` and `argvus config theme-runtime consumers`, Hyprland's `wallpaper`) without it, and a reload with nothing to do shows nothing. Repeated reloads are serialized and unchanged sections do not restart their consumers. `/reload` `apply-config`  is an explicit alias for this operation. When it is shown, the reload splash is opaque while the work is in progress, so the intermediate desktop is not exposed. It is not a replacement for logging out when the compositor or login environment must be restarted.

यदि प्रोजेक्शन पूरा नहीं किया जा सकता है, तो पुनः लोड डेस्कटॉप सतहों को फिर से शुरू करने से पहले बंद हो जाता है। फिर से प्रयास करने से पहले `argvus sessionctl logs` की जाँच करें और `argvus config validate` चलाएँ; यह असफल थीम प्रोजेक्शन से Waybar, सूचनाओं, या कंट्रोल पैनल को विषयों के पुराने मिश्रण के साथ चलने से रोकता है।

डिफ़ॉल्ट लॉगिन एकीकरण greetd है। देखें [Greeter](/docs/components/argvus-greeter/) और [सत्र समस्या निवारण](/docs/user-guide/troubleshooting/session-startup/)।

सेवा स्वामित्व और स्टार्टअप अनुक्रम के लिए, देखें [रनटाइम जीवनचक्र](/docs/developer-guide/architecture/runtime-lifecycle/)।

## नाइट लाइट

`argvus-session`, `hyprsunset>=0.4.0` पर निर्भर करता है और सत्र लक्ष्य के माध्यम से अपस्ट्रीम उपयोगकर्ता सेवा शुरू करता है, बिना एक दूसरा डेमन सक्षम किए। `argvus-night-light-init.service` प्रवेश पर संरक्षित स्थिति लागू करता है; टाइमर हर मिनट फिक्स्ड स्थानीय अनुसूचियों का मूल्यांकन करता है और क्लॉक/समय-क्षेत्र परिवर्तनों के बाद भी। अनुसूची बंद होने पर, आवधिक जांच मैनुअल स्थिति को अपरिवर्तित छोड़ देती है। अपस्ट्रीम सेवा लॉगआउट पर `graphical-session.target` का पालन करती है।

पैकेज्ड ड्रॉप-इन zxqmask000000qxzq और सर्विस-लोकल  `--identity` `XDG_CONFIG_HOME`/`XDG_CONFIG_DIRS` के साथ Hyprsunset को प्रारंभ करता है जो `/usr/share/argvus/session/config/night-light` की ओर इशारा करता है, जिसमें कोई नेटिव प्रोफाइल नहीं हैं। यह प्रतिस्पर्धी शेड्यूलर्स और अपस्ट्रीम 6000 K डिफ़ॉल्ट पर स्टार्टअप से बचाता है। यह इंस्टॉल होने के दौरान ARGVUS के बाहर अपस्ट्रीम सर्विस पर भी लागू होता है; व्यक्तिगत Hyprsunset फाइलें सुरक्षित रहती हैं। उपयोगकर्ता सिस्टमड ओवरराइड प्राथमिकता ले सकता है। कोई भी पैकेज इंस्टॉल HOME में नहीं लिखता। प्राथमिकताएं `/displays/night_light` में हैं, ओवरराइड `$XDG_RUNTIME_DIR/argvus/night-light/` में हैं; `argvus config display night-light status` देखें।

सत्र पर्यावरण को आयात करने से पहले लॉग इन किए गए उपयोगकर्ता के `$XDG_CONFIG_HOME/locale.conf` (डिफ़ॉल्ट `~/.config/locale.conf`) से LANG लोड करता है। यह TTY और ग्राफिकल लॉगिन प्रबंधकों पर लागू होता है। भाषा बदलने के लिए लॉग आउट और पुनः लॉग इन करना आवश्यक है; `/etc/locale.conf` को संशोधित नहीं किया जाता है।

वैध उपयोगकर्ता `LANG` के बिना, सत्र अंग्रेजी में शुरू होता है भले ही होस्ट स्थानीय भाषा पुर्तगाली हो। इसे उत्पन्न करते समय `en_US.UTF-8` का उपयोग किया जाता है और अन्यथा `C.UTF-8` का उपयोग किया जाता है, बिना उपयोगकर्ता कॉन्फ़िगरेशन बनाए। स्थानीय भाषा का निर्धारण कॉन्फ़िगरेशन प्रोजेक्शन और डेस्कटॉप शुरू होने से पहले होता है। सत्र वंशानुगत `LC_ALL` को साफ करता है और systemd उपयोगकर्ता और D-Bus सक्रियण वातावरण में भाषा चर को बदल देता है, जिसमें `LANGUAGE` शामिल है। उसी locale.conf से क्षेत्रीय श्रेणियाँ संरक्षित रहती हैं। पुरानी ARGVUS भाषा फ़ाइलों की अनदेखी की जाती है।

सत्र Hyprland शुरू करने से पहले `$XDG_CONFIG_HOME/environment.d/20-timezone.conf` से व्यक्तिगत TZ असाइनमेंट पढ़ता है और इसे उपयोगकर्ता सेवा और D-Bus वातावरण में आयात करता है। यह zoneinfo नामों को मान्य करता है और कभी भी फ़ाइल को निष्पादित नहीं करता। एक नया लॉगिन ऐप्लिकेशन पर टाइमज़ोन परिवर्तनों को लागू करता है।


## विंडो बटन और एप्लिकेशन बार

न्यूनतमकरण आरक्षित `special:argvus-minimized` कार्यक्षेत्र का उपयोग करता है। उस कार्यक्षेत्र का मैनुअल रूप से उपयोग न करें। `argvus windows service` प्रक्रिया पहचान, मूल कार्यक्षेत्र/मॉनिटर, ज्यामिति, फुलस्क्रीन/अधिकतमकरण और पिन स्थिति को एक compositor-_instance-विशिष्ट रनटाइम रजिस्ट्री में `$XDG_RUNTIME_DIR/argvus` के तहत रिकॉर्ड करती है। रिकॉर्ड सेवा पुनःआरंभ या कॉन्फ़िगरेशन रीलोड के बाद भी रहते हैं, लेकिन compressor सत्रों को पार नहीं करते। किसी विंडो को बंद करने पर उसका रिकॉर्ड हटा दिया जाता है। यदि कोई मॉनिटर गायब हो जाता है, तो पुनर्स्थापन उपलब्ध आउटपुट का उपयोग करता है। एक गायब या विफल पुनर्प्राप्ति बार नई न्यूनतमकरण को रोकता है; विफल पुनर्स्थापन रिकॉर्ड और पुनर्प्राप्ति बार को बनाए रखता है।

सत्र के पास `argvus-windows.service` और `argvus-window-bar.service` हैं। बाद वाला अपने Waybar चाइल्ड को Tile में निष्क्रिय रखता है। hyprbars प्लगइन `argvus-hyprland` द्वारा बंडल किया गया है, जो Hyprland 0.57.0 ABI के लिए x86_64 पर बनाया गया है; इसे उपयोगकर्ता के होम डायरेक्टरी में संकलित नहीं किया गया है। कंपोज़िटर ABI अपडेट के साथ प्लगइन को पुनर्निर्माण करें।

सत्र सभी दस ARGVUS भाषाओं के लिए चयनित UTF-8 लोकल को प्रसारित करता है, जिसमें चीनी, जापानी और कोरियाई शामिल हैं। कैटलॉग चयन `argvus i18n` द्वारा प्रबंधित किया जाता है; सिस्टम लोकल उपलब्धता और फ़ॉन्ट फॉलबैक अलग आवश्यकताएँ हैं।
