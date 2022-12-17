package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.app.Application;

class OutdatedSubState extends MusicBeatState
{
	public static final left:Map<String, Bool> = ["version"=>false, "mod"=>false];
	public var mode:String = "";

	public function new(ss:String)
	{
		super();
		mode = ss;
		switch(mode)
		{
			case "mod": 
				mod();
		}
	}

	public function version()
	{
		//clear();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);
		var ver = "v" + Application.current.meta.get('version');
		var txt:FlxText = new FlxText(0, 0, FlxG.width,
			"HEY! You're running an outdated version of the game!\nCurrent version is "
			+ ver
			+ " while the most recent version is "
			+ NGio.GAME_VER
			+ "! Press Space to go to itch.io, or ESCAPE to ignore this!!",
			32);
		txt.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		txt.screenCenter();
		add(txt);

		mode = "version";
	}

	public function mod()
	{
		//clear();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);
		var txt:FlxText = new FlxText(0, 0, FlxG.width,'
			Mod Version is Outdated!!
			(mod version: ${Modin.enabledMod.modData.modApi}, engine version: ${APIStuff.engineVersion})

			Press ENTER to proceed though some bugs may occur. 
			OR
			Press ESCAPE to open the engine download page
		',32);
		txt.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		txt.screenCenter();
		add(txt);
	}

	override function update(elapsed:Float)
	{
		if(mode == "mod")
		{
			if (controls.ACCEPT)
			{
				left.set("mod", true);
				FlxG.switchState(new MainMenuState());
			}
			if (controls.BACK)
			{
				FlxG.openURL("https://nocluebruh.itch.io/fnf-sos-engine");
				Sys.exit(0);
			}
		}
		else 
		{
			if (controls.ACCEPT)
			{
				FlxG.openURL("https://ninja-muffin24.itch.io/funkin");
			}
			if (controls.BACK)
			{
				left.set("version", true);
				FlxG.switchState(new MainMenuState());
			}	
		}
		super.update(elapsed);
	}
}
