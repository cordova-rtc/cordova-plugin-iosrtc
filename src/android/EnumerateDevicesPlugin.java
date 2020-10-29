package cordova.plugin.iosrtc.enumeratedevices;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.annotation.TargetApi;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCharacteristics;

import android.media.AudioManager;
import android.media.AudioDeviceInfo;
import android.content.BroadcastReceiver;
import android.content.Intent;
import android.bluetooth.BluetoothDevice;
import android.os.Build;
import android.support.annotation.RequiresApi;
import android.widget.Toast;
import android.content.IntentFilter;

import android.app.Activity;
import android.content.Context;

/**
 * This class echoes a string called from JavaScript.
 */
public class EnumerateDevicesPlugin extends CordovaPlugin {
   
    static final String FRONT_CAM = "Front Camera";
    static final String BACK_CAM = "Back Camera";
    static final String EXTERNAL_CAM = "External Camera";
    static final String UNKNOWN_CAM = "Unknown Camera";

    static final String BUILTIN_MIC = "Built-in Microphone";
    static final String BLUETOOTH_MIC = "Bluetooth";
    static final String WIRED_MIC = "Wired Microphone";
    static final String USB_MIC = "USB Microphone";
    static final String UNKNOWN_MIC = "Unknown Microphone";

    private Context context;
    private Activity activity;
    AudioManager audioManager;
    JSONArray devicesArray;


    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        this.context = cordova.getActivity().getApplicationContext();
        this.activity = cordova.getActivity();
        this.audioManager = (AudioManager) this.activity.getSystemService(this.context.AUDIO_SERVICE);

        if (action.equals("enumerateDevices")) {

            this.enumerateDevices(args, callbackContext);
            return true;

        } else if (action.equals("addDeviceListener")) {
            IntentFilter filter = new IntentFilter();
            filter.addAction(BluetoothDevice.ACTION_ACL_CONNECTED);
            filter.addAction(BluetoothDevice.ACTION_ACL_DISCONNECT_REQUESTED);
            filter.addAction(BluetoothDevice.ACTION_ACL_DISCONNECTED);
            filter.addAction(Intent.ACTION_HEADSET_PLUG);
            context.registerReceiver(BTReceiver, filter);
            return true;
        }
        return false;
    }

    // The BroadcastReceiver that listens for bluetooth broadcasts
    private final BroadcastReceiver BTReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();

            if (BluetoothDevice.ACTION_ACL_CONNECTED.equals(action)) {
                Toast.makeText(context, "Bluetooth connected", Toast.LENGTH_SHORT).show();
            } else if (BluetoothDevice.ACTION_ACL_DISCONNECTED.equals(action)) {
                Toast.makeText(context, "Bluetooth disconnected", Toast.LENGTH_SHORT).show();
            } else if (Intent.ACTION_HEADSET_PLUG.equals(action)) {
                int state = intent.getIntExtra("state", -1);
                switch (state) {
                    case 0:
                        Toast.makeText(context, "Wired device disconnected", Toast.LENGTH_SHORT).show();
                        break;
                    case 1:
                        Toast.makeText(context, "Wired device connected", Toast.LENGTH_SHORT).show();
                        break;
                    default:
                        break;
                }
            }
            fireEvent("devicechange");
        }
    };

    @TargetApi(Build.VERSION_CODES.M)
    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    private void enumerateDevices(JSONArray args, CallbackContext callback) {

        this.devicesArray = new JSONArray();

        this.getMics();
        this.getCams();
        callback.success(this.devicesArray);
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    private void getMics() {
        AudioDeviceInfo[] mics = this.audioManager.getDevices(AudioManager.GET_DEVICES_ALL);
        String label = "";

        for (int i = 0; i < mics.length; i++) {
            Integer type = mics[i].getType();
            if ((type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO || type == AudioDeviceInfo.TYPE_BUILTIN_MIC
                    || type == AudioDeviceInfo.TYPE_WIRED_HEADSET || type == AudioDeviceInfo.TYPE_USB_DEVICE)
                    ) {
                JSONObject device = new JSONObject();

                label = this.getAudioType(mics[i]);
                try {
                    device.put("deviceId", Integer.toString(mics[i].getId()));
                    device.put("groupId", "");
                    device.put("kind", "audioinput");
                    device.put("label", label);
                    this.devicesArray.put(device);
                } catch (JSONException e) {
                    System.out.println("ERROR JSONException " + e.toString());
                }
            }
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    private void getCams() {
        // Video inputs
        CameraManager camera = (CameraManager) this.activity.getSystemService(this.context.CAMERA_SERVICE);

        try {
            String[] cameraId = camera.getCameraIdList();
            CameraCharacteristics characteristics;
            String label = "";

            for (int i = 0; i < cameraId.length; i++) {
                JSONObject device = new JSONObject();
                characteristics = camera.getCameraCharacteristics(cameraId[i]);
                label = this.getVideoType(characteristics);
                device.put("deviceId", cameraId[i]);
                device.put("groupId", "");
                device.put("kind", "videoinput");
                device.put("label", label);
                this.devicesArray.put(device);
            }

        } catch (CameraAccessException e) {
            System.out.println("ERROR IOException " + e.toString());

        } catch (JSONException e) {
            System.out.println("ERROR IOException " + e.toString());
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    private String getAudioType(AudioDeviceInfo input) {
        String deviceType = "";

        switch (input.getType()) {
            case AudioDeviceInfo.TYPE_BLUETOOTH_SCO:
                deviceType = input.getProductName().toString() + " " + BLUETOOTH_MIC;
                break;
            case AudioDeviceInfo.TYPE_BUILTIN_MIC:
                deviceType = input.getProductName().toString() + " " + BUILTIN_MIC;
                break;
            case AudioDeviceInfo.TYPE_WIRED_HEADSET:
                deviceType = input.getProductName().toString() + " " + WIRED_MIC;
                break;
            case AudioDeviceInfo.TYPE_USB_DEVICE:
                deviceType = input.getProductName().toString() + " " + USB_MIC;
                break;
            default:
                deviceType = UNKNOWN_MIC;
                break;
        }

        return deviceType;
    }

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    private String getVideoType(CameraCharacteristics input) {
        String deviceType = "";
        String num = "";

        try {
            for (int i = 0; i < this.devicesArray.length(); ++i) {
                JSONObject obj = this.devicesArray.getJSONObject(i);
                String id = obj.getString("label");
                if (id.contains(EXTERNAL_CAM)) {
                    num = Integer.toString(Integer.parseInt(num) + 1);
                }
            }
        } catch (JSONException e) {
            System.out.println("ERROR JSONException " + e.toString());
        }

        switch (input.get(CameraCharacteristics.LENS_FACING)) {
            case CameraCharacteristics.LENS_FACING_FRONT:
                deviceType = FRONT_CAM;
                break;
            case CameraCharacteristics.LENS_FACING_BACK:
                deviceType = BACK_CAM;
                break;
            case CameraCharacteristics.LENS_FACING_EXTERNAL:
                deviceType = EXTERNAL_CAM + " " + num;
                break;
            default:
                deviceType = UNKNOWN_CAM;
        }

        return deviceType;
    }

    public void fireEvent(String eventName) {

        final String js = "javascript:(function(){" +
                "var event = new CustomEvent('" + eventName + "');" +
                "setTimeout(() => { navigator.mediaDevices.dispatchEvent(event); }, 500);" +
                "})()";

        this.activity.runOnUiThread(() -> webView.loadUrl(js));
    }
}