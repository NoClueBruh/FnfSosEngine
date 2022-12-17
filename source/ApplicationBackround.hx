package;

import openfl.display.Window;
import lime.graphics.opengl.GL;
import openfl.geom.Matrix;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import lime.app.Application;
import openfl.display.FPS;
import openfl.system.System;
import openfl.text.TextFormat;
import openfl.text.TextField;
import openfl.events.Event;
import openfl.Lib;
import openfl.display.MovieClip;

class ApplicationBackround
{
    public static var current:ApplicationBackround = null;
    public static var stateFrameLimit:Map<String, Int> = ["playstate" => 999];
    public static var allowStateFpscap:Bool = true;
    public static function init():Void
    {
        ApplicationBackround.current = new ApplicationBackround();
        Lib.current.addEventListener(Event.ENTER_FRAME, (a)->{
            @:privateAccess {ApplicationBackround.current.startUpdate();}
        });
    }

    public var delta:Float = 0.0;
    private var enteredFrames:Int = 0;
    private var texts:Map<String, TextField> = [];
    private var bitmaps:Map<String, Bitmap> = [];

    private var fixedDelta:Float = 0;
    private var prevTime:Float = 0;
    public var signal:Simple_Signal;

    public function new()
    {
        signal = new Simple_Signal();

        #if !mobile
        final memory = new TextField();
        memory.defaultTextFormat = new TextFormat("_sans", 12, FlxColor.WHITE);
        memory.x = 10;
        memory.y = 16;

        final mark = new TextField();
        mark.defaultTextFormat = new TextFormat("_sans", 12, FlxColor.WHITE);
        mark.x = 10;
        mark.text = "SosEngine v" + APIStuff.engineVersion;

        final markp2 = new TextField();
        markp2.defaultTextFormat = new TextFormat("_sans", 12, FlxColor.WHITE);
        markp2.x = 10;
        markp2.text = "By 'noClueBruh'";

        final noClueBruh = new Bitmap(new BitmapData(30, 30));
        final matr = new Matrix();
        matr.scale(noClueBruh.bitmapData.width / 50, noClueBruh.bitmapData.height / 50);
        noClueBruh.bitmapData.draw(BitmapData.fromFile(Paths.image("noClueBruh")), matr);
        
        bitmaps.set("noClueBruh", noClueBruh);
        texts.set("fps", new FPS(10, 3, 0xFFFFFF));
        texts.set("memory", memory);
        texts.set("watermark", mark);
        texts.set("watermark2", markp2);

        for(i in texts)
            Lib.current.stage.addChild(i);
        for(i in bitmaps)
            Lib.current.stage.addChild(i);
        #end
        
    }
    private function startUpdate()
    {
        var frameRate:Int = Std.int(Math.abs(FlxG.save.data.fps_cap));
        var ob:Dynamic = null;
        if(FlxG.state.subState != null)
            ob = FlxG.state.subState;
        else 
            ob = FlxG.state;

        if(!FlxG.save.data.vsync)
        {
            final cap:Null<Int> = ApplicationBackround.stateFrameLimit.get(Type.getClassName(Type.getClass(ob)).toLowerCase());
            if(ApplicationBackround.allowStateFpscap)
            {
                var ccap:Int = (cap == null?250:cap);
                if(frameRate > ccap)
                    frameRate = ccap;
            }
    
            @:privateAccess
            {
                Lib.current.stage.window.__attributes.context.vsync = false;
                FlxG.drawFramerate = frameRate;
                FlxG.updateFramerate = frameRate;    
            } 
        }
        else 
        {
            @:privateAccess
            {
                Lib.current.stage.window.__attributes.context.vsync = true;
                FlxG.drawFramerate = Lib.current.stage.window.displayMode.refreshRate;
                FlxG.updateFramerate = Lib.current.stage.window.displayMode.refreshRate;
            } 
        }

        enteredFrames++;
        final milTime = Lib.getTimer() / 1000;
        delta = Math.abs(prevTime - milTime);
        onUpdate();

        fixedDelta += delta;
        while(fixedDelta > 0.02)
        {
            fixedUpdate();
            fixedDelta -= 0.02;
        }
        prevTime = milTime;
    }

    private function fixedUpdate()
    {
        signal.call("fixedUpdate");
    }

    private function onUpdate()
    {
        #if !mobile
        final memory = texts.get("memory");
        final fps = texts.get("fps");
        final mark = texts.get("watermark");
        final mark2 = texts.get("watermark2");
        final icon = bitmaps.get("noClueBruh");
        memory.visible = FlxG.save.data.showMemory;
        fps.visible = FlxG.save.data.showFps;

        if(FlxG.save.data.showMemory)
        {
            memory.text = "MEM: " + Math.abs(FlxMath.roundDecimal(System.totalMemory * 0.000001, 0)) + " MB";
            if(!FlxG.save.data.showFps)
                memory.y = 3;
            else 
                memory.y = 16;
        }

        if(FlxG.save.data.showMemory)
            mark.y = memory.y + 13;
        else 
        {
            if(FlxG.save.data.showFps)
                mark.y = 16;
            else 
                mark.y = 3;
        }
        mark2.y = mark.y + 13;
        icon.x = mark2.x + 3;
        icon.y = mark2.y + 16;
    #end
        signal.call("update");
    }
}

class Simple_Signal
{
    private var func:Map<String, Array<Void->Void>>;
    public function new(){
        func = new Map<String, Array<Void->Void>>();
    }
    public function add(type:String, reF:Void->Void):Void{
        if(!func.exists(type))
            func.set(type, []);
        func.get(type).push(reF);
    }
    public function remove(type:String, ob:OneOfTwo<Void->Void, Int>):Bool
    {
        if(Reflect.isFunction(ob))
            return func.get(type).remove(Closet.toDynamic(ob));
        else if(ob is Int)
            return func.get(type).remove(func.get(type)[Closet.toDynamic(ob)]);
        return false;
    }
    public function removeAll(type:String):Bool
        return func.remove(type);

    public function call(type:String):Void
    {
        if(!func.exists(type))
            return;

        var i:Int = func.get(type).length;
        while(i-- > 0)
            func.get(type)[i]();
    }
}