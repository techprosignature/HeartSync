import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Sensor;
import Toybox.Timer;
import Toybox.Lang;
import Toybox.System;

class HeartSyncView extends WatchUi.View {

    // Initialize variables needed throughout the view
    private var heartRate = 124; // default value
    private var heartRateTimer = new Timer.Timer();
    private var status = 0; // 0 = disconnected, 1 = offline, 2 = online
    private var robotoBoldExtraLarge as FontResource;
    private var robotoBoldLarge as FontResource;

    private var backgroundData as Array<Dictionary<Symbol, Lang.Number or Lang.ResourceId>> = [
        {
            :upperColor => 0x6CF983 as Lang.Number,
            :lowerColor => 0x338BFF as Lang.Number,
            :background => Rez.Drawables.backgroundGreenBlue as Lang.ResourceId
        },
        {
            :upperColor => 0xF96CF0 as Lang.Number,
            :lowerColor => 0xFF3336 as Lang.Number,
            :background => Rez.Drawables.backgroundPurpleRed as Lang.ResourceId
        }
    ];

    (:small) private const size = 0; // small watch
    (:large) private const size = 1; // large watch

    // Set up the view
    function initialize() {
        // Enable heart rate sensor
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);

        // Set up a timer to refresh the view every second
        var viewRefreshTimer = new Timer.Timer();
        viewRefreshTimer.start(method(:onUpdateTimer), 1000, true);

        // Set up a timer to vibrate based on heart rate
        heartRateTimer.start(method(:onHeartRateUpdate), 1000, false);

