package com.mamasodikov.zkfinger10;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbManager;
import android.util.Base64;
import android.util.Log;

import androidx.annotation.NonNull;

import com.mamasodikov.zkfinger10.ZKUSBManager.ZKUSBManager;
import com.mamasodikov.zkfinger10.ZKUSBManager.ZKUSBManagerListener;
import com.mamasodikov.zkfinger10.util.FingerListener;
import com.mamasodikov.zkfinger10.util.FingerStatusType;
import com.mamasodikov.zkfinger10.util.PermissionUtils;
import com.zkteco.android.biometric.FingerprintExceptionListener;
import com.zkteco.android.biometric.core.device.ParameterHelper;
import com.zkteco.android.biometric.core.device.TransportType;
import com.zkteco.android.biometric.core.utils.LogHelper;
import com.zkteco.android.biometric.core.utils.ToolUtils;
import com.zkteco.android.biometric.module.fingerprintreader.FingerprintCaptureListener;
import com.zkteco.android.biometric.module.fingerprintreader.FingerprintSensor;
import com.zkteco.android.biometric.module.fingerprintreader.FingprintFactory;
import com.zkteco.android.biometric.module.fingerprintreader.ZKFingerService;
import com.zkteco.android.biometric.module.fingerprintreader.exception.FingerprintException;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.PluginRegistry;


public class ZKFingerPrintHelper implements PluginRegistry.RequestPermissionsResultListener {
    private static final int ZKTECO_VID = 0x1b55;
    private static final int LIVE20R_PID = 0x0120;
    private static final int LIVE10R_PID = 0x0124;
    private static final String TAG = "MainActivity";
    private final int REQUEST_PERMISSION_CODE = 9;
    private ZKUSBManager zkusbManager = null;
    private FingerprintSensor fingerprintSensor = null;
    private int usb_vid = ZKTECO_VID;
    private int usb_pid = 0;
    private boolean bStarted = false;
    private int deviceIndex = 0;
    private boolean isReseted = false;
    private String strUid = "0";
    private final static int ENROLL_COUNT = 3;
    private int enroll_index = 0;
    private byte[][] regtemparray = new byte[3][2048];  //register template buffer array
    private boolean bRegister = false;
    private DBManager dbManager = new DBManager();
    private String dbFileName;

    private FingerListener mFingerListener;

    private Context mContext;
    private Activity mActivity;


    public ZKFingerPrintHelper(Activity mActivity, Context mContext, FingerListener mFingerListener) {
        Log.d("Zkteco FingerPrint", "ZKFingerPrintHelper");

        this.mActivity = mActivity;
        this.mContext = mContext;
        this.mFingerListener = mFingerListener;

        dbFileName = mActivity.getFilesDir().getAbsolutePath() + "/zkfinger10.db";
        dbManager.opendb(dbFileName);

        checkStoragePermission();
        zkusbManager = new ZKUSBManager(mContext, zkusbManagerListener);
        zkusbManager.registerUSBPermissionReceiver();
    }


