import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Sensor;
import Toybox.Timer;
import Toybox.Lang;

class HeartSyncView extends WatchUi.View {

    // Initialize variables needed throughout the view
    private var heartRate = 60;
    private var heartRateTimer = new Timer.Timer();

    // Set up the view
    function initialize() {
        // Enable heart rate sensor
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);

        // Set up a timer to refresh the view every second
        var viewRefreshTimer = new Timer.Timer();
        viewRefreshTimer.start(method(:onUpdateTimer), 1000, true);

        // Set up a timer to vibrate based on heart rate
        heartRateTimer.start(method(:onHeartRateUpdate), 1000, false);
        View.initialize();
    }

    function onUpdateTimer() as Void {
        // Update view
        WatchUi.requestUpdate();

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

    // Handle heart rate vibrations
    function onHeartRateUpdate() as Void {
        
        // Read heart rate sensor
        var sensorInfo = Sensor.getInfo();
        if(sensorInfo has :heartRate && sensorInfo.heartRate != null){
            heartRate = sensorInfo.heartRate;
        }

        // Vibrate
        Attention.vibrate([new Attention.VibeProfile(Application.Properties.getValue("vibration_strength_prop"), 100)]);

        // Handle possible errors in vibration settings
        if(Application.Properties.getValue("whovibrate_prop") == null){
            Application.Properties.setValue("whovibrate_prop", 1);
        }

        // Determine who to vibrate for based on settings and restart timer
        if(Application.Properties.getValue("whovibrate_prop") == 1){
            var vibrateTime = Application.Storage.getValue("friend_heartrate");

            // Handle possible blank values in friend's heart rate
            if(vibrateTime == null || vibrateTime == 0){
                vibrateTime = 12;
            }
            System.println("Vibrate Time: " + vibrateTime);
            heartRateTimer.start(method(:onHeartRateUpdate), 60000 / vibrateTime, false);
        }
        else{
            System.println("Vibrate Time: " + heartRate);
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

    // Handle server response
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
           if(responseCode == -101){
                System.println("Server starting...");
           }
           else{
                System.println("Response: " + responseCode);            // print response code
                System.println("Request Failed: " + data); // print error message
           }
       }

    }

    // Update the view
    function onUpdate(dc as Dc) as Void {

        // Clear the screen
        dc.clear();

        // Draw background based on who to vibrate for
        var background;
        if(Application.Properties.getValue("whovibrate_prop") == 1){
            background = WatchUi.loadResource(Rez.Drawables.splitViewGreen) as BitmapResource;
        }
        else{
            background = WatchUi.loadResource(Rez.Drawables.splitViewBlue) as BitmapResource;
        }
        dc.drawBitmap(0, 0, background);

        // Read heart rate sensor
        var sensorInfo = Sensor.getInfo();
        if(sensorInfo has :heartRate && sensorInfo.heartRate != null){
            heartRate = sensorInfo.heartRate;
        }
        
        // Handle possible blank nickname and heart rate values
        var friend_nickname = Application.Storage.getValue("friend_nickname");
        if(friend_nickname == null){
            friend_nickname = "";
        }

        var friend_heartrate = Application.Storage.getValue("friend_heartrate");
        if(friend_heartrate == null){
            friend_heartrate = "--";
        }

        // Draw names
        dc.setColor(0x94FA7F, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() * 0.21 - 20, Graphics.FONT_SMALL, friend_nickname, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(0x5DA3FF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() * 0.79 - 20, Graphics.FONT_SMALL, Application.Properties.getValue("nickname_prop"), Graphics.TEXT_JUSTIFY_CENTER);

        // Draw heart rate values
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() * 0.34 - 20, Graphics.FONT_SMALL, friend_heartrate, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() * 0.66 - 20, Graphics.FONT_SMALL, heartRate, Graphics.TEXT_JUSTIFY_CENTER);

    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

}
