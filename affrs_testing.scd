/**
This is the affrs test



**/
//do at 48k

(
    m=Server.local.options;
    m.numOutputBusChannels=10;
    m.numInputBusChannels=10;
    m.numBuffers=2000;
    m.sampleRate=48000;
    m.inDevice="xCORE USB Audio 2.0";
    m.outDevice="xCORE USB Audio 2.0";
    m.hardwareBufferSize=8192;
    //Server.default.options.device_("Scarlett 18i20 USB");
    //ServerOptions.inDevices;
)

(
var test,cal_signal,noise,utterance,wwdd;
//this is the path to the amazon files
test=PathName.new("/Users/phenix/Downloads/V2.10 Preview - will be in effect on May.6/");
~noi=Order.new(size:5);
~noi_p=Order.new(size:5);
~utt=Order.new(size:50);
~utt_p=Order.new(size:50);
~wwdd=Order.new(size:10);
~wwdd_p=Order.new(size:10);

test.files.do({|path|

	cal_signal=if(path.extension=="wav",{path.fullPath},{});
});

//Loaded Calibration Signal
~cal=Buffer.read(s,cal_signal);

test.folders.do({|path|

	if(path.folderName=="Noise",{noise=path},{});
	if(path.folderName=="Utterances",{utterance=path},{});
	if(path.folderName=="WWDD_Test",{wwdd=path},{});

});

//Noises
noise.entries.do({|path|
	~noi.add(Buffer.read(s,path.fullPath));
	~noi_p.add(path.fileNameWithoutExtension);
});

//Utterances
utterance.entries.do({|path|
	~utt.add(Buffer.read(s,path.fullPath));
	~utt_p.add(path.fileNameWithoutExtension);
});

//Wake Word Test
wwdd.entries.do({|path|
	~wwdd.add(Buffer.read(s,path.fullPath));
	~wwdd_p.add(path.fileNameWithoutExtension);
});

	SynthDef.new(\playbuf_m,{|amp=1,cal,out=0,bufnum=7,lp=0|
	var sig;
	sig=PlayBuf.ar(1,bufnum,BufRateScale.kr(bufnum),doneAction:2,loop:lp);
	sig=sig*amp*cal;
	OffsetOut.ar(out,sig);
	}).add;

	SynthDef.new(\send_m,{|amp=1,cal,out=0,send,bufnum=7,lp=0|
	var sig;
	sig=PlayBuf.ar(1,bufnum,BufRateScale.kr(bufnum),doneAction:2,loop:lp);
	sig=sig*amp*cal;
	OffsetOut.ar(out,sig);
	OffsetOut.ar(send,sig);
	}).add;

	SynthDef.new(\mic_listen_3510,{|out,in|
	var input;
	input=SoundIn.ar(in+[0,1]);
	OffsetOut.ar(out,input);
	}).add;

//Recording Bus
~rec_bus=Bus.audio(s,2);

)

(
/**
speech should be calibrated 57dBSPL/54dBA
noise should be calibrated to 54dBA
**/
var utterance_calibration,noise_calibration;

//this is level in dB from peak amplitude
noise_calibration=(0);
utterance_calibration=(-10);
~speech_out=0;
~noise_out=1;
~input_channel=0;
~rec=Recorder(s);
~rec_path="/Users/phenix/Downloads/V2.10 Preview - will be in effect on May.6/test_rec/";
~gap_size=0.05;

//ignore below
~utt_cal=utterance_calibration.dbamp;
~noi_cal=noise_calibration.dbamp;

//normal 57dBSPL / 54dBA level
~n57=(0).dbamp;

//normal 62dBSPL / 59dBA
~n62=(5).dbamp;

//normal 67dBSL / 64dBA
~n67=(10).dbamp;

//soft 47dBSPL / 44dBA level
~s47=(-10).dbamp;

//soft 52dBSPL / 49dBA
~s52=(-5).dbamp;

//soft 57dBSPL / 54dBA
~s57=(0).dbamp;

/**

Noise levels

**/

//far audio
~noise_45=(-10).dbamp;
~noise_55=(0).dbamp;
~noise_65=(10).dbamp;
~noise_61=(6).dbamp;
)

(
~utt_calibration=Synth(\playbuf_m,[\amp,~n57,\cal,~utt_cal,\out,~speech_out,\bufnum,~cal,\lp,1]);
~noise_calibration=Synth(\playbuf_m,[\amp,~noise_55,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(6),\lp,1]);
)

(
~silence_57=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"Silence_"++"57dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~n57,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});
	monitor.free;
});

~silence_47=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"Silence_"++"47dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~s47,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});
	monitor.free;
});

