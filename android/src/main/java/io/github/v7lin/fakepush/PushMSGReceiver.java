package io.github.v7lin.fakepush;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.text.TextUtils;

import com.tencent.android.tpush.XGPushClickedResult;
import com.tencent.android.tpush.XGPushManager;
import com.tencent.android.tpush.XGPushShowedResult;
import com.tencent.android.tpush.XGPushTextMessage;

import java.io.Serializable;
import java.util.HashMap;
import java.util.Map;

import io.github.v7lin.fakepush.util.JsonUtils;

public abstract class PushMSGReceiver extends BroadcastReceiver {
    private static final String ACTION_RECEIVE_MESSAGE = "fake_push.action.RECEIVE_MESSAGE";
    private static final String ACTION_RECEIVE_NOTIFICATION = "fake_push.action.RECEIVE_NOTIFICATION";

    private static final String KEY_EXTRA_MAP = "extraMap";

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
        map.put(FakePushPlugin.ARGUMENT_KEY_RESULT_CONTENT, message.getContent());
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
        map.put(FakePushPlugin.ARGUMENT_KEY_RESULT_CUSTOMCONTENT, message.getCustomContent());

        Intent receiver = new Intent();
        receiver.setAction(ACTION_RECEIVE_NOTIFICATION);
        receiver.putExtra(KEY_EXTRA_MAP, JsonUtils.toJson(map));
        receiver.setPackage(context.getPackageName());
        context.sendBroadcast(receiver);
    }
}