    void doRegister(byte[] template) {
        byte[] bufids = new byte[256];
        int ret = ZKFingerService.identify(template, bufids, 70, 1);
        if (ret > 0) {
            String strRes[] = new String(bufids).split("\t");
            mFingerListener.onStatusChange("The finger already enroll by " + strRes[0] + ", cancel enroll", FingerStatusType.ENROLL_ALREADY_EXIST, strRes[0], "");
            bRegister = false;
            enroll_index = 0;
            return;
        }
        if (enroll_index > 0 && (ret = ZKFingerService.verify(regtemparray[enroll_index - 1], template)) <= 0) {
            mFingerListener.onStatusChange("Please press the same finger 3 times for the enrollment, cancel enroll, score= " + ret, FingerStatusType.ENROLL_STARTED, "", Integer.toString(ret));
            bRegister = false;
            enroll_index = 0;
            return;
        }
        System.arraycopy(template, 0, regtemparray[enroll_index], 0, 2048);
        enroll_index++;
        if (enroll_index == ENROLL_COUNT) {
            bRegister = false;
            enroll_index = 0;
            byte[] regTemp = new byte[2048];
            if (0 < (ret = ZKFingerService.merge(regtemparray[0], regtemparray[1], regtemparray[2], regTemp))) {
                int retVal = 0;
                retVal = ZKFingerService.save(regTemp, strUid);
                Log.d("HELPER", Arrays.toString(regTemp));
                if (0 == retVal) {
                    String strFeature = Base64.encodeToString(regTemp, 0, ret, Base64.NO_WRAP);
                    Log.d("HELPER", strFeature);
                    dbManager.insertUser(strUid, strFeature);
                    mFingerListener.onStatusChange("Enroll Succeed!", FingerStatusType.ENROLL_SUCCESS, strUid, strFeature);
//                    mFingerListener.onStatusChange("Finger registered!", FingerStatusType.FINGER_REGISTERED, strUid, strFeature);
                } else {
                    mFingerListener.onStatusChange("Enroll fail, add template fail, ret= " + retVal, FingerStatusType.ENROLL_FAILED, "", "");
                }
            } else {
                mFingerListener.onStatusChange("Enroll failed!", FingerStatusType.ENROLL_FAILED, "", "");

            }
            bRegister = false;
        } else {
            String enrollIndex = String.valueOf(3 - enroll_index);
            mFingerListener.onStatusChange("You need to press the " + enrollIndex + " times fingerprint", FingerStatusType.ENROLL_CONFIRM, "", enrollIndex);
        }
    }

    void doIdentify(byte[] template) {
        byte[] bufids = new byte[256];

        int ret = ZKFingerService.identify(template, bufids, 70, 1);
        if (ret > 0) {
            String[] strRes = new String(bufids).split("\t");
            String userId = strRes[0].trim();
            String score;
            try {
                score = strRes[1].trim();
            } catch (NumberFormatException exception) {
                score = "";
            }
            mFingerListener.onStatusChange("Identify succeed, userid: " + userId + ", score: " + score, FingerStatusType.IDENTIFIED_SUCCESS, userId, score);
        } else {
            mFingerListener.onStatusChange("Identify failed, ret= " + ret, FingerStatusType.IDENTIFIED_FAILED, "", "");
        }
    }


    private FingerprintCaptureListener fingerprintCaptureListener = new FingerprintCaptureListener() {
        @Override
        public void captureOK(byte[] fpImage) {
            final Bitmap bitmap = ToolUtils.renderCroppedGreyScaleBitmap(fpImage, fingerprintSensor.getImageWidth(), fingerprintSensor.getImageHeight());

            mFingerListener.onCaptureFinger(bitmap);
        }

        @Override
        public void captureError(FingerprintException e) {
            // nothing to do, it always happens

//            final FingerprintException exp = e;
//            mFingerListener.onStatusChange(
//                    "CaptureError  errno=" + exp.getErrorCode() + ", Internal error code: "
//                            + exp.getInternalErrorCode() + ", message= " + exp.getMessage(),
//                    FingerStatusType.CAPTURE_ERROR, "", "");
        }

        @Override
        public void extractOK(byte[] fpTemplate) {
            // For always getting finger base64 feature
            int length = fpTemplate.length;
            String strFeature = Base64.encodeToString(fpTemplate, 0, length, Base64.NO_WRAP);
            mFingerListener.onStatusChange("Finger extracted OK", FingerStatusType.FINGER_EXTRACTED, "", strFeature);
            if (bRegister) {
                doRegister(fpTemplate);
            } else {
                doIdentify(fpTemplate);
            }
        }

        @Override
        public void extractError(int i) {
            // nothing to do
        }
    };


    private FingerprintExceptionListener fingerprintExceptionListener = new FingerprintExceptionListener() {
        @Override
        public void onDeviceException() {
            LogHelper.e("USB exception!!!");

            mFingerListener.onStatusChange("No permission to start finger sensor", FingerStatusType.FINGER_USB_PERMISSION_ERROR, "", "");


            if (!isReseted) {
                try {
                    fingerprintSensor.openAndReboot(deviceIndex);
                } catch (FingerprintException e) {
                    e.printStackTrace();
                }
                isReseted = true;
            }
        }
    };

