package com.mamasodikov.zkfinger10.ZKUSBManager;

import static android.content.ContentValues.TAG;

import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbManager;
import android.util.Log;

import androidx.annotation.NonNull;

import java.util.Random;

/**
 * usb permission and hotplug
 */
public class ZKUSBManager {
    //usb's vendor id for zkteco
    private int vid = 0x1b55;
    //usb's product id
    private int pid = 0;
    //application context
    private Context mContext = null;

    /////////////////////////////////////////////
    //for usb permission
    private static final String SOURCE_STRING = "0123456789-_abcdefghigklmnopqrstuvwxyzABCDEFGHIGKLMNOPQRSTUVWXYZ";
    private static final int DEFAULT_LENGTH = 16;
    private String ACTION_USB_PERMISSION;
    private boolean mbRegisterFilter = false;
    private ZKUSBManagerListener zknirusbManagerListener = null;

    private BroadcastReceiver usbMgrReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();
            UsbManager usbManager = (UsbManager) mContext.getSystemService(Context.USB_SERVICE);
            UsbDevice usbDevice = null;
            for (UsbDevice device : usbManager.getDeviceList().values()) {
                int device_vid = device.getVendorId();
                int device_pid = device.getProductId();
                if (device_vid == vid && device_pid == pid) {
                    usbDevice = device;
                    break;
                }
            }

            if (ACTION_USB_PERMISSION.equals(action)) {

                if (usbDevice.getVendorId() == vid && usbDevice.getProductId() == pid) {
                    if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
                        zknirusbManagerListener.onCheckPermission(0);
                    } else {
                        zknirusbManagerListener.onCheckPermission(-2);
                    }
                }
            } else if (UsbManager.ACTION_USB_DEVICE_ATTACHED.equals(action)) {
                UsbDevice device = (UsbDevice) intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
                if (device.getVendorId() == vid && device.getProductId() == pid) {
                    zknirusbManagerListener.onUSBArrived(device);
                }
            } else if (UsbManager.ACTION_USB_DEVICE_DETACHED.equals(action)) {
                UsbDevice device = (UsbDevice) intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
                if (device.getVendorId() == vid && device.getProductId() == pid) {
                    zknirusbManagerListener.onUSBRemoved(device);
                }
            }
        }
    };


    private boolean isNullOrEmpty(String target) {
        if (null == target || "".equals(target) || target.isEmpty()) {
            return true;
        }
        return false;
    }

    private String createRandomString(String source, int length) {
        if (this.isNullOrEmpty(source)) {
            return "";
        }

        StringBuffer result = new StringBuffer();
        Random random = new Random();

        for (int index = 0; index < length; index++) {
            result.append(source.charAt(random.nextInt(source.length())));
        }
        return result.toString();
    }

    public boolean registerUSBPermissionReceiver() {
        if (null == mContext || mbRegisterFilter) {
            Log.d("USB Manager", "USB register false");
            return false;
        }
        IntentFilter filter = new IntentFilter();
        filter.addAction(ACTION_USB_PERMISSION);
        filter.addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED);
        filter.addAction(UsbManager.ACTION_USB_DEVICE_DETACHED);
        // Fix for Android API 34+ - specify receiver export flag
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            mContext.registerReceiver(usbMgrReceiver, filter, Context.RECEIVER_NOT_EXPORTED);
        } else {
            mContext.registerReceiver(usbMgrReceiver, filter);
        }
        mbRegisterFilter = true;
        Log.d("USB Manager", "USB register true");
        return true;
    }

    public void unRegisterUSBPermissionReceiver() {
        if (null == mContext || !mbRegisterFilter) {
            return;
        }
        mContext.unregisterReceiver(usbMgrReceiver);
        mbRegisterFilter = false;
    }


    //End USB Permission
    /////////////////////////////////////////////

    public ZKUSBManager(@NonNull Context context, @NonNull ZKUSBManagerListener listener) {
        super();

        Log.d("USB Manager", "USB ========== constructor ");
        if (null == context || null == listener) {
            throw new NullPointerException("context or listener is null");
        }
        zknirusbManagerListener = listener;
        ACTION_USB_PERMISSION = createRandomString(SOURCE_STRING, DEFAULT_LENGTH);
        mContext = context;
    }

    //0 means success
    //-1 means device no found
    //-2 means device no permission
    public void initUSBPermission(int vid, int pid) {

        Log.d("USB Manager", "USB ========== initialized ");

        UsbManager usbManager = (UsbManager) mContext.getSystemService(Context.USB_SERVICE);
        UsbDevice usbDevice = null;
        for (UsbDevice device : usbManager.getDeviceList().values()) {
            int device_vid = device.getVendorId();
            int device_pid = device.getProductId();
            if (device_vid == vid && device_pid == pid) {
                usbDevice = device;
                break;
            }
        }
        if (null == usbDevice) {
            zknirusbManagerListener.onCheckPermission(-1);
            return;
        }
        this.vid = vid;
        this.pid = pid;
        if (!usbManager.hasPermission(usbDevice)) {
            Intent intent = new Intent(ACTION_USB_PERMISSION);
            PendingIntent pendingIntent = PendingIntent.getBroadcast(mContext, 0, intent, PendingIntent.FLAG_IMMUTABLE);
            Log.d(TAG, "initUSBPermission:" + pendingIntent.toString());
            usbManager.requestPermission(usbDevice, pendingIntent);
        } else {
            zknirusbManagerListener.onCheckPermission(0);
        }
    }

}
