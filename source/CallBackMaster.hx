package;

import flixel.util.FlxColor;
import flixel.input.keyboard.FlxKey;
import flixel.FlxState;
import flixel.util.FlxSave;
import flixel.FlxG;

using StringTools;

class CallBackMaster 
{
    //TODO add more thingies bruh
    public static function startUp()
    {
        Option.startOptions(false);
    }
}

enum OptionType 
{
    SLIDER;
    ACTION;
    TOGGLE;
}

class Option
{
    public var item:String;
    public var curText:String;
    public var status(default, set):String;

    public var description:String;
    public var optionType:OptionType = TOGGLE;
    public var isLocked:Bool = false;

    public function new(item:String, startStatus:String, description:String)
    {
        this.item = item;
        this.description = description;
        this.status = startStatus;
    }

    public function action(args:Array<Dynamic>){}
    public function update(elapsed:Float){}

    private function set_status(str:String):String
    {
        status = str;
        curText = item + ": " + status;
        return status;
    }

    public static function startOptions(reset:Bool)
    {
        if(FlxG.save.data.downscroll == null || reset)
            FlxG.save.data.downscroll = false;
        if(FlxG.save.data.fps_cap == null || FlxG.save.data.fps_cap < 60 || FlxG.save.data.fps_cap > 999 || reset)
            FlxG.save.data.fps_cap = 120;
        if(FlxG.save.data.startWithFullScreen == null || reset)
            FlxG.save.data.startWithFullScreen = false;
        if(FlxG.save.data.ShowExtendedScores == null || reset)
            FlxG.save.data.ShowExtendedScores = true;
        if(FlxG.save.data.MiddleScroll == null || reset)
            FlxG.save.data.MiddleScroll = false;
        if(FlxG.save.data.GhostTapping == null || reset)
            FlxG.save.data.GhostTapping = false;
        if(FlxG.save.data.lightstrums == null || reset)
            FlxG.save.data.lightstrums = "animated";
        if(FlxG.save.data.Accuracy == null || reset)
            FlxG.save.data.Accuracy = "simple";
        if(FlxG.save.data.healthBarColors == null || reset)
            FlxG.save.data.healthBarColors = false;
        if(FlxG.save.data.pitch == null || reset)
            FlxG.save.data.pitch = 1;
        if(FlxG.save.data.showTime == null || reset)
            FlxG.save.data.showTime = false;
        if(FlxG.save.data.TimeType == null || reset)
            FlxG.save.data.TimeType = "time-left";
        if(FlxG.save.data.botplay == null || reset)
            FlxG.save.data.botplay = false;
        if(FlxG.save.data.resetKey == null || reset)
            FlxG.save.data.resetKey = false;
        if(FlxG.save.data.colorEffect == null || reset)
            FlxG.save.data.colorEffect = "none";
        if(FlxG.save.data.cache == null || reset)
            FlxG.save.data.cache = "off";
        if(FlxG.save.data.useVcr == null || reset)
            FlxG.save.data.useVcr = false;
        if(FlxG.save.data.showFps == null || reset)
            FlxG.save.data.showFps = false;
        if(FlxG.save.data.smoothCam == null || reset)
            FlxG.save.data.smoothCam = false;
        if(FlxG.save.data.showMemory == null || reset)
            FlxG.save.data.showMemory = false;
        if(FlxG.save.data.UILayout == null || reset)
            FlxG.save.data.UILayout = "default";
        if(FlxG.save.data.vsync == null || reset)
            FlxG.save.data.vsync = false;
        Controls.saveControls_start(false);

        if(reset)
            trace("RESETED OPTIONS!");
        else 
            trace("CHECKED OPTIONS..");
        
        FlxG.save.flush();
    }
}

class ActionOption extends Option
{
    var onPState:Class<FlxState>;
    public function new(context:String,description:String, onPressState:Class<FlxState>)
    {
        onPState = onPressState;
        super(curText, "", description);
        curText = context;
        optionType = ACTION;
    }
    override function action(args:Array<Dynamic>)
    {
        super.action(args);
        FlxG.switchState(Type.createInstance(onPState, []));
    }
}

class SliderOption extends Option
{
    public var options:Array<String> = [];
    public var curSelected:Int = 0;

    public function new(txt:String, startStatus:String, desc:String, options:Array<String>) 
    {
        this.options = options;
        curSelected = options.indexOf(startStatus);
        status = startStatus;
        super(txt, getStatus(), desc);

        this.optionType = SLIDER;
    }

    override function action(args:Array<Dynamic>)
    {
        if(args[0] == "left")
            curSelected--;   
        else if(args[0] == "right")
            curSelected++;

        if(curSelected < 0)
            curSelected = 0;
        if(curSelected > options.length - 1)
            curSelected = options.length - 1;
            
        status = getStatus();
        super.action(args);
    }
    public function getSelected():String
        return options[curSelected];
    public function getStatus()
    {
        var uhm = "<" + getSelected() + ">";
        if(curSelected == 0)
            uhm = uhm.substring(1, uhm.length);
        else if(curSelected == options.length - 1)
            uhm = uhm.substring(0, uhm.length - 1);
        return uhm;
    }
}

