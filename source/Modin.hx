package;

import haxe.Serializer;
import flixel.FlxG;
import flixel.util.FlxColor;
import haxe.DynamicAccess;
import flixel.text.FlxText.FlxTextBorderStyle;
import polymod.hscript.HScriptable.Script;
import flixel.math.FlxMath;
import hscript.Interp;
import haxe.Json;

using StringTools;

class Modin
{
    public static var mods:Map<String, Mod> = [];
    public static var runningMod:String = "";
    public static var enabledMod:Mod = null;
    public static var isModReady:Bool = false;

    public static function load()
    {
        mods.clear();

        #if sys
        var files = sys.FileSystem.readDirectory("mods/");
        for(i in files)
        {
            if(!i.contains("."))
            {
                var mod = new Mod(i);
                mods.set(i, mod);
            }
        }
        #end
    }

    public static function destroyMod()
    {
        if(enabledMod != null)
        {
            runningMod = "";
            isModReady = false;
            enabledMod = null;
        }
    }

    public static function runMod(name:String):Bool
    {
        if(mods.exists(name))
        {
            runningMod = name;
            enabledMod = mods.get(name);
            isModReady = true;
            return true;
        }

        runningMod = "";
        enabledMod = null;
        isModReady = false;
        return false;
    }

    public static function isModOutdated():Bool 
    {
        return Modin.enabledMod != null ? Modin.enabledMod.modData.modApi != Mod.modApi : false;
    }

    public static function instantiateScript(name:String):Interp
    {
        if(enabledMod == null)
            return null;

        enabledMod.reload();
        return enabledMod.runScript(name);
    }

    public static function runFunctionFromInterp(interp:Interp, object:Dynamic, functionName:String)
    {
        if(interp == null)
            return; 
        if(!interp.variables.exists(functionName))
            return;

        enabledMod.updateVars(interp, object);
        interp.variables.get(functionName)();
    }
}

typedef ModData =
{
    var version:String;
    var modApi:String;
} 
typedef ModSong_data =
{
    var weekNum:Int;
    var name:String;
    var icon:String;
}
class Mod
{
    public static final modApi:String = APIStuff.engineVersion;

    private var scripts:Map<String, Script> = [];
    public var songs:Array<ModSong_data> = [];

    public var name:String = "";
    public var modData:ModData = null;
    public var modDir:String = "";

    public function new(name:String)
    {
        this.name = name;
        modDir = "mods/" + name + "/";
        reload();
    }

    public function reload()
    {
        #if sys
        this.modData = Json.parse(sys.io.File.getContent("mods/" + name + "/modData.json"));
        #end

        loadSongs();
        loadScripts();
    }

    public function loadSongs()
    {
        songs = [];
        #if sys
        if(!sys.FileSystem.exists("mods/"+name+"/assets/data/freeplaySongs.txt"))
            return;
        
        var sf = sys.io.File.getContent("mods/"+name+"/assets/data/freeplaySongs.txt").split("\n");
        for(i in sf)
        {
            if(i.trim() != "")
            {
                var args = i.split(":");
                var songData:ModSong_data = {name: args[0], weekNum: Std.parseInt(args[1]), icon: args[2]};
                songs.push(songData);
            }
        }
        #end
    }

    public function loadScripts()
    {
        scripts.clear();
    
        #if sys
        final searchPaths:Array<String> = [modDir + "scripts/"];
        for(x in searchPaths)
        {
            if(sys.FileSystem.exists(x))
            {
                final exten = [".hs",  ".hx"];
                for(a in exten)
                {
                    for(script in Closet.getFilesOfType(a, x, true))
                    {
                        var name:String = script.substring(script.lastIndexOf("/") + 1, script.indexOf("."));
                        var hscript:Script = new Script(sys.io.File.getContent(script));
                        scripts.set(name, hscript);
                    }
                }
            }
        }
        #end
    }

    public function updateVars(scr:Interp, object:Dynamic)
    {
        for(i in Reflect.fields(object))
        {
            var val = Reflect.field(object, i);
            scr.variables.set(i, val);
        }
    }

    private function fixInterp(scr:Interp)
    {
        for(key=>value in DynamicScript.getAllClasses())
            scr.variables.set(key, value);
    }

    public function runScript(scriptName:String):Interp
    {
        var script = scripts.get(scriptName);

        if(script == null)
            return null;
    
        script.execute();

        var dfvdf = script.interp;
        fixInterp(dfvdf);
        return dfvdf;
    }
}
class DynamicScript
{
    public static function fromString(str:String)
    {
        var script:Dynamic = {};
        #if sys
            var hs = new Script(str);
            hs.execute();
            
            var bit:String = "";
            for(key => value in hs.interp.variables)
                bit += '"$key": 0,';

            script = Json.parse('{${bit.substring(0, bit.length - 1)}}');
            for(k=>va in getAllClasses())
                hs.interp.variables.set(k, va);
            for(k=>va in hs.interp.variables)
                Reflect.setField(script, k, va);
        #end
        return script;
    }

    public static function newScript(source:String)
    {
        #if sys
        return DynamicScript.fromString(sys.io.File.getContent(Modin.enabledMod.modDir + source));
        #end
        return {};
    }
    public static function getAllClasses():Map<String, Dynamic>
    {
        final a:Map<String, Dynamic> = [];
        //https://lib.haxe.org/p/compiletime/
        CompileTime.getAllClasses().map((f)->{
            a.set( Closet.last((f + "").split(".")), f);
        });
        a.set("Math", Math);
        a.set("Array", Array);
        a.set("Reflect", Reflect);
        a.set("StringTools", StringTools);
        a.set("MU", ModingUtils);
        a.set("Color", ModingUtils.Color);
        a.set("Video", EpicVideo);
        a.set("Closet", Closet);
        a.set("Script", DynamicScript);
        return a;
    }
}