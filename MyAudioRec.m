% Program: MyAudioRec.m
%  Author: Noboru SATO
%    Date: 3 August 2026
%
% This program is a basic program for recording audio in MATLAB. You can
% record audio while freely adjusting settings such as the sampling rate
% and recording time.

clear;
Fs             = 44100;       % sampling frequency(Hz)
Nbit           = 24;          % bits/sample(bits)
Nch            = 1;           % recording channel number
recDuration    = 2.0;         % recording duration(s)
preRecDuration = 0.5;         % pre-recording duration(s)
filename       = 'aiueo.wav'; % Please change the file name to match the content of the recording.

RecObj = audiorecorder(Fs, Nbit, Nch); % make recording object
disp("Startspeaking...");     % start recording
recordblocking(RecObj, preRecDuration+recDuration); 
disp("...end of recording");  % stop recording

% get audio date
sig        = getaudiodata(RecObj, 'double'); % Store the data from the record object in *sig*
indexOfRec = Fs * preRecDuration + 1;        % Get the index following the 0.5-second duration of preRecDuration
sig        = sig(indexOfRec:end);            % cut pre-recording signal

Ns   = length(sig);    % get the number of samples
tvec = (0:(Ns-1))./Fs; % time axis vector for signal

% Check the waveform in Fugure and decide whether to save it
figure(1);
plot(tvec, sig);
xlabel('Time (s)');
ylabel('Amplitude');
xlim([0 Ns/Fs]);ylim([-1 1]);
set(gca,'FontSize',14, 'Fontname',"Calibri");
set(gcf, 'Name','waveform & spectrogram', 'color', 'w');

prompt = 'Do you want to save the recorded waveform? y/n: ';
inputvalue = input(prompt, 's'); 

if inputvalue == 'y'
    audiowrite(filename, sig, Fs); % Write to file
    disp('The WAV file has been saved.');
end