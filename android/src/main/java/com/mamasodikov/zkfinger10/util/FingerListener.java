package com.mamasodikov.zkfinger10.util;

import android.graphics.Bitmap;

public interface FingerListener {

    void onStatusChange(String message, FingerStatusType fingerStatusType, String id, String data);

    void onCaptureFinger(Bitmap fingerBitmap);

}
