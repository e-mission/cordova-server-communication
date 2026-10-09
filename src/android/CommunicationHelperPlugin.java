package edu.berkeley.eecs.emission.cordova.comm;

import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.content.Context;
import edu.berkeley.eecs.emission.cordova.comm.CommunicationHelper;
import edu.berkeley.eecs.emission.cordova.connectionsettings.ConnectionSettings;

public class CommunicationHelperPlugin extends CordovaPlugin {
    @Override
    public boolean execute(String action, JSONArray data, final CallbackContext callbackContext) throws JSONException {
        if (action.equals("pushGetJSON")) {
            try {
                final Context ctxt = cordova.getActivity();
                String relativeURL = data.getString(0);
                final JSONObject filledMessage = data.getJSONObject(1);

                String commuteTrackerHost = ConnectionSettings.getConnectURL(ctxt);
                final String fullURL = commuteTrackerHost + relativeURL;

                cordova.getThreadPool().execute(new Runnable() {
                    public void run() {
                        try {
                             String resultString = CommunicationHelper.pushGetJSON(ctxt, fullURL, filledMessage);                            
                             try {
                               callbackContext.success(new JSONObject(resultString));
                             } catch (JSONException e) {
                                callbackContext.error(errorJSON("While pushing/getting from server, "
                                  + "Response was not JSON: " + resultString
                                  + " Exception: "+e.getMessage(), e));
                             }
                        } catch (Exception e) {
                            callbackContext.error(errorJSON("While pushing/getting from server, "+e.getMessage(), e));
                        }
                    }
                });
            } catch (Exception e) {
                callbackContext.error(errorJSON("While pushing/getting from server "+e.getMessage(), e));
            }
            return true;
        } else {
            return false;
        }
    }

    private static JSONObject errorJSON(String message, Exception e) {
        JSONObject err = new JSONObject();
        try {
            err.put("message", message);
            if (e instanceof CommunicationHelper.HttpStatusException) {
                CommunicationHelper.HttpStatusException hse = (CommunicationHelper.HttpStatusException) e;
                err.put("status", hse.status);
                err.put("body", hse.body);
            }
        } catch (JSONException je) {
            // put() throws for a null key or a NaN/infinite double; our keys are literals and values are strings/ints, so this is unreachable
            android.util.Log.e("CommunicationHelperPlugin", "Unexpected error building error JSON for: " + message, je);
        }
        return err;
    }
}

