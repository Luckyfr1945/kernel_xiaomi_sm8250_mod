# Ki-kernel for POCO F4 / Redmi K40S (munch)

**Build Date:** 2026-10-03  
**Kernel Version:** Linux 4.19.325  
**Variant:** MIUI / HyperOS & AOSP
**Toolchain:** ZyCromerZ Clang 16.0.6 (LLVM 16.0.6 + GNU Binutils 2.47)  

---

## v1.4 P2
• Added WCD938x Hi-Fi audio and UHQA tuning
• Improved USB Audio and external DAC support
• Improved battery safety and bypass charging
• Enabled BBRv3 and built-in WireGuard
• Added Deadline, Kyber and Maple I/O schedulers
• Switched default ZRAM compression to LZ4
• Added KCAL hardware color control
• Fixed KernelSU / SuSFS root detection
• Fixed AOSP boot, lockscreen and display stability issues
• Fixed Adreno 650 undervolt and GPU lockups
• Improved gaming performance and CPU / memory tuning
• Improved touchscreen and DC Dimming handling
• Added Boeffla Wakelock Blocker
• Enabled non-root and Shizuku bypass charging access (writable sysfs + SELinux untrusted_app support)
• Integrated Focaltech Touch Game Mode (low-latency high report rate) into Ki-Profile Performance mode
• Integrated Adreno 650 GPU Turbo clock floor into Ki-Profile Performance mode
• Fixed MIUI / AOSP flashing issues
• Unified Android 14–17 AOSP and MIUI / HyperOS support

---

## v1.4
• Switched default ZRAM compression to LZ4
• Fixed hardware DC Dimming
• Tuned Ki-Profile for higher gaming performance
• Improved CPU migration and schedutil response
• Tuned RAM, VM and kswapd behavior
• Improved Force Fast Charge and Screen-On Fast Charge
• Set ZRAM and system swappiness to 90
• Backported Binder TF_CLEAR_BUF support
• Added USB UAS support
• Added NTFS filesystem support
• Fixed CPU idle frequency and wake-from-idle issues
• Fixed MIUI and AnyKernel3 flashing issues
• Backported epoll_pwait2 and improved TCP Westwood
• Optimized CFS load balancing
• Optimized Focaltech touch and aw86927 haptic handling
• Removed Adreno POPP throttling and Wi-Fi debug wakelocks
• Added Boeffla Wakelock Blocker
• Improved Deep Sleep and suspend behavior
• Added Virtual A/B snapshot support
• Tuned F2FS background GC
• Improved GPU and touchscreen thread scheduling
• Enabled Clang ThinLTO
---

## v1.3
• Added in-kernel ki_profile switcher (Battery / Balanced / Performance)
• Added Dynamic Fsync
• Migrated to ReSukiSU v4.2.0
• Backported NTSYNC driver
• Upstream SUSFS v2.3.0
• Improved CPU idle frequency handling
• Added I/O wait boost limits
• Fixed Wi-Fi hotspot and tethering
• Improved bypass charging handling
• Migrated to ZyCromerZ Clang 16.0.6

---
  <a href="https://t.me/+i7NfuXZA6mZjOWJl">
    <img src="https://img.shields.io/badge/Telegram-26A5E4?style=for-the-badge&logo=telegram&logoColor=white" alt="Telegram">
  </a>

