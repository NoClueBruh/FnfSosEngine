package;

import flixel.math.FlxRect;
import openfl.filters.BlurFilter;
import flixel.system.debug.interaction.tools.Mover;
import openfl.geom.Point;
import openfl.display.BitmapData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
#if polymod
import polymod.format.ParseRules.TargetSignatureElement;
#end

using StringTools;

class Note extends FlxSprite
{
	public var strumTime:Float = 0;
	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var prevNote:Note;
	public var isSustainNote:Bool = false;
	public var sustainLength:Float;

	public static var swagWidth:Float = 160 * 0.7;
	private static var sustainQuality:Int = 4;

	public var susCount:Int = 0;

	public var onPress:(diff:Float)->Void = (x) -> {};
	public var onMiss:Void->Void = () -> {};

	public var isSustainEnd:Bool = false;
	public var isBadNote:Bool = false;
	public var useDownscroll(default, set):Bool = false;

	public var startRect:FlxRect;
	public var startBPMcroch:Float = 0.0;

	/**
		Using for now bc downscroll long notes kinda buggy
	**/
	public static function trail_quality(a:OneOfTwo<Note, Bool>):Int
	{
		final ff:Dynamic = a;
		if(Std.isOfType(a, Note))
		{
			final n:Note = ff;
			if(n.useDownscroll)
				return 1;
			else 
				return sustainQuality;
		}
		else if(Std.isOfType(a, Bool))
		{
			if(ff)
				return 1;
			else 
				return sustainQuality;
		}
		return 1;
	}

	private function set_useDownscroll(a):Bool 
	{
		useDownscroll = a;
		if(isSustainNote)
			flipY = a;
		return a;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false)
	{
		super();

		startBPMcroch = Conductor.stepCrochet;
		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.strumTime = strumTime;
		this.noteData = noteData;

		if(PlayState.isPixelStage)
		{
			loadGraphic(Paths.image('weeb/pixelUI/arrows-pixels'), true, 17, 17);

			animation.add('greenScroll', [6]);
			animation.add('redScroll', [7]);
			animation.add('blueScroll', [5]);
			animation.add('purpleScroll', [4]);

			if (isSustainNote)
			{
				loadGraphic(Paths.image('weeb/pixelUI/arrowEnds'), true, 7, 6);

				animation.add('purpleholdend', [4]);
				animation.add('greenholdend', [6]);
				animation.add('redholdend', [7]);
				animation.add('blueholdend', [5]);

				animation.add('purplehold', [0]);
				animation.add('greenhold', [2]);
				animation.add('redhold', [3]);
				animation.add('bluehold', [1]);
			}

			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			updateHitbox();
		}
		else
		{
			frames = Paths.getSparrowAtlas('NOTE_assets');

			animation.addByPrefix('greenScroll', 'green0');
			animation.addByPrefix('redScroll', 'red0');
			animation.addByPrefix('blueScroll', 'blue0');
			animation.addByPrefix('purpleScroll', 'purple0');

			animation.addByPrefix('purpleholdend', 'pruple end hold');
			animation.addByPrefix('greenholdend', 'green hold end');
			animation.addByPrefix('redholdend', 'red hold end');
			animation.addByPrefix('blueholdend', 'blue hold end');

			animation.addByPrefix('purplehold', 'purple hold piece');
			animation.addByPrefix('greenhold', 'green hold piece');
			animation.addByPrefix('redhold', 'red hold piece');
			animation.addByPrefix('bluehold', 'blue hold piece');

			setGraphicSize(Std.int(width * 0.7));
			updateHitbox();
			antialiasing = true;
		}

		switch (noteData)
		{
			case 0:
				animation.play('purpleScroll');
			case 1:
				animation.play('blueScroll');
			case 2:
				animation.play('greenScroll');
			case 3:
				animation.play('redScroll');
		}

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
		
			switch (noteData)
			{
				case 2:
					animation.play('greenholdend');
				case 3:
					animation.play('redholdend');
				case 1:
					animation.play('blueholdend');
				case 0:
					animation.play('purpleholdend');
			}
			updateHitbox();
			isSustainEnd = true;

			if (prevNote.isSustainNote)
			{
				switch (prevNote.noteData)
				{
					case 0:
						prevNote.animation.play('purplehold');
					case 1:
						prevNote.animation.play('bluehold');
					case 2:
						prevNote.animation.play('greenhold');
					case 3:
						prevNote.animation.play('redhold');
				}

				prevNote.scale.y *= (Conductor.stepCrochet / Note.trail_quality(prevNote)) / 100 * (!PlayState.isPixelStage ? 1.502 : 1.25) * PlayState.SONG.speed;
				prevNote.updateHitbox();
				prevNote.startRect = new FlxRect(0,0,prevNote.width,prevNote.height);

				prevNote.isSustainEnd = false;
			}
		}
		//scrollFactor.set(0, 0);
		updateHitbox();
		startRect = new FlxRect(0,0,width,height);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (strumTime > PlayState.noteTiming - Conductor.safeZoneOffset
			&& strumTime < PlayState.noteTiming + (Conductor.safeZoneOffset * 0.5))
			canBeHit = true;
		else
			canBeHit = false;

		if (strumTime < PlayState.noteTiming - Conductor.safeZoneOffset && !wasGoodHit)
			tooLate = true;

		if (tooLate)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}

	public static function generateTrailOfNote(note:Note):Array<Note>
	{
		var trailNotes:Array<Note> = [note];
		var cur:Int = 1;

		for (susNote in 0...Std.int((note.sustainLength / Conductor.stepCrochet) * Note.trail_quality(note)))
		{
			var sustainNote:Note = new Note(
				note.strumTime + ((Conductor.stepCrochet / Note.trail_quality(note)) * susNote) + (Conductor.stepCrochet / Note.trail_quality(note)), 
				note.noteData, trailNotes[Std.int(trailNotes.length - 1)], 
			true);
			sustainNote.scrollFactor.set(0, 0);

			trailNotes.push(sustainNote);
			sustainNote.mustPress = note.mustPress;
			sustainNote.susCount = cur++;
			sustainNote.useDownscroll = note.useDownscroll;
		}
		return trailNotes.slice(1);
	}
}
