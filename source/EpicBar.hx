package;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;

enum Bar_dir
{
	LEFT_RIGHT;
	RIGHT_LEFT;
}

typedef BarAsset =
{
	var graph:FlxGraphicAsset;
	var color:FlxColor;
}

class EpicBar extends FlxTypedSpriteGroup<FlxSprite>
{
	public var fg:FlxSprite = null;
	public var full:FlxSprite = null;
	public var empty:FlxSprite = null;

    public var percent:Float = 0;
	public var value:Float = 0;
	public var direction:Bar_dir = LEFT_RIGHT;

	public var object:String = "";
	public var ref:Dynamic;

	public var minValue:Float = 0;
	public var maxValue:Float = 1;

	private var bScale:Float = 1;

	public function new(x, y, dir:Bar_dir, minValue:Float, maxValue:Float, object:String, ref:Dynamic, fg:BarAsset, full:BarAsset, empty:BarAsset,
			?scale:Float = 1)
	{
		this.minValue = minValue;
		this.maxValue = maxValue;
		this.object = object;
		this.ref = ref;
		this.bScale = scale;
		direction = dir;
	
		super(x, y);
		makeBar(fg, full, empty);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
        value = Math.max(minValue, Math.min(Reflect.getProperty(ref, object), maxValue));
		percent = ((value - minValue) / (maxValue - minValue)) * 100;

		var fullRect = new FlxRect(0, 0, full.width / bScale, full.height / bScale);
		fullRect.width *= percent / 100;

		if (direction == RIGHT_LEFT)
			fullRect.x = full.width / bScale - fullRect.width;
		full.clipRect = fullRect;
		//STILL ON A TESTING STATE!!!
	}

	public function makeBar(fgGraphic:BarAsset, fullGraphic:BarAsset, emptyGraphic:BarAsset)
	{
		if (emptyGraphic != null)
		{
			empty = new FlxSprite().loadGraphic(emptyGraphic.graph);
			empty.color = emptyGraphic.color;
			add(empty);
		}
		else
			empty = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);

		if (fullGraphic != null)
		{
			full = new FlxSprite().loadGraphic(fullGraphic.graph);
			full.color = fullGraphic.color;
			add(full);
		}
		else
			full = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);

		if (fgGraphic != null)
		{
			fg = new FlxSprite().loadGraphic(fgGraphic.graph);
			fg.color = fgGraphic.color;
			add(fg);
		}
		else
			fg = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);

		for (i in [full, empty, fg])
		{
			i.scale.x *= bScale;
			i.scale.y *= bScale;
			i.updateHitbox();
			i.antialiasing = true;
		}
	}
}
