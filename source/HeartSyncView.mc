import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Sensor;
import Toybox.Timer;
import Toybox.Lang;

class HeartSyncView extends WatchUi.View {

    private var heartRate = 60;
    var heartRateTimer = new Timer.Timer();
    var nickname = "User";

    function initialize() {
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
        var viewRefreshTimer = new Timer.Timer();
        nickname = Application.Properties.getValue("nickname_prop");
        viewRefreshTimer.start(method(:onUpdateTimer), 1000, true);
        heartRateTimer.start(method(:onHeartRateUpdate), 1000, false);
        View.initialize();
    }

    function onUpdateTimer() as Void {
        // Force the view to update
        WatchUi.requestUpdate();
    }


    function onHeartRateUpdate() as Void {
        var sensorInfo = Sensor.getInfo();
        if(sensorInfo has :heartRate && sensorInfo.heartRate != null){
            heartRate = sensorInfo.heartRate;
            // You can now use the heart rate value as needed
            // For example, display it on the screen or log it
            
        }
        // Vibrate based on heart rate
        Attention.vibrate([new Attention.VibeProfile(Application.Properties.getValue("vibration_strength_prop"), 100)]);

        if(Application.Storage.getValue("whovibrate_prop") == 1){
            var vibrateTime = Application.Storage.getValue("friend_heartrate");
            if(vibrateTime == null || vibrateTime == 0){
                vibrateTime = 12;
            }
            heartRateTimer.start(method(:onHeartRateUpdate), 60000 / vibrateTime, false);
        }
        else{
            heartRateTimer.start(method(:onHeartRateUpdate), 60000 / heartRate, false);
        }
    }

    // Load your resources here
    /*function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }*/

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    function onReceive(responseCode as Number, data as Dictionary?) as Void{
       if (responseCode == 200) {
           System.println("Request Successful");                   // print success
              System.println("Response Data: " + data); // print response data
            Application.Storage.setValue("friend_nickname", data["nickname"]);
            Application.Storage.setValue("friend_heartrate", data["heartRate"]);
            Application.Storage.setValue("friend_last_updated", data["timestamp"]);
            Application.Storage.setValue("friend_status", data["status"]);
       }
       else {
           System.println("Response: " + responseCode);            // print response code
           System.println("Request Failed: " + data); // print error message
       }

    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        dc.clear();

        var background = WatchUi.loadResource(Rez.Drawables.splitViewBlue) as BitmapResource;
        dc.drawBitmap(0, 0, background);

        var sensorInfo = Sensor.getInfo();
        if(sensorInfo has :heartRate && sensorInfo.heartRate != null){
            heartRate = sensorInfo.heartRate;
            // You can now use the heart rate value as needed
            // For example, display it on the screen or log it
        }
        
        dc.setColor(0x94FA7F, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() * 0.21 - 20, Graphics.FONT_SMALL, Application.Storage.getValue("friend_nickname"), Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(0x5DA3FF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() * 0.79 - 20, Graphics.FONT_SMALL, nickname, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() * 0.34 - 20, Graphics.FONT_SMALL, Application.Storage.getValue("friend_heartrate"), Graphics.TEXT_JUSTIFY_CENTER);

        dc.drawText(dc.getWidth() / 2, dc.getHeight() * 0.66 - 20, Graphics.FONT_SMALL, heartRate, Graphics.TEXT_JUSTIFY_CENTER);

        // Push data to server
        var url = "https://heartsync-pt41.onrender.com/heartrate";
        var params = {
            "username" => Application.Properties.getValue("username_prop"),
            "nickname" => Application.Properties.getValue("nickname_prop"),
            "friend_username" => Application.Properties.getValue("friend_username_prop"),
            "heartrate" => heartRate,
        };

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => { "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };

        var responseCallback = method(:onReceive);

        Communications.makeWebRequest(url, params, options, responseCallback);

    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

}
