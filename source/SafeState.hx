package;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.FlxState;

class SafeState extends FlxState
{
    var options:Array<{name:String, color:FlxColor, onClick:Void->Void}> = 
    [
        {
            name: "reset options",
            color: FlxColor.YELLOW,
            onClick: () -> CallBackMaster.Option.startOptions(true)
        },
        {
            name: "reset controls",
            color: FlxColor.ORANGE,
            onClick: () -> Controls.saveControls_start(true)
        },
        {
            name: "quit game",
            color: FlxColor.RED,
            onClick: () -> Sys.exit(0)
        },
        {
            name: "exit safe mode",
            color: FlxColor.RED,
            onClick: () -> FlxG.switchState(new TitleState())
        }
    ];
    var grp = new FlxTypedGroup<Alphabet>();
    var cur = 0;
    override function create()
    {
        add(grp);
        addStuff();
        super.create();
    }
    function addStuff()
    {
        grp.clear();
        for(i in 0...options.length)
        {
            var txt:Alphabet = new Alphabet(0, (70 * i) + 30, options[i].name, true, false);
            txt.isMenuItem = true;
            txt.targetY = i;
            txt.ID = i;
            txt.color = options[i].color;
            grp.add(txt);
        }
        changeS(-0);
    }
    override function update(elapsed)
    {
        super.update(elapsed);
        if(FlxG.keys.anyJustPressed([UP, W]))
            changeS(-1);
        else if(FlxG.keys.anyJustPressed([DOWN, S]))
            changeS(1);

        if(FlxG.keys.justPressed.ENTER)
        {
            options[cur].onClick();
            if(options[cur].name != "exit safe mode")
                addStuff();
        }
            
    }
    function changeS(change:Int)
    {
        var bullShit:Int = 0;
        cur += change;

		if (cur < 0)
			cur = grp.members.length - 1;
		if (cur >= grp.members.length)
			cur = 0;

        for (item in grp.members)
        {
            item.targetY = bullShit - cur;
            bullShit++;
            item.alpha = 0.6;
            if (item.targetY == 0)
                item.alpha = 1;
        }
    }
}