//Pink Noise
~pink_45dBA_norm_57=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	noise_num=4;
	noise_player=Synth(\playbuf_m,[\amp,~noise_45,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"45dB_"++"Normal_"++~noi_p.at(noise_num)++"_57dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~n57,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~pink_55dBA_norm_62=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=4;
	noise_player=Synth(\playbuf_m,[\amp,~noise_55,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"55dB_"++"Normal_"++~noi_p.at(noise_num)++"_62dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~n62,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~pink_65dBA_norm_67=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=4;
	noise_player=Synth(\playbuf_m,[\amp,~noise_65,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"65dB_"++"Normal_"++~noi_p.at(noise_num)++"_67dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~n67,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~pink_45dBA_soft_47=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=4;
	noise_player=Synth(\playbuf_m,[\amp,~noise_45,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"45dB_"++"Soft_"++~noi_p.at(noise_num)++"_47dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~s47,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~pink_55dBA_soft_52=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=4;
	noise_player=Synth(\playbuf_m,[\amp,~noise_55,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"55dB_"++"Soft_"++~noi_p.at(noise_num)++"_52dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~s52,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~pink_65dBA_soft_57=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=4;
	noise_player=Synth(\playbuf_m,[\amp,~noise_65,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"65dB_"++"Soft_"++~noi_p.at(noise_num)++"_57dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~s57,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

//Happy
~happy_45dBA_norm_57=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=2;
	noise_player=Synth(\playbuf_m,[\amp,~noise_45,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"45dB_"++"Normal_"++~noi_p.at(noise_num)++"_57dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~n57,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~happy_55dBA_norm_62=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=2;
	noise_player=Synth(\playbuf_m,[\amp,~noise_55,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"55dB_"++"Normal_"++~noi_p.at(noise_num)++"_62dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~n62,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~happy_65dBA_norm_67=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=2;
	noise_player=Synth(\playbuf_m,[\amp,~noise_65,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"65dB_"++"Normal_"++~noi_p.at(noise_num)++"_67dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~n67,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~happy_45dBA_soft_47=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=2;
	noise_player=Synth(\playbuf_m,[\amp,~noise_45,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"45dB_"++"Soft_"++~noi_p.at(noise_num)++"_47dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~s47,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~happy_55dBA_soft_52=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=2;
	noise_player=Synth(\playbuf_m,[\amp,~noise_55,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"55dB_"++"Soft_"++~noi_p.at(noise_num)++"_52dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~s52,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~happy_65dBA_soft_57=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=2;
	noise_player=Synth(\playbuf_m,[\amp,~noise_65,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"65dB_"++"Soft_"++~noi_p.at(noise_num)++"_57dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~s57,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

//Cafeteria
~cafe_45dBA_norm_57=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=0;
	noise_player=Synth(\playbuf_m,[\amp,~noise_45,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"45dB_"++"Normal_"++~noi_p.at(noise_num)++"_57dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~n57,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~cafe_55dBA_norm_62=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=0;
	noise_player=Synth(\playbuf_m,[\amp,~noise_55,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"55dB_"++"Normal_"++~noi_p.at(noise_num)++"_62dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~n62,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~cafe_65dBA_norm_67=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=0;
	noise_player=Synth(\playbuf_m,[\amp,~noise_65,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"65dB_"++"Normal_"++~noi_p.at(noise_num)++"_67dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~n67,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~cafe_45dBA_soft_47=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=0;
	noise_player=Synth(\playbuf_m,[\amp,~noise_45,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"45dB_"++"Soft_"++~noi_p.at(noise_num)++"_47dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~s47,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~cafe_55dBA_soft_52=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=0;
	noise_player=Synth(\playbuf_m,[\amp,~noise_55,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"55dB_"++"Soft_"++~noi_p.at(noise_num)++"_52dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~s52,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~cafe_65dBA_soft_57=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=0;
	noise_player=Synth(\playbuf_m,[\amp,~noise_65,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"65dB_"++"Soft_"++~noi_p.at(noise_num)++"_57dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~s57,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

//ETSI Rock
~etsi_rock_45dBA_norm_57=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=1;
	noise_player=Synth(\playbuf_m,[\amp,~noise_45,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"45dB_"++"Normal_"++~noi_p.at(noise_num)++"_57dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~n57,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~etsi_rock_55dBA_norm_62=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=1;
	noise_player=Synth(\playbuf_m,[\amp,~noise_55,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"55dB_"++"Normal_"++~noi_p.at(noise_num)++"_62dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~n62,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~etsi_rock_65dBA_norm_67=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=1;
	noise_player=Synth(\playbuf_m,[\amp,~noise_65,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"65dB_"++"Normal_"++~noi_p.at(noise_num)++"_67dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~n67,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~etsi_rock_45dBA_soft_47=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=1;
	noise_player=Synth(\playbuf_m,[\amp,~noise_45,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"45dB_"++"Soft_"++~noi_p.at(noise_num)++"_47dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~s47,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~etsi_rock_55dBA_soft_52=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=1;
	noise_player=Synth(\playbuf_m,[\amp,~noise_55,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"55dB_"++"Soft_"++~noi_p.at(noise_num)++"_52dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~s52,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~etsi_rock_65dBA_soft_57=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=1;
	noise_player=Synth(\playbuf_m,[\amp,~noise_65,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"65dB_"++"Soft_"++~noi_p.at(noise_num)++"_57dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~s57,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

//NPR
~npr_45dBA_norm_57=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=3;
	noise_player=Synth(\playbuf_m,[\amp,~noise_45,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"45dB_"++"Normal_"++~noi_p.at(noise_num)++"_57dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~n57,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~npr_55dBA_norm_62=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=3;
	noise_player=Synth(\playbuf_m,[\amp,~noise_55,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"55dB_"++"Normal_"++~noi_p.at(noise_num)++"_62dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~n62,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~npr_65dBA_norm_67=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=3;
	noise_player=Synth(\playbuf_m,[\amp,~noise_65,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"65dB_"++"Normal_"++~noi_p.at(noise_num)++"_67dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~n67,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~npr_45dBA_soft_47=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=3;
	noise_player=Synth(\playbuf_m,[\amp,~noise_45,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"45dB_"++"Soft_"++~noi_p.at(noise_num)++"_47dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~s47,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~npr_55dBA_soft_52=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=3;
	noise_player=Synth(\playbuf_m,[\amp,~noise_55,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"55dB_"++"Soft_"++~noi_p.at(noise_num)++"_52dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~s52,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~npr_65dBA_soft_57=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=3;
	noise_player=Synth(\playbuf_m,[\amp,~noise_65,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"65dB_"++"Soft_"++~noi_p.at(noise_num)++"_57dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~s57,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

//Pub

~pub_45dBA_norm_57=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=5;
	noise_player=Synth(\playbuf_m,[\amp,~noise_45,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"45dB_"++"Normal_"++~noi_p.at(noise_num)++"_57dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~n57,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~pub_55dBA_norm_62=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=5;
	noise_player=Synth(\playbuf_m,[\amp,~noise_55,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"55dB_"++"Normal_"++~noi_p.at(noise_num)++"_62dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~n62,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~pub_65dBA_norm_67=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=5;
	noise_player=Synth(\playbuf_m,[\amp,~noise_65,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"65dB_"++"Normal_"++~noi_p.at(noise_num)++"_67dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~n67,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~pub_45dBA_soft_47=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=5;
	noise_player=Synth(\playbuf_m,[\amp,~noise_45,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"45dB_"++"Soft_"++~noi_p.at(noise_num)++"_47dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~s47,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~pub_55dBA_soft_52=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=5;
	noise_player=Synth(\playbuf_m,[\amp,~noise_55,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"55dB_"++"Soft_"++~noi_p.at(noise_num)++"_52dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~s52,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

~pub_65dBA_soft_57=Routine({
	var nframe,rate,seconds,noise_player,noise_num,monitor;
	monitor=Synth(\mic_listen_3510,[\out,~rec_bus,\in,~input_channel]);
	noise_num=5;
	noise_player=Synth(\playbuf_m,[\amp,~noise_65,\cal,~noi_cal,\out,~noise_out,\bufnum,~noi.at(noise_num).bufnum,\lp,1]);
	for(0,49,{|speak|
		nframe=~utt.at(speak).numFrames;
		rate=~utt.at(speak).sampleRate;
		seconds=(nframe/rate);
		~rec.recHeaderFormat="WAV";
		~rec.recSampleFormat="int16";
		~gap_size.wait;
		~rec.prepareForRecord(~rec_path++"65dB_"++"Soft_"++~noi_p.at(noise_num)++"_57dB_"++~utt_p.at(speak)++".wav",2);
		~gap_size.wait;
		Synth(\playbuf_m,[\amp,~s57,\cal,~utt_cal,\out,~speech_out,\bufnum,~utt.at(speak)]);
		~rec.record(duration:seconds,bus:~rec_bus);
		seconds.wait;
	});

	~gap_size.wait;
	noise_player.free;
	monitor.free;
});

)

~pub_65dBA_soft_57.play;
~test=~silence_57++~silence_47;


~test.play;






