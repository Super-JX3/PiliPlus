package com.example.piliplus;

import android.content.Context;
import android.util.Log;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;

import java.lang.reflect.Method;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

final class MpvHdrSurface extends PlatformViewFactory {
    static final String TYPE = "piliplus/mpv_hdr";
    private final BinaryMessenger messenger;

    MpvHdrSurface(BinaryMessenger messenger) {
        super(StandardMessageCodec.INSTANCE);
        this.messenger = messenger;
    }

    @Override
    public PlatformView create(Context context, int id, Object args) {
        return new Output(context, new MethodChannel(messenger, TYPE + "/" + id));
    }

    private static final class Output implements PlatformView, SurfaceHolder.Callback {
        private final SurfaceView view;
        private final MethodChannel channel;
        private long wid;

        Output(Context context, MethodChannel channel) {
            this.channel = channel;
            view = new SurfaceView(context);
            view.setZOrderMediaOverlay(true);
            view.getHolder().addCallback(this);
        }

        @Override
        public View getView() {
            return view;
        }

        @Override
        public void surfaceCreated(SurfaceHolder holder) {
            try {
                Class<?> helper = Class.forName(
                        "com.alexmercerind.mediakitandroidhelper.MediaKitAndroidHelper");
                Method method = helper.getDeclaredMethod("newGlobalObjectRef", Object.class);
                method.setAccessible(true);
                Surface surface = holder.getSurface();
                wid = (long) method.invoke(null, surface);
                if (wid == 0) {
                    channel.invokeMethod("surface", -1);
                } else {
                    channel.invokeMethod("surface", wid);
                }
            } catch (ReflectiveOperationException | RuntimeException error) {
                Log.e("PiliMpvHDR", "Could not retain mpv video surface", error);
                channel.invokeMethod("surface", -1);
            }
        }

        @Override
        public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {}

        @Override
        public void surfaceDestroyed(SurfaceHolder holder) {
            detach();
        }

        @Override
        public void dispose() {
            view.getHolder().removeCallback(this);
            detach();
        }

        private void detach() {
            final long previous = wid;
            if (previous == 0) return;
            wid = 0;
            // Keep the JNI reference valid until Dart has detached it from mpv.
            channel.invokeMethod("surface", 0, new MethodChannel.Result() {
                @Override public void success(Object result) { release(previous); }
                @Override public void error(String code, String message, Object details) {
                    release(previous);
                }
                @Override public void notImplemented() { release(previous); }
            });
        }

        private static void release(long reference) {
            try {
                Class<?> helper = Class.forName(
                        "com.alexmercerind.mediakitandroidhelper.MediaKitAndroidHelper");
                Method method = helper.getDeclaredMethod("deleteGlobalObjectRef", long.class);
                method.setAccessible(true);
                method.invoke(null, reference);
            } catch (ReflectiveOperationException | RuntimeException error) {
                Log.e("PiliMpvHDR", "Could not release mpv video surface", error);
            }
        }
    }
}
