package;

import openfl.geom.Matrix;
import openfl.net.FileReference;
import haxe.Exception;
import lime.media.openal.ALC;
import lime.media.AudioManager;
import flixel.util.FlxTimer;
import openfl.Assets;
import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets.FlxGraphicAsset;
import openfl.filters.ColorMatrixFilter;
import lime.math.ColorMatrix;
import ModingUtils;
import openfl.display.Bitmap;
import openfl.filters.BitmapFilter;
import openfl.media.Sound;
import flixel.system.FlxSound;
import openfl.geom.Rectangle;
import openfl.display.BitmapData;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.math.FlxMath;
using StringTools;

class Closet 
{
    public static function toDynamic(a:Dynamic):Dynamic 
        return a;
    
    public static function fixedLerp(a:Float, b:Float, ratio:Float)
    {
       return (a + (ratio * (60 / FlxG.drawFramerate)) * (b - a));
    }

    public static function lerp(b:Float, a:Float, ratio:Float)
    {
        return (1-ratio) * a + ratio * b;
    }

    public static function lerpInd(a, b, smoothing, dt)
    {
        return lerp(a, b, 1 - Math.pow(smoothing, dt));
    }

    public static function sharpLerp(a:Float, b:Float, ratio:Float, ?elapsed:Null<Float> = null)
    {
        if(elapsed == null)
            elapsed = FlxG.elapsed;
        return lerpInd(a,b,1 - ratio,elapsed);
    }

    public static function clamp(value:Float, min:Float, max:Float):Float 
    {
        if(value < min)
            return min;
        else if(value > max)
            return max;
        return value;
    }

    public static function getAccuracy(state:PlayState):Float
    {
        var accTM = 
            (FlxG.save.data.Accuracy == "simple" ? (state.songScore / state.maxScore) * 100 : 
            (FlxG.save.data.Accuracy == "complex" ? (state.ratio / state.noteHits) * 100 : 0));
        var acc = FlxMath.roundDecimal(accTM, 2); 
        
        if(acc > 100) return 100; 
        else if(acc < 0 || Math.isNaN(accTM)) return 0;
        return acc;
    }

    public static function makeStatus(state:PlayState):String
    {
        var str:String = "";
        str = "Score: " + state.songScore + " / Misses: " + state.misses + " / (" + FlxG.save.data.Accuracy + ") Accuracy: " + Closet.getAccuracy(state) + "%";
        return str;
    }

    public static function makeSimpleStatus(state:PlayState):String
    {
        var str:String = "";
        str = "S: " + state.songScore + " \\ M: " + state.misses + " \\ A(" + FlxG.save.data.Accuracy.charAt(0) + "): " + Closet.getAccuracy(state) + "%";
        return str;
    }

    inline public static function last(ar:Array<Dynamic>):Dynamic 
        return ar[ar.length - 1];

    public static function getMostUsedColor(bit:BitmapData, rect:Rectangle)
    {
        var colors:Map<FlxColor, Int> = [];
        var LOD:Int = 4;

        for(x in Std.int(rect.x)...Std.int(rect.width / LOD))
        {
            for(y in Std.int(rect.y)...Std.int(rect.height / LOD))
            {
                var curC = bit.getPixel32(Std.int(x * LOD), Std.int(y * LOD));
                if(curC != FlxColor.TRANSPARENT && curC != FlxColor.BLACK)
                    colors.set(curC, colors.get(curC) + 1);
            }
        }

        var winninColor:FlxColor = FlxColor.BLACK;
        var max:Int = 0;
        for(key => value in colors)
        {
            if(value > max)
            {
                max = value;
                winninColor = key;
            }
        }

        return winninColor;
    }

    public static function milToString(mil:Float):String
    {
        var maxNumz:Array<Int> = [60, 60];
        var values:Array<Int> = [Math.floor(mil / 1000), 0];

        if(((mil / 1000) / 60) / 60 >= 1)
        {
            maxNumz.push(24);
            values.push(0);
        }

        for(i in 1...values.length)
        {
            var abc = Math.floor(values[i-1] / maxNumz[i]);
            values[i-1] -= maxNumz[i] * abc;
            values[i] += abc;
        }
        values.reverse();

        var t:String = "";
        for(v in values)
            t += '${(v < 0 ? '00' : (v < 10 ? '0$v' : '$v'))} / ';
        if(t.endsWith("/ "))
            t = t.substring(0, t.length-2);

        return t;
    }

