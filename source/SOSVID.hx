package;

import openfl.geom.Point;
import openfl.geom.Rectangle;
import haxe.io.BytesOutput;
import vlc.lib.LibVLC;
import lime.media.AudioBuffer;
import openfl.media.Sound;
import haxe.zip.Uncompress;
import haxe.zip.Writer;
import cpp.NativeArray;
import sys.io.FileOutput;
import haxe.io.BytesInput;
import haxe.io.Input;
import haxe.zip.Reader;
import openfl.Lib;
import lime.text.UTF8String;
import haxe.io.Encoding;
import lime.ui.FileDialog;
import openfl.display.PNGEncoderOptions;
import openfl.utils.ByteArray;
import openfl.display.BitmapData;
import openfl.utils.CompressionAlgorithm;
import openfl.system.System;
import openfl.display.Bitmap;
import cpp.UInt8;
import haxe.io.Bytes;
import vlc.MP4Handler;
import openfl.Assets;
import openfl.display.Sprite;

typedef SOSVID_data = {
    var frames:Array<{time:Float, info:String}>;
    var res:Array<Int>;
    var audio:Sound;
}

class SOSVID
{
    public var data:SOSVID_data = null;
    public var isReady:Bool = false;

    public var display:BitmapData;
    public var canvas:Bitmap;

    public var time:Float = 0;
   //TODOSUPER EXPERIMENTAL

    public function new(path:String)
    {
        /*
        var data:String = "";
        #if sys
        data = (sys.io.File.getContent(path));
        #else
        data = (Assets.getText(path));
        #end
        */

        this.data = new SOSVID_Data_reader().fromData(path).data;

        display = new BitmapData(this.data.res[0],this.data.res[1]);

        canvas = new Bitmap(display);
        Lib.current.addChild(canvas);

        if(this.data != null)
            isReady = true;
    }

    public function play()
    {
        Closet.stringToBitmap(data.frames[0].info, (bitm)->{
            var b:ByteArray = new ByteArray();
            b = bitm.encode(bitm.rect, new PNGEncoderOptions(true), b);
            new FileDialog().save(b, "png", null, "file");
        });
        return;

        ApplicationBackround.current.signal.add("update", updateVideo);
    }

    public function end()
    {
        display.dispose();
        Lib.current.removeChild(canvas);
        ApplicationBackround.current.signal.remove("update", updateVideo);
    }

    var loadingFrames = false;
    private function updateVideo()
    {   
        if(!loadingFrames)
            time += 1000 * ApplicationBackround.current.delta;

        if(data.frames[0] != null)
        {
            while(data.frames.length > 0 && data.frames[0].time <= time)
            {
                loadingFrames = true;
                Closet.stringToBitmap(data.frames[0].info, (a)->{
                    loadingFrames = false;
                    display = a.clone();
                    data.frames.shift();
                });
            }
        }
        else 
            end();
    }

    public static function mp4ToData(mp4:MP4Handler)
    {
        final lmao:SOSVID_Data_reader = new SOSVID_Data_reader();
        @:privateAccess
        {
            lmao.data.res = [mp4.videoWidth, mp4.videoHeight];
            lmao.data.audio = null;
        }

        ApplicationBackround.current.signal.add("update", function (){
            inline function complete()
            {
                lmao.data.frames.sort((a,b)->Std.int(a.time - b.time));
                lmao.toData();
                //new FileDialog().save(  lmao.toData(), "json", null, "file");

                ApplicationBackround.current.signal.removeAll("update");
                trace("RENDERING ENDED");
            }

            var prevF:Array<UInt8> = [];
            var prevTime:Float = 0;
            if(mp4.getTime() > 1000 && !mp4.isPlaying)
                complete();
            @:privateAccess
            {
                if(FlxG.keys.pressed.Y)
                    complete();
                if(mp4.bufferMem != prevF)
                {
                    var bm = mp4.bitmapData;
                    //var f = new ByteArray(Std.int(bm.width * bm.height));
                    //bm.encode(bm.rect, new PNGEncoderOptions(true), f);
                    //new FileDialog().save(f, "png", null, "file");
                    //lmao.data.frames.push({time: mp4.getTime(), info: f.toString()});
                    Closet.bitmapToString(bm, (f)-> {
                        lmao.data.frames.push({time: mp4.getTime(), info: f});
                    });
                }
                prevF = mp4.bufferMem;
                //prevTime = mp4.getTime();
            }
        });
    }
}

class SOSVID_Data_reader
{
    public var data:SOSVID_data = {frames: [], res: [100,100], audio: null};

    public function new()
    {}

    public function fromData(path:String):SOSVID_Data_reader
    {
        data.frames = [];
        data.res = [100, 100];
        data.audio = null;

        var lastTime:Float = 0.0;

        var bruh = Reader.readZip(new BytesInput(sys.io.File.getBytes(path)));
        bruh.map(
            function (entry)
            {
                var b = Reader.unzip(entry);
                if(entry.fileName.startsWith("frame_"))
                {
                    final time = Std.parseFloat(entry.fileName.split("frame_")[1]);
                    if(lastTime != time)
                        data.frames.push({time: time, info: b.getString(0, b.toString().length)});
                    lastTime = time;
                }
                else if(entry.fileName == "data.ini")
                {
                    final lines:Array<String> = b.getString(0, b.toString().length).split("\n");
                    for(i in 0...lines.length)
                    {
                        final hde:String = lines[i].split(":")[0];
                        final vla:Dynamic = Closet.stringToDynamic(lines[i].split(":")[1]);

                        switch (hde)
                        {
                            case "resolution": 
                                data.res = vla;
                        }
                    } 
                }
                else if(entry.fileName.startsWith("audio"))
                    data.audio = Sound.fromAudioBuffer(AudioBuffer.fromBytes(b));
            }
        );
        return this;
    }

    public function toData():SOSVID_Data_reader
    {
        var wr = new Writer( sys.io.File.write("C:/lmao.zip", true));
        var stuffs = new haxe.ds.List<haxe.zip.Entry>();

        var dataIni:String = 'resolution: ${data.res}';
        stuffs.add({
            fileTime: Date.now(),
            fileSize: dataIni.length,
            fileName: 'data.ini',
            compressed: false,
            data: Bytes.ofString(Closet.toDynamic(dataIni)),
            dataSize: Bytes.ofString(dataIni).length,
            crc32: haxe.crypto.Crc32.make(Bytes.ofString(dataIni))
        });

        for(i in data.frames)
        {
            stuffs.add({
                fileTime: Date.now(),
                fileSize: i.info.length,
                fileName: 'frame_${i.time}.fr',
                compressed: false,
                data: Bytes.ofString(Closet.toDynamic(i.info)),
                dataSize: Bytes.ofString(i.info).length,
                crc32: haxe.crypto.Crc32.make(Bytes.ofString(i.info))
            });
        }
        wr.write(stuffs);
        return this;
    }
}