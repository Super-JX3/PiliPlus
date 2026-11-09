# mpv HDR validation builds

In the fork's GitHub Actions, select **Build → Run workflow**, choose
`test/mpv-hdr-output`, enable all five build targets, and leave `tag` empty.
Download the packages from the run's **Artifacts** section. Android builds
cover arm64-v8a, armeabi-v7a and x86_64. The iOS IPA requires signing for device
installation.

| Platform | Playback path in this experiment |
| --- | --- |
| Android | mpv with MediaCodec and SurfaceView |
| macOS | Separate mpv window using gpu-next and macvk |
| Windows x64 | Separate mpv window using gpu-next and D3D11 |
| Linux x64 (Wayland) | Separate mpv window using gpu-next and waylandvk |
| Linux x64 (X11), iOS and iPadOS | Existing player |

On a platform with an experimental path, open **设置 → 播放器设置**,
turn on **mpv HDR 直出（实验）**, reopen an online video and choose **HDR 真彩**
or **杜比视界**. The switch defaults to off. Linux HDR output depends on the
system libmpv build, Vulkan driver, Wayland compositor and HDR display.

On Android, the selected Dolby Vision player takes precedence when it is
set to Media3. The native HDR10 switch takes precedence for HDR 真彩 only.
To test mpv for either quality, select mpv for Dolby Vision or turn off
native HDR10 for HDR 真彩, then reopen the video.

Record build results separately from device results. For device testing,
record the OS, display, video ID and quality. Compare HDR10 and Dolby Vision
samples where available, check the display's HDR status and picture color,
then switch to SDR and confirm embedded playback resumes. Mark platforms
without a test device as untested.
