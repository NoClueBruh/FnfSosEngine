
//Example!!
function create()
{
	trace("started! 1e");
}

var ben = 0;
function update()
{
	ben += FlxG.elapsed * 4;
}

function fixedUpdate()
{
	menuItems.forEach
	(
		function (i)
		{
			var r = Math.sin(ben + (1 * i.ID * 0.34)); 
			if(i.ID == curSelected)
			{
				i.alpha =  FlxMath.lerp(1, i.alpha, 0.96);
			}
			else if(i.ID != curSelected)
			{
				i.alpha =  FlxMath.lerp(r, i.alpha, 0.6);
			}
		}
	);
}
