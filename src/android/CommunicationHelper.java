package edu.berkeley.eecs.cordova.comm;

import android.content.Context;
import android.net.http.AndroidHttpClient;

import org.apache.http.HttpResponse;
import org.apache.http.StatusLine;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;

import edu.berkeley.eecs.emission.cordova.connectionsettings.ConnectionSettings;
import edu.berkeley.eecs.emission.cordova.jwtauth.GoogleAccountManagerAuth;
import edu.berkeley.eecs.emission.cordova.jwtauth.UserProfile;
import edu.berkeley.eecs.emission.cordova.unifiedlogger.Log;

import edu.berkeley.eecs.emission.R;

public class CommunicationHelper {
    public static final String TAG = "CommunicationHelper";

    public static String readResults(Context ctxt, String cacheControlProperty)
            throws MalformedURLException, IOException {
        final String result_url = ConnectionSettings.getConnectURL(ctxt)+"/compare";
        final String userName = UserProfile.getInstance(ctxt).getUserEmail();
        final String userToken = GoogleAccountManagerAuth.getServerToken(ctxt, userName);

        final URL url = new URL(result_url);
        final HttpURLConnection connection = (HttpURLConnection) url.openConnection();

        connection.setUseCaches(true);
        connection.setDoOutput(false);
        connection.setDoInput(true);
        connection.setReadTimeout(10000 /*milliseconds*/);
        connection.setConnectTimeout(15000 /* milliseconds */);
        connection.setRequestMethod("GET");
        connection.setRequestProperty("User", "" + userToken);

        /* Force the invalidation of the results summary cache entry */
        connection.addRequestProperty("Cache-Control", cacheControlProperty);
        connection.setRequestProperty("Content-Type", "application/json;charset=utf-8");
        connection.connect();

        final InputStream inputStream = connection.getInputStream();
        final int code = connection.getResponseCode();
        Log.d(ctxt, TAG, "Update Connection response status " + connection.getResponseCode());
        if (connection.getResponseCode() != HttpURLConnection.HTTP_OK) {
            throw new RuntimeException("Failed : HTTP error code : " + connection.getResponseCode());
        }
        final BufferedReader in = new BufferedReader(new InputStreamReader(inputStream));
        final StringBuilder builder = new StringBuilder();
        String currLine = null;
        while ((currLine = in.readLine()) != null) {
            builder.append(currLine + "\n");
        }
        final String rawHTML = builder.toString();
        in.close();
        connection.disconnect();
        return rawHTML;
    }

    public static void pushJSON(Context ctxt, String fullURL, String userToken,
                                String objectLabel, Object jsonObjectOrArray)
            throws IOException, JSONException {
        HttpPost msg = new HttpPost(fullURL);
        System.out.println("Posting data to " + msg.getURI());
        msg.setHeader("Content-Type", "application/json");
        JSONObject toPush = new JSONObject();

        toPush.put("user", userToken);
        toPush.put(objectLabel, jsonObjectOrArray);
        msg.setEntity(new StringEntity(toPush.toString()));
        AndroidHttpClient connection = AndroidHttpClient.newInstance(ctxt.getString(R.string.app_name));
        HttpResponse response = connection.execute(msg);
        System.out.println("Got response " + response + " with status " + response.getStatusLine());
        Log.i(ctxt, TAG, "Got response "+response+" with status"+response.getStatusLine());
        connection.close();
        if (response.getStatusLine().getStatusCode() != 200) {
            throw new IOException();
        }
        // TODO: Decide whether we want to return the server response here as a string instead of returning void
    }

    public static String getUserPersonalData(Context ctxt, String fullURL, String userToken) throws
            JSONException, IOException {
        String result = "";
        HttpPost msg = new HttpPost(fullURL);
        msg.setHeader("Content-Type", "application/json");

        //String result;
        JSONObject toPush = new JSONObject();
        toPush.put("user", userToken);
        msg.setEntity(new StringEntity(toPush.toString()));

        System.out.println("Posting data to "+msg.getURI());

        //create connection
        AndroidHttpClient connection = AndroidHttpClient.newInstance(R.class.toString());
        HttpResponse response = connection.execute(msg);
        StatusLine statusLine = response.getStatusLine();
        Log.i(ctxt, TAG, "Got response "+response+" with status "+statusLine);
        int statusCode = statusLine.getStatusCode();

        if(statusCode == 200){
            BufferedReader in = new BufferedReader(new InputStreamReader(response.getEntity().getContent()));
            StringBuilder builder = new StringBuilder();
            String currLine = null;
            while ((currLine = in.readLine()) != null) {
                builder.append(currLine+"\n");
            }
            result = builder.toString();
            System.out.println("Result Summary JSON = "+
                result.substring(0, Math.min(200, result.length())) + " length "+result.length());
            Log.i(ctxt, TAG, "Result Summary JSON = "+
                result.substring(0, Math.min(200, result.length())) + " length "+result.length());
            in.close();
        } else {
            Log.e(ctxt, R.class.toString(),"Failed to get JSON object");
            throw new IOException();
        }
        connection.close();
        return result;
    }
}
