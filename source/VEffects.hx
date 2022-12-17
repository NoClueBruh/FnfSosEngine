package;

import lime.graphics.opengl.GL;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import lime.ui.Window;
import openfl.filters.ShaderFilter;
import flixel.math.FlxMath;
import openfl.display.ShaderParameter;
import flixel.FlxG;
import haxe.io.Bytes;
import openfl.utils.ByteArray;
import openfl.display.Shader;
import openfl.filters.BlurFilter;
import openfl.filters.BitmapFilter;
import flixel.FlxCamera;
import flixel.system.FlxAssets.FlxShader;

class VEffects
{
    public static var active_effects:Array<VEffect> = [];
    public static function update(elapsed)
    {
        var i = 0;
        while (i < active_effects.length)
            active_effects[i++].update(elapsed);
    }
}
class VEffect extends FlxShader
{
    public var asShaderFilter:ShaderFilter;
    public function new()
    {
        super();
        this.asShaderFilter = new ShaderFilter(this);
        VEffects.active_effects.push(this);
    }

    public function update(elapsed:Float)
    {}

    public function clear()
    {
        VEffects.active_effects.remove(this);
    }
}

typedef VCR_Options =
{
    var useStatic:Bool;
    var useChromaticAberration:Bool;
    var useBlackBorder:Bool;
    var staticResolution:Int;

    var distortPower:Float;
    var chromaticAberrationPower:Float;
    var chromaticAberrationRadius:Float;
    var staticPower:Float;
}
class VCR extends VEffect
{
    public static var defaultOptions(default, null):VCR_Options = {
        useStatic: true,
        useChromaticAberration: true,
        useBlackBorder: true,
        staticResolution: 500,
        distortPower: 0.3,
        chromaticAberrationPower: 0.3,
        chromaticAberrationRadius: -0.05,
        staticPower: 0.2
    };

    //barrel distortion based on https://www.shadertoy.com/view/wtBXRz
    //chromatic aberration based on https://www.shadertoy.com/view/Mds3zn

