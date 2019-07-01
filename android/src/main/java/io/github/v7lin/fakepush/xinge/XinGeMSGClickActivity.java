package io.github.v7lin.fakepush.xinge;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.text.TextUtils;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import io.github.v7lin.fakepush.util.JsonUtils;

public class XinGeMSGClickActivity extends Activity {

    private static final String KEY_NOTIFACTION_CLICKED = "notifaction_clicked";
    private static final String KEY_CUSTOMCONTENT = "customContent";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        handleIntent(getIntent());
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        handleIntent(intent);
    }

    private void handleIntent(Intent intent) {
        Intent launchIntent = getPackageManager().getLaunchIntentForPackage(getPackageName());
        launchIntent.putExtra(KEY_NOTIFACTION_CLICKED, true);
        Map<String, Object> map = new HashMap<>();
        if (intent.getData() != null) {
            Uri uri = intent.getData();
            Set<String> keys = uri.getQueryParameterNames();
            if (keys != null && !keys.isEmpty()) {
                for (String key : keys) {
                    if (!TextUtils.isEmpty(key)) {
                        List<String> values = uri.getQueryParameters(key);
                        if (values != null && !values.isEmpty()) {
                            if (values.size() == 1) {
                                map.put(key, values.get(0));
                            } else {
                                map.put(key, values);
                            }
                        }
                    }
                }
            }
        }
        launchIntent.putExtra(KEY_CUSTOMCONTENT, JsonUtils.toJson(map));
        launchIntent.setPackage(getPackageName());
        launchIntent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
        startActivity(launchIntent);
        finish();
    }

    public static String extraClick(Intent intent) {
        if (intent.getExtras() != null && intent.getBooleanExtra(KEY_NOTIFACTION_CLICKED, false)) {
            String customContent = intent.getStringExtra(KEY_CUSTOMCONTENT);
            intent.removeExtra(KEY_NOTIFACTION_CLICKED);
            intent.removeExtra(KEY_CUSTOMCONTENT);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                intent.removeFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
            } else {
                int flags = intent.getFlags();
                flags &= ~Intent.FLAG_ACTIVITY_CLEAR_TOP;
                intent.setFlags(flags);
            }
            return customContent;
        }
        return null;
    }
}
