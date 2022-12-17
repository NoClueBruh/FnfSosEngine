package;

import flixel.system.FlxAssets.FlxSoundAsset;
import openfl.display.BitmapData;
import haxe.Json;
import Song.SwagSong;
import openfl.media.Sound;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;

class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;

	static var currentLevel:String;

	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	static function getPath(file:String, type:AssetType, library:Null<String>)
	{
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath = getLibraryPathForce(file, currentLevel);
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		return '$library:assets/$library/$file';
	}

	inline static function getPreloadPath(file:String)
	{
		return 'assets/$file';
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		return getPath(file, type, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('data/$key.json', TEXT, library);
	}

	static public function sound(key:String, ?library:String)
	{
		return getPath('sounds/$key.$SOUND_EXT', SOUND, library);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String)
	{
		return getPath('music/$key.$SOUND_EXT', MUSIC, library);
	}

	public static function voices(song:String, ?Pitch:Float):FlxSoundAsset
	{
		if(Pitch == null)
			Pitch = FlxG.save.data.pitch;

		var path = 'assets/songs/${song.toLowerCase()}/Voices.$SOUND_EXT';
		if(Pitch != 1) 
			return Closet.changePitch(Sound.fromFile(path), Pitch);
		return "songs:"+path;
	}

	public static function inst(song:String, ?Pitch:Float):FlxSoundAsset
	{
		if(Pitch == null)
			Pitch = FlxG.save.data.pitch;

		var path = 'assets/songs/${song.toLowerCase()}/Inst.$SOUND_EXT';
		if(Pitch != 1) 
			return Closet.changePitch(Sound.fromFile(path), Pitch);
		return "songs:"+path;
	}

	inline static public function image(key:String, ?library:String)
	{
		return getPath('images/$key.png', IMAGE, library);
	}

	inline static public function font(key:String)
	{
		return 'assets/fonts/$key';
	}

	inline static public function getSparrowAtlas(key:String, ?library:String)
	{
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
	}

	inline static public function getPackerAtlas(key:String, ?library:String)
	{
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
	}

	//---------------------------------------------MOD STUFF-------------------------------------------------------//
	#if sys
	inline static public function ModSong_data(songName:String, dif:String):SwagSong
		return Song.parseJSONshit(sys.io.File.getContent("mods/" + Modin.enabledMod.name + "/assets/data/" + songName + "/" + songName + dif + ".json"), true);

	inline static public function ModSong_Inst(songName:String, ?Pitch:Float):FlxSoundAsset
	{
		if(Pitch == null)
			Pitch = FlxG.save.data.pitch;

		var path = "assets/songs/" + songName + "/Inst.ogg";
		var a:Sound = null;
		
		if(Pitch == 1)
			a = Paths.getModSound(path);
		else
			a = Closet.changePitch(Sound.fromFile(Modin.enabledMod.modDir + path), Pitch);
		return a;
	}

	inline static public function ModSong_Voices(songName:String, ?Pitch:Float):FlxSoundAsset
	{
		if(Pitch == null)
			Pitch = FlxG.save.data.pitch;

		var path = "assets/songs/" + songName + "/Voices.ogg";
		var a:Sound = null;

		if(Pitch == 1)
			a = Paths.getModSound(path);
		else
			a = Closet.changePitch(Sound.fromFile(Modin.enabledMod.modDir + path), Pitch);
		return a;
	}

	inline static public function getModFrames(png:String, xml:String)
		return FlxAtlasFrames.fromSparrow(Paths.getModImage(png), sys.io.File.getContent(Modin.enabledMod.modDir + xml));
	inline static public function getModImage(png:String)
		return ModingUtils.modCache.getBitmap(Modin.enabledMod.modDir + png);
	inline static public function getUncachedModImage(png:String)
		return BitmapData.fromFile(Modin.enabledMod.modDir + png);
	inline static public function getModVideo(path:String)
		return Modin.enabledMod.modDir + path;
	inline static public function getModSound(path:String)
		return ModingUtils.modCache.getSound(Modin.enabledMod.modDir + path);
	#end
}
