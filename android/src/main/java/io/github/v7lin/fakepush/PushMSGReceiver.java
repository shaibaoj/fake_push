package io.github.v7lin.fakepush;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.Uri;
import android.text.TextUtils;

import com.tencent.android.tpush.XGPushShowedResult;
import com.tencent.android.tpush.XGPushTextMessage;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import io.github.v7lin.fakepush.util.JsonUtils;

public abstract class PushMSGReceiver extends BroadcastReceiver {
    private static final String ACTION_RECEIVE_MESSAGE = "fake_push.action.RECEIVE_MESSAGE";
    private static final String ACTION_RECEIVE_NOTIFICATION = "fake_push.action.RECEIVE_NOTIFICATION";

    private static final String KEY_EXTRA_MAP = "extraMap";

    private static final int PUSH_CHANNEL_XIAOMI = 3;
    private static final int PUSH_CHANNEL_HUAWEI = 4;

    @Override
    public final void onReceive(Context context, Intent intent) {
        if (TextUtils.equals(ACTION_RECEIVE_MESSAGE, intent.getAction())) {
            onReceiveMessage(context, extraMap(intent));
        } else if (TextUtils.equals(ACTION_RECEIVE_NOTIFICATION, intent.getAction())) {
            onReceiveNotification(context, extraMap(intent));
        }
    }

    private Map<String, Object> extraMap(Intent intent) {
        String json = intent.getStringExtra(KEY_EXTRA_MAP);
        return JsonUtils.toMap(json);
    }

    public abstract void onReceiveMessage(Context context, Map<String, Object> map);

    public abstract void onReceiveNotification(Context context, Map<String, Object> map);

    public static <PR extends PushMSGReceiver> void registerReceiver(Context context, PR receiver) {
        IntentFilter intentFilter = new IntentFilter();
        intentFilter.addAction(ACTION_RECEIVE_NOTIFICATION);
        intentFilter.addAction(ACTION_RECEIVE_MESSAGE);
        context.registerReceiver(receiver, intentFilter);
    }

    public static <PR extends PushMSGReceiver> void unregisterReceiver(Context context, PR receiver) {
        context.unregisterReceiver(receiver);
    }

    public static void receiveMessage(Context context, XGPushTextMessage message) {
        Map<String, Object> map = new HashMap<>();
        map.put(FakePushPlugin.ARGUMENT_KEY_RESULT_TITLE, message.getTitle());
        // 信鸽BUG？
        // 华为通道 content 为 json
        // 华为通道 customContent 喂狗了
        String dest = null;
        if (message.getPushChannel() == PUSH_CHANNEL_HUAWEI) {
            Map<String, Object> content = JsonUtils.toMap(message.getContent());
            Object value = content.get("content");
            if (value != null && value instanceof String) {
                dest = (String) value;
            }
        } else {
            dest = message.getContent();
        }
        map.put(FakePushPlugin.ARGUMENT_KEY_RESULT_CONTENT, dest);
        map.put(FakePushPlugin.ARGUMENT_KEY_RESULT_CUSTOMCONTENT, message.getCustomContent());

        Intent receiver = new Intent();
        receiver.setAction(ACTION_RECEIVE_MESSAGE);
        receiver.putExtra(KEY_EXTRA_MAP, JsonUtils.toJson(map));
        receiver.setPackage(context.getPackageName());
        context.sendBroadcast(receiver);
    }

    public static void receiveNotification(Context context, XGPushShowedResult message) {
        Map<String, Object> map = new HashMap<>();
        map.put(FakePushPlugin.ARGUMENT_KEY_RESULT_TITLE, message.getTitle());
        map.put(FakePushPlugin.ARGUMENT_KEY_RESULT_CONTENT, message.getContent());
        Map<String, Object> dest = new HashMap<>();
        // 信鸽BUG？
        // 华为通道 notificationActionType = 1
        // 信鸽通道 notificationActionType = 3
        if ((message.getPushChannel() == PUSH_CHANNEL_XIAOMI && message.getNotificationActionType() == XGPushShowedResult.NOTIFICATION_ACTION_ACTIVITY)
                || message.getNotificationActionType() == XGPushShowedResult.NOTIFICATION_ACTION_INTENT) {
            Map<String, Object> customContent = JsonUtils.toMap(message.getCustomContent());
            Object intentUri = customContent.get("intent_uri");
            if (intentUri != null && intentUri instanceof String) {
                Uri uri = Uri.parse((String) intentUri);
                Set<String> keys = uri.getQueryParameterNames();
                if (keys != null && !keys.isEmpty()) {
                    for (String key : keys) {
                        if (!TextUtils.isEmpty(key)) {
                            List<String> values = uri.getQueryParameters(key);
                            if (values != null && !values.isEmpty()) {
                                if (values.size() == 1) {
                                    dest.put(key, values.get(0));
                                } else {
                                    dest.put(key, values);
                                }
                            }
                        }
                    }
                }
            }
        }
        map.put(FakePushPlugin.ARGUMENT_KEY_RESULT_CUSTOMCONTENT, JsonUtils.toJson(dest));

        Intent receiver = new Intent();
        receiver.setAction(ACTION_RECEIVE_NOTIFICATION);
        receiver.putExtra(KEY_EXTRA_MAP, JsonUtils.toJson(map));
        receiver.setPackage(context.getPackageName());
        context.sendBroadcast(receiver);
    }
}
