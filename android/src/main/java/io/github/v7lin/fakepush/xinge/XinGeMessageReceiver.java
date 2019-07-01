package io.github.v7lin.fakepush.xinge;

import android.content.Context;

import com.tencent.android.tpush.XGPushBaseReceiver;
import com.tencent.android.tpush.XGPushClickedResult;
import com.tencent.android.tpush.XGPushRegisterResult;
import com.tencent.android.tpush.XGPushShowedResult;
import com.tencent.android.tpush.XGPushTextMessage;

import io.github.v7lin.fakepush.PushMSGReceiver;

public class XinGeMessageReceiver extends XGPushBaseReceiver {
    @Override
    public void onRegisterResult(Context context, int errorCode, XGPushRegisterResult message) {
        // 注册的回调
    }

    @Override
    public void onUnregisterResult(Context context, int errorCode) {
        // 反注册的回调
    }

    @Override
    public void onSetTagResult(Context context, int errorCode, String tagName) {
        // 设置tag的回调
    }

    @Override
    public void onDeleteTagResult(Context context, int errorCode, String tagName) {
        // 删除tag的回调
    }

    @Override
    public void onTextMessage(Context context, XGPushTextMessage message) {
        // 消息透传的回调
        PushMSGReceiver.receiveMessage(context, message);
    }

    @Override
    public void onNotifactionClickedResult(Context context, XGPushClickedResult message) {
        // 通知点击回调 actionType=1为该消息被清除，actionType=0为该消息被点击。
        // 此处不能做点击消息跳转，详细方法请参照官网的Android常见问题文档
    }

    @Override
    public void onNotifactionShowedResult(Context context, XGPushShowedResult message) {
        // 通知展示
        // notificationActionType==1为Activity，2为url，3为intent
        // Activity,url,intent都可以通过getActivity()获得
        PushMSGReceiver.receiveNotification(context, message);
    }
}
