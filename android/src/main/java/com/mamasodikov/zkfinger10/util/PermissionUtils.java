package com.mamasodikov.zkfinger10.util;

import android.app.Activity;
import android.content.pm.PackageManager;
import android.os.Build;

import androidx.core.app.ActivityCompat;

import java.util.ArrayList;

/**
 * @author Magic
 * @version 创建时间：2020/05/22 上午 9:44
 */
public class PermissionUtils {

    public static ArrayList<String> checkPermissions(Activity activity, String[] permissions) {
        if (activity == null) {
            throw new NullPointerException("activity can't be null");
        }

        ArrayList<String> deniedPermissions = new ArrayList<>();
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return deniedPermissions;
        }
        for (String permission : permissions) {
            if (activity.checkSelfPermission(permission) != PackageManager.PERMISSION_GRANTED) {
                deniedPermissions.add(permission);
            }
        }
        return deniedPermissions;
    }


    public static void requestPermission(Activity activity, String[] permissions, int requestCode) {
        if (activity == null) {
            throw new NullPointerException("activity can't be null");
        }
        ActivityCompat.requestPermissions(activity, permissions, requestCode);
    }
}
