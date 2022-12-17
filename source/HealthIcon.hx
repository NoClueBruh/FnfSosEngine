package;

import flixel.FlxG;
import openfl.filters.BlurFilter;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.display.BitmapData;
import flixel.FlxSprite;

class HealthIcon extends FlxSprite
{
	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;
	public var diplayedSprite:BitmapData;
	public var animationFrames:Map<String, Array<Int>> = [];
	public var character:String = "";

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		switchIcon(char, isPlayer);
	}

	public function refreshSpr(grid:BitmapData)
	{
		final frames = animationFrames.get(animation.curAnim.name);
		if(frames == null)
			return;

		final frame = frames[animation.curAnim.curFrame];
		var x:Int = Math.floor(frame * 150);
		var y:Int = 0;

		if(x > grid.width)
		{
			y += 150 * Math.floor(x / grid.width);
			x -= grid.width * Math.floor(x / grid.width);
		}

		diplayedSprite = new BitmapData(150, 150);
		diplayedSprite.setPixels(diplayedSprite.rect, grid.getPixels(new Rectangle(x, y, 150, 150)));
	}

	public function addAnim(name, frames, player)
	{
		animation.add(name, frames,0, false, player);
		animationFrames.set(name, frames);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}

	public function switchIcon(newID:String, isPlayer:Bool)
	{
		animation.destroyAnimations();
		character = newID;
		var grid:BitmapData = BitmapData.fromFile(Paths.image('iconGrid'));

		loadGraphic(grid, true, 150, 150);

		antialiasing = true;
		addAnim('bf', [0, 1],  isPlayer);
		addAnim('bf-car', [0, 1],  isPlayer);
		addAnim('bf-christmas', [0, 1],  isPlayer);
		addAnim('bf-pixel', [21, 21],  isPlayer);
		addAnim('spooky', [2, 3],  isPlayer);
		addAnim('pico', [4, 5],  isPlayer);
		addAnim('mom', [6, 7],  isPlayer);
		addAnim('mom-car', [6, 7],  isPlayer);
		addAnim('tankman', [8, 9], isPlayer);
		addAnim('face', [10, 11], isPlayer);
		addAnim('dad', [12, 13], isPlayer);
		addAnim('senpai', [22, 22], isPlayer);
		addAnim('senpai-angry', [22, 22],  isPlayer);
		addAnim('spirit', [23, 23],  isPlayer);
		addAnim('bf-old', [14, 15],  isPlayer);
		addAnim('gf', [16],  isPlayer);
		addAnim('parents-christmas', [17],  isPlayer);
		addAnim('monster', [19, 20],  isPlayer);
		addAnim('monster-christmas', [19, 20], isPlayer);
		
		#if sys
		if(Modin.isModReady && Modin.enabledMod != null)
		{
			var data = Paths.getModImage("assets/images/icons/" + newID + "-icons.png");
			if(data != null)
			{
				grid = data;
				loadGraphic(data, true, 150, 150);
				var frameArray:Array<Int> = [];
				for(i in 0...Math.floor(data.width / 150))
				{
					frameArray.push(i);
				}
				if(frameArray.length < 2)
					frameArray = [0, 0];
				addAnim(newID, frameArray, isPlayer);
				animation.play(newID);
			}
		}
		#end 
		
		if(animationFrames.exists(newID))
			animation.play(newID);
		else 
			animation.play('face');

		refreshSpr(grid);
		scrollFactor.set();
	}
}
