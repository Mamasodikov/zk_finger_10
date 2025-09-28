package com.mamasodikov.zkfinger10;

import static java.nio.file.Paths.get;

import android.app.Activity;
import android.content.Context;
import android.graphics.Bitmap;

import androidx.annotation.NonNull;

import com.mamasodikov.zkfinger10.util.FingerListener;
import com.mamasodikov.zkfinger10.util.FingerStatus;
import com.mamasodikov.zkfinger10.util.FingerStatusType;

import java.io.ByteArrayOutputStream;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
// V1 embedding removed - using V2 embedding only
import io.reactivex.Observer;
import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.disposables.Disposable;
import io.reactivex.schedulers.Schedulers;
import io.reactivex.subjects.PublishSubject;

/**
 * ZkFingerPlugin
 */
public class ZkFinger10Plugin implements FlutterPlugin, MethodCallHandler, ActivityAware, FingerListener {

    private static final String METHOD_FINGER_OPEN_CONNECTION =
            "openConnection";
    private static final String METHOD_FINGER_CLOSE_CONNECTION =
            "closeConnection";
    private static final String METHOD_FINGER_START_LISTEN =
            "startListen";
    private static final String METHOD_FINGER_STOP_LISTEN =
            "stopListen";
    private static final String METHOD_FINGER_IDENTIFY =
            "identify";
    private static final String METHOD_FINGER_VERIFY =
            "verify";
    private static final String METHOD_FINGER_REGISTER =
            "register";
    private static final String METHOD_FINGER_CLEAR =
            "clear";
    private static final String METHOD_CLEAR_AND_LOAD =
            "clearAndLoad";
    private static final String METHOD_FINGER_DELETE =
            "delete";
    private static final String METHOD_ON_DESTROY =
            "onDestroy";
    private static final String METHOD_GET_USER_FEATURE =
            "getUserFeature";
    private static final String METHOD_GET_ALL_USERS =
            "getAllUsers";
    private static final String METHOD_GET_USER_COUNT =
            "getUserCount";
    private static final String METHOD_UPDATE_USER_FEATURE =
            "updateUserFeature";
    private static final String METHOD_CHECK_USER_EXISTS =
            "checkUserExists";

    private static final String CHANNEL_FINGER_STATUS_CHANGE = "com.mamasodikov.zkfinger10/status_change";
    private static final String CHANNEL_FINGER_IMAGE = "com.mamasodikov.zkfinger10/finger_image";
    private static PublishSubject<FingerStatus> fingerStatusSubject = PublishSubject.create();
    private static PublishSubject<byte[]> fingerImageSubject = PublishSubject.create();

    private MethodChannel channel;
    private EventChannel statusChangeEventChannel;
    private EventChannel imageEventChannel;
    private Context context;
    private Activity activity;
    private ZKFingerPrintHelper zkFingerPrintHelper;
    private Result result;

