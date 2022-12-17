package;

import CallBackMaster.SmoothCam;
import CallBackMaster.UILayout;
import CallBackMaster.UseVCR;
import CallBackMaster.ShowMemory;
import CallBackMaster.ShowFPS;
import CallBackMaster.Cache;
import CallBackMaster.ColorEffect;
import CallBackMaster.ResetKey;
import CallBackMaster.Botplay;
import CallBackMaster.Pitch;
import CallBackMaster.TimeType;
import CallBackMaster.ShowTime;
import CallBackMaster.HealthBarColors;
import CallBackMaster.AccuracyType;
import CallBackMaster.EnemyStrums;
import CallBackMaster.GhostTapping;
import CallBackMaster.ActionOption;
import CallBackMaster.OptionActionState;
import CallBackMaster.MiddleScroll;
import CallBackMaster.ShowExtendedScores;
import CallBackMaster.StartFullscreen;
import flixel.text.FlxText;
import flixel.math.FlxRect;
import CallBackMaster.FPS_cap;
import flixel.math.FlxPoint;
import CallBackMaster.Downscroll;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxCamera;
import CallBackMaster.Option;
import flixel.tweens.FlxEase;
import flixel.tweens.misc.ColorTween;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;

typedef OptionGroup =
{
    var options:Array<Option>;
    var tabName:String;
    var color:FlxColor;
    var decr:String;
} 

class OptionState extends MusicBeatState
{ 
    var bg:FlxSprite;
    var contextBg:FlxSprite;
    var context:FlxText;
    var prevCategory:Int = 0;

    var optionGroups:Array<OptionGroup> = [
        {
            tabName: "gameplay options",
            color: FlxColor.CYAN,
            decr: "Gameplay Options",
            options: [
                new Downscroll("Downscroll", FlxG.save.data.downscroll, "Enable to play with Downscroll!", "on", "off"),
                new MiddleScroll("Middlescroll",  FlxG.save.data.MiddleScroll, "Enable to Screen Center your arrows! \n (applies to both Downscroll and Upscroll)\n", "on", "off"),
                new GhostTapping("Ghost Tapping", FlxG.save.data.GhostTapping, "If enabled, there is no penalty for misspresses","on", "off"),
                new Botplay("BotPlay", FlxG.save.data.botplay, "Enable to make a bot do all Your work", "on", "off"),
                new Pitch("song play speed", FlxG.save.data.pitch, "Changes the speed of the song \n(the Audio not the Scroll-Speed)\n", ["0.1", "0.2", "0.3", "0.4", "0.5", "0.6", "0.7", "0.8", "0.9", "1", "1.1", "1.2", "1.3", "1.4", "1.5", "1.6", "1.7", "1.8", "1.9", "2"]),
                new HealthBarColors("HealthBar colors", FlxG.save.data.healthBarColors, "Use Custom Healthbar colors", "on", "off"),
                new ShowExtendedScores("Show Extended Score", FlxG.save.data.ShowExtendedScores, "Enable to show the Accuracy, Misses and Score \n Or \n Disable to show only the Score \n", "on", "off"),
                new UILayout("HUD layout", FlxG.save.data.UILayout, "Choose a HUD layout mode", ["default", "simple"]),
                new SmoothCam("Smooth Cam", FlxG.save.data.smoothCam, "if on, the camera will scroll smoothly", "on", "off"),
                new AccuracyType("Accuracy", FlxG.save.data.Accuracy, "Set the Accuracy mode \n (default: simple) \n", ["simple", "complex"]),
                new ShowTime("Show Time", FlxG.save.data.showTime, "Enable to show either the elapsed or the remaining time of the song", "on", "off"),
                new TimeType("Time Type", FlxG.save.data.TimeType, "Choose the time type..", ["time-left", "time-elapsed"]),
                new EnemyStrums("Enemy Strums", FlxG.save.data.lightstrums, "(Enemy Arrows)", ["animated", "static"])
            ]
        },
        {
            tabName: "Video options",
            decr: "Video Options",
            color: FlxColor.YELLOW,
            options: [
                new StartFullscreen("Start With Fullscreen", FlxG.save.data.startWithFullScreen, "Start FNF with Fullscreen", "ye", "nah"),
                new CallBackMaster.UseVsync("Use Vsync", FlxG.save.data.vsync, "Use Vsync", "yes please", "nah"),
                new FPS_cap("Fps cap", FlxG.save.data.fps_cap, "Set your Framerate Cap (fps cap over 250 applies Only on the Game state)", ["60", "75", "100", "120", "160", "200", "250", "999"]),
                new ShowFPS("Show Fps", FlxG.save.data.showFps, "Enable to display the Framerate", "on", "off"),
                new ShowMemory("Show Memory", FlxG.save.data.showMemory, "Enable to display the Memory Usage", "on", "off"),
                new ColorEffect("Color Filter", FlxG.save.data.colorEffect, "Interestring Color Effects", Closet.filterTypes)
                #if Preview
                ,new UseVCR("Use VCR Filter", FlxG.save.data.useVcr, "A custom VCR filter available for the preview!!", "on", "off")
                #end
            ]
        },
        {
            tabName: "Controls",
            decr: "Controls...",
            color: FlxColor.ORANGE,
            options: [
                new ResetKey("Reset Key", FlxG.save.data.resetKey, "Turn on if you want the Reset Key (R) to actually reset the stage", "on", "off"),
                new ActionOption("Set Keys", "Customize your keys here!", KeyMappingState)
            ]
        }#if sys
        ,{
            tabName: "Mod settings",
            decr: "Mod Settings..",
            color: FlxColor.LIME,
            options: [
                new Cache("Cache Mod", FlxG.save.data.cache, "'OFF' -> mod assets will not be cached. \n'OnLoad' -> mod assets will be cached when loaded for the first time. \n 'OnStart' -> the mod will be cached when FNF starts. \n", ["off", "onLoad", "onStart"])
            ]
        } 
        #end
    ];