    private ZKUSBManagerListener zkusbManagerListener = new ZKUSBManagerListener() {
        @Override
        public void onCheckPermission(int result) {
            afterGetUsbPermission();
        }

        @Override
        public void onUSBArrived(UsbDevice device) {
            if (bStarted) {
                closeDevice();
                tryGetUSBPermission();
            }
        }

        @Override
        public void onUSBRemoved(UsbDevice device) {
            LogHelper.d("USB removed!");
        }
    };


    /**
     * storage permission
     */
    private void checkStoragePermission() {
        String[] permission = new String[]{
                Manifest.permission.READ_EXTERNAL_STORAGE,
                Manifest.permission.WRITE_EXTERNAL_STORAGE
        };
        ArrayList<String> deniedPermissions = PermissionUtils.checkPermissions(mActivity, permission);
        if (deniedPermissions.isEmpty()) {
            //permission all granted
            Log.i(TAG, "[checkStoragePermission]: all granted");
        } else {
            int size = deniedPermissions.size();
            String[] deniedPermissionArray = deniedPermissions.toArray(new String[size]);
            PermissionUtils.requestPermission(mActivity, deniedPermissionArray, REQUEST_PERMISSION_CODE);
        }
    }


    @Override
    public boolean onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {

        if (requestCode == REQUEST_PERMISSION_CODE) {
            boolean granted = true;
            for (int result : grantResults) {
                if (result != PackageManager.PERMISSION_GRANTED) {
                    granted = false;
                    break;
                }
            }
            if (granted) {
                mFingerListener.onStatusChange("Permission granted", FingerStatusType.FINGER_USB_PERMISSION_GRANTED, "", "");
//                    Toast.makeText(this, "Permission granted", Toast.LENGTH_SHORT).show();
            } else {
                mFingerListener.onStatusChange("Permission Denied,The application can't run on this device", FingerStatusType.FINGER_USB_PERMISSION_DENIED, "", "");

//                    Toast.makeText(this, "Permission Denied,The application can't run on this device", Toast.LENGTH_SHORT).show();
            }
        }
        return true;
    }


    private void createFingerprintSensor() {
        if (null != fingerprintSensor) {
            FingprintFactory.destroy(fingerprintSensor);
            fingerprintSensor = null;
        }
        // Define output log level
        LogHelper.setLevel(Log.VERBOSE);
        LogHelper.setNDKLogLevel(Log.ASSERT);
        // Start fingerprint sensor
        Map deviceParams = new HashMap();
        //set vid
        deviceParams.put(ParameterHelper.PARAM_KEY_VID, usb_vid);
        //set pid
        deviceParams.put(ParameterHelper.PARAM_KEY_PID, usb_pid);
        fingerprintSensor = FingprintFactory.createFingerprintSensor(mContext, TransportType.USB, deviceParams);
    }

    private boolean enumSensor() {
        UsbManager usbManager = (UsbManager) mContext.getSystemService(Context.USB_SERVICE);
        for (UsbDevice device : usbManager.getDeviceList().values()) {
            int device_vid = device.getVendorId();
            int device_pid = device.getProductId();
            if (device_vid == ZKTECO_VID && (device_pid == LIVE20R_PID || device_pid == LIVE10R_PID)) {
                usb_pid = device_pid;
                Log.d("ZkFingerPrintHelper", "Enum sensor true");
                return true;
            }
        }

        Log.d("ZkFingerPrintHelper", "Enum sensor false");
        return false;
    }


    public void tryGetUSBPermission() {
        zkusbManager.initUSBPermission(usb_vid, usb_pid);
    }

    private void afterGetUsbPermission() {
        startFingerSensor(this.strUid);
    }

