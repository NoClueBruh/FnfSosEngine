package;

import flixel.tweens.FlxTween;
import flixel.FlxG;
import vlc.MP4Handler;
//using hxcodec at https://lib.haxe.org/p/hxCodec/
class EpicVideo
{
    public static var inAnimation:Bool = false;

	public static function play(path:String, onEnd:Void->Void)
	{
        var s:MP4Handler = new MP4Handler(FlxG.width, FlxG.height, true);
        s.disposeOnStop = false;

        s.finishCallback = ()->
        {
            FlxG.state.active = true;
            if(onEnd != null)
                onEnd();

            FlxG.stage.removeChild(s);
            inAnimation = false;
        }

        s.playVideo(path, false, true);
        inAnimation = true;
        FlxG.state.active = false;
	}
}