    private var isInCategories:Bool = true;
    private var transitioning:Bool = false;

    public var curSelected:Int = 0;
    public var curOption:Int = 0;
    public var optionDisplay:FlxCamera;
    public var textGroup:FlxTypedGroup<Alphabet>;

    var a:FlxPoint;

    override function create()
    {
        a = new FlxPoint(0,0);
        bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		add(bg);
        bg.color = FlxColor.CYAN;
        bg.camera = FlxG.camera;
        
        optionDisplay = new FlxCamera();
        optionDisplay.bgColor = FlxColor.BLACK;
		optionDisplay.bgColor.alpha = 0;
        FlxG.cameras.add(optionDisplay);

        var transitionCam = new FlxCamera();
		transitionCam.bgColor.alpha = 0;
        FlxG.cameras.add(transitionCam);

        optionDisplay.zoom = 0.85;
        FlxTween.tween(optionDisplay, {zoom: 1}, 0.15, {startDelay: 1});

        var sad =new FlxSprite(0,0);
        sad.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        add(sad);
        sad.alpha = 0.35;
        sad.camera = optionDisplay;

        textGroup = new FlxTypedGroup<Alphabet>();
        add(textGroup);
        textGroup.camera = optionDisplay;

        curLockSprites = new FlxTypedGroup<FlxSprite>();
        add(curLockSprites);
        curLockSprites.camera = optionDisplay;

        contextBg = new FlxSprite(0,13);
        contextBg.color = FlxColor.BLACK;
        contextBg.alpha = 0.23;
        add(contextBg);
        contextBg.camera = optionDisplay;

        context = new FlxText(0,13);
        context.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        context.text = "";
        add(context);
        context.camera = optionDisplay;
        
        curSelected = OptionActionState.lastSelected;
        curOption = OptionActionState.lastOption;

        if(OptionActionState.wasInCategories)
            addCatigories();
        else 
            addOptions();

        colorTween();
        updateDescr();
        super.create();
    }    
    public function colorTween()
    {
        if(curColorTween != null)
            curColorTween.destroy();
        curColorTween = FlxTween.color(bg, 1, bg.color, optionGroups[curSelected].color);
    }
    public function addCatigories()
    {
        textGroup.clear();
        curLockSprites.clear();
        clipLock.clear();

        for(i in 0...optionGroups.length)
        {
            var txt:Alphabet = new Alphabet(0, (70 * i) + 30, optionGroups[i].tabName, true, false);
            txt.isMenuItem = true;
            txt.targetY = i;
            txt.ID = i;
            textGroup.add(txt);
        }
        isInCategories = true;
        changeSelection(0);
    }

