package io.github.v7lin.fakepush;

import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import android.util.Log;

import com.tencent.android.tpush.XGIOperateCallback;
import com.tencent.android.tpush.XGPushConfig;
import com.tencent.android.tpush.XGPushManager;

import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.view.FlutterNativeView;
import io.github.v7lin.fakepush.util.NotificationManagerCompat;
import xinge.push.stub.android.XinGeConstants;

/**
 * FakePushPlugin
 */
public class FakePushPlugin implements MethodCallHandler, PluginRegistry.NewIntentListener, PluginRegistry.UserLeaveHintListener, PluginRegistry.ActivityResultListener, PluginRegistry.ViewDestroyListener {
    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "v7lin.github.io/fake_push");
        FakePushPlugin plugin = new FakePushPlugin(registrar, channel);
        registrar.addNewIntentListener(plugin);
        registrar.addUserLeaveHintListener(plugin);
        registrar.addActivityResultListener(plugin);
        registrar.addViewDestroyListener(plugin);
        channel.setMethodCallHandler(plugin);
    }

    private static final String METHOD_ARENOTIFICATIONSENABLED = "areNotificationsEnabled";
    private static final String METHOD_OPENNOTIFICATIONSSETTINGS = "openNotificationsSettings";
    private static final String METHOD_STARTWORK = "startWork";
    private static final String METHOD_STOPWORK = "stopWork";
    private static final String METHOD_GETDEVICETOKEN = "getDeviceToken";
    private static final String METHOD_BINDACCOUNT = "bindAccount";
    private static final String METHOD_UNBINDACCOUNT = "unbindAccount";
    private static final String METHOD_BINDTAGS = "bindTags";
    private static final String METHOD_UNBINDTAGS = "unbindTags";

    private static final String METHOD_ONRECEIVEDEVICETOKEN = "onReceiveDeviceToken";
    private static final String METHOD_ONRECEIVEMESSAGE = "onReceiveMessage";
    private static final String METHOD_ONRECEIVENOTIFICATION = "onReceiveNotification";
    private static final String METHOD_ONLAUNCHNOTIFICATION = "onLaunchNotification";
    private static final String METHOD_ONRESUMENOTIFICATION = "onResumeNotification";

    private static final String ARGUMENT_KEY_ENABLEDEBUG = "enableDebug";
    private static final String ARGUMENT_KEY_ACCOUNT = "account";
    private static final String ARGUMENT_KEY_TAGS = "tags";

    public static final String ARGUMENT_KEY_RESULT_TITLE = "title";
    public static final String ARGUMENT_KEY_RESULT_CONTENT = "content";
    public static final String ARGUMENT_KEY_RESULT_CUSTOMCONTENT = "customContent";

    private final Registrar registrar;
    private final MethodChannel channel;
    private final AtomicBoolean register = new AtomicBoolean(false);

    private FakePushPlugin(Registrar registrar, MethodChannel channel) {
        this.registrar = registrar;
        this.channel = channel;
        if (register.compareAndSet(false, true)) {
            PushMSGReceiver.registerReceiver(registrar.context(), pushMSGReceiver);
        }
    }

    private PushMSGReceiver pushMSGReceiver = new PushMSGReceiver() {
        @Override
        public void onReceiveMessage(Context context, Map<String, Object> map) {
            channel.invokeMethod(METHOD_ONRECEIVEMESSAGE, map);
        }

        @Override
        public void onReceiveNotification(Context context, Map<String, Object> map) {
            channel.invokeMethod(METHOD_ONRECEIVENOTIFICATION, map);
        }
    };

    @Override
    public void onMethodCall(MethodCall call, final Result result) {
        if (METHOD_ARENOTIFICATIONSENABLED.equals(call.method)) {
            result.success(NotificationManagerCompat.from(registrar.context()).areNotificationsEnabled());
        } else if (METHOD_OPENNOTIFICATIONSSETTINGS.equals(call.method)) {
            openNotificationsSettings(call, result);
        } else if (METHOD_STARTWORK.equals(call.method)) {
            startWork(call, result);
        } else if (METHOD_STOPWORK.equals(call.method)) {
            stopWork(call, result);
        } else if (METHOD_GETDEVICETOKEN.equals(call.method)) {
            result.success(XGPushConfig.getToken(registrar.context()));
        } else if (METHOD_BINDACCOUNT.equals(call.method)) {
            bindAccount(call, result);
        } else if (METHOD_UNBINDACCOUNT.equals(call.method)) {
            unbindAccount(call, result);
        } else if (METHOD_BINDTAGS.equals(call.method)) {
            bindTags(call, result);
        } else if (METHOD_UNBINDTAGS.equals(call.method)) {
            unbindTags(call, result);
        } else {
            result.notImplemented();
        }
    }

    private void openNotificationsSettings(MethodCall call, final Result result) {
        Intent intent = new Intent();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            intent.setAction(Settings.ACTION_APP_NOTIFICATION_SETTINGS);
            intent.putExtra(Settings.EXTRA_APP_PACKAGE, registrar.context().getPackageName());
//            intent.putExtra(Settings.EXTRA_CHANNEL_ID, registrar.context().getApplicationInfo().uid);
        } else {
            intent.setAction(Settings.ACTION_APP_NOTIFICATION_SETTINGS);
            intent.putExtra("app_package", registrar.context().getPackageName());
            intent.putExtra("app_uid", registrar.context().getApplicationInfo().uid);
        }
        if (intent.resolveActivity(registrar.context().getPackageManager()) != null) {
            intent.setAction(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
            intent.setData(Uri.fromParts("package", registrar.context().getPackageName(), null));
        }
        registrar.activity().startActivity(intent);

        result.success(null);
    }

    private void startWork(MethodCall call, final Result result) {
        boolean enableDebug = call.argument(ARGUMENT_KEY_ENABLEDEBUG);
        XGPushConfig.enableDebug(registrar.context(), enableDebug);

        try {
            ApplicationInfo appInfo = registrar.context().getPackageManager().getApplicationInfo(registrar.context().getPackageName(), PackageManager.GET_META_DATA);
            XGPushConfig.enableOtherPush(registrar.context(), true);
            XGPushConfig.setHuaweiDebug(enableDebug);
            XGPushConfig.setMiPushAppId(registrar.context(), appInfo.metaData.getString(XinGeConstants.META_KEY_XIAOMI_APPID));
            XGPushConfig.setMiPushAppKey(registrar.context(), appInfo.metaData.getString(XinGeConstants.META_KEY_XIAOMI_APPKEY));
            XGPushConfig.setMzPushAppId(registrar.context(), appInfo.metaData.getString(XinGeConstants.META_KEY_MEIZU_APPID));
            XGPushConfig.setMzPushAppKey(registrar.context(), appInfo.metaData.getString(XinGeConstants.META_KEY_MEIZU_APPKEY));
        } catch (PackageManager.NameNotFoundException ignore) {
        }

        XGPushManager.registerPush(registrar.context(), new XGIOperateCallback() {
            @Override
            public void onSuccess(Object data, int flag) {
                //token在设备卸载重装的时候有可能会变
                Log.d("TPush", "注册成功，设备token为：" + data);
                if (registrar.activity() != null && !registrar.activity().isFinishing()) {
                    registrar.activity().runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            channel.invokeMethod(METHOD_ONRECEIVEDEVICETOKEN, XGPushConfig.getToken(registrar.context()));
                        }
                    });
                }
            }

            @Override
            public void onFail(Object data, int errCode, String msg) {
                Log.d("TPush", "注册失败，错误码：" + errCode + ",错误信息：" + msg);
            }
        });

        if (registrar.activity() != null) {
            handleNotificationClickedFromIntent(METHOD_ONLAUNCHNOTIFICATION, registrar.activity().getIntent());
        }

        result.success(null);
    }

    private void stopWork(MethodCall call, final Result result) {
        XGPushManager.unregisterPush(registrar.context(), new XGIOperateCallback() {
            @Override
            public void onSuccess(Object data, int flag) {

            }

            @Override
            public void onFail(Object data, int errCode, String msg) {

            }
        });

        result.success(null);
    }

    private void bindAccount(MethodCall call, final Result result) {
        String account = call.argument(ARGUMENT_KEY_ACCOUNT);
        XGPushManager.bindAccount(registrar.context(), account, new XGIOperateCallback() {
            @Override
            public void onSuccess(Object data, int flag) {

            }

            @Override
            public void onFail(Object data, int errCode, String msg) {

            }
        });

        result.success(null);
    }

    private void unbindAccount(MethodCall call, final Result result) {
        String account = call.argument(ARGUMENT_KEY_ACCOUNT);
        XGPushManager.delAccount(registrar.context(), account, new XGIOperateCallback() {
            @Override
            public void onSuccess(Object data, int flag) {

            }

            @Override
            public void onFail(Object data, int errCode, String msg) {

            }
        });

        result.success(null);
    }

    private void bindTags(MethodCall call, final Result result) {
        List<String> tags = call.argument(ARGUMENT_KEY_TAGS);
        XGPushManager.setTags(registrar.context(), "bindTags:" + tags.hashCode(), new HashSet<>(tags));

        result.success(null);
    }

    private void unbindTags(MethodCall call, final Result result) {
        List<String> tags = call.argument(ARGUMENT_KEY_TAGS);
        XGPushManager.deleteTags(registrar.context(), "unbindTags:" + tags.hashCode(), new HashSet<>(tags));

        result.success(null);
    }

    private boolean handleNotificationClickedFromIntent(String method, Intent intent) {
        Map<String, Object> map = PushMSGReceiver.extraMapClick(intent);
        if (map != null) {
            channel.invokeMethod(method, map);
            return true;
        }
        return false;
    }

    // --- NewIntentListener

    @Override
    public boolean onNewIntent(Intent intent) {
        boolean res = handleNotificationClickedFromIntent(METHOD_ONRESUMENOTIFICATION, intent);
        if (res && registrar.activity() != null) {
            registrar.activity().setIntent(intent);
        }
        return res;
    }

    // --- UserLeaveHintListener

    @Override
    public void onUserLeaveHint() {
        // 应用退到后台
    }

    // --- ActivityResultListener

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        return false;
    }

    // --- ViewDestroyListener

    @Override
    public boolean onViewDestroy(FlutterNativeView flutterNativeView) {
        if (register.compareAndSet(true, false)) {
            PushMSGReceiver.unregisterReceiver(registrar.context(), pushMSGReceiver);
        }
        return false;
    }
}