    public void startFingerSensor(String userId) {
        this.strUid = userId;

        if (!bStarted) {
            createFingerprintSensor();
            bRegister = false;
            enroll_index = 0;
            isReseted = false;
            try {
                //fingerprintSensor.setCaptureMode(1);
                fingerprintSensor.open(deviceIndex);
                //load all templates form db
                if (dbManager.opendb(dbFileName) && dbManager.getCount() > 0) {
                    HashMap<String, String> vUserList;
                    vUserList = dbManager.queryUserList();
                    int ret = 0;
                    if (vUserList.size() > 0) {
                        for (Map.Entry<String, String> entry : vUserList.entrySet()) {
                            String strID = entry.getKey();
                            String strFeature = entry.getValue();
                            byte[] blobFeature = Base64.decode(strFeature, Base64.NO_WRAP);
                            ret = ZKFingerService.save(blobFeature, strID);
                            if (0 != ret) {
                                Log.d("DATABASE", "add [" + strID + "] template failed, ret=" + ret);
                            }
                        }
                    }
                }
                {
                    // device parameter
                    LogHelper.d("sdk version" + fingerprintSensor.getSDK_Version());
                    LogHelper.d("firmware version" + fingerprintSensor.getFirmwareVersion());
                    LogHelper.d("serial:" + fingerprintSensor.getStrSerialNumber());
                    LogHelper.d("width=" + fingerprintSensor.getImageWidth() + ", height=" + fingerprintSensor.getImageHeight());
                }
                fingerprintSensor.setFingerprintCaptureListener(deviceIndex, fingerprintCaptureListener);
                fingerprintSensor.SetFingerprintExceptionListener(fingerprintExceptionListener);
                fingerprintSensor.startCapture(deviceIndex);
                bStarted = true;
                mFingerListener.onStatusChange("Connect success!", FingerStatusType.STARTED_SUCCESS, "", "");
            } catch (FingerprintException e) {
                e.printStackTrace();
                // try to  reboot the sensor
                try {
                    fingerprintSensor.openAndReboot(deviceIndex);
                } catch (FingerprintException ex) {
                    ex.printStackTrace();
                }
                mFingerListener.onStatusChange("Connect failed!", FingerStatusType.STARTED_FAILED, "", "");
            }
        } else {
            mFingerListener.onStatusChange("Device already started to listen!", FingerStatusType.STARTED_ALREADY, "", "");
        }
    }

    public void openDevice() {

        if (bStarted) {
            mFingerListener.onStatusChange("Device already connected!", FingerStatusType.STARTED_ALREADY, "", "");
            return;
        }
        if (!enumSensor()) {
            mFingerListener.onStatusChange("Device not found!", FingerStatusType.STARTED_ERROR, "", "");

            return;
        }
        tryGetUSBPermission();
    }

    public void closeDevice() {
        if (bStarted) {
            try {
                fingerprintSensor.stopCapture(deviceIndex);
                fingerprintSensor.close(deviceIndex);
            } catch (FingerprintException e) {
                e.printStackTrace();
            }
            bStarted = false;
        } else {
            mFingerListener.onStatusChange("Closed already!", FingerStatusType.STOPPED_ALREADY, "", "");
        }
    }


    public void stopFingerSensor() {
        if (!bStarted) {
            mFingerListener.onStatusChange("Device not connected!", FingerStatusType.STOPPED_ERROR, "", "");
            return;
        }
        closeDevice();
        mFingerListener.onStatusChange("Device stopped successfully!", FingerStatusType.STOPPED_SUCCESS, "", "");
    }


    public void registerFinger(String strUid) {
        this.strUid = strUid;
        if (bStarted) {
            if (null == strUid || strUid.isEmpty()) {
                mFingerListener.onStatusChange("Please input your user ID", FingerStatusType.ENROLL_FAILED, "", "");
                bRegister = false;
                return;
            }
            if (dbManager.isUserExisted(strUid)) {
                bRegister = false;
                mFingerListener.onStatusChange("User exists!", FingerStatusType.ENROLL_ALREADY_EXIST, strUid, "");
                return;
            }
            bRegister = true;
            enroll_index = 0;
            mFingerListener.onStatusChange("Please press your finger 3 times.", FingerStatusType.ENROLL_STARTED, "", "3");
        } else {
            mFingerListener.onStatusChange("Please start capture first", FingerStatusType.IDENTIFIED_START_FIRST, "", "");
        }
    }


