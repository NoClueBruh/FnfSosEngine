package;

import hscript.Interp;
import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.FlxSubState;

class MusicBeatSubstate extends FlxSubState
{
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	public var stateScript:Interp = null;

	override function create()
	{
		stateScript = Modin.instantiateScript(Type.getClassName(Type.getClass(FlxG.state.subState)));
		if(stateScript != null)
			stateScript.variables.set("state", this);
		Modin.runFunctionFromInterp(stateScript,this, "create");

		super.create();
	}

	private var hold:Float = 0;
	private var fixThres:Float = 0.02;
	
	override function update(elapsed:Float)
	{
		//if(PlayerSettings.player1.controls != null)
		//	KeyManager.updateKeys(PlayerSettings.player1.controls);

		hold += elapsed;
		while(hold > fixThres) {
			fixedUpdate();
			hold -= fixThres;
		}
		//everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0)
			stepHit();

		Modin.runFunctionFromInterp(stateScript, this,"update");
		super.update(elapsed);
	}
	public function fixedUpdate(){
		Modin.runFunctionFromInterp(stateScript, this,"fixedUpdate");
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
	}
	private function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet);
	}

	public function stepHit():Void
	{
		Modin.runFunctionFromInterp(stateScript, this,"stepHit");
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		Modin.runFunctionFromInterp(stateScript, this,"beatHit");
		//do literally nothing dumbass
	}
}