class ToggleOption extends Option 
{
    public var trueString:String;
    public var falseString:String;
    public var boolItem:Bool;

    public function new(item:String, boolItem:Bool, description:String, trueString:String, falseString:String)
    {
        this.trueString = trueString;
        this.falseString = falseString;
        this.boolItem = boolItem;

        super(item, getAssignedString(), description);
    }

    override function action(args:Array<Dynamic>) 
    {
        boolItem = !boolItem;
        status = getAssignedString();
        super.action(args);
    }

    public function getAssignedString()
    {
        return (boolItem ? trueString : falseString);
    }
}

class OptionActionState extends MusicBeatState
{
    public static var lastSelected:Int = 0; 
    public static var lastOption:Int = 0;
    public static var wasInCategories:Bool = true;

    public function close()
    {
        FlxG.switchState(new OptionState());
    }
}


///////REAL OPTIONS//////////

class Downscroll extends ToggleOption {override function action(args){ super.action(args); FlxG.save.data.downscroll = boolItem; }}
class FPS_cap extends SliderOption {override function action(args:Array<Dynamic>) { super.action(args); FlxG.save.data.fps_cap = Std.parseInt(getSelected());} override function update(elapsed){isLocked = FlxG.save.data.vsync;super.update(elapsed);}}
class StartFullscreen extends ToggleOption {override function action(args:Array<Dynamic>) { super.action(args); FlxG.save.data.startWithFullScreen = boolItem; }}
class ShowExtendedScores extends ToggleOption{override function action(args:Array<Dynamic>) { super.action(args); FlxG.save.data.ShowExtendedScores = boolItem; }}
class MiddleScroll extends ToggleOption {override function action(args:Array<Dynamic>){ super.action(args); FlxG.save.data.MiddleScroll = boolItem; }}
class GhostTapping extends ToggleOption {override function action(args:Array<Dynamic>){ super.action(args); FlxG.save.data.GhostTapping = boolItem; }}
class ShowTime extends ToggleOption {override function action(args:Array<Dynamic>){ super.action(args); FlxG.save.data.showTime = boolItem; }}
class TimeType extends SliderOption {override function action(args:Array<Dynamic>) { super.action(args); FlxG.save.data.TimeType = getSelected().toLowerCase();} override function update(elapsed){isLocked = !FlxG.save.data.showTime;super.update(elapsed);}}
class HealthBarColors extends ToggleOption {override function action(args:Array<Dynamic>){ super.action(args); FlxG.save.data.healthBarColors = boolItem; }}
class EnemyStrums extends SliderOption {override function action(args:Array<Dynamic>) { super.action(args); FlxG.save.data.lightstrums = getSelected().toLowerCase(); }}
class AccuracyType extends SliderOption {override function action(args:Array<Dynamic>) { super.action(args); FlxG.save.data.Accuracy = getSelected().toLowerCase();} override function update(elapsed){isLocked = !FlxG.save.data.ShowExtendedScores;super.update(elapsed);}}
class Pitch extends SliderOption {override function action(args:Array<Dynamic>) { super.action(args); FlxG.save.data.pitch = Std.parseFloat(getSelected()); }}
class Botplay extends ToggleOption {override function action(args:Array<Dynamic>){ super.action(args); FlxG.save.data.botplay = boolItem; }}
class ResetKey extends ToggleOption {override function action(args:Array<Dynamic>){ super.action(args); FlxG.save.data.resetKey = boolItem; }}
class ColorEffect extends SliderOption {override function action(args:Array<Dynamic>) { super.action(args); FlxG.save.data.colorEffect = (getSelected()); Closet.reloadColorFilter(); }}
class Cache extends SliderOption {override function action(args:Array<Dynamic>) { super.action(args); FlxG.save.data.cache = (getSelected());}}
class ShowFPS extends ToggleOption {override function action(args:Array<Dynamic>){ super.action(args); FlxG.save.data.showFps = boolItem; }}
class ShowMemory extends ToggleOption {override function action(args:Array<Dynamic>){ super.action(args); FlxG.save.data.showMemory = boolItem; }}
class UseVCR extends ToggleOption {override function action(args:Array<Dynamic>){ super.action(args); FlxG.save.data.useVcr = boolItem; }}
class UILayout extends SliderOption {override function action(args:Array<Dynamic>) { super.action(args); FlxG.save.data.UILayout = getSelected().toLowerCase();}}
class SmoothCam extends ToggleOption {override function action(args:Array<Dynamic>){ super.action(args); FlxG.save.data.smoothCam = boolItem; }}
class UseVsync extends ToggleOption {override function action(args:Array<Dynamic>){ super.action(args); FlxG.save.data.vsync = boolItem; }}