    public void identifyFinger(String userId) {
        this.strUid = userId;
        if (bStarted) {
            bRegister = false;
            enroll_index = 0;
        } else {
            mFingerListener.onStatusChange("Please start capture first", FingerStatusType.IDENTIFIED_START_FIRST, "", "");
        }
    }

    public void deleteFinger(String strUid) {
        if (bStarted) {

            if (null == strUid || strUid.isEmpty()) {
                mFingerListener.onStatusChange("Input your userID", FingerStatusType.UNKNOWN_ERROR, "", "");
                return;
            }
            if (!dbManager.isUserExisted(strUid)) {
                mFingerListener.onStatusChange("User not registered", FingerStatusType.UNKNOWN_ERROR, "", "");
            } else {
                if (dbManager.deleteUser(strUid)) {
                    ZKFingerService.del(strUid);
                    mFingerListener.onStatusChange("Delete success!", FingerStatusType.FINGER_DELETED, "", "");

                } else {
                    mFingerListener.onStatusChange("Open DB failed!", FingerStatusType.FINGER_CLEAR_FAILED, "", "");

                }
            }

        }
    }

    public void clear() {
        Log.d("ZKTeco FingerPrint", "clear");

        if (dbManager.clear()) {
            ZKFingerService.clear();
            mFingerListener.onStatusChange("Finger DB Cleared!", FingerStatusType.FINGER_CLEARED, "", "");

        } else {
            mFingerListener.onStatusChange("Open DB failed!", FingerStatusType.FINGER_CLEAR_FAILED, "", "");
        }

    }

    public void clearAndLoad(Map<String, String> vUserList) {

        //load all templates form external source

        try {
            if (dbManager.clear()) {
                ZKFingerService.clear();
                int ret = 0;
                int c = 0;
                if (vUserList.size() > 0) {
                    for (Map.Entry<String, String> entry : vUserList.entrySet()) {

                        String strID = entry.getKey();
                        String strFeature = entry.getValue();
                        byte[] blobFeature = Base64.decode(strFeature, Base64.NO_WRAP);
                        dbManager.insertUser(strID, strFeature);
                        ret = ZKFingerService.save(blobFeature, strID);
                        Log.d("DATABASE", "ID: " + strID + " adding to DB");
                        if (0 != ret) {
                            Log.d("DATABASE", "add [" + strID + "] template failed, ret=" + ret);
                        }
                    }
                    mFingerListener.onStatusChange("Clear DB and load success", FingerStatusType.FINGER_CLEARED_AND_LOADED, "", "");
                }
            } else {
                mFingerListener.onStatusChange("Clear DB failed", FingerStatusType.FINGER_CLEAR_FAILED, "", "");
            }
        } catch (Exception e) {
            System.out.println("Something went wrong on clear and laod, check again...");
            mFingerListener.onStatusChange("Clear and load function failed", FingerStatusType.FINGER_CLEAR_FAILED, "", "");
        }


    }

    public void verify(String strFeature1, String strFeature2) {

        try {
            byte[] blobFeature1 = Base64.decode(strFeature1, Base64.NO_WRAP);
            byte[] blobFeature2 = Base64.decode(strFeature2, Base64.NO_WRAP);
            double score = ZKFingerService.verify(blobFeature1, blobFeature2);
            if (score > 70) {
                mFingerListener.onStatusChange("Verified", FingerStatusType.VERIFIED_SUCCESS, "", Double.toString(score));
            } else {
                mFingerListener.onStatusChange("Verify failed", FingerStatusType.VERIFIED_FAILED, "", Double.toString(score));
            }
        } catch (Exception e) {
            System.out.println("Something went wrong on verify, check again...");
            mFingerListener.onStatusChange("Verify error", FingerStatusType.VERIFIED_ERROR, "", "");
        }

    }


    public void onDestroy() {
        if (bStarted) {
            closeDevice();
        }
        zkusbManager.unRegisterUSBPermissionReceiver();
    }

}