package;

import flixel.input.keyboard.FlxKeyboard;
import lime.system.Clipboard;
import Closet.NoteArrayType;
import Closet.NoteArray;
import flixel.group.FlxGroup;

class PlayState extends MusicBeatState
{
	public static var instance:PlayState;
	public static var curStage:String = '';
	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	public static var isPixelStage:Bool = false;
	public static var modSong:Bool = false;

	public var ratio:Float = 0;
	public var noteHits:Float = 0;
	var halloweenLevel:Bool = false;

	private var vocals:FlxSound;

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Boyfriend;

	private var notes:FlxTypedGroup<Note>;
	private var unspawnNotes:Array<Note> = [];

	private var strumLine:FlxSprite;

	private var camFollow:FlxObject;
	private var camPoint:FlxPoint;
	private static var prevCamFollow:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StaticArrow>;
	public var playerStrums:FlxTypedGroup<StaticArrow>;

	private var camZooming:Bool = false;
	private var curSong:String = "";

	private var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;
	private var healthBar:HealthBar;

	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;

	private var iconP1:HealthIcon;
	private var iconP2:HealthIcon;
	private var camHUD:FlxCamera;
	private var camGame:FlxCamera;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];

	var halloweenBG:FlxSprite;
	var isHalloween:Bool = false;

	var phillyCityLights:FlxTypedGroup<FlxSprite>;
	var phillyTrain:FlxSprite;
	var trainSound:FlxSound;

	var limo:FlxSprite;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:FlxSprite;

	var upperBoppers:FlxSprite;
	var bottomBoppers:FlxSprite;
	var santa:FlxSprite;

	var bgGirls:BackgroundGirls;
	var wiggleShit:WiggleEffect = new WiggleEffect();

	var talking:Bool = true;
	public var songScore:Int = 0;

	var scoreTxt:FlxText;

	var time_time:Float = 0;

	var timeTxt:FlxText;
	var timeBG:FlxSprite;

	public static var campaignScore:Int = 0;

	var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	var inCutscene:Bool = false;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var iconRPC:String = "";
	var songLength:Float = 0;
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	var bgLayer:FlxTypedGroup<FlxSprite>;
	var fgLayer:FlxTypedGroup<FlxSprite>;
	var characterLayer:FlxTypedGroup<FlxSprite>;

	public var misses:Int = 0;
	public var maxScore:Int = 0;
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;

	private var normalNotes:FlxGroup;
	private var trailNotes:FlxGroup;

	@:noPrivateAccess
	private var keyPresses:NoteArray = new NoteArray(NoteArrayType.PRESS);
	@:noPrivateAccess
	private var keyReleases:NoteArray = new NoteArray(NoteArrayType.RELEASE);
	@:noPrivateAccess
	private var keys:NoteArray = new NoteArray(NoteArrayType.HOLD);

	public var opponentHitNote:Note->Void = (note)->{};

	public function new()
	{
		instance = this;
		super();
	}

	override public function create()
	{
		bgLayer = new FlxTypedGroup<FlxSprite>();
		fgLayer = new FlxTypedGroup<FlxSprite>();
		characterLayer = new FlxTypedGroup<FlxSprite>();

		normalNotes = new FlxGroup();
		trailNotes = new FlxGroup();

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);

		FlxCamera.defaultCameras = [camGame];

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		switch (SONG.song.toLowerCase())
		{
			case 'tutorial':
				dialogue = ["Hey you're pretty cute.", 'Use the arrow keys to keep up \nwith me singing.'];
			case 'bopeebo':
				dialogue = [
					'HEY!',
					"You think you can just sing\nwith my daughter like that?",
					"If you want to date her...",
					"You're going to have to go \nthrough ME first!"
				];
			case 'fresh':
				dialogue = ["Not too shabby boy.", ""];
			case 'dadbattle':
				dialogue = [
					"gah you think you're hot stuff?",
					"If you can beat me here...",
					"Only then I will even CONSIDER letting you\ndate my daughter!"
				];
			case 'senpai':
				dialogue = CoolUtil.coolTextFile(Paths.txt('senpai/senpaiDialogue'));
			case 'roses':
				dialogue = CoolUtil.coolTextFile(Paths.txt('roses/rosesDialogue'));
			case 'thorns':
				dialogue = CoolUtil.coolTextFile(Paths.txt('thorns/thornsDialogue'));
		}

		#if desktop
		// Making difficulty text for Discord Rich Presence.
		switch (storyDifficulty)
		{
			case 0:
				storyDifficultyText = "Easy";
			case 1:
				storyDifficultyText = "Normal";
			case 2:
				storyDifficultyText = "Hard";
		}

		iconRPC = SONG.player2;

		// To avoid having duplicate images in Discord assets
		switch (iconRPC)
		{
			case 'senpai-angry':
				iconRPC = 'senpai';
			case 'monster-christmas':
				iconRPC = 'monster';
			case 'mom-car':
				iconRPC = 'mom';
		}

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: Week " + storyWeek;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
		#end

		switch (SONG.song.toLowerCase())
		{
                        case 'spookeez' | 'monster' | 'south': 
                        {
                                curStage = 'spooky';
	                          halloweenLevel = true;

		                  var hallowTex = Paths.getSparrowAtlas('halloween_bg');

	                          halloweenBG = new FlxSprite(-200, -100);
		                  halloweenBG.frames = hallowTex;
	                          halloweenBG.animation.addByPrefix('idle', 'halloweem bg0');
	                          halloweenBG.animation.addByPrefix('lightning', 'halloweem bg lightning strike', 24, false);
	                          halloweenBG.animation.play('idle');
	                          halloweenBG.antialiasing = true;
	                          add(halloweenBG);

		                  isHalloween = true;
		          }
		          case 'pico' | 'blammed' | 'philly': 
                        {
		                  curStage = 'philly';

		                  var bg:FlxSprite = new FlxSprite(-100).loadGraphic(Paths.image('philly/sky'));
		                  bg.scrollFactor.set(0.1, 0.1);
		                  add(bg);

	                          var city:FlxSprite = new FlxSprite(-10).loadGraphic(Paths.image('philly/city'));
		                  city.scrollFactor.set(0.3, 0.3);
		                  city.setGraphicSize(Std.int(city.width * 0.85));
		                  city.updateHitbox();
		                  add(city);

		                  phillyCityLights = new FlxTypedGroup<FlxSprite>();
		                  add(phillyCityLights);

		                  for (i in 0...5)
		                  {
		                          var light:FlxSprite = new FlxSprite(city.x).loadGraphic(Paths.image('philly/win' + i));
		                          light.scrollFactor.set(0.3, 0.3);
		                          light.visible = false;
		                          light.setGraphicSize(Std.int(light.width * 0.85));
		                          light.updateHitbox();
		                          light.antialiasing = true;
		                          phillyCityLights.add(light);
		                  }

		                  var streetBehind:FlxSprite = new FlxSprite(-40, 50).loadGraphic(Paths.image('philly/behindTrain'));
		                  add(streetBehind);

	                          phillyTrain = new FlxSprite(2000, 360).loadGraphic(Paths.image('philly/train'));
		                  add(phillyTrain);

		                  trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
		                  FlxG.sound.list.add(trainSound);

		                  // var cityLights:FlxSprite = new FlxSprite().loadGraphic(AssetPaths.win0.png);

		                  var street:FlxSprite = new FlxSprite(-40, streetBehind.y).loadGraphic(Paths.image('philly/street'));
	                          add(street);
		          }
		          case 'milf' | 'satin-panties' | 'high':
		          {
		                  curStage = 'limo';
		                  defaultCamZoom = 0.90;

		                  var skyBG:FlxSprite = new FlxSprite(-120, -50).loadGraphic(Paths.image('limo/limoSunset'));
		                  skyBG.scrollFactor.set(0.1, 0.1);
		                  add(skyBG);

		                  var bgLimo:FlxSprite = new FlxSprite(-200, 480);
		                  bgLimo.frames = Paths.getSparrowAtlas('limo/bgLimo');
		                  bgLimo.animation.addByPrefix('drive', "background limo pink", 24);
		                  bgLimo.animation.play('drive');
		                  bgLimo.scrollFactor.set(0.4, 0.4);
		                  add(bgLimo);

		                  grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
		                  add(grpLimoDancers);

		                  for (i in 0...5)
		                  {
		                          var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
		                          dancer.scrollFactor.set(0.4, 0.4);
		                          grpLimoDancers.add(dancer);
		                  }

		                  var overlayShit:FlxSprite = new FlxSprite(-500, -600).loadGraphic(Paths.image('limo/limoOverlay'));
		                  overlayShit.alpha = 0.5;
		                  // add(overlayShit);

		                  // var shaderBullshit = new BlendModeEffect(new OverlayShader(), FlxColor.RED);

		                  // FlxG.camera.setFilters([new ShaderFilter(cast shaderBullshit.shader)]);

		                  // overlayShit.shader = shaderBullshit;

		                  var limoTex = Paths.getSparrowAtlas('limo/limoDrive');

		                  limo = new FlxSprite(-120, 550);
		                  limo.frames = limoTex;
		                  limo.animation.addByPrefix('drive', "Limo stage", 24);
		                  limo.animation.play('drive');
		                  limo.antialiasing = true;

		                  fastCar = new FlxSprite(-300, 160).loadGraphic(Paths.image('limo/fastCarLol'));
		                  // add(limo);
		          }
		          case 'cocoa' | 'eggnog':
		          {
	                          curStage = 'mall';

		                  defaultCamZoom = 0.80;

		                  var bg:FlxSprite = new FlxSprite(-1000, -500).loadGraphic(Paths.image('christmas/bgWalls'));
		                  bg.antialiasing = true;
		                  bg.scrollFactor.set(0.2, 0.2);
		                  bg.active = false;
		                  bg.setGraphicSize(Std.int(bg.width * 0.8));
		                  bg.updateHitbox();
		                  add(bg);

		                  upperBoppers = new FlxSprite(-240, -90);
		                  upperBoppers.frames = Paths.getSparrowAtlas('christmas/upperBop');
		                  upperBoppers.animation.addByPrefix('bop', "Upper Crowd Bob", 24, false);
		                  upperBoppers.antialiasing = true;
		                  upperBoppers.scrollFactor.set(0.33, 0.33);
		                  upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
		                  upperBoppers.updateHitbox();
		                  add(upperBoppers);

		                  var bgEscalator:FlxSprite = new FlxSprite(-1100, -600).loadGraphic(Paths.image('christmas/bgEscalator'));
		                  bgEscalator.antialiasing = true;
		                  bgEscalator.scrollFactor.set(0.3, 0.3);
		                  bgEscalator.active = false;
		                  bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
		                  bgEscalator.updateHitbox();
		                  add(bgEscalator);

		                  var tree:FlxSprite = new FlxSprite(370, -250).loadGraphic(Paths.image('christmas/christmasTree'));
		                  tree.antialiasing = true;
		                  tree.scrollFactor.set(0.40, 0.40);
		                  add(tree);

		                  bottomBoppers = new FlxSprite(-300, 140);
		                  bottomBoppers.frames = Paths.getSparrowAtlas('christmas/bottomBop');
		                  bottomBoppers.animation.addByPrefix('bop', 'Bottom Level Boppers', 24, false);
		                  bottomBoppers.antialiasing = true;
	                          bottomBoppers.scrollFactor.set(0.9, 0.9);
	                          bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
		                  bottomBoppers.updateHitbox();
		                  add(bottomBoppers);

		                  var fgSnow:FlxSprite = new FlxSprite(-600, 700).loadGraphic(Paths.image('christmas/fgSnow'));
		                  fgSnow.active = false;
		                  fgSnow.antialiasing = true;
		                  add(fgSnow);

		                  santa = new FlxSprite(-840, 150);
		                  santa.frames = Paths.getSparrowAtlas('christmas/santa');
		                  santa.animation.addByPrefix('idle', 'santa idle in fear', 24, false);
		                  santa.antialiasing = true;
		                  add(santa);
		          }
		          case 'winter-horrorland':
		          {
		                  curStage = 'mallEvil';
		                  var bg:FlxSprite = new FlxSprite(-400, -500).loadGraphic(Paths.image('christmas/evilBG'));
		                  bg.antialiasing = true;
		                  bg.scrollFactor.set(0.2, 0.2);
		                  bg.active = false;
		                  bg.setGraphicSize(Std.int(bg.width * 0.8));
		                  bg.updateHitbox();
		                  add(bg);

		                  var evilTree:FlxSprite = new FlxSprite(300, -300).loadGraphic(Paths.image('christmas/evilTree'));
		                  evilTree.antialiasing = true;
		                  evilTree.scrollFactor.set(0.2, 0.2);
		                  add(evilTree);

		                  var evilSnow:FlxSprite = new FlxSprite(-200, 700).loadGraphic(Paths.image("christmas/evilSnow"));
	                          evilSnow.antialiasing = true;
		                  add(evilSnow);
                        }
		          case 'senpai' | 'roses':
		          {
		                  curStage = 'school';

		                  // defaultCamZoom = 0.9;

		                  var bgSky = new FlxSprite().loadGraphic(Paths.image('weeb/weebSky'));
		                  bgSky.scrollFactor.set(0.1, 0.1);
		                  add(bgSky);

		                  var repositionShit = -200;

		                  var bgSchool:FlxSprite = new FlxSprite(repositionShit, 0).loadGraphic(Paths.image('weeb/weebSchool'));
		                  bgSchool.scrollFactor.set(0.6, 0.90);
		                  add(bgSchool);

		                  var bgStreet:FlxSprite = new FlxSprite(repositionShit).loadGraphic(Paths.image('weeb/weebStreet'));
		                  bgStreet.scrollFactor.set(0.95, 0.95);
		                  add(bgStreet);

		                  var fgTrees:FlxSprite = new FlxSprite(repositionShit + 170, 130).loadGraphic(Paths.image('weeb/weebTreesBack'));
		                  fgTrees.scrollFactor.set(0.9, 0.9);
		                  add(fgTrees);

		                  var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
		                  var treetex = Paths.getPackerAtlas('weeb/weebTrees');
		                  bgTrees.frames = treetex;
		                  bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
		                  bgTrees.animation.play('treeLoop');
		                  bgTrees.scrollFactor.set(0.85, 0.85);
		                  add(bgTrees);

		                  var treeLeaves:FlxSprite = new FlxSprite(repositionShit, -40);
		                  treeLeaves.frames = Paths.getSparrowAtlas('weeb/petals');
		                  treeLeaves.animation.addByPrefix('leaves', 'PETALS ALL', 24, true);
		                  treeLeaves.animation.play('leaves');
		                  treeLeaves.scrollFactor.set(0.85, 0.85);
		                  add(treeLeaves);

		                  var widShit = Std.int(bgSky.width * 6);

		                  bgSky.setGraphicSize(widShit);
		                  bgSchool.setGraphicSize(widShit);
		                  bgStreet.setGraphicSize(widShit);
		                  bgTrees.setGraphicSize(Std.int(widShit * 1.4));
		                  fgTrees.setGraphicSize(Std.int(widShit * 0.8));
		                  treeLeaves.setGraphicSize(widShit);

		                  fgTrees.updateHitbox();
		                  bgSky.updateHitbox();
		                  bgSchool.updateHitbox();
		                  bgStreet.updateHitbox();
		                  bgTrees.updateHitbox();
		                  treeLeaves.updateHitbox();

		                  bgGirls = new BackgroundGirls(-100, 190);
		                  bgGirls.scrollFactor.set(0.9, 0.9);

		                  if (SONG.song.toLowerCase() == 'roses')
	                          {
		                          bgGirls.getScared();
		                  }

		                  bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
		                  bgGirls.updateHitbox();
		                  add(bgGirls);
		          }
		          case 'thorns':
		          {
		                  curStage = 'schoolEvil';

		                  var waveEffectBG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 3, 2);
		                  var waveEffectFG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 5, 2);

		                  var posX = 400;
	                          var posY = 200;

		                  var bg:FlxSprite = new FlxSprite(posX, posY);
		                  bg.frames = Paths.getSparrowAtlas('weeb/animatedEvilSchool');
		                  bg.animation.addByPrefix('idle', 'background 2', 24);
		                  bg.animation.play('idle');
		                  bg.scrollFactor.set(0.8, 0.9);
		                  bg.scale.set(6, 6);
		                  add(bg);
		          }
		          default:
		          {
		                  defaultCamZoom = 0.9;
		                  curStage = 'stage';
		                  var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image('stageback'));
		                  bg.antialiasing = true;
		                  bg.scrollFactor.set(0.9, 0.9);
		                  bg.active = false;
		                  add(bg);

		                  var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(Paths.image('stagefront'));
		                  stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		                  stageFront.updateHitbox();
		                  stageFront.antialiasing = true;
		                  stageFront.scrollFactor.set(0.9, 0.9);
		                  stageFront.active = false;
		                  add(stageFront);

		                  var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic(Paths.image('stagecurtains'));
		                  stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
		                  stageCurtains.updateHitbox();
		                  stageCurtains.antialiasing = true;
		                  stageCurtains.scrollFactor.set(1.3, 1.3);
		                  stageCurtains.active = false;

		                  add(stageCurtains);
		          }
              }

		var gfVersion:String = 'gf';
		switch (curStage)
		{
			case 'limo':
				gfVersion = 'gf-car';
			case 'mall' | 'mallEvil':
				gfVersion = 'gf-christmas';
			case 'school':
				gfVersion = 'gf-pixel';
			case 'schoolEvil':
				gfVersion = 'gf-pixel';
		}

		if (curStage == 'limo')
			gfVersion = 'gf-car';

		isPixelStage = curStage == "school" || curStage == "schoolEvil";

		gf = new Character(400, 130, gfVersion);
		gf.scrollFactor.set(0.95, 0.95);

		dad = new Character(100, 100, SONG.player2);
		//TODO vcr part
		#if Preview
			if(FlxG.save.data.useVcr)
			{
				var camGameOptions:VCR_Options = {
					useStatic: true,
					useChromaticAberration: true,
					staticPower: 0.4,
					staticResolution: 500,
					chromaticAberrationRadius: 0.025,
					chromaticAberrationPower: 0.4,
					distortPower: 0.225,
					useBlackBorder: false
				};
	
				camHUD.setFilters([new VCR(camHUD).asShaderFilter]);
				camGame.setFilters([new VCR(camGame, camGameOptions).asShaderFilter]);
				FlxG.stage.window.onResize.add((a,b)->{
					camHUD.setFilters([]);
					camGame.setFilters([]);
					new FlxTimer().start(0.1, (c)->{
						camHUD.setFilters([new VCR(camHUD).asShaderFilter]);
						camGame.setFilters([new VCR(camGame, camGameOptions).asShaderFilter]);
					});
					// removing the old Vcr intance and adding a new one bc when the game resizes it gets messed up
				});
			}
		#end
		var camPos:FlxPoint = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);

		switch (SONG.player2)
		{
			case 'gf':
				dad.setPosition(gf.x, gf.y);
				gf.visible = false;
				if (isStoryMode)
				{
					camPos.x += 600;
					tweenCamIn();
				}

			case "spooky":
				dad.y += 200;
			case "monster":
				dad.y += 100;
			case 'monster-christmas':
				dad.y += 130;
			case 'dad':
				camPos.x += 400;
			case 'pico':
				camPos.x += 600;
				dad.y += 300;
			case 'parents-christmas':
				dad.x -= 500;
			case 'senpai':
				dad.x += 150;
				dad.y += 360;
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
			case 'senpai-angry':
				dad.x += 150;
				dad.y += 360;
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
			case 'spirit':
				dad.x -= 150;
				dad.y += 100;
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
		}

		boyfriend = new Boyfriend(770, 450, SONG.player1);

		// REPOSITIONING PER STAGE
		switch (curStage)
		{
			case 'limo':
				boyfriend.y -= 220;
				boyfriend.x += 260;

				resetFastCar();
				add(fastCar);

			case 'mall':
				boyfriend.x += 200;

			case 'mallEvil':
				boyfriend.x += 320;
				dad.y -= 80;
			case 'school':
				boyfriend.x += 200;
				boyfriend.y += 220;
				gf.x += 180;
				gf.y += 300;
			case 'schoolEvil':
				// trailArea.scrollFactor.set();

				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
				// evilTrail.changeValuesEnabled(false, false, false, false);
				// evilTrail.changeGraphic()
				add(evilTrail);
				// evilTrail.scrollFactor.set(1.1, 1.1);

				boyfriend.x += 200;
				boyfriend.y += 220;
				gf.x += 180;
				gf.y += 300;
		}

		// Shitty layering but whatev it works LOL
		if (curStage == 'limo')
		{
			add(gf);
			add(limo);
		}

		add(bgLayer);
		add(characterLayer);

		characterLayer.add(gf);
		characterLayer.add(dad);
		characterLayer.add(boyfriend);

		if (curStage == 'limo')
			characterLayer.remove(gf);

		add(fgLayer);
		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		if(FlxG.save.data.downscroll)
			strumLine.y = FlxG.height - 165;
		strumLine.scrollFactor.set();
		strumLineNotes = new FlxTypedGroup<StaticArrow>();
		add(strumLineNotes);

		playerStrums = new FlxTypedGroup<StaticArrow>();
		add(playerStrums);

		// startCountdown();

		generateSong(SONG.song);

		// add(strumLine);

		camFollow = new FlxObject(0, 0, 1, 1);

		camFollow.setPosition(camPos.x, camPos.y);
		camPoint = new FlxPoint(camPos.x, camPos.y);

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		add(camFollow);

		//FlxG.camera.follow(camFollow, LOCKON, 0.04);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		//FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		healthBar = new HealthBar(0, (FlxG.save.data.downscroll ? 50 : FlxG.height * 0.9), 'healthBar', 0xFFFF0000, 0xFF66FF33, 'health');
		healthBar.screenCenter(X);

		scoreTxt = new FlxText(healthBar.x + healthBar.width - 190, healthBar.y + 30, 0, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT);
		scoreTxt.scrollFactor.set();

		iconP1 = new HealthIcon(SONG.player1, true);
		iconP1.y = healthBar.y + healthBar.height / 2 - (iconP1.height / 2);
		
		iconP2 = new HealthIcon(SONG.player2, false);
		iconP2.y = healthBar.y + healthBar.height / 2 - (iconP2.height / 2);

		if(FlxG.save.data.healthBarColors)
		{
			healthBar.enemyColor = Closet.getMostUsedColor(iconP2.diplayedSprite, iconP2.diplayedSprite.rect);
			healthBar.playerColor = Closet.getMostUsedColor(iconP1.diplayedSprite, iconP1.diplayedSprite.rect);
		}

		add(healthBar);
		add(iconP1);
		add(iconP2);
		add(scoreTxt);

		if(FlxG.save.data.showTime)
		{
			timeBG = new FlxSprite(0, -10);
			timeBG.makeGraphic(1,1, FlxColor.WHITE);
			timeBG.alpha = 0;
			add(timeBG);

			timeTxt = new FlxText(0, -110);
			timeTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT);
			timeTxt.scrollFactor.set();
			timeTxt.alpha = 0;
			timeTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1, 1);
			add(timeTxt);

			timeBG.cameras = [camHUD];
			timeTxt.cameras = [camHUD];
		}

		if(FlxG.save.data.botplay)
		{
			var botTxt = new FlxText(0, 0);
			botTxt.setFormat(Paths.font("vcr.ttf"), 26, FlxColor.WHITE, RIGHT);
			botTxt.scrollFactor.set();
			botTxt.text = "BOTPLAY";
			botTxt.screenCenter();
			botTxt.camera = camHUD;
			botTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1, 1);
			add(botTxt);
		}

		if(FlxG.save.data.UILayout == "simple")
			scoreTxt.y = healthBar.y + 45;

		strumLineNotes.cameras = [camHUD];
		playerStrums.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];

		super.create();
		startingSong = true;
		if (isStoryMode)
		{
			switch (curSong.toLowerCase())
			{
				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;

					new FlxTimer().start(0.1, function(tmr:FlxTimer)
					{
						remove(blackScreen);
						FlxG.sound.play(Paths.sound('Lights_Turn_On'));
						camFollow.y = -2050;
						camFollow.x += 200;
						FlxG.camera.focusOn(camFollow.getPosition());
						FlxG.camera.zoom = 1.5;

						new FlxTimer().start(0.8, function(tmr:FlxTimer)
						{
							camHUD.visible = true;
							remove(blackScreen);
							FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
								ease: FlxEase.quadInOut,
								onComplete: function(twn:FlxTween)
								{
									startCountdown();
								}
							});
						});
					});
				case 'senpai':
					schoolIntro();
				case 'roses':
					FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro();
				case 'thorns':
					schoolIntro();
				default:
					startCountdown();
			}
		}
		else
		{
			switch (curSong.toLowerCase())
			{
				default:
					startCountdown();
			}
		}
	}

	function schoolIntro():Void
	{
		var dialogueBox:DialogueBox = new DialogueBox(false, dialogue);
		dialogueBox.scrollFactor.set();
		dialogueBox.finishThing = startCountdown;
		dialogueBox.cameras = [camHUD];
		add(dialogueBox);

		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();

		if (SONG.song.toLowerCase() == 'roses' || SONG.song.toLowerCase() == 'thorns')
		{
			remove(black);

			if (SONG.song.toLowerCase() == 'thorns')
			{
				add(red);
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					inCutscene = true;

					if (SONG.song.toLowerCase() == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	var startTimer:FlxTimer;
	var perfectMode:Bool = false;

	function startCountdown():Void
	{
		inCutscene = false;

		generateStaticArrows(0);
		generateStaticArrows(1);

		if(FlxG.save.data.MiddleScroll)
		{
			strumLineNotes.forEach((a)->{
				a.visible = false;
			});
			playerStrums.forEach((a)->{
				a.screenCenter(X);
				a.x -= Note.swagWidth * ((playerStrums.length - 1) / 2 - a.data);
			});
		}

		talking = false;
		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;
		noteTiming = -Conductor.crochet * 5;

		var swagCounter:Int = 0;
		var timerTime = (Conductor.crochet / 1000) / songAudioSpeed;

		startTimer = new FlxTimer().start(timerTime, function(tmr:FlxTimer)
		{
			dad.dance();
			gf.dance();
			boyfriend.playAnim('idle');

			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('default', ['ready', "set", "go"]);
			introAssets.set('school', ['weeb/pixelUI/ready-pixel', 'weeb/pixelUI/set-pixel', 'weeb/pixelUI/date-pixel']);
			introAssets.set('schoolEvil', ['weeb/pixelUI/ready-pixel', 'weeb/pixelUI/set-pixel', 'weeb/pixelUI/date-pixel']);

			var introAlts:Array<String> = introAssets.get('default');
			var altSuffix:String = "";

			for (value in introAssets.keys())
			{
				if (value == curStage)
				{
					introAlts = introAssets.get(value);
					altSuffix = '-pixel';
				}
			}

			switch (swagCounter)

			{
				case 0:
					FlxG.sound.play(Paths.sound('intro3'), 0.6);
				case 1:
					canPause = true;
					var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
					ready.scrollFactor.set();
					ready.updateHitbox();

					if (isPixelStage)
						ready.setGraphicSize(Std.int(ready.width * daPixelZoom));

					ready.screenCenter();
					add(ready);
					FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, timerTime, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							ready.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro2'), 0.6);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
					set.scrollFactor.set();

					if (isPixelStage)
						set.setGraphicSize(Std.int(set.width * daPixelZoom));

					set.screenCenter();
					add(set);
					FlxTween.tween(set, {y: set.y += 100, alpha: 0}, timerTime, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							set.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro1'), 0.6);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
					go.scrollFactor.set();

					if (isPixelStage)
						go.setGraphicSize(Std.int(go.width * daPixelZoom));

					go.updateHitbox();

					go.screenCenter();
					add(go);
					FlxTween.tween(go, {y: go.y += 100, alpha: 0}, timerTime, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							go.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('introGo'), 0.6);
				case 4:
			}

			swagCounter += 1;
			// generateSong('fresh');
		}, 5);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	public static var noteTiming:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.music.onComplete = endSong;
		FlxG.sound.music.play();
		vocals.play();

		#if desktop
		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength);
		#end
	}

	var debugNum:Int = 0;
	public var songAudioSpeed:Float = 1;

	private function generateSong(dataPath:String):Void
	{
		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;
		if(!PlayState.modSong)
			FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song, FlxG.save.data.pitch), 1, false);
		else 
			FlxG.sound.playMusic(Paths.ModSong_Inst(PlayState.SONG.song, FlxG.save.data.pitch), 1, false);
		FlxG.sound.music.stop();

		vocals = new FlxSound();
		if (SONG.needsVoices)
		{
			if(PlayState.modSong)
				vocals.loadEmbedded(Paths.ModSong_Voices(PlayState.SONG.song, FlxG.save.data.pitch));
			else 
				vocals.loadEmbedded(Paths.voices(PlayState.SONG.song, FlxG.save.data.pitch));
		}
		#if lime
			songAudioSpeed = FlxG.save.data.pitch;
		#end

		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		final noteData:Array<SwagSection> = songData.notes;
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				final daStrumTime:Float = songNotes[0];
				final daNoteData:Int = Std.int(songNotes[1] % 4);
				final gottaHitNote:Bool = (songNotes[1] > 3 ? !section.mustHitSection : section.mustHitSection);
				var oldNote:Note = null;
				
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.sustainLength = songNotes[2];
				swagNote.useDownscroll = FlxG.save.data.downscroll;
				swagNote.mustPress = gottaHitNote;
					
				unspawnNotes.push(swagNote);
				for(i in Note.generateTrailOfNote(swagNote))
					unspawnNotes.push(i);
			}
		}
		unspawnNotes.sort(sortByShit);
		generatedMusic = true;
	}

	public static function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			var babyArrow:StaticArrow = new StaticArrow(50 + ((FlxG.width / 2) * player) + Note.swagWidth * i, strumLine.y, i, player);

			if (!isStoryMode)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}

			if (player == 1)
				playerStrums.add(babyArrow);
			else 
				strumLineNotes.add(babyArrow);
		}
	}

	function tweenCamIn():Void
	{
		FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000) * songAudioSpeed, {ease: FlxEase.elasticInOut});
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished)
				startTimer.active = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (!startTimer.finished)
				startTimer.active = true;
			paused = false;

			#if desktop
			if (startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength - Conductor.songPosition);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength - Conductor.songPosition);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			}
		}
		#end

		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		FlxG.sound.music.play();
		vocals.play();
		noteTiming = FlxG.sound.music.time * songAudioSpeed;
		vocals.time = noteTiming / songAudioSpeed;
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = false;
	override public function update(elapsed:Float)
	{
		#if !debug
		perfectMode = false;
		#end
		if (FlxG.keys.justPressed.NINE)
		{
			if (iconP1.animation.curAnim.name == 'bf-old')
				iconP1.animation.play(SONG.player1);
			else
				iconP1.animation.play('bf-old');
		}

		switch (curStage)
		{
			case 'philly':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}
				// phillyCityLights.members[curLight].alpha -= (Conductor.crochet / 1000) * FlxG.elapsed;
		}

		if(!FlxG.save.data.ShowExtendedScores)
			scoreTxt.text = "Score:" + songScore;
		else 
		{
			scoreTxt.screenCenter(X);
			scoreTxt.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			scoreTxt.text = Closet.makeStatus(this) + " - SosEngine";
			if(FlxG.save.data.UILayout == "simple")
				scoreTxt.text = Closet.makeSimpleStatus(this) + " \\ SosEngine";
			else
				scoreTxt.text = Closet.makeStatus(this) + " - SosEngine";
		}

		if(FlxG.save.data.botplay)
		{
			scoreTxt.text = "SosEngine - Botplay";
			scoreTxt.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			scoreTxt.screenCenter(X);
		}

		if(FlxG.save.data.showTime)
		{
			if(FlxG.save.data.TimeType == "time-left")
			{
				var a = (FlxG.sound.music.length - FlxG.sound.music.time);
				time_time = (a < 0 ? 0 : a);
			}
			else if(FlxG.save.data.TimeType == "time-elapsed")
				time_time = FlxG.sound.music.time;

			timeTxt.text = (FlxG.save.data.TimeType == "time-left" ? "Time Left: " : "Time Elapsed: ") + Closet.milToString(time_time);

			if(timeBG.width != timeTxt.width + 10 || timeBG.height != timeTxt.height + 10)
				timeBG.makeGraphic(Std.int(timeTxt.width + 10), Std.int(timeTxt.height + 10));
			if(FlxG.save.data.UILayout == "simple")
			{
				timeTxt.screenCenter(X);
				if(FlxG.save.data.downscroll)
					timeTxt.y = FlxG.height - timeTxt.height - 10;
				else 
					timeTxt.y = 10;
			}
			else
				timeTxt.setPosition(healthBar.x + healthBar.width + 160 - timeTxt.width / 2, healthBar.y + healthBar.height / 2 - timeTxt.height / 2);
			timeBG.setPosition(timeTxt.x - 5, timeTxt.y - 5);
		}

		if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;
			FlxG.sound.music.pause();
			vocals.pause();

			openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		
			#if desktop
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			#end
		}

		if (FlxG.keys.justPressed.SEVEN)
		{
			FlxG.switchState(new ChartingState());

			#if desktop
			DiscordClient.changePresence("Chart Editor", null, null, true);
			#end
		}
		if (health > 2)
			health = 2;

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		if (FlxG.keys.justPressed.EIGHT)
			FlxG.switchState(new AnimationDebug(dad.curCharacter));

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000 * songAudioSpeed;
				noteTiming += FlxG.elapsed * 1000 * songAudioSpeed;
				if (Conductor.songPosition >= 0)
				{
					startSong();
					if(FlxG.save.data.showTime)
						startTime();
				}
				
			}
		}
		else
		{
			// Conductor.songPosition = FlxG.sound.music.time;
			Conductor.songPosition = FlxG.sound.music.time * songAudioSpeed;
			noteTiming += FlxG.elapsed * 1000 * songAudioSpeed;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != noteTiming)
				{
					songTime = (songTime + noteTiming) / 2;
					Conductor.lastSongPos = noteTiming;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		final prev = [camFollow.x, camFollow.y];

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null)
		{
			if (curBeat % 4 == 0)
			{
				// trace(PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection);
			}
			if (!PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
			{
				var dadPos = new FlxPoint(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
				switch (dad.curCharacter)
				{
					case 'mom':
						dadPos.y = dad.getMidpoint().y;
					case 'senpai':
						dadPos.y = dad.getMidpoint().y - 430;
						dadPos.x = dad.getMidpoint().x - 100;
					case 'senpai-angry':
						dadPos.y = dad.getMidpoint().y - 430;
						dadPos.x = dad.getMidpoint().x - 100;
				}
				dadPos.x += dad.camOffset[0];
				dadPos.y += dad.camOffset[1];

				if(camFollow.x != dadPos.x || camFollow.y != dadPos.y)
				{
					camFollow.setPosition(dadPos.x, dadPos.y);
					if (dad.curCharacter == 'mom')
						vocals.volume = 1;
	
					if (SONG.song.toLowerCase() == 'tutorial')
					{
						tweenCamIn();
					}
				}
			}

			if (PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
			{
				var bfPos = new FlxPoint(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
				switch (curStage)
				{
					case 'limo':
						bfPos.x = boyfriend.getMidpoint().x - 300;
					case 'mall':
						bfPos.y = boyfriend.getMidpoint().y - 200;
					case 'school':
						bfPos.x = boyfriend.getMidpoint().x - 200;
						bfPos.y = boyfriend.getMidpoint().y - 200;
					case 'schoolEvil':
						bfPos.x = boyfriend.getMidpoint().x - 200;
						bfPos.y = boyfriend.getMidpoint().y - 200;
				}

				bfPos.x += boyfriend.camOffset[0];
				bfPos.y += boyfriend.camOffset[1];

				if(camFollow.x != bfPos.x || camFollow.y != bfPos.y)
				{
					camFollow.setPosition(bfPos.x, bfPos.y);

					if (SONG.song.toLowerCase() == 'tutorial')
					{
						FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000) * songAudioSpeed, {ease: FlxEase.elasticInOut});
					}
				}
			}
		}

		if(prev[0] != camFollow.x || prev[1] != camFollow.y)
		{
			mids = [
				(camFollow.x - prev[0]) / 2 - FlxG.camera.width / 2,
				(camFollow.y - prev[1]) / 2 - FlxG.camera.height / 2
			];
			goingMid = [true, true];
		}
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		if (curSong == 'Fresh')
		{
			switch (curBeat)
			{
				case 16:
					camZooming = true;
					gfSpeed = 2;
				case 48:
					gfSpeed = 1;
				case 80:
					gfSpeed = 2;
				case 112:
					gfSpeed = 1;
				case 163:
					// FlxG.sound.music.stop();
					// FlxG.switchState(new TitleState());
			}
		}

		if (curSong == 'Bopeebo')
		{
			switch (curBeat)
			{
				case 128, 129, 130:
					vocals.volume = 0;
					// FlxG.sound.music.stop();
					// FlxG.switchState(new PlayState());
			}
		}
		// better streaming of shit

		// RESET = Quick Game Over Screen
		if (controls.RESET && FlxG.save.data.resetKey)
		{
			health = 0;
			trace("RESET = True");
		}

		// CHEAT = brandon's a pussy
		if (controls.CHEAT)
		{
			health += 1;
			trace("User is cheating!");
		}

		if (health <= 0)
		{
			boyfriend.stunned = true;

			persistentUpdate = false;
			persistentDraw = false;
			paused = true;

			vocals.stop();
			FlxG.sound.music.stop();

			openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

			// FlxG.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
			
			#if desktop
			// Game Over doesn't get his own variable because it's only used here
			DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			#end
		}

		if (unspawnNotes[0] != null)
		{
			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - noteTiming < 1650 / SONG.speed)
			{
				final note = unspawnNotes[0];
				notes.insert(0, note);

				final forHits:Bool = true;
				if(!forHits || (forHits && note.mustPress))
				{
					if(note.isSustainNote)
						trailNotes.insert(0,note);
					else 
						normalNotes.insert(0,note);
				}
				unspawnNotes.splice(0, 1);
			}
		}

		if (generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				final rArrow = (daNote.mustPress ? playerStrums.members[daNote.noteData] : strumLineNotes.members[daNote.noteData]);
				final speed = FlxMath.roundDecimal(SONG.speed, 2);
				//daNote.y = (rArrow.y - 0.45 * ((Conductor.songPosition - daNote.strumTime) / songMultiplier) * (FlxMath.roundDecimal(SONG.speed,2)));

				if(!daNote.useDownscroll)
					daNote.y = (rArrow.y - 0.45 * (noteTiming - daNote.strumTime) * speed);
				else 
					daNote.y = (rArrow.y + 0.45 * (noteTiming - daNote.strumTime) * speed);
				daNote.x = rArrow.x + rArrow.offsetRect.width / 2 - daNote.width / 2;

				if(daNote.isSustainNote)
				{
					if(daNote.useDownscroll)
					{
						var step = (0.45 * speed * daNote.startBPMcroch * songAudioSpeed);
						daNote.y -= (daNote.height - step);
					}
					if (((daNote.wasGoodHit || keys.getUpdate(daNote.noteData, controls) || FlxG.save.data.botplay) && daNote.mustPress) || !daNote.mustPress)
					{
						if(!daNote.useDownscroll)
						{
							if(daNote.y <= rArrow.y + rArrow.offsetRect.height / 2)
							{
								var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.height / daNote.scale.y);
								swagRect.y = (rArrow.y + rArrow.offsetRect.height / 2 - daNote.y) / daNote.scale.y;
								swagRect.height -= swagRect.y;
								daNote.clipRect = swagRect;
							}
						}
						else if(daNote.useDownscroll)
						{
							if(daNote.y + daNote.height >= rArrow.y + rArrow.offsetRect.height / 2)
							{
								var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.height);
								swagRect.height = (rArrow.y + rArrow.offsetRect.height / 2 - daNote.y) / daNote.scale.y;
								swagRect.y = daNote.frameHeight - swagRect.height;
								daNote.clipRect = swagRect;
							}
						}
					}
				}
			
				daNote.visible = !(FlxG.save.data.MiddleScroll && !daNote.mustPress);

				if (!daNote.mustPress && !daNote.wasGoodHit && daNote.strumTime <= noteTiming)
				{
					if (SONG.song != 'Tutorial')
						camZooming = true;

					var altAnim:String = "";
					daNote.wasGoodHit = true;

					if (SONG.notes[Math.floor(curStep / 16)] != null)
					{
						if (SONG.notes[Math.floor(curStep / 16)].altAnim)
							altAnim = '-alt';
					}

					if(!daNote.isSustainNote || (daNote.isSustainNote && daNote.susCount % Note.trail_quality(daNote) == 0))
					{
						switch (Math.abs(daNote.noteData))
						{
							case 0:
								dad.playAnim('singLEFT' + altAnim, true);
							case 1:
								dad.playAnim('singDOWN' + altAnim, true);
							case 2:
								dad.playAnim('singUP' + altAnim, true);
							case 3:
								dad.playAnim('singRIGHT' + altAnim, true);
						}
						if (SONG.needsVoices)
							vocals.volume = 1;
						dad.holdTimer = 0;
						opponentHitNote(daNote);

						if(FlxG.save.data.lightstrums == "animated")
							lightEnemyStrum(daNote.noteData);
					}

					if(!daNote.isSustainNote)
						exterminateNote(daNote);
				}

				if ((daNote.y < -daNote.height && !daNote.useDownscroll) || (daNote.y > FlxG.height + daNote.height && daNote.useDownscroll))
				{
					if (!daNote.wasGoodHit && !daNote.canBeHit && daNote.mustPress && (!daNote.isSustainNote || (daNote.isSustainNote && daNote.susCount % Note.trail_quality(daNote) == 0)))
					{
						if(!daNote.isBadNote)
						{
							if(!daNote.isSustainNote)
								health -= 0.0475;
							else 
								health -= 0.0475;
							vocals.volume = 0;
							playBfAnimation(daNote.noteData, true);
							exterminateNote(daNote);
	
							misses++;
							noteHits += Conductor.safeZoneOffset;
							maxScore += 350;
							songScore -= 10;
							combo = 0;
						}
						daNote.onMiss();
					}
					else if(!daNote.mustPress || (daNote.mustPress && daNote.isSustainNote && !(daNote.susCount % Note.trail_quality(daNote) == 0)))
						exterminateNote(daNote);
				}
			});
		}

		if (!inCutscene)
			(!FlxG.save.data.botplay ? keyShit : botplayInput)();
		#if debug
		if (FlxG.keys.justPressed.ONE)
			endSong();
		#end
		updateIconPositions();
		lerpingFunctions(elapsed);
		super.update(elapsed);
	}

	function lerpingFunctions(e)
	{
		//iconP1.setGraphicSize(Std.int(Closet.sharpLerp(150, iconP1.width, iconBopLerp)));
		//iconP2.setGraphicSize(Std.int(Closet.sharpLerp(150, iconP2.width, iconBopLerp)));

		FlxG.camera.zoom = Closet.sharpLerp(defaultCamZoom, FlxG.camera.zoom, cameraZoomLerp, e);
		camHUD.zoom = Closet.sharpLerp(1, camHUD.zoom, cameraZoomLerp, e);

		final trg = [camPoint.x + camFollow.width / 2 - FlxG.camera.width / 2, camPoint.y + camFollow.height / 2 - FlxG.camera.height / 2];
		if(FlxG.save.data.smoothCam)
		{
			camPoint.x = Closet.sharpLerp(camFollow.x, camPoint.x, cameraFollowLerp, e);
			camPoint.y = Closet.sharpLerp(camFollow.y, camPoint.y, cameraFollowLerp, e);
		}
		else 
			camPoint.set(camFollow.x, camFollow.y);
		FlxG.camera.scroll.set(
			Closet.sharpLerp(trg[0], FlxG.camera.scroll.x, cameraFollowLerp, e),
			Closet.sharpLerp(trg[1], FlxG.camera.scroll.y, cameraFollowLerp, e)
		);
	}

	function endSong():Void
	{
		canPause = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		if (SONG.validScore)
		{
			#if !switch
			Highscore.saveScore(SONG.song, songScore, storyDifficulty);
			#end
		}

		if (isStoryMode)
		{
			campaignScore += songScore;

			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0)
			{
				FlxG.sound.playMusic(Paths.music('freakyMenu'));

				//transIn = FlxTransitionableState.defaultTransIn;
				//transOut = FlxTransitionableState.defaultTransOut;

				FlxG.switchState(new StoryMenuState());

				// if ()
				StoryMenuState.weekUnlocked[Std.int(Math.min(storyWeek + 1, StoryMenuState.weekUnlocked.length - 1))] = true;

				if (SONG.validScore)
				{
					NGio.unlockMedal(60961);
					Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty);
				}

				FlxG.save.data.weekUnlocked = StoryMenuState.weekUnlocked;
				FlxG.save.flush();
			}
			else
			{
				var difficulty:String = "";

				if (storyDifficulty == 0)
					difficulty = '-easy';

				if (storyDifficulty == 2)
					difficulty = '-hard';

				trace('LOADING NEXT SONG');
				trace(PlayState.storyPlaylist[0].toLowerCase() + difficulty);

				if (SONG.song.toLowerCase() == 'eggnog')
				{
					var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
						-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
					blackShit.scrollFactor.set();
					add(blackShit);
					camHUD.visible = false;

					FlxG.sound.play(Paths.sound('Lights_Shut_off'));
				}

				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				prevCamFollow = camFollow;

				if(!PlayState.modSong)
					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + difficulty, PlayState.storyPlaylist[0]);
				else 
					PlayState.SONG = Paths.ModSong_data(PlayState.storyPlaylist[0].toLowerCase(), difficulty);
				FlxG.sound.music.stop();

				LoadingState.loadAndSwitchState(new PlayState());
			}
		}
		else
		{
			trace('WENT BACK TO FREEPLAY??');
			FlxG.switchState(new FreeplayState());
		}
	}

	var endingSong:Bool = false;

	private function popUpScore(note:Note):Void
	{
		final noteDiff:Float = Math.abs(note.strumTime - noteTiming);
		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.55;

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		var daRating:String = "sick";

		if (noteDiff > Conductor.safeZoneOffset * 0.9)
		{
			daRating = 'shit';
			score = 50;
			shits++;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.75)
		{
			daRating = 'bad';
			score = 100;
			bads++;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.2)
		{
			daRating = 'good';
			score = 200;
			goods++;
		}
		if(daRating == "sick")
			sicks++;

		songScore += score;
		maxScore += 350;
		
		//complex accuracy thingey
		ratio += Conductor.safeZoneOffset - noteDiff;
		noteHits += Conductor.safeZoneOffset;

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (isPixelStage)
		{
			pixelShitPart1 = 'weeb/pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating + pixelShitPart2));
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;
		comboSpr.velocity.x += FlxG.random.int(1, 10);
		add(rating);

		if (!isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = true;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = true;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.7));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.7));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		seperatedScore.push(Math.floor(combo / 100));
		seperatedScore.push(Math.floor((combo - (seperatedScore[0] * 100)) / 10));
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			if (!isPixelStage)
			{
				numScore.antialiasing = true;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);

			if (combo >= 10 || combo == 0)
				add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / songAudioSpeed
			});

			daLoop++;
		}
		coolText.text = Std.string(seperatedScore);

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onUpdate: (xd)->{rating.alpha = comboSpr.alpha;},
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001/ songAudioSpeed
		});
	}

	public function lightPlayerStrum(note:Int)
	{
		playerStrums.forEach(function(spr:StaticArrow)
		{
			if (note == spr.data)
			{
				spr.playAnim("confirm", true);
			}
		});
	}

	public function lightEnemyStrum(note:Int)
	{
		strumLineNotes.forEach(function(spr:StaticArrow)
		{
			if (note == spr.data)
			{
				spr.playAnim("confirm", true);
			}
		});
	}

	public function playBfAnimation(note:Int, miss:Bool)
	{
		var animID = "";
		switch (note)
		{
			case 0:
				animID = ('singLEFT');
			case 1:
				animID = ('singDOWN');
			case 2:
				animID = ('singUP');
			case 3:
				animID = ('singRIGHT');
		}
		if(miss) animID += "miss";
		boyfriend.playAnim(animID, true);
	}

	private function keyShit():Void
	{
		var heldNote:Bool = false;
		if(keys.hasAny(controls))
		{
			boyfriend.holdTimer = 0;
			trailNotes.forEachAlive(function(f:Dynamic)
			{
				final daNote:Note = f;
				if (daNote.mustPress && daNote.canBeHit && !daNote.wasGoodHit)
				{
					if(daNote.strumTime <= noteTiming && keys.getUpdate(daNote.noteData, controls))
					{
						sustainNoteHit(daNote);
						heldNote = true;
					}
				}
			});
		}

		if (keyPresses.hasAny(controls) && !boyfriend.stunned && generatedMusic)
		{
			final notez:Array<Array<Note>> = [[], [], [], []];
			final inter:Array<Int> = [];
			final unChecked:Array<Int> = [0,1,2,3];

			normalNotes.forEachAlive(function(f:Dynamic)
			{
				final daNote:Note = f;
				if (daNote.mustPress && daNote.canBeHit && !daNote.wasGoodHit)
				{
					if(keyPresses.getUpdate(daNote.noteData, controls))
					{
						notez[daNote.noteData].push(daNote);
						if(inter.contains(daNote.noteData) == false)
							inter.push(daNote.noteData);
					}
				}
			});
			for(i in notez)
				i.sort((a, b)->Std.int(a.strumTime - b.strumTime));

			for (x in inter)
			{
				final group:Array<Note> = notez[x];
				final note = group.shift();
				if(group.length > 0)
					for(i in group)
					{
						if(Math.abs(i.strumTime - note.strumTime) < 2)
							exterminateNote(i);
					}
				standardNoteHit(note);
				unChecked.remove(x);
			}

			if(unChecked.length > 0)
			{
				for(a in unChecked)
				{
					if(keyPresses.getUpdate(a, controls))
					{
						if(!heldNote)
						{
							noteMiss(a);
						}
					}
				}
			}
		}

		bfIdleCheck();

		playerStrums.forEach(function(spr:StaticArrow)
		{
			if(keyReleases.getUpdate(spr.data, controls) || !keys.getUpdate(spr.data, controls))
				spr.playAnim('static');
			if(keyPresses.getUpdate(spr.data, controls) && keys.getUpdate(spr.data, controls) && spr.animation.curAnim.name != 'confirm')
				spr.playAnim('pressed');		
		});
	}

	private function botplayInput()
	{
		if(!FlxG.save.data.botplay)
			return;

		notes.forEachAlive(
			function (daNote)
			{
				if(daNote.mustPress && daNote.strumTime <= noteTiming && !daNote.wasGoodHit && !daNote.isBadNote)
				{
					boyfriend.holdTimer = 0;
					var tmr = new FlxTimer().start(Conductor.stepCrochet * 0.001, (s)->{boyfriend.holdTimer = 0;}, 2);
					if(daNote.isSustainNote)	
						sustainNoteHit(daNote);
					else 
						standardNoteHit(daNote);
				}
			}
		);
		SONG.validScore = false;
		bfIdleCheck();
	}

	function bfIdleCheck()
	{
		if (boyfriend.holdTimer > (Conductor.stepCrochet * boyfriend.singDuration * 0.001) / songAudioSpeed && (FlxG.save.data.botplay ? true : !keys.hasAny(controls)))
		{
			if (boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.playAnim('idle');
			}
		}
	}

	function noteMiss(direction:Int = 1):Void
	{
		if(FlxG.save.data.GhostTapping || boyfriend.stunned)
			return;

		health -= 0.04;
		misses++;
		noteHits += Conductor.safeZoneOffset * 0.42;

		if (combo > 5 && gf.animOffsets.exists('sad'))
			gf.playAnim('sad');
		combo = 0;

		songScore -= 10;
		maxScore += 150;

		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), 0.1);
		boyfriend.stunned = true;
		new FlxTimer().start(5 / 60, function(tmr:FlxTimer)
		{
			boyfriend.stunned = false;
		});

		playBfAnimation(direction, true);
	}

	function standardNoteHit(note:Note)
	{
		if (note.noteData >= 0)
			health += 0.023;
		else
			health += 0.004;

		note.onPress(Math.abs(note.strumTime - noteTiming));
		lightPlayerStrum(note.noteData);
		playBfAnimation(note.noteData, false);

		popUpScore(note);
		combo += 1;

		note.wasGoodHit = true;
		vocals.volume = 1;
		
		exterminateNote(note);
	}

	function sustainNoteHit(note:Note)
	{
		note.wasGoodHit = true;
		var isValid = note.susCount % Note.trail_quality(note) == 0;
		if(isValid)
		{
			note.onPress(Math.abs(note.strumTime - noteTiming));
			lightPlayerStrum(note.noteData);
			playBfAnimation(note.noteData, false);
			vocals.volume = 1;
			boyfriend.holdTimer = 0;
		}
		health += 0.011 / Note.trail_quality(note);
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	function fastCarDrive()
	{
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
		});
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			gf.playAnim('hairBlow');
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		gf.playAnim('hairFall');
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		halloweenBG.animation.play('lightning');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		boyfriend.playAnim('scared', true);
		gf.playAnim('scared', true);
	}

	override function stepHit()
	{
		super.stepHit();

		if (Math.abs(Conductor.songPosition - noteTiming) > 30)
			resyncVocals();
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	override function beatHit()
	{
		super.beatHit();

		if (generatedMusic)
		{
			//notes.sort(FlxSort.byY, (!FlxG.save.data.downscroll ? FlxSort.DESCENDING : FlxSort.ASCENDING));
			if(!FlxG.save.data.downscroll)
				notes.sort(FlxSort.byY, FlxSort.DESCENDING);
			else notes.sort((i,a,b) -> sortByShit(b,a));
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				FlxG.log.add('CHANGED BPM!');
			}
		}
		wiggleShit.update(Conductor.crochet * songAudioSpeed);

		if (curSong.toLowerCase() == 'milf' && curBeat >= 168 && curBeat < 200 && camZooming && FlxG.camera.zoom < 1.35)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		if (camZooming && FlxG.camera.zoom < 1.35 && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}
		
		iconP1.setGraphicSize(Std.int(iconP1.width + (FlxG.save.data.botplay ? 10 : 30)));
		iconP2.setGraphicSize(Std.int(iconP2.width + 30));

		iconP1.updateHitbox();
		iconP2.updateHitbox();
		updateIconPositions();

		if (curBeat % gfSpeed == 0)
		{
			gf.dance();
		}

		if(!boyfriend.animation.curAnim.name.startsWith("sing") && boyfriend.animation.curAnim.name != ("idle"))
		{
			if(!boyfriend.animation.curAnim.looped)
			{
				if(boyfriend.animation.curAnim.finished)	
					boyfriend.dance();
			}
			else 
			{
				if(boyfriend.animation.curAnim.curFrame + 1 > boyfriend.animation.curAnim.numFrames)
					boyfriend.dance();
			}
		}

		if(curBeat % 2 == 0)
		{
			if (boyfriend.animation.curAnim.name == "idle")
				boyfriend.dance();
		}

		if(dad.curCharacter == "spooky" || dad.curCharacter.startsWith("gf"))
		{
			if (!dad.animation.curAnim.name.startsWith("sing"))
				dad.dance();
		}
		else 
		{
			if(!dad.animation.curAnim.name.startsWith("sing") && dad.animation.curAnim.name != ("idle"))
			{
				if(!dad.animation.curAnim.looped)
				{
					if(dad.animation.curAnim.finished)	
						dad.dance();
				}
				else 
				{
					if(dad.animation.curAnim.curFrame + 1 > dad.animation.curAnim.numFrames)
						dad.dance();
				}
			}
			if(curBeat % 2 == 0)
			{
				if (dad.animation.curAnim.name == "idle")
					dad.dance();
			}
		}

		if (curBeat % 8 == 7 && curSong == 'Bopeebo')
		{
			boyfriend.playAnim('hey', true);
		}

		if (curBeat % 16 == 15 && SONG.song == 'Tutorial' && dad.curCharacter == 'gf' && curBeat > 16 && curBeat < 48)
		{
			boyfriend.playAnim('hey', true);
			dad.playAnim('cheer', true);
		}

		switch (curStage)
		{
			case 'school':
				bgGirls.dance();

			case 'mall':
				upperBoppers.animation.play('bop', true);
				bottomBoppers.animation.play('bop', true);
				santa.animation.play('idle', true);

			case 'limo':
				grpLimoDancers.forEach(function(dancer:BackgroundDancer)
				{
					dancer.dance();
				});

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
			case "philly":
				if (!trainMoving)
					trainCooldown += 1;

				if (curBeat % 4 == 0)
				{
					phillyCityLights.forEach(function(light:FlxSprite)
					{
						light.visible = false;
					});

					curLight = FlxG.random.int(0, phillyCityLights.length - 1);

					phillyCityLights.members[curLight].visible = true;
					// phillyCityLights.members[curLight].alpha = 1;
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
		}

		if (isHalloween && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShit();
		}
	}

	var curLight:Int = 0;
	public function startTime() 
	{
		FlxTween.tween(timeBG, {alpha: 0.6}, 1);
		FlxTween.tween(timeTxt, {alpha: 1}, 1);
	}
	public var cameraZoomLerp:Float = 0.93;
	public var cameraFollowLerp:Float = 0.97;
	public var iconBopLerp:Float = 0.8;

	private var mids:Array<Float> = [0,0];
	private var goingMid:Array<Bool> = [false, false];

	override function fixedUpdate()
	{
		
		iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, iconBopLerp)));
		iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, iconBopLerp)));
		/*
		FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, cameraZoomLerp);
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, cameraZoomLerp);
		if(FlxG.save.data.smoothCam)
		{
			//camPoint.x = FlxMath.lerp(camFollow.x, camPoint.x, cameraZoomLerp);
			//camPoint.y = FlxMath.lerp(camFollow.y, camPoint.y, cameraZoomLerp);
		}
		else 
		{
			camPoint.x = camFollow.x;
			camPoint.y = camFollow.y;
		}

		final trg = [camPoint.x + camFollow.width / 2 - FlxG.camera.width / 2, camPoint.y + camFollow.height / 2 - FlxG.camera.height / 2];
		FlxG.camera.scroll.set(
			FlxMath.lerp(trg[0], FlxG.camera.scroll.x, cameraFollowLerp),
			FlxMath.lerp(trg[1], FlxG.camera.scroll.y, cameraFollowLerp)
		);
		*/
		super.fixedUpdate();
	}

	public function exterminateNote(daNote:Note)
	{
		daNote.active = false;
		daNote.visible = false;

		if(daNote.isSustainNote)
			trailNotes.remove(daNote, true);
		else 
			normalNotes.remove(daNote, true);
		daNote.kill();
		notes.remove(daNote, true);
		daNote.destroy();
	}

	public function updateIconPositions()
	{
		var iconOffset:Int = 26;
		
		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if(iconP1.width > 180)
		{
			iconP1.width = 180;
			iconP1.updateHitbox();
		}
		if(iconP2.width > 180)
		{
			iconP2.width = 180;
			iconP2.updateHitbox();
		}	

		var bar = healthBar;
		iconP1.x = bar.x + (bar.width * (FlxMath.remapToRange(bar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = bar.x + (bar.width * (FlxMath.remapToRange(bar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);
	}

	public function switchGf(newID:String)
	{
		var ox = new FlxPoint(gf.x, gf.y);
		characterLayer.remove(gf);
		
		if(cachedCharacters.exists(newID) && cachedCharacters.get(newID) is Character)
		{
			gf = cachedCharacters.get(newID);
			gf.setPosition(ox.x, ox.y);
		}
		else
			gf = new Character(ox.x, ox.y, newID, gf.isPlayer);
		characterLayer.add(gf);
	}

	public function switchDad(newID:String)
	{
		var ox = new FlxPoint(dad.x, dad.y);
		characterLayer.remove(dad);
		
		if(cachedCharacters.exists(newID) && cachedCharacters.get(newID) is Character)
		{
			dad = cachedCharacters.get(newID);
			dad.setPosition(ox.x, ox.y);
		}
		else
			dad = new Character(ox.x, ox.y, newID, dad.isPlayer);
		characterLayer.add(dad);
	}

	public function switchBf(newID:String)
	{
		var ox = new FlxPoint(boyfriend.x, boyfriend.y);
		characterLayer.remove(boyfriend);

		if(cachedCharacters.exists(newID) && cachedCharacters.get(newID) is Boyfriend)
		{
			boyfriend = cachedCharacters.get(newID);
			boyfriend.setPosition(ox.x, ox.y);
		}
		else
			boyfriend = new Boyfriend(ox.x, ox.y, newID);
		characterLayer.add(boyfriend);
	}

	/*
	private static var cachedCharacters:Map<String, OneOfTwo<Character, Boyfriend>> = [];
	private static var CacheOrder:Array<String> = [];
	private var cacheLimit:Int = 10;

	public function cacheCharacter(name:String, char:Character) 
	{
		if(cachedCharacters.exists(name))
			return;

		CacheOrder.push(name);
		cachedCharacters.set(name, char);

		if(CacheOrder.length - 1 >= cacheLimit)
		{
			var names:Array<String> = [];
			for(i in Math.floor(CacheOrder.length - 1 - cacheLimit)...CacheOrder.length)
				names.push(CacheOrder[i]);
			for(i in names)
			{
				cachedCharacters.remove(i);
				CacheOrder.remove(i);
			}
			names = [];
			//TODO still workin on it
		}
	}
	*/

	private var cachedCharacters:Map<String, OneOfTwo<Character, Boyfriend>> = [];

	public function cacheCharacter(name:String, char:Character) 
	{
		cachedCharacters.set(name, char);
	}
}
