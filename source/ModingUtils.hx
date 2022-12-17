package;

import flixel.FlxG;
import openfl.display.BitmapData;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import Closet;
class ModingUtils 
{
    public static var modCache:CacheCab = null;

    public static function initialize()
    {
        #if sys
        modCache = new CacheCab();
        Modin.load();
		Modin.runMod(sys.io.File.getContent("mods/mod.txt"));
		#end
    }
    
    public static function addOutline(txt:FlxText, color:FlxColor, outlineW:Int)
    {
        txt.setBorderStyle(OUTLINE, color, outlineW, 1);
    } 

    public static function cacheCharacter(a:String, b:String, c:Bool)
    {
        if(PlayState.instance != null)
        {
            PlayState.instance.cacheCharacter(a, (c? new Boyfriend(0,0,b) : new Character(0,0,b,false)));
        }
    }
}
class Color
{
    public static function fromString(str:String):Int 
        return FlxColor.fromString(str.toUpperCase());

    public static function fromRGB(r:Int, g:Int, b:Int, a:Int = 255):Int 
        return FlxColor.fromRGB(r,g,b,a);

    public static function fromRGBfloat(r:Float, g:Float, b:Float, a:Float = 1):Int 
        return FlxColor.fromRGBFloat(r,g,b,a);
}