    public function transition(offScreen:()->Void)
    {
        transitioning = true;
        FlxTween.tween(optionDisplay, {zoom: 0.85}, 0.15, {startDelay: 0.1, onComplete: (xd)->{
            FlxTween.tween(optionDisplay, {x: -optionDisplay.width}, 0.5, {startDelay: 0.1,ease: FlxEase.cubeIn, onComplete: (ok)->{
                optionDisplay.x = FlxG.width;
                offScreen();
                FlxTween.tween(optionDisplay, {x: 0}, 0.5, {startDelay: 0.1,ease: FlxEase.cubeIn, onComplete: (osk)->{
                    FlxTween.tween(optionDisplay, {zoom: 1}, 0.15, {startDelay: 0.1, onComplete: (xds)->{
                        transitioning = false;
                    }});
                }});
            }});
        }});
    }
    var curLockSprites:FlxTypedGroup<FlxSprite>;
    var clipLock:Map<Alphabet, FlxSprite> = [];
    public function addOptions()
    {
        textGroup.clear();
        clipOption.clear();
        curLockSprites.clear();
        clipLock.clear();

        var what = optionGroups[curSelected].options;
        for(i in 0...what.length)
        {
            var txt:Alphabet = new Alphabet(0, (140 * i) + 30, what[i].curText, true, false);
            txt.isMenuItem = true;
            txt.targetY = i;
            txt.ID = i;

            textGroup.add(txt);
            clipOption.set(txt, what[i]);
        }
        
        isInCategories = false;
        changeSelection(0);
    }

    public function setLock(option:Option, alpha:Alphabet)
    {
        if(option.isLocked)
        {
            if(clipLock.exists(alpha))
                return;

            var lock:FlxSprite = new FlxSprite(0,0);
            lock.frames = Paths.getSparrowAtlas('campaign_menu_UI_assets');
            lock.animation.addByPrefix('lock', 'lock');
            lock.animation.play('lock');
            lock.ID = alpha.ID;
            lock.antialiasing = true;
            lock.updateHitbox();

            curLockSprites.add(lock);
            alpha.color = FlxColor.GRAY;
            clipLock.set(alpha, lock);
        }
        else 
        {
            if(!clipLock.exists(alpha))
                return;

            alpha.color = FlxColor.WHITE;
            curLockSprites.remove(clipLock.get(alpha), true);
            clipLock.get(alpha).destroy();
            clipLock.remove(alpha);
        }
    }
    