    public static function getOpenFLSound(flxSound:FlxSound):Sound
    {
        var soundAsset:Sound = null;
        #if lime
        @:privateAccess soundAsset = flxSound._sound;
        #end
        return soundAsset;
    }
    public static function changePitch(sound:Sound, pitch:Float):Sound
    {
        #if lime
        @:privateAccess
        {
            var buffer = sound.__buffer;
            buffer.sampleRate = Math.round(buffer.sampleRate * pitch);
        }
        #end
        return sound;
    }
    public static function copySound(sound:Sound):Sound
    {
        #if lime
        @:privateAccess
        {
            return Sound.fromAudioBuffer(sound.__buffer);
        }
        throw "sry i tried lmao";
        #end
        return null;
    }
    public static function reloadAudioDevice()
    {
        ALC.openDevice(null);
    }

    public static function stringToDynamic(str:String):Dynamic
    {
        if(str is String)
            str = '"' + str + '"';
        return Json.parse('{"f":$str }').f;
    }

    public static var filterTypes:Array<String> = ["none", "inverted", "bnw", "bnw2", "ynb", "nightVis"];
    public static function reloadColorFilter()
    {
        var filters:Array<BitmapFilter> = [];
        
        switch(FlxG.save.data.colorEffect)
        {
            case "inverted": 
                filters = [new ColorMatrixFilter([-1,0,0,0,255,0,-1,0,0,255,0,0,-1,0,255,0,0,0,1,0])];
            case "bnw": 
                filters = [new ColorMatrixFilter([0.5,0.5,0.5,0,0,0.5,0.5,0.5,0,0,0.5,0.5,0.5,0,0,0,0,0,0.6,0])];
            case "bnw2": 
                filters = [new ColorMatrixFilter(
                    [
                     1,0,0,0,0,
                     1,0,0,0,0,
                     1,0,0,0,0,
                     0,0,0,0.6,0
                    ]
                )];
            case "ynb": 
                filters = [new ColorMatrixFilter(
                    [
                        1,0,1,0,0,
                        1,0,1,0,0,
                        1,1,0,0,0,
                        0,0,0,0.6,0
                    ]
                )];
            case "nightVis": 
                filters = [new ColorMatrixFilter(
                    [
                        0,0.5,0,0,0,
                        0,1,0,0,0,
                        0,0.5,0,0,0,
                        0,0,0,0.8,0
                    ]
                )];
            default: 
                filters = [];
        }
        Main.fnf.setFilters(filters);
    }

    #if sys
    /**
        Returns all the files' paths with that extension.
        @param extension The extension of the files to search.
        @param path The path of the Folder to search.
        @param subFolders If true, searches the subfolders too.
    */
    public static function getFilesOfType(extension:String = "", path:String, ?subFolders:Bool = false):Array<String>
    {
        var _:Array<String> = sys.FileSystem.readDirectory(path);
        var files:Array<String> = [];
        for(i in _)
        {
            if(i.endsWith(extension))
                files.push(path + i);
            else if(subFolders)
            {
                if(!i.contains("."))
                {
                    for(ii in getFilesOfType(extension, '$path$i/', subFolders))
                        files.push(ii);
                }
            }
        }
        return files;
    }
    #end

    public static function simpleTimer(t:Float, onComplete:()->Void)
    {
        var time:Float = 0.0;
        var updateTime:Void->Void = null;
        updateTime = ()->
        {
            time += ApplicationBackround.current.delta;
            if(time >= t)
            {
                onComplete();
                ApplicationBackround.current.signal.remove("update", updateTime);
            }
        }
        ApplicationBackround.current.signal.add("update", updateTime);
    }
    inline public static function bitmapToString(bitmap:BitmapData, onLoad:(s:String)->Void) 
    {
        //TODOSUPER EXPERIMENTAL
        final lod:Int = 4;
        final obj = FrCode.obj();
        for(x in 0...Std.int(bitmap.width / lod))
        {
            for(y in 0...Std.int(bitmap.height / lod))
            {
                final clrCode = bitmap.getPixel(Std.int(x * lod),Std.int(y * lod));
                final h = obj.get(clrCode);

                if(h != null)
                    h.push([x, y])
                else 
                    obj.set(clrCode, [[x, y]]);
            }
        }
        FrCode.toData(obj, onLoad);
    }