    public ZkFinger10Plugin() {
        // Default constructor for V2 embedding
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        context = flutterPluginBinding.getApplicationContext();
        setupChannels(flutterPluginBinding.getBinaryMessenger());
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        teardownChannels();
        if (zkFingerPrintHelper != null) {
            zkFingerPrintHelper.onDestroy();
        }
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        activity = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivity() {
        activity = null;
    }

    private void setupChannels(BinaryMessenger messenger) {
        channel = new MethodChannel(messenger, "zkfinger");
        channel.setMethodCallHandler(this);

        statusChangeEventChannel = new EventChannel(messenger, CHANNEL_FINGER_STATUS_CHANGE);
        statusChangeEventChannel.setStreamHandler(createStatusChangeStreamHandler());

        imageEventChannel = new EventChannel(messenger, CHANNEL_FINGER_IMAGE);
        imageEventChannel.setStreamHandler(createImageStreamHandler());
    }

    private void teardownChannels() {
        if (channel != null) {
            channel.setMethodCallHandler(null);
            channel = null;
        }
        if (statusChangeEventChannel != null) {
            statusChangeEventChannel.setStreamHandler(null);
            statusChangeEventChannel = null;
        }
        if (imageEventChannel != null) {
            imageEventChannel.setStreamHandler(null);
            imageEventChannel = null;
        }
    }

    // V1 embedding removed - using V2 embedding only


    private EventChannel.StreamHandler createStatusChangeStreamHandler() {
        return new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object o, final EventChannel.EventSink eventSink) {
                fingerStatusSubject.subscribeOn(Schedulers.newThread()).observeOn(AndroidSchedulers.mainThread()).subscribe(new Observer<FingerStatus>() {
                    @Override
                    public void onSubscribe(Disposable d) {

                    }

                    @Override
                    public void onNext(FingerStatus status) {
                        HashMap<String, Object> statusMap = new HashMap<>();
                        statusMap.put("id", status.getId());
                        statusMap.put("message", status.getMessage());
                        statusMap.put("data", status.getData());
                        statusMap.put("fingerStatus", status.getFingerStatusType().ordinal());
                        eventSink.success(statusMap);
                    }

                    @Override
                    public void onError(Throwable e) {

                    }

                    @Override
                    public void onComplete() {

                    }
                });
            }

            @Override
            public void onCancel(Object o) {

            }
        };
    }

    // V1 embedding listener removed - using V2 embedding only

    private EventChannel.StreamHandler createImageStreamHandler() {
        return new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object o, final EventChannel.EventSink eventSink) {
                fingerImageSubject.subscribeOn(Schedulers.newThread()).observeOn(AndroidSchedulers.mainThread()).subscribe(new Observer<byte[]>() {
                    @Override
                    public void onSubscribe(Disposable d) {

                    }

                    @Override
                    public void onNext(byte[] imageBytes) {
                        eventSink.success(imageBytes);
                    }

                    @Override
                    public void onError(Throwable e) {

                    }

                    @Override
                    public void onComplete() {

                    }
                });
            }

            @Override
            public void onCancel(Object o) {

            }
        };
    }

    // V1 embedding image listener removed - using V2 embedding only

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        this.result = result;
        if (zkFingerPrintHelper == null && activity != null && context != null) {
            zkFingerPrintHelper = new ZKFingerPrintHelper(activity, context, this);
        }


        switch (call.method) {
            case "getPlatformVersion":
                result.success("Android " + android.os.Build.VERSION.RELEASE);
                break;
            case METHOD_FINGER_OPEN_CONNECTION:
                openConnection();
                break;
            case METHOD_FINGER_CLOSE_CONNECTION:
                closeConnection();
                break;
            case METHOD_FINGER_START_LISTEN:
                startFingerListen(getUserId(call));
                break;
            case METHOD_FINGER_STOP_LISTEN:
                stopFingerListen();
                break;
            case METHOD_FINGER_IDENTIFY:
                identifyFinger(getUserId(call));
                break;
            case METHOD_FINGER_VERIFY:
                verifyFinger(getUserFingers(call).get("finger1"), getUserFingers(call).get("finger2"));
                break;
            case METHOD_FINGER_REGISTER:
                registerFinger(getUserId(call));
                break;
            case METHOD_FINGER_CLEAR:
                clearFingers();
                break;
            case METHOD_CLEAR_AND_LOAD:
                clearAndLoad(getFingersMap(call));
                break;
            case METHOD_FINGER_DELETE:
                deleteFinger(getUserId(call));
                break;
            case METHOD_ON_DESTROY:
                onDestroy();
                break;
            case METHOD_GET_USER_FEATURE:
                getUserFeature(getUserId(call));
                break;
            case METHOD_GET_ALL_USERS:
                getAllUsers();
                break;
            case METHOD_GET_USER_COUNT:
                getUserCount();
                break;
            case METHOD_UPDATE_USER_FEATURE:
                updateUserFeature(getUserId(call), getFingerData(call));
                break;
            case METHOD_CHECK_USER_EXISTS:
                checkUserExists(getUserId(call));
                break;
            default:
                result.notImplemented();
        }
    }

    private String getUserId(MethodCall call) {
        return call.argument("id");
    }

    Map<String, String> getUserFingers(MethodCall call) {
        Map<String, Object> fingers = (Map<String, Object>) call.arguments;
        String finger1 = (String) fingers.get("finger1");
        String finger2 = (String) fingers.get("finger2");
        Map<String, String> fingersMap = new HashMap<>();
        fingersMap.put("finger1", finger1);
        fingersMap.put("finger2", finger2);
        return fingersMap;
    }

    private Map<String, String> getFingersMap(MethodCall call) {
        return call.argument("fingers");
    }

    private boolean isLogEnabled(MethodCall call) {
        return call.argument("isLogEnabled");
    }

    private String getFingerData(MethodCall call) {
        return call.argument("data");
    }

    private void openConnection() {
        zkFingerPrintHelper.openDevice();
        result.success(true);
    }

    private void closeConnection() {
        zkFingerPrintHelper.closeDevice();
        result.success(true);
    }


    private void startFingerListen(String userId) {
        zkFingerPrintHelper.startFingerSensor(userId);
        result.success(true);
    }

    private void stopFingerListen() {
        zkFingerPrintHelper.stopFingerSensor();
        result.success(true);
    }

    private void registerFinger(String userId) {
        zkFingerPrintHelper.registerFinger(userId);
        result.success(true);
    }

    private void identifyFinger(String userId) {
        zkFingerPrintHelper.identifyFinger(userId);
        result.success(true);
    }

    private void verifyFinger(String template1, String template2) {
        zkFingerPrintHelper.verify(template1, template2);
        result.success(true);
    }

    private void clearAndLoad(Map<String, String> vUserList) {
        zkFingerPrintHelper.clearAndLoad(vUserList);
        result.success(true);
    }


    private void clearFingers() {
        zkFingerPrintHelper.clear();
        result.success(true);
    }

    private void deleteFinger(String userId) {
        zkFingerPrintHelper.deleteFinger(userId);
        result.success(true);
    }

    private void onDestroy() {
        zkFingerPrintHelper.onDestroy();
        result.success(true);
    }

    private void getUserFeature(String userId) {
        if (zkFingerPrintHelper != null) {
            String feature = zkFingerPrintHelper.getUserFeature(userId);
            if (feature != null) {
                result.success(feature);
            } else {
                result.error("USER_NOT_FOUND", "User with ID " + userId + " not found", null);
            }
        } else {
            result.error("HELPER_NOT_INITIALIZED", "ZKFingerPrintHelper not initialized", null);
        }
    }

    private void getAllUsers() {
        if (zkFingerPrintHelper != null) {
            Map<String, String> users = zkFingerPrintHelper.getAllUsers();
            if (users != null) {
                result.success(users);
            } else {
                result.success(new HashMap<String, String>());
            }
        } else {
            result.error("HELPER_NOT_INITIALIZED", "ZKFingerPrintHelper not initialized", null);
        }
    }

    private void getUserCount() {
        if (zkFingerPrintHelper != null) {
            int count = zkFingerPrintHelper.getUserCount();
            result.success(count);
        } else {
            result.error("HELPER_NOT_INITIALIZED", "ZKFingerPrintHelper not initialized", null);
        }
    }

    private void updateUserFeature(String userId, String feature) {
        if (zkFingerPrintHelper != null) {
            boolean success = zkFingerPrintHelper.updateUserFeature(userId, feature);
            result.success(success);
        } else {
            result.error("HELPER_NOT_INITIALIZED", "ZKFingerPrintHelper not initialized", null);
        }
    }

    private void checkUserExists(String userId) {
        if (zkFingerPrintHelper != null) {
            boolean exists = zkFingerPrintHelper.checkUserExists(userId);
            result.success(exists);
        } else {
            result.error("HELPER_NOT_INITIALIZED", "ZKFingerPrintHelper not initialized", null);
        }
    }


    @Override
    public void onStatusChange(String message, FingerStatusType fingerStatusType, String id, String data) {
        fingerStatusSubject.onNext(new FingerStatus(message, fingerStatusType, id, data));
    }

    @Override
    public void onCaptureFinger(Bitmap fingerBitmap) {

        //Calculate how many bytes our image consists of.

//        int bytes = fingerBitmap.getByteCount();
//        //or we can calculate bytes this way. Use a different value than 4 if you don't use 32bit images.
//        //int bytes = b.getWidth()*b.getHeight()*4;
//        ByteBuffer buffer = ByteBuffer.allocate(bytes); //Create a new buffer
//        fingerBitmap.copyPixelsToBuffer(buffer); //Move the byte data to the buffer
//        byte[] array = buffer.array(); //Get the underlying array containing the data.

        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        fingerBitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
        byte[] byteArray = stream.toByteArray();
        fingerBitmap.recycle();

        fingerImageSubject.onNext(byteArray);
    }

}


