package com.mamasodikov.zkfinger10.ZKUSBManager;

import android.hardware.usb.UsbDevice;

public interface ZKUSBManagerListener
{
    //0 means success
    //-1 means device no found
    //-2 means device no permission
    void onCheckPermission(int result);

    void onUSBArrived(UsbDevice device);

    void onUSBRemoved(UsbDevice device);
}
