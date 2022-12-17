package;

import EpicBar.Bar_dir;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.ui.FlxBar;

/*
class HealthBar extends FlxTypedSpriteGroup<FlxSprite>
{
    public var bgName:String = "";
    public var bgOutlineWidth:Int = 1;
    public var enemyColor(default, set):FlxColor;
    public var playerColor(default, set):FlxColor;

    public var healthBar:FlxBar;
    public var healthBarBG:FlxSprite;
    public var listenObject:String = "";

    public function new(x:Float, y:Float, bgName:String, bgOutlineWidth:Int, enemyColor:FlxColor, playerColor:FlxColor, listenObject:String)
    {
        this.playerColor = playerColor;
        this.enemyColor = enemyColor;
        this.bgName = bgName;
        this.bgOutlineWidth = bgOutlineWidth;
        this.listenObject = listenObject;
        super(x, y);

        make();
    }

    private function set_enemyColor(a) 
    {
        enemyColor = a;
        if(healthBar != null)
            healthBar.createFilledBar(enemyColor, playerColor);
        return a;
    }

    private function set_playerColor(a) 
    {
        playerColor = a;
        if(healthBar != null)
            healthBar.createFilledBar(enemyColor, playerColor);
        return a;
    }

    public function changeColors(empty:FlxColor, full:FlxColor)
    {
        if(healthBar == null)
            return;
        playerColor = full;
        enemyColor = empty;
        healthBar.createFilledBar(empty, full);
    }

    public function make()
    {
        clear();

        healthBarBG = new FlxSprite(0, 0).loadGraphic(Paths.image(bgName));
		healthBarBG.scrollFactor.set();
		add(healthBarBG);

        healthBar = new FlxBar(bgOutlineWidth / 2, bgOutlineWidth / 2, RIGHT_TO_LEFT, 
        Std.int(healthBarBG.width - bgOutlineWidth), Std.int(healthBarBG.height - bgOutlineWidth), FlxG.state, listenObject, 0, 2);
		healthBar.scrollFactor.set();
        healthBar.numDivisions = 1000;
        healthBar.createFilledBar(enemyColor, playerColor);
        add(healthBar);

        healthBar.updateHitbox();
        healthBar.updateBar();
    }
}
*/

class HealthBar extends EpicBar 
{
    public var enemyColor:FlxColor;
    public var playerColor:FlxColor;
    public function new(x:Float, y:Float, bgName:String, enemyColor:FlxColor, playerColor:FlxColor, listenObject:String)
    {
        this.enemyColor = enemyColor;
        this.playerColor = playerColor;
        var img = Paths.image(bgName);
        super(x,y, Bar_dir.RIGHT_LEFT,0, 2,listenObject,FlxG.state,null,{graph: img, color: playerColor}, {graph: img, color:enemyColor}, 1);

        full.antialiasing = false;
        empty.antialiasing = false;
    }

    override function update(elapsed):Void
    {
        super.update(elapsed);
        if(this.full != null)
            full.color = playerColor;
        if(this.empty != null)
            empty.color = enemyColor;
    }
}