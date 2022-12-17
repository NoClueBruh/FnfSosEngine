package;

import flixel.FlxG;
import flixel.math.FlxRect;
import flixel.FlxSprite;

class StaticArrow extends FlxSprite
{
    public var player:Int = 0;
    public var data:Int = 0;
    public var offsetRect:FlxRect= null;

    /**
        how many seconds to wait before returning to the static animation (for oponent or botplay) 
    */
    public var noteAnimationTimer:Float = 0;

    public function new(x:Float, y:Float, data:Int, player:Int)    
    {
        super(x, y);
        this.player = player;
        this.data = data;

        if(PlayState.isPixelStage)
        {
            this.loadGraphic(Paths.image('weeb/pixelUI/arrows-pixels'), true, 17, 17);
            this.animation.add('green', [6]);
            this.animation.add('red', [7]);
            this.animation.add('blue', [5]);
            this.animation.add('purplel', [4]);

            this.setGraphicSize(Std.int(this.width * PlayState.daPixelZoom));
            this.updateHitbox();
            this.antialiasing = false;

            switch (Math.abs(data))
            {
                case 0:
                    this.animation.add('static', [0]);
                    this.animation.add('pressed', [4, 8], 12, false);
                    this.animation.add('confirm', [12, 16], 24, false);
                case 1:
                    this.animation.add('static', [1]);
                    this.animation.add('pressed', [5, 9], 12, false);
                    this.animation.add('confirm', [13, 17], 24, false);
                case 2:
                    this.animation.add('static', [2]);
                    this.animation.add('pressed', [6, 10], 12, false);
                    this.animation.add('confirm', [14, 18], 12, false);
                case 3:
                    this.animation.add('static', [3]);
                    this.animation.add('pressed', [7, 11], 12, false);
                    this.animation.add('confirm', [15, 19], 24, false);
            }

            noteAnimationTimer = 0.15;
        }
        else 
        {
            this.frames = Paths.getSparrowAtlas('NOTE_assets');
            this.animation.addByPrefix('green', 'arrowUP');
            this.animation.addByPrefix('blue', 'arrowDOWN');
            this.animation.addByPrefix('purple', 'arrowLEFT');
            this.animation.addByPrefix('red', 'arrowRIGHT');

            this.antialiasing = true;
            this.setGraphicSize(Std.int(this.width * 0.7));

            switch (Math.abs(data))
            {
                case 0:
                    this.animation.addByPrefix('static', 'arrowLEFT');
                    this.animation.addByPrefix('pressed', 'left press', 24, false);
                    this.animation.addByPrefix('confirm', 'left confirm', 24, false);
                case 1:
                    this.animation.addByPrefix('static', 'arrowDOWN');
                    this.animation.addByPrefix('pressed', 'down press', 24, false);
                    this.animation.addByPrefix('confirm', 'down confirm', 24, false);
                case 2:
                    this.animation.addByPrefix('static', 'arrowUP');
                    this.animation.addByPrefix('pressed', 'up press', 24, false);
                    this.animation.addByPrefix('confirm', 'up confirm', 24, false);
                case 3:
                    this.animation.addByPrefix('static', 'arrowRIGHT');
                    this.animation.addByPrefix('pressed', 'right press', 24, false);
                    this.animation.addByPrefix('confirm', 'right confirm', 24, false);
            }

            noteAnimationTimer = 0.175;
        } 
        ID = data;

        animation.play("static");
        updateHitbox();
        offsetRect = new FlxRect(0,0,width, height);
       
    }

    private var animTime:Float = 0;
    override function update(elapsed)
    {
        if((player == 0 || (FlxG.save.data.botplay && player == 1)) && animation.curAnim.name == "confirm")
        {
            animTime += elapsed;
            if(animTime >= noteAnimationTimer)
            {
                animTime = 0;
                playAnim("static", true);
            }
        }
        
        super.update(elapsed);
    }

    public function playAnim(name:String, ?force:Bool = false)
    {
        animTime = 0;
        animation.play(name, force);
		centerOffsets();
		updateHitbox();
		offset.x -= (offsetRect.width - width) / 2;
		offset.y -= (offsetRect.height - height) / 2;
    }
}