        // Load fonts
        robotoBoldExtraLarge = WatchUi.loadResource(Rez.Fonts.robotoBoldExtraLarge);
        robotoBoldLarge = WatchUi.loadResource(Rez.Fonts.robotoBoldLarge);
        View.initialize();
        System.println("Size: " + size);
    }

    function onUpdateTimer() as Void {
        // Update view
        WatchUi.requestUpdate();

        // Push data to server
        var url = "https://heartsync-pt41.onrender.com/heartrate";
        var params = {
            "username" => Application.Properties.getValue("username_prop"),
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
        if(sensorInfo.heartRate != null){
            heartRate = sensorInfo.heartRate;
        }

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

            // Vibrate otherwise
            else{
                Attention.vibrate([new Attention.VibeProfile(Application.Properties.getValue("vibration_strength_prop"), Application.Properties.getValue("vibration_length_prop"))]);
            }
            System.println("Vibrate Time: " + vibrateTime);
            heartRateTimer.start(method(:onHeartRateUpdate), 60000 / vibrateTime, false);
        }

        // Always vibrate for self
        else{
            Attention.vibrate([new Attention.VibeProfile(Application.Properties.getValue("vibration_strength_prop"), Application.Properties.getValue("vibration_length_prop"))]);
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
              System.println("Status: " + data["status"]); // print status
            if("no_data".find(data["status"]) != null){
                System.println("No data for friend.");
                status = 1; // offline
                Application.Storage.setValue("friend_heartrate", null);
                return;
            }
            else if("offline".find(data["status"]) != null){
                System.println("Friend is offline.");
                status = 1; // offline
                Application.Storage.setValue("friend_heartrate", null);
                Application.Storage.setValue("friend_last_updated", data["timestamp"]);
                Application.Storage.setValue("friend_status", data["status"]);
            }
            else{
                status = 2; // online
                Application.Storage.setValue("friend_heartrate", data["heartRate"]);
                Application.Storage.setValue("friend_last_updated", data["timestamp"]);
                Application.Storage.setValue("friend_status", data["status"]);
            }
       }
       else {
           if(responseCode == -101){
                System.println("Server starting...");
                status = 1; // offline
                Application.Storage.setValue("friend_heartrate", null);
           }
           else if(responseCode == -104){
                status = 0; // disconnected
                System.println("No internet connection.");
                Application.Storage.setValue("friend_heartrate", null);
           }
           else{
                status = 0; // disconnected
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
        var selectedBackground = Application.Properties.getValue("backgroundcolor_prop") as Lang.Number;

        // Set label colors based on status
        var selfColor;
        var friendColor;
        var batteryColor;
        var timeColor;

        // Update background and colors based on connection status
        if(status == 0){
            dc.setColor(0xAEAEAE, 0xAEAEAE);
            dc.fillRectangle(0, 0, 390, 390);
            dc.drawBitmap(0, 0, WatchUi.loadResource(Rez.Drawables.foregroundOnlineMe) as BitmapResource);
            selfColor = 0xAEAEAE;
            friendColor = 0xAEAEAE;
            batteryColor = 0xAEAEAE;
            timeColor = 0xFFFFFF;
        }
        else if(status == 1){
            dc.drawBitmap(0, 0, WatchUi.loadResource(backgroundData[selectedBackground][:background]) as BitmapResource);
            dc.drawBitmap(0, 0, WatchUi.loadResource(Rez.Drawables.foregroundOnlineMe) as BitmapResource);
            selfColor = backgroundData[selectedBackground][:lowerColor];
            batteryColor = backgroundData[selectedBackground][:upperColor];
            friendColor = 0xAEAEAE;
            timeColor = 0xFFFFFF;
        }
        else{
            selfColor = backgroundData[selectedBackground][:lowerColor];
            friendColor = backgroundData[selectedBackground][:upperColor];
            batteryColor = backgroundData[selectedBackground][:upperColor];
            dc.drawBitmap(0, 0, WatchUi.loadResource(backgroundData[selectedBackground][:background]) as BitmapResource);
            if(Application.Properties.getValue("whovibrate_prop") == 1){
                timeColor = 0x000000;
                dc.drawBitmap(0, 0, WatchUi.loadResource(Rez.Drawables.foregroundOnlineFriend) as BitmapResource);
            }
            else{
                timeColor = 0xFFFFFF;
                dc.drawBitmap(0, 0, WatchUi.loadResource(Rez.Drawables.foregroundOnlineMe) as BitmapResource);
            }
        }

        // Read heart rate sensor
        var sensorInfo = Sensor.getInfo();
        if(sensorInfo.heartRate != null){
            heartRate = sensorInfo.heartRate;
        }

        // Handle possible blank values in friend's heart rate
        var friend_heartrate = Application.Storage.getValue("friend_heartrate");
        if(friend_heartrate == null){
            friend_heartrate = "--";
        }

        // Get current time
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;
        if(hours > 12){
            hours = hours - 12;
        }
        else if(hours == 0){
            hours = 12;
        }

        // Get current battery level
        var batteryLevel = System.getSystemStats().battery;


        // Draw for larger watches
        if(size == 1){
            // Draw heart rates
            dc.setColor(friendColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(291, 79, Graphics.FONT_SMALL, friend_heartrate, Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(selfColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(105, 275, Graphics.FONT_SMALL, heartRate, Graphics.TEXT_JUSTIFY_CENTER);

            // Draw baterry level
            dc.setColor(batteryColor, batteryColor);
            dc.fillRoundedRectangle(177, 34, 36 * (batteryLevel / 100), 16, 5);

            // Draw time
            dc.setColor(timeColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(108, 77, robotoBoldLarge, hours, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(256, 195, robotoBoldExtraLarge, clockTime.min.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Draw for smaller watches
        else{
            // Draw heart rates
            dc.setColor(friendColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(188, 49, Graphics.FONT_SMALL, friend_heartrate, Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(selfColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(65, 170, Graphics.FONT_SMALL, heartRate, Graphics.TEXT_JUSTIFY_CENTER);

            // Draw baterry level
            dc.setColor(batteryColor, batteryColor);
            dc.fillRoundedRectangle(118.5, 23.5, 18 * (batteryLevel / 100), 9, 3);
            
            // Draw time
            dc.setColor(timeColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(66, 48, robotoBoldLarge, hours, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(157, 118, robotoBoldExtraLarge, clockTime.min.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER);
        }

        /*
        // Scratch everything entirely
        dc.clear();
        var clockBackground = WatchUi.loadResource(Rez.Drawables.clockBackground) as BitmapResource;
        dc.drawBitmap(0, 0, clockBackground);
        */
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

}