    inline public static function stringToBitmap(str:String, onLoad:(s:BitmapData)->Void) 
    {
        //TODOSUPER EXPERIMENTAL
        final infoArray = str.split(",");

        final pixelData:Map<Array<Int>, Int> = [];
        final resolution:Array<Int> = [];
        for(i in 0...infoArray.length)
        {
            final cur = infoArray[i];
            if(i < 1)
            {
                var w = Std.parseInt(cur.split("")[0]);
                var h = Std.parseInt(cur.split("")[1]);
                resolution.push(w);
                resolution.push(h);
            }
            else 
            {
                var pos = cur.split("");
                pixelData.set([Std.parseInt(pos[0]), Std.parseInt(pos[1])], Std.parseInt(pos[2]));
            }
                
        }
        final bm:BitmapData = new BitmapData(resolution[0], resolution[1]);
        var x:Int = resolution[0];
        while (x > 0)
        {
            var y:Int = resolution[1];
            while (y > 0)
                bm.setPixel(x, y, pixelData.get([x, y]));

            if(x < 1)
                onLoad(bm);
        }
    }
}

class CacheCab
{
    public static var bitmap_max:Int = 100;
    public static var bitmap_smallFactor:Int = 250000;
    public static var sound_max:Int = -1;

    private var sounds:CacheAssetGroup<Sound>;
    private var bitmaps:CacheAssetGroup<FlxGraphic>;
    private var bitmapExceptions:Array<String>;
    
    public function new()
    {
        sounds = new CacheAssetGroup<Sound>(sound_max);
        bitmaps = new CacheAssetGroup<FlxGraphic>((FlxG.save.data.cache != "off" ? bitmap_max : 0));
        bitmapExceptions = new Array<String>();

        sounds.onRemove = (
            function (path, sound)
            {
                sound.close();
            }
        );
        bitmaps.onRemove = (
            function (path, graphic)
            {
                graphic.persist = false;
                graphic.bitmap.dispose();
                graphic.destroy();
            }
        );
    }

    inline public function addBitmapException(path:String)  
        bitmapExceptions.push(path);

    inline private function hasAssetPath(path:String, cacheGroup:CacheAssetGroup<Dynamic>):Bool 
        return cacheGroup.has(path);
    /**
        Returns a BitmapData object from the path and caches it. 
    */
    public function getBitmap(path:String):BitmapData
    {
        if(!hasAssetPath(path, bitmaps))
        {
            if(!bitmapExceptions.contains(path))
            {
                var graphic = FlxGraphic.fromBitmapData(BitmapData.fromFile(path));
                graphic.persist = FlxG.save.data.cache != "off";
                bitmaps.add(path, graphic);
            }
            else 
                return BitmapData.fromFile(path);
        }
        return bitmaps.get(path).bitmap;
    }

    /**
        Returns a Sound object from the path and caches it
    */
    inline public function getSound(path:String):Sound
    {
        if(!hasAssetPath(path, sounds))
            sounds.add(path, Sound.fromFile(path));
        return sounds.get(path);
    }

    inline public function addBitmapFixed(path:String, bitmap:BitmapData)
        bitmaps.add(path, FlxGraphic.fromBitmapData(bitmap));
}

class CacheAssetGroup<X>
{
    private var paths:Array<String>;
    private var values:Array<X>;
    private var maxSize:Int = 0;

    public var onRemove:(p:String, x:X)->Void = (p,x)->{};
    public var onAdd:(p:String, x:X)->Void = (p,x)->{};
    public function new(maxSize:Int)
    {
        this.maxSize = maxSize;

        paths = new Array<String>();
        values = new Array<X>();
    }

    public function add(path:String, item:X, replace:Bool = true)
    {
        if(has(path))
        {
            if(!replace)
                return;
            else 
            {
                remove(path);
                add(path, item);
            }
        }
        else 
        {
            paths.push(path); 
            values.push(item);
        }

        onAdd(path, item);
        if(length() - 1 > maxSize && maxSize > -1)
            remove(paths[0]);
    }

    public function remove(path:String)
    {
        if(!has(path))
            return;

        var removeItem:X = get(path);
        onRemove(path, removeItem);

        values.remove(removeItem); 
        paths.remove(path);
    }

    public function get(path:String):X 
    {
        if(!has(path))
            return null;
        
        var value = values[paths.indexOf(path)];
        return value;
    }

    public function has(path:String):Bool
        return paths.contains(path);
    public function length():Int 
        return paths.length;
    public function listPaths():Array<String>
        return paths;
    public function listAssets():Array<X>
        return values;
}

class CacheSystem
{
    public static var assets:Int = 0;
    public static var assetsDone:Int = 0;
    public static var formats = [".png", ".jpg", ".ogg", ".mp3"];

