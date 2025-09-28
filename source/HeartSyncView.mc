import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Sensor;
import Toybox.Timer;

class HeartSyncView extends WatchUi.View {

    private var heartRate = 60;
    var heartRateTimer = new Timer.Timer();

    function initialize() {
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
        var viewRefreshTimer = new Timer.Timer();
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
            Attention.vibrate([new Attention.VibeProfile(25, 100)]);
        }
        heartRateTimer.start(method(:onHeartRateUpdate), 60000 / heartRate, false);
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
        dc.drawText(dc.getWidth() / 2, dc.getHeight() * 0.21 - 20, Graphics.FONT_SMALL, "Elizabeth", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(0x5DA3FF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() * 0.79 - 20, Graphics.FONT_SMALL, "Phineas", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() * 0.34 - 20, Graphics.FONT_SMALL, "--", Graphics.TEXT_JUSTIFY_CENTER);

        dc.drawText(dc.getWidth() / 2, dc.getHeight() * 0.66 - 20, Graphics.FONT_SMALL, heartRate, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

}
