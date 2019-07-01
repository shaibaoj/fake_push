package io.github.v7lin.fakepush.xinge;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.net.UrlQuerySanitizer;
import android.os.Bundle;
import android.text.TextUtils;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

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
            UrlQuerySanitizer sanitizer = new UrlQuerySanitizer();
            sanitizer.setUnregisteredParameterValueSanitizer(UrlQuerySanitizer.getAllButNulLegal());
            sanitizer.parseUrl(uri.toString());
            List<UrlQuerySanitizer.ParameterValuePair> pairs = sanitizer.getParameterList();
            if (pairs != null && !pairs.isEmpty()) {
                for (UrlQuerySanitizer.ParameterValuePair pair : pairs) {
                    if (!TextUtils.isEmpty(pair.mParameter) && !TextUtils.isEmpty(pair.mValue)) {
                        map.put(pair.mParameter, pair.mValue);
                    }
                }
            }
        }
        launchIntent.putExtra(KEY_CUSTOMCONTENT, JsonUtils.toJson(map));
        launchIntent.setPackage(getPackageName());
        launchIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivity(launchIntent);
        finish();
    }

    public static String extraClick(Intent intent) {
        if (intent.getExtras() != null && intent.getBooleanExtra(KEY_NOTIFACTION_CLICKED, false)) {
            String customContent = intent.getStringExtra(KEY_CUSTOMCONTENT);
            intent.removeExtra(KEY_NOTIFACTION_CLICKED);
            intent.removeExtra(KEY_CUSTOMCONTENT);
            return customContent;
        }
        return null;
    }
}