    private var clipOption:Map<Alphabet, Option> = [];
    var curColorTween:ColorTween;
    public function fixRect(item:FlxSprite)
    {
        var r:FlxRect = new FlxRect(0,0, item.width, item.height);
        var a = new FlxPoint(0, 0);
        var b = new FlxPoint(item.width, item.height);

        if(item.y < 0)
            a.y = -item.y;
        if(item.x + item.width > optionDisplay.width)
            b.x -= (item.x + item.width) - optionDisplay.width;
        if(item.y + item.height > optionDisplay.height)
            b.y -= (item.y + item.height) - optionDisplay.height;
        item.clipRect = r.fromTwoPoints(a, b);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        for(item in textGroup.members)
            fixRect(item);
        for(item in curLockSprites.members)
            fixRect(item);

        if(!isInCategories)
        {
            for(i in optionGroups[curSelected].options)
            {
                i.update(elapsed);
                for(key => value in clipOption)
                {
                    if(value == i)
                        setLock(value, key);
                }
            }

            for(key => value in clipLock)
            {
                value.x = key.x + key.width / 2 - value.width / 2;
                value.y = key.y + key.height / 2 - value.height / 2;
            }
        }
        updateDescr();

        if(transitioning)
            return;
            
		var accepted = controls.ACCEPT || controls.LEFT_P || controls.RIGHT_P;

		if (controls.UP_P)
			changeSelection(-1);
		if (controls.DOWN_P)
			changeSelection(1);

        if(accepted)
        {
            if(isInCategories)
            {
                if(controls.ACCEPT)
                {
                    if(prevCategory != curSelected)
                        curOption = 0;
                    transition(addOptions);
                }
            }
            else
            {
                var txt = textGroup.members[curOption];
                var option = clipOption.get(txt);
                var omgomg:Bool = false;

                if(!option.isLocked)
                {
                    if(option.optionType == ACTION)
                    {
                        if(controls.ACCEPT)
                        {
                            OptionActionState.lastSelected = curSelected;
                            OptionActionState.lastOption = curOption;
                            OptionActionState.wasInCategories = isInCategories;
                            option.action([]);
                        }
                    }
                    else if(option.optionType == TOGGLE)
                    {
                        if(controls.ACCEPT)
                        {
                            omgomg = true;
                            option.action([]);
                        }
                    }
                    else if(option.optionType == SLIDER)
                    {
                        if(controls.LEFT_P)
                        {
                            omgomg = true;
                            option.action(["left"]);
                        }
                        else if(controls.RIGHT_P)
                        {
                            omgomg = true;
                            option.action(["right"]);
                        }
                    }
                }

                if(omgomg)
                {
                    var prev:Alphabet = txt;

                    textGroup.remove(txt);
                    var hm = new Alphabet(0, prev.y, option.curText, true, false);
                    hm.isMenuItem = prev.isMenuItem;
                    hm.targetY = prev.targetY;
                    hm.ID = prev.ID;
                    textGroup.add(hm);

                    clipOption.remove(txt);
                    clipOption.set(hm, option);
                    FlxG.save.flush();
                }
            }
        }
        if(controls.BACK)
        {
            if(isInCategories)
            {
                OptionActionState.lastOption = 0;
                OptionActionState.lastSelected = 0;
                OptionActionState.wasInCategories = true;
                transition(() -> {
                    optionDisplay.x = 0;
                    optionDisplay.zoom = 1;
                    textGroup.clear();
                    context.visible = false;
                    contextBg.visible = false;

                    FlxG.switchState(new MainMenuState());
                });
            }
            else 
            {
                prevCategory = curSelected;
                transition(addCatigories);
            }
        }
    }

    public function changeSelection(change:Int)
    {
        if(isInCategories)
            changeCurrentSelected(change);
        else 
            changeSelectedOption(change);
    }

    public function changeCurrentSelected(change) 
    {
        var bullShit:Int = 0;
        curSelected += change;

		if (curSelected < 0)
			curSelected = optionGroups.length - 1;
		if (curSelected >= optionGroups.length)
			curSelected = 0;

        for (item in textGroup.members)
        {
            item.targetY = bullShit - curSelected;
            bullShit++;

            item.alpha = 0.6;
            // item.setGraphicSize(Std.int(item.width * 0.8));

            if (item.targetY == 0)
            {
                item.alpha = 1;
                // item.setGraphicSize(Std.int(item.width));
            }
        }
        colorTween();
    }

    public function changeSelectedOption(change) 
    {
        var bullShit:Int = 0;
        curOption += change;

        if (curOption < 0)
            curOption = optionGroups[curSelected].options.length - 1;
        if (curOption >= optionGroups[curSelected].options.length)
            curOption = 0;

        for (item in textGroup.members)
        {
            item.targetY = bullShit - curOption;
            bullShit++;

            item.alpha = 0.6;
            // item.setGraphicSize(Std.int(item.width * 0.8));

            if (item.targetY == 0 && !clipOption.get(item).isLocked)
            {
                item.alpha = 1;
                // item.setGraphicSize(Std.int(item.width));
            }

            if(item.ID == curOption - 2)
                item.alpha = 0.25;
        }
    }

    public function updateDescr()
    {
        if(isInCategories)
            context.text = optionGroups[curSelected].decr;
        else 
            context.text = optionGroups[curSelected].options[curOption].description;

        context.updateHitbox();
        context.screenCenter(X);

        var uh = StringTools.endsWith(StringTools.trim(context.text), "\n");
        var lines = context.text.split("\n");
        var bruh = lines.length - 1;

        if(uh)
            bruh -= 1;
        if(bruh <= 0)
            bruh = 1;

        contextBg.setGraphicSize(optionDisplay.width, Std.int(context.size * bruh));
        contextBg.updateHitbox();
        contextBg.screenCenter(X);
    }
}