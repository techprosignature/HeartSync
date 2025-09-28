import Toybox.Lang;
import Toybox.WatchUi;

class HeartSyncDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new HeartSyncMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

}