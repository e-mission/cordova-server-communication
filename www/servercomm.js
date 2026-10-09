/*global cordova, module*/

var exec = require("cordova/exec")

/*
 * While this is the javascript implementation, it does not actually call any
 * native code! That is because it is basically a wrapper around HTTP get and
 * post, just like the corresponding native implementations are. Since the
 * javascript has perfectly good support for HTTP, we don't really need the
 * overhead of going to native. In fact, you could even argue that we don't
 * really need a wrapper here since the default implementation is easy enough
 * to use, but abstracting out the implementation makes it consistent with
 * native code, and simultaneously makes it easier for us to change the library
 * if we switch to a newer and cooler library (websockets? pub/sub? capnproto?).
 */

/*
 * Native code reports errors as {message, status?, body?}. Convert to an Error
 * so that existing callers that stringify the error keep working.
 */
function toServerCommError(err) {
    if (err instanceof Error) {
        return err;
    }
    var nativeErr = (err && typeof err === 'object') ? err : { message: String(err) };
    var body = nativeErr.body;
    if (typeof body === 'string') {
        try {
            body = JSON.parse(body);
        } catch (e) {
            // non-JSON body, e.g. an HTML error page; leave as a string
        }
    }
    var message = nativeErr.message;
    if (body && typeof body === 'object' && typeof body.error === 'string') {
        message += ' - ' + body.error;
    }
    var error = new Error(message);
    error.name = 'ServerCommError';
    error.status = nativeErr.status;
    error.body = body;
    return error;
}

var ServerCommunication = {
    /*
     * This is only used for communication with our own server. For
     * communication with other services, we can use the standard HTTP
     * libraries from our javascript framework.
     */
    pushGetJSON: function(relativeURL, messageFiller, successCallback, errorCallback) {
        filledMessage = {};
        messageFiller(filledMessage);
        var wrappedErrorCallback = function(err) {
            if (errorCallback) {
                errorCallback(toServerCommError(err));
            }
        };
        exec(successCallback, wrappedErrorCallback, "ServerComm", "pushGetJSON", [relativeURL, filledMessage]);
    },
    postUserPersonalData: function(relativeUrl, objectLabel, objectJSON, successCallback, errorCallback) {
        var msgFiller = function(message) {
            message[objectLabel] = objectJSON;
        };
        ServerCommunication.pushGetJSON(relativeUrl, msgFiller, successCallback, errorCallback);
    },
    getUserPersonalData: function(relativeUrl, successCallback, errorCallback) {
        var msgFiller = function(message) {
            // nop. we don't really send any data for what are effectively get calls
        };
        ServerCommunication.pushGetJSON(relativeUrl, msgFiller, successCallback, errorCallback);
    }
}

module.exports = ServerCommunication;
