package;

import ApplicationBackround.Simple_Signal;
import flixel.FlxG;
import Controls.Control;
import flixel.input.keyboard.FlxKey;

typedef KeyManager_keyGroups =
{
    var holdArray:Array<Bool>;
    var pressArray:Array<Bool>;
    var releaseArray:Array<Bool>;
}

class KeyManager 
{
    public static var keys:KeyManager_keyGroups = {holdArray: [], pressArray: [], releaseArray: []};

    @:deprecated
    public static function updateKeys(controls:Controls)
    {
        if(controls == null)
            return;
        final nP:Array<Bool> = [controls.LEFT_P, controls.DOWN_P, controls.UP_P, controls.RIGHT_P];
        final nR:Array<Bool> = [controls.LEFT_R, controls.DOWN_R, controls.UP_R, controls.RIGHT_R];
        final nH:Array<Bool> = [controls.LEFT, controls.DOWN, controls.UP, controls.RIGHT];
        keys = {
            holdArray: nH,
            pressArray:  nP, 
            releaseArray:  nR
        };
    }

    public static function getNoteKeys():Map<Controls.Control, Array<FlxKey>>
    {
        var data:Map<String, Array<String>> = [
			"UP" => FlxG.save.data.upKey,
			"DOWN" => FlxG.save.data.downKey,
			"LEFT" => FlxG.save.data.leftKey,
			"RIGHT" => FlxG.save.data.rightKey
		];
        var uh:Map<String, Control> = ["UP" => Control.UP, "DOWN" => Control.DOWN, "LEFT" => Control.LEFT, "RIGHT" => Control.RIGHT];
		var fixedMap:Map<Control, Array<FlxKey>> = [];

		for(key => value in data)
        {
            var br:Array<FlxKey> = [];
            for(i in value)
                br.push(FlxKey.fromString(i));

            fixedMap.set(uh.get(key), br);
        }
		return fixedMap;
    }

    public static function getSaveString(dir:Control):Dynamic
    {
        switch (dir)
        {
            case UP: return FlxG.save.data.upKey;
            case DOWN: return FlxG.save.data.downKey;
            case LEFT: return  FlxG.save.data.leftKey;
            case RIGHT: return FlxG.save.data.rightKey;
            case ACCEPT | BACK | CHEAT | PAUSE | RESET: return null;
        }
        return null;
    }
}