    public static function onStart()
    {
        #if sys
        CacheSystem.assets = 0;
        if(Modin.enabledMod != null)
        {
            CacheSystem.assets = getAssets(Modin.enabledMod.modDir);
            cacheFolder(Modin.enabledMod.modDir, true);
        }
        #end
    }

    private static function cacheFolder(id:String, mod:Bool)
    {
        #if sys
        var wh = sys.FileSystem.readDirectory(id);
        for(item in wh)
        {
            new FlxTimer().start(wh.indexOf(item) * 0.03, 
                function exc(timer)
                {
                    if(!item.contains("."))
                        cacheFolder(id + item + "/", mod);

                    else if(item.endsWith(".png") || item.endsWith(".jpg"))
                    {
                        CacheSystem.assetsDone++;
                        if(!mod)
                            FlxG.bitmap.add(id.split("/")[1] + ":" + id + item);
                        else 
                        {
                            var bm = BitmapData.fromFile(id + item);
                            if(bm.width * bm.height < CacheCab.bitmap_smallFactor)
                                ModingUtils.modCache.addBitmapException(id + item);
                            else
                                ModingUtils.modCache.getBitmap(id + item);
                        }
                    }
                    else if(item.endsWith(".ogg") || item.endsWith(".mp3"))
                    {
                        CacheSystem.assetsDone++;
                        if(!mod)
                            Assets.loadSound(id.split("/")[1] + ":" + id + item, true);
                        else 
                            ModingUtils.modCache.getSound(id + item);
                    }
                }
            );
        }
        #end
    }

    private static function getAssets(dir:String):Int
    {
        var length:Int = 0;
        #if sys
        var files = sys.FileSystem.readDirectory(dir);
        for(i in files)
        {
            if(!i.contains("."))
                length += getAssets(dir + i + "/");
            else if(formats.contains("." + i.split(".")[1]))
                length++;
        }
        #end
        return length;
    }
}

class FrCode
{
    public static final coordSplit = ".";
    public static final xySplit = ",";
    public static final pointerSplit = '->';

    public static function toData(clrMap:Map<FlxColor, Array<Array<Int>>>, onLoad:(str:String)->Void)
    {
        var dat:String = "";
        /*
        for(i in 0...clrs.length)
        {
            final curGroup = clrs[i];
            for(coord in coords[i])
                dat += '${coord[0]}$xySplit${coord[1]}$coordSplit';
            dat += '$pointerSplit$curGroup\n';
        }
        */
        
        for(curGroup => coords in clrMap)
        {
            var str:String = "";
            for(coord in coords)
            {
                str += '[${coord[0]}$xySplit${coord[1]}]$coordSplit';      
            }
            dat = dat + '$str$pointerSplit$curGroup\n';
        }
        onLoad(dat);
    }

    inline public static function fromData(dat:String):Map<Array<Int>, Int>
    {
        final map:Map<Array<Int>, Int> = [];
        for(line in dat.split("\n"))
        {
            final color:FlxColor = FlxColor.fromInt(Std.parseInt(line.split(pointerSplit)[1]));
            for(coord in line.split('$coordSplit$pointerSplit')[0].split(coordSplit))
            {
                var raw = coord.substring(1, coord.length-1).split(xySplit);
                var f:Array<Int> =[Std.parseInt(raw[0]),Std.parseInt(raw[1])];
                map.set(f, color);
            }
        }
        return map;
    }

    inline public static function obj()
        return new Map<FlxColor, Array<Array<Int>>>();
}

enum NoteArrayType 
{
    HOLD;
    PRESS;
    RELEASE;
}
class NoteArray
{
    private var container:Array<Bool> = [];
    private var type:NoteArrayType = PRESS;
    public function new(type:NoteArrayType)
    {
        this.type = type;
    }

    private function update(controls:Controls)
    {
        switch (type)
        {
            case HOLD: 
                container = [controls.LEFT, controls.DOWN, controls.UP, controls.RIGHT];
            case PRESS:
                container = [controls.LEFT_P, controls.DOWN_P, controls.UP_P, controls.RIGHT_P];
            case RELEASE: 
                container = [controls.LEFT_R, controls.DOWN_R, controls.UP_R, controls.RIGHT_R];
        }
    }

    public function getUpdate(i:Int, controls:Controls)
    {
        update(controls);
        return container[i];
    }

    public function hasAny(controls:Controls)
    {
        update(controls);
        return container.contains(true);
    }
}