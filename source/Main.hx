package;

import lime.utils.Bytes;
import haxe.io.BytesInput;
import haxe.zip.Reader;
import openfl.system.System;
import vlc.MP4Handler;
import flixel.FlxSprite;
import haxe.CallStack;
import haxe.CallStack.StackItem;
import lime.app.Application;
import haxe.io.Input;
import openfl.ui.GameInputDevice;
import openfl.events.GameInputEvent;
import flixel.util.FlxTimer;
import openfl.events.UncaughtErrorEvent;
import openfl.events.UncaughtErrorEvents;
import lime.system.CFFIPointer;
import lime.media.openal.ALContext;
import lime.media.AudioManager;
import lime.media.AudioContext;
import openfl.system.Capabilities;
import openfl.events.MouseEvent;
import openfl.events.NetStatusEvent;
import openfl.events.AsyncErrorEvent;
import flixel.tweens.FlxTween;
import openfl.net.NetConnection;
import openfl.net.NetStream;
import openfl.media.Video;
import openfl.net.URLRequest;
import flixel.system.FlxSound;
import openfl.geom.ColorTransform;
import openfl.display.Bitmap;
import openfl.filters.DisplacementMapFilter;
import openfl.filters.ColorMatrixFilter;
import flixel.util.FlxColor;
import openfl.filters.GlowFilter;
import openfl.filters.BlurFilter;
import flixel.system.debug.watch.Watch;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = TitleState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 60; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static var fnf:FlxGame;
	public static function main():Void
	{
		try{
		Lib.current.addChild(new Main());}
		catch(a:Any)
		{
			throw Std.string(a);
		}
	}

	public function new()
	{
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}

		#if !debug
		initialState = TitleState;
		#end

		fnf = new FlxGame(gameWidth, gameHeight, initialState, zoom, framerate, framerate, skipSplash, startFullscreen);
		addChild(fnf);
		fnf.stage.quality = BEST;
		Closet.reloadColorFilter();

		ModingUtils.initialize();
		
		/*
		final record = true;

		if(record)
		{
			var a = new MP4Handler();
			a.playVideo("E:/xd.mp4", false, true);
			a.onVideoReady = ()->{SOSVID.mp4ToData(a);}
		}
		else
			new SOSVID("E:/lmao.zip").play();
		*/

		Lib.application.window.fullscreen = FlxG.save.data.startWithFullScreen;
	}
}