    //had to modify some stuff tho
    @:glFragmentSource('
        #pragma header
        uniform vec2 screenRes;
        uniform float power = 0.23;
        uniform sampler2D staticTexture;
        uniform vec2 staticWH;

        uniform bool useStatic;
        uniform float staticStrength;

        uniform bool useChromaticAberration;
        uniform float chromaticAberrationRadius;
        uniform float chromaticAberrationStrength;

        uniform float borderBound;

        vec2 brownConradyDistortion(vec2 uv, float k1, float k2)
        {
            uv = uv * 2.0 - 1.0;
            float r2 = uv.x*uv.x + uv.y*uv.y;
            uv *= 1.0 + k1 * r2 + k2 * r2 * r2;
            uv = (uv * .5 + .5);
            return uv;
        }

        vec3 chromaticA(vec2 uv)
        {
            if(!useChromaticAberration)
                return vec3(0,0,0);

            float amount = 0.0;
            
            amount = (1.0 + chromaticAberrationRadius) * 0.5;
            amount *= 1.0 + chromaticAberrationRadius * 0.5;
            amount *= 1.0 + chromaticAberrationRadius * 0.5;
            amount *= 1.0 + chromaticAberrationRadius * 0.5;
            amount = pow(amount, 3.0);
        
            amount *= 0.05;
            
            vec3 col;
            col.r = texture(bitmap, vec2(uv.x+amount,uv.y)).r;
            col.g = texture( bitmap, uv ).g;
            col.b = texture(bitmap, vec2(uv.x-amount,uv.y)).b;
        
            col *= (1.0 - amount * 0.5);
            
            return col * chromaticAberrationStrength;
        }

        vec3 addStatic(vec2 uv)
        {
            if(!useStatic)
                return vec3(0,0,0);

            float fx = uv.x;
            float fy = uv.y;

            if(fx > staticWH.x)
                fx = floor(fx / staticWH.x);
            if(fy > staticWH.y)
                fy = floor(fy / staticWH.y);

            return texture2D(staticTexture, vec2(fx, fy)) * staticStrength;
        }

        void main()
        {
            vec2 uv = (openfl_TextureCoordv * screenRes).xy / screenRes.xy; 
            
            float k1 = -0.2 + 0.7 * (-abs(power * 0.5) + 0.5);
            float k2 = 0.;
            
            uv = brownConradyDistortion( uv, k1, k2 );

            float scale = abs(k1) < 1. ? 1.-abs(k1) : 1./ (k1+1.);		
            uv = uv * scale - (scale * .5) + .5;

            vec4 texture = texture2D(bitmap, uv);
            vec3 c = texture.rgb;
            float alpha = texture.a;
            if(alpha < 0.2)
                alpha = 0.2;

            vec2 border = 1.-smoothstep(vec2(.95),vec2(1.0), abs(uv * 2. - 1.));
            float lmao = mix(.2, 1.0, border.x * border.y);

            if(!(abs(lmao) > borderBound))
            {
                c = vec3(0,0,0);
                alpha = 1;
            }
            else if(!(abs(lmao) > borderBound + 0.02))
            {
                alpha = 0.85;
                c = vec3(0,0,0);
            }
            else
                c += chromaticA(uv) - addStatic(uv);

            gl_FragColor = vec4(c, alpha);
        }
    ')
    
    private var target:FlxCamera;

    private var staticIndex:Int = 0;
    private var staticTimer:Float = 0;

    public var staticMaps:Array<BitmapData> = [];
    public var options(default, null):VCR_Options = null;

    public function new(target:FlxCamera, ?options:VCR_Options)
    {
        super();
        if(options == null)
            options = VCR.defaultOptions;

        this.target = target;
        this.borderBound.value = [(options.useBlackBorder ? 0.2 : -0.02)];
        this.power.value = [options.distortPower];
        this.screenRes.value = [target.width, target.height];
        this.useChromaticAberration.value = [options.useChromaticAberration];
        this.chromaticAberrationRadius.value = [options.chromaticAberrationRadius];
        this.chromaticAberrationStrength.value = [options.chromaticAberrationPower];
        this.useStatic.value = [options.useStatic];
        this.staticStrength.value = [options.staticPower];
        this.staticWH.value = [options.staticResolution, options.staticResolution];
        
        if(options.useStatic)
        {
            if(staticMaps.length <= 0)
            {
                for(ii in 0...4)
                {
                    var i = new BitmapData(options.staticResolution, options.staticResolution);
                    for(x in 0...i.width)
                    {
                        for(y in 0...i.height)
                        {
                            var r = FlxG.random.int(0,182);
                            i.setPixel(x, y, FlxColor.fromRGB(r,r,r));
                        }
                    }
                    staticMaps.push(i);
                }
            }
            this.staticTexture.input = staticMaps[0];
        }
    }

    override function update(elapsed)
    {
        staticTimer+=elapsed;
        while(staticTimer > 0.08)
        {
            this.staticTexture.input = staticMaps[staticIndex];

            staticIndex++;
            if(staticIndex > staticMaps.length - 1)
                staticIndex = 0;

            staticTimer -= 0.08;
        }
        /*
        if(FlxG.keys.justPressed.UP)
        {
            this.chromaticAberrationRadius.value = [this.chromaticAberrationRadius.value[0] + 0.05];
            trace(this.chromaticAberrationRadius.value[0]);
        }
        if(FlxG.keys.justPressed.DOWN)
        {
            this.chromaticAberrationRadius.value = [this.chromaticAberrationRadius.value[0] - 0.05];
            trace(this.chromaticAberrationRadius.value[0]);
        }
        */
        super.update(elapsed);
    }
}

class SingleColor extends VEffect
{
    @:glFragmentSource('
        #pragma header
        uniform float r;
        uniform float g;
        uniform float b;
        uniform float a;

        vec4 singleOut(vec4 input)
        {
            return vec4(input.r * r,  input.g * g, input.b * b, input.a * a);
        }
        void main()
        {
			gl_FragColor = singleOut(texture2D(bitmap, openfl_TextureCoordv));
        }
    ')

    public function new(code:Array<Float>)
    {
        super();
        this.r.value = [code[0]];
        this.g.value = [code[1]];
        this.b.value = [code[2]];
        this.a.value = [code[3]];
    }
}

class TestShader extends VEffect
{
    @:glFragmentSource('
        #pragma header
        uniform vec2 center;
        uniform float fadeRadius;

        float xposition(float a, float t)
        {
            return 0.5 * a * t * t;
        }

        vec4 shader(vec2 input)
        {
            vec4 clr = texture2D(bitmap, input);
            float dist = distance(center, input);
            if(dist > fadeRadius)
            {
                clr.a = xposition(1 / 10000, input.x*10);
            }
            return clr;
        }
        void main()
        {
			gl_FragColor = shader(openfl_TextureCoordv);
        }
        float distance(vec2 a, vec2 b)
        {
            float dx = a.x - b.x;
            float dy = a.y - b.y;
            return sqrt(dx * dx + dy * dy);
        }
    ')

    var trgRadius:Float = 0.4;
    var tmr:Float = 0;
    public function new()
    {
        super();
        this.fadeRadius.value = [-0.1];
    }
    override function update(elapsed:Float) 
    {
        this.center.value = [(FlxG.stage.application.window.width / 2) / FlxG.stage.application.window.width, (FlxG.stage.application.window.height / 2) / FlxG.stage.application.window.height];
        super.update(elapsed);

        tmr+=elapsed;
        while(tmr > 0.02)
        {
            fixedUpdate();
            tmr -= 0.02;
        }
    }
    function fixedUpdate()
    {
        if(FlxG.random.bool(5))
            trgRadius = FlxG.random.float(0.3, 0.6);
        this.fadeRadius.value = [FlxMath.lerp(trgRadius, this.fadeRadius.value[0], 0.95)];
    }
}