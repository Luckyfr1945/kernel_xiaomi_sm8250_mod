# Ki-kernel for POCO F4 / Redmi K40S (munch)

**Build Date:** 2026-10-03  
**Kernel Version:** Linux 4.19.325  
**Variant:** MIUI / HyperOS & AOSP
**Toolchain:** ZyCromerZ Clang 16.0.6 (LLVM 16.0.6 + GNU Binutils 2.47)  

---

## v1.4 P6 (KCAL Color Calibration & KernelSU SuSFS Fix)
• KCAL Advanced Color Calibration:
  - Implemented guarded KCAL driver via Qualcomm SDE DSPP PCC hardware
  - Exposes sysfs interface at `/sys/devices/platform/kcal_ctrl.0/` compatible with standard KCAL apps
  - Supports: RGB (`kcal`), saturation (`kcal_sat`), brightness (`kcal_val`), contrast (`kcal_cont`), hue (`kcal_hue`), invert (`kcal_invert`), min value (`kcal_min`)
  - Auto-enables on slider adjustments and auto-reapplies on display resume
  - Full hardware configuration setup across active DSPP blocks and color management pipelines
  - Safety guards: skips PCC updates during FOD/HBM fingerprint overlay to prevent display freeze
• KernelSU + SuSFS Root Restoration:
  - Reverted unintended manual hook switch and restored native SuSFS inline hooks (`CONFIG_KSU_SUSFS=y`)
  - Restored proper `ksu_handle_sys_read` and `ksu_is_init_rc_hook_enabled` hooks in `fs/read_write.c`
  - Cleaned up manual hook artifacts from `fs/stat.c`
  - Fixed KernelSU root detection so manager properly recognizes root without "Unsupported" state

---

## v1.4 P5 (GPU OC/UV, BBRv3, Kyber I/O & Official Naming)
• GPU Overclock & Undervolt:
  - Adreno 650 Overclocked to 683 MHz (`0x28b5c0c0`) on speed-bins 1, 2, and 4
  - Applied Konabess Undervolt profile (RPMh levels 225, 129, 66, 1) across all power levels for cooler thermals and sustained high FPS
• Networking & TCP:
  - Restored full TCP BBRv3 with ECN response tuning, Protective Load Balancing (PLB), and fast RTT probing
  - Enabled `CONFIG_TCP_CONG_BBR` in defconfig alongside Westwood
• Storage & I/O:
  - Enabled Kyber I/O Scheduler (`CONFIG_MQ_IOSCHED_KYBER`) native for UFS 3.1 multi-queue (`blk-mq`) storage
• Kernel Identity & Release Cleanup:
  - Restored classic Ki-kernel v1.4 name and AnyKernel3 banner
  - Restored `build-user@build-host 4.19.404R` banner for NoKontzzzManager (NKM) detection
  - Suppressed automatic git commit hash suffix via `.scmversion` and disabled `CONFIG_LOCALVERSION_AUTO`
  - Removed upstream CIP/ST suffix (`-cip135-st19`) for a clean release string: `4.19.325-ki-kernel-v1.4`

---

## v1.4 P4 (Stability Overhaul & Boot Crash Fix)
• Fixed Boot Freeze, kpanic & Recovery Reboot on AOSP:
  - Reverted experimental broken pipe interception (`fs/pipe.c`) to eliminate Android SystemServer & Netd IPC deadlocks
  - Restored Qualcomm MSM `ramoops_memreserve` (4MB @ 0xb0000000) passed by Munch bootloader, preventing kernel buddy allocator from corrupting protected hardware/modem memory
  - Defaulted Boeffla Wakelock Blocker to empty list (`""`) on boot to prevent breaking cellular network registration and `netmgr_wl`
  - Restored stock hardware watchdog timing (20s bark / 15s pet) in device tree (`xiaomi-sm8250-common.dtsi`)
  - Restored standard SELinux MAC handling on kernfs sysfs nodes
  - Deferred Ki-Profile background application to 45 seconds for smooth, reliable userspace boot settlement

---

## v1.4 P3 (Hotfix: Lockscreen & Display Stability)
• Resolved Lockscreen HWUI dequeueBuffer ETIMEDOUT (-110) & 480 frames skipped freeze:
  - Reverted experimental SDE plane QoS throttling (`sde_plane.c`) to maintain continuous real-time memory bandwidth for display scanout pipes
  - Restored DRM panel FPS change notifier chain (`sde_kms.c`) so 60Hz ↔ 120Hz refresh rate transitions properly sync with DSI panel timing and WALT scheduler
• Fixed GPU Undervolt & Lockup: Restored official Qualcomm Adreno 650 OPP table with correct RPMh regulator corner voltages
• Fixed Hardware Memory Collision: Removed conflicting ramoops node colliding with QCA6390 WLAN hardware registers
• Guarded KGSL performance switcher with `KGSL_STATE_ACTIVE` check to prevent early boot GMU timeouts
• Clamped schedutil up/down rate limits floor to 500us/1000us to eliminate context-switch clock thrashing
• Defaulted Dynamic Fsync to disabled on early boot for SQLite / SystemUI database integrity

---

## v1.4 P2
• Unified & Ported all optimizations to Astide Base (Android 14-17 AOSP & MIUI/HyperOS)
• Extreme Gaming Performance Mode Overhaul (WuWa / Heavy Games Edition):
  - Adreno 650 GPU floor frequency locked to 510 MHz (runs only at 510, 587, and 683 MHz OC, eliminating mid-game frame drops)
  - DDR AXI Bus locked high (`force_bus_on = 1`) to eliminate 3D texture & shader streaming hitches
  - Disabled internal Adreno cycle-skipping clock throttling in Performance mode
  - Extended GPU idle timeout to 1000ms for stable inter-frame clock pacing
  - Added CPU Instant Snap Hispeed (`sugov_set_cluster_hispeed`) — snaps to max turbo (1.80/2.42/3.19 GHz) at 35-40% load without relying on Android WALT RTG classification
  - Extended cpufreq down-rate delay to 25ms to maintain peak clock speeds across 60, 90, and 120 FPS frame intervals
  - Bypassed Qualcomm thermal CPU core isolation (`cpu_isolate`) and GPU devfreq throttling in Performance mode — all 8 cores stay active
  - Auto-revive all isolated cores (`sched_unisolate_cpu`) upon activating Performance mode
  - Optimized VFS cache pressure and memory headroom for heavy 4GB+ games
• Added Maple I/O Scheduler (Android flash/UFS 3.1 optimized FIFO scheduler)
• Auto-populated Boeffla Wakelock Blocker on boot (wlan_pno_wl, wlan_extscan_wl, wlan_wow_wl, netmgr_wl)
• Fixed Focaltech 3658u Touchscreen sleep EIO and CRC abnormal logs on screen off/on
• Fixed Aftermarket / KW LCD DC dimming DCS commands and smart FPS fallback

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

