package;

import openfl.Assets;
import flixel.FlxSprite;
import flixel.FlxBasic;
import hscript.Interp;
import openfl.Lib;
import flixel.addons.transition.TransitionData;
import flixel.addons.transition.Transition;
import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;

class MusicBeatState extends FlxUIState
{
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	private var controls(get, never):Controls;

	public var stateScript:Interp = null;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	override function create()
	{
		if (transIn != null)
			trace('reg ' + transIn.region);
		stateScript = Modin.instantiateScript(Type.getClassName(Type.getClass(FlxG.state)));
		if(stateScript != null)
			stateScript.variables.set("state", this);
		
		Modin.runFunctionFromInterp(stateScript,this, "create");

		ApplicationBackround.current.signal.add("fixedUpdate", beforeFixedUpdate);

		super.create();
	}
	override function update(elapsed:Float)
	{
		if(subState != null && subState is Transition)
		{
			subState.camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];

			var region:FlxRect = new FlxRect(0,0,(subState.camera.width / subState.camera.zoom) * 1.2, (subState.camera.height / subState.camera.zoom) * 1.2);
			transIn.region = region;
			transOut.region = region;
		}
		final oldStep:Int = curStep;
		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0)
			stepHit();

		Modin.runFunctionFromInterp(stateScript, this,"update");
		super.update(elapsed);
		VEffects.update(elapsed);
	}

	public function beforeFixedUpdate(){
		if(this.active)
		{
			if(this.subState == null || (this.subState != null && this.subState is Transition))
				fixedUpdate();
		}
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
		var pos = (Conductor.songPosition);
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (pos >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((pos - lastChange.songTime) / Conductor.stepCrochet);
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
	}
	override function destroy()
	{
		VEffects.active_effects = [];
		ApplicationBackround.current.signal.remove("fixedUpdate", beforeFixedUpdate);
		super.destroy();
	}
}
