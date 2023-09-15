package com.mamasodikov.zkfinger10.util;

import android.content.Context;
import android.view.Gravity;
import android.widget.Toast;

public class ToastUtils {


    public static void show(Context context, String content) {
        Toast toast = Toast.makeText(context, content, Toast.LENGTH_SHORT);
        toast.setGravity(Gravity.CENTER, 0, 0);
        toast.show();
    }
}
