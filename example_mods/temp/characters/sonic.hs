//to refer to the character start with "character"
//for example; don't use "x = 10", use "character.x = 10"
function load()
{
	character.frames = Paths.getModFrames("assets/images/sonic.png", "assets/images/sonic.xml");
	character.animation.addByPrefix("idle", "idle", 24, false);
	character.playAnim("idle", true);
}
function create()
{
    trace("controling bf!!11 not");
}

function update()
{
}