package;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.text.FlxText;
import flixel.input.keyboard.FlxKey;
import Controls.Control;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxG;

class KeyMappingState extends CallBackMaster.OptionActionState
{
    var bg:FlxSprite;
    var othrBG:FlxSprite;

    var dir:Array<Control> = [UP, DOWN, LEFT, RIGHT];

    var optionDisplay:FlxTypedGroup<Alphabet>;
    var selectingDir:Bool = true;
    var awaitingInput:Bool = false;
    var curDir:Int = 0;
    var curKey:Int = 0;

    override function create()
    {
        bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.color = FlxColor.ORANGE;
		add(bg);

        othrBG = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        othrBG.color = FlxColor.RED;
		add(othrBG);

        optionDisplay = new FlxTypedGroup<Alphabet>();
        add(optionDisplay);
        add(belowLayer);
        add(waitOb);

        addOptions();
        super.create();
    }

    var inVisX:FlxPoint = new FlxPoint(0,0);
    var idK:FlxSprite;

    override function update(elapsed:Float)
    {
        var br = new FlxRect(0,0,othrBG.width, othrBG.height);
        othrBG.clipRect = br.fromTwoPoints(new FlxPoint(0, 0), new FlxPoint(inVisX.x, othrBG.height));
        if(awaitingInput)
        {
            var resetControls:Bool = false;
            var resetScreen:Bool = false;
            var exit:Bool = false;

            var changes:Bool = false;

            if(FlxG.keys.justPressed.ESCAPE)
            {
                var a = KeyManager.getSaveString(dir[curDir]);
                var br = a[a.length - 1];
                if(br == "($)")
                    a.remove(br);

                exit = true;
                changes = true;
            }
            else if(FlxG.keys.justPressed.BACKSPACE)
            {
                var a = KeyManager.getSaveString(dir[curDir]);
                a.remove(a[curKey]);

                resetControls = true;
                exit = true;
                resetScreen = true;
                changes = true;
            }
            else if(FlxG.keys.anyJustPressed([FlxKey.ANY]))
            {
                var keyL:FlxKey = FlxG.keys.firstJustPressed();
                if(!controls.occupiedKeys.contains(keyL))
                {
                    KeyManager.getSaveString(dir[curDir])[curKey] = keyL.toString();
                    trace(KeyManager.getNoteKeys());
                    resetControls = true;
                    exit = true;
                    resetScreen = true;
                    changes = true;
                }
            }
            
            if(resetControls)
                controls.setKeyboardScheme(Solo, true);
            if(exit)
            {
                waitOb.clear();
                awaitingInput = false;
            }

            if(resetScreen)
            {
                transition(()->{
                    addOptions();
                });
            }
            if(changes)
                FlxG.save.flush();

            return;
        }
        super.update(elapsed);
        if(transitioningRN)
        {
            for(i in optionDisplay.members)
            {
                var r = new FlxRect(0,0,i.width,i.height);

                var a = new FlxPoint(0,0);
                var b = new FlxPoint(i.width, i.height);
                
                if(inVisX.x > i.x)
                    a.x = inVisX.x;
                if(inVisX.y > i.y)
                    a.y = i.y;

                i.clipRect = r.fromTwoPoints(a, b);
            }
            return;
        }

        if(controls.UP_P)
            changeSelection(-1);
        else if(controls.DOWN_P)
            changeSelection(1);

        if(selectingDir)
        {
            if(controls.ACCEPT)
            {
                transition(()->{
                    selectingDir = false;
                    addOptions();
                });
            }
            if(controls.BACK)
            {
                transition(()->{
                    close();
                });
            }
        }
        else 
        {
            if(controls.ACCEPT)
            {
                if(curKey >= optionDisplay.members.length - 1)
                {
                    KeyManager.getSaveString(dir[curDir]).push("($)");
                    waitKeyInput(false);
                }
                else 
                    waitKeyInput(true);
                
            }
            if(controls.BACK)
            {
                transition(()->{
                    selectingDir = true;
                    addOptions();
                });
            }
        }
    }

    var transitioningRN:Bool = false;
    public function transition(onOff:Void->Void)
    {
        //TODO make transition more interesting!!
        transitioningRN = true;
        FlxTween.tween(inVisX, {x: FlxG.width}, 0.5, {ease: FlxEase.quintInOut, onComplete: (x) -> {
            onOff();
            FlxTween.tween(inVisX, {x: 0}, 0.5, {ease: FlxEase.quintInOut, onComplete: (x) -> {
                transitioningRN = false;
            }});    
        }});    
    }

    public function addOptions()
    {
        optionDisplay.clear();
        if(selectingDir)
        {
            for(i in 0...dir.length)
                addAlpha(dir[i] + "", i);
        }
        else 
        {
            var i:Int = 0;
            for(ez in KeyManager.getNoteKeys().get(dir[curDir]))
            {
                addAlpha(ez.toString(), i);
                i++;
            }
            addAlpha("Add new Key", i);
        }
        changeSelection(0);
    }
    private function addAlpha(str:String, index:Int)
    {
        var alpha = new Alphabet(30 + (30 * index), (130 * index) + 30, str, true, false);
        alpha.isMenuItem = true;
        alpha.targetY = index;
        alpha.ID = index;
        optionDisplay.add(alpha);
    }

    public function changeSelection(change)
    {
        var bullShit:Int = 0;
        var xd:Int = 0;

        if(selectingDir)
        {
            curDir += change;
            if (curDir < 0)
                curDir = optionDisplay.members.length - 1;
            if (curDir >= optionDisplay.members.length)
                curDir = 0;
            xd = curDir;
        }
        else 
        {
            curKey += change;
            if (curKey < 0)
                curKey = optionDisplay.members.length - 1;
            if (curKey >= optionDisplay.members.length)
                curKey = 0;
            xd = curKey;
        }

        for (item in optionDisplay.members)
        {
            item.targetY = bullShit - xd;
            bullShit++;

            item.alpha = 0.4;
            // item.setGraphicSize(Std.int(item.width * 0.8));

            if (item.targetY == 0)
            {
                item.alpha = 1;
                // item.setGraphicSize(Std.int(item.width));
            }
        }
    }

    var waitOb:FlxTypedGroup<FlxBasic>= new FlxTypedGroup<FlxBasic>();
    var belowLayer:FlxTypedGroup<FlxBasic>= new FlxTypedGroup<FlxBasic>();
    public function waitKeyInput(replace:Bool)
    {
        waitOb.clear();
        awaitingInput = true;

        var spr = new FlxSprite();
        spr.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        spr.alpha = 0.6;
        waitOb.add(spr);

        var txt = new FlxText();
        txt.setFormat(Paths.font("vcr.ttf"), 26, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        txt.text = "Press Any key to " + (replace ? "replace the selected key" : "add it") + "\n (Used keys cannot be added)" + (replace ?"\n(Press BACKSPACE to delete the keybind) \n or":"") + "\n (Press ESC to Go Back) \n";
        txt.screenCenter();
        waitOb.add(txt);
    }
}