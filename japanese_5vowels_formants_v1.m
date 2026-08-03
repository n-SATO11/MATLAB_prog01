% Program: japanese_5vowels_formants_v1.m
%  Author: Noboru SATO
%    Date: 3 August 2026
%
% This program estimates the formants of the 5 Japanese vowels
% and plots them on the F1-F2 plane, as assigned for a class task
% in Audio Signal Processing.
% 
% It reads an audio file containing the pronunciation of /aiueo/, 
% and by labeling the waveform and spectrogram, it estimates the formants 
% for each vowel and generates the F1-F2 plane.
% 


clear
% close all
% [sig, Fs] = audioread('aiueo2.wav'); % read data from WAV file

[filename, pathname] = uigetfile({'*.wav'}, 'Please select the WAV file you want to process.');
full_filepath = fullfile(pathname, filename);
disp(['Selected File: ', full_filepath]);
[sig, Fs1] = audioread(full_filepath);

Fs2    = 16000;               % Sampling Frequency for Resampling
[p, q] = rat(Fs2 / Fs1);   
sig    = resample(sig, p, q); % Resampling to Fs2

b = 0.99;                   % Preemphasis coefficient
x = filter([1 -b], 1, sig); % preemphasis

x    = x';              % make x a row vector (横ベクトルに変換)
Ns   = length(x);       % get the number of samples(サンプルの総数)
tvec = (0:(Ns-1))./Fs2; % time axis vector for signal

FL_s  = 0.050;                            % set the frame length(s)フレーム長(s)
FSh_s = 0.010;                            % set the frame shift(s)シフト幅(s)
FL    = fix(FL_s*Fs2);                    % frame length(samples)
hFL   = fix(FL/2);                        % half the frame length(samples)
FSh   = fix(FSh_s*Fs2);                   % frame shift(samples)
NFr   = ceil((Ns-1)/FSh);                 % number of frames(フレームの総数)
xx    = [zeros(1,hFL) x zeros(1,hFL)];    % zero-padding x on left & right
xxo   = [zeros(1,hFL) sig' zeros(1,hFL)]; % zero-padding sig on left & right
win   = hann(FL)';                        % prepare Hann window

NFFT = 2048;                % set FFT length(samples)
Nf   = (NFFT/2)+1;          % number of frequencies(DC to Nyquist)
fvec = (0:(Nf-1))*Fs2/NFFT; % frequency vector(Hz)

LPOrder = 18;               % order of LPC 

for fr = 1 : NFr                                        % for each frame...
    nstart = 1 + ((fr - 1) * FSh);                      % start sample
    nend   = nstart + FL - 1;                           % end sample
    SGtvec(fr) = ((0.5 * (nstart + nend)) - hFL) / Fs2; % time axis (s)
    % for spectrogram (time at frame center) 

    wxx  = win .* xx(nstart : nend);  % window the frame (Preemphasised sig)
    wxxo = win .* xxo(nstart : nend); % window the frame (Original sig)
    X    = fft(wxx, NFFT);            % get complex spectrum (Preemphasised sig)
    Xo   = fft(wxxo, NFFT);           % get complex spectrum (Original sig)

    % get log power spectrum in dB (from DC to Nyquist)
    SG(:,fr) = 20.0 * log10( abs( X(1 : Nf)') );   % (Preemphasised sig)
    SGo(:,fr) = 20.0 * log10( abs( Xo(1 : Nf)') ); % (Original sig)
end

x_freqlim = 8000;
% plot waveform & specrtogram
figure(100);

subplot(3, 1, 1);
plot(tvec, sig, 'color', [0	0.5	0.8]);
xlabel('Time (s)');
ylabel('Amplitude');
xlim([0 Ns/Fs2]);ylim([-1 1]);
set(gca,'FontSize',14, 'Fontname',"Calibri");
set(gcf, 'Name','waveform & spectrogram', 'Position', [100 100 1400 800], 'color', 'w');

subplot(3, 1, 2:3);
imagesc([SGtvec(1) SGtvec(end)], [fvec(1) fvec(end)], SG); cmap = colormap('jet'); % parula turbo jet bone gray
colormap(cmap);
set(gca, 'YDir', 'normal');
xlabel('Time (s)');
xlim([0 Ns/Fs2]); % Set the x-axis limit to recording duration
ylim([0 x_freqlim]);
ylabel('Frequency (Hz)');
set(gca,'FontSize',14, 'Fontname',"Calibri");

% % manual input
% a_time = 0.94; % /a/ center time [s]
% i_time = 1.21; % /i/ center time [s]
% u_time = 1.35; % /u/ center time [s]
% e_time = 1.56; % /e/ center time [s]
% o_time = 1.83; % /o/ center time [s]

% GUI input
[a_time,~] = ginput(1); % /a/ center time [s]
subplot(3, 1, 1);
xline(a_time,'-','/a/','LineWidth', 1.0,'FontSize',14, 'Fontname',"Calibri", 'LabelHorizontalAlignment', 'center', 'LabelOrientation', 'horizontal');
subplot(3, 1, 2:3);
xline(a_time,'-','/a/','LineWidth', 1.0,'FontSize',14, 'Fontname',"Calibri", 'LabelHorizontalAlignment', 'center', 'LabelOrientation', 'horizontal');

[i_time,~] = ginput(1); % /i/ center time [s]
subplot(3, 1, 1);
xline(i_time,'-','/i/','LineWidth', 1.0,'FontSize',14, 'Fontname',"Calibri", 'LabelHorizontalAlignment', 'center', 'LabelOrientation', 'horizontal');
subplot(3, 1, 2:3);
xline(i_time,'-','/i/','LineWidth', 1.0,'FontSize',14, 'Fontname',"Calibri", 'LabelHorizontalAlignment', 'center', 'LabelOrientation', 'horizontal');

[u_time,~] = ginput(1); % /u/ center time [s]
subplot(3, 1, 1);
xline(u_time,'-','/u/','LineWidth', 1.0,'FontSize',14, 'Fontname',"Calibri", 'LabelHorizontalAlignment', 'center', 'LabelOrientation', 'horizontal');
subplot(3, 1, 2:3);
xline(u_time,'-','/u/','LineWidth', 1.0,'FontSize',14, 'Fontname',"Calibri", 'LabelHorizontalAlignment', 'center', 'LabelOrientation', 'horizontal');

[e_time,~] = ginput(1); % /e/ center time [s]
subplot(3, 1, 1);
xline(e_time,'-','/e/','LineWidth', 1.0,'FontSize',14, 'Fontname',"Calibri", 'LabelHorizontalAlignment', 'center', 'LabelOrientation', 'horizontal');
subplot(3, 1, 2:3);
xline(e_time,'-','/e/','LineWidth', 1.0,'FontSize',14, 'Fontname',"Calibri", 'LabelHorizontalAlignment', 'center', 'LabelOrientation', 'horizontal');

[o_time,~] = ginput(1); % /o/ center time [s]
subplot(3, 1, 1);
xline(o_time,'-','/o/','LineWidth', 1.0,'FontSize',14, 'Fontname',"Calibri", 'LabelHorizontalAlignment', 'center', 'LabelOrientation', 'horizontal');
subplot(3, 1, 2:3);
xline(o_time,'-','/o/','LineWidth', 1.0,'FontSize',14, 'Fontname',"Calibri", 'LabelHorizontalAlignment', 'center', 'LabelOrientation', 'horizontal');


for fr = 1 : NFr                   % for each frame...
    nstart = 1 + ((fr - 1) * FSh); % start sample
    nend = nstart + FL - 1;        % end sample
    [LPa, LPg] = lpc(win .* xx(nstart:nend), LPOrder);
    tmplps(:,fr) = -20.0 * log10( abs(fft(LPa, NFFT)) ./ sqrt(LPg * FL) );
    LPlps = tmplps(1:Nf,1:fr);
end


% plot each vowel's power spectrum & estimated formant with LP
figure(200);

ax(1) = subplot(3,2,1);
plot(fvec,SGo(:,fix(a_time*100+1)),'Linewidth',0.3,'Color', [0.8 0.8 0.8]);hold on;
plot(fvec,SG(:,fix(a_time*100+1)),'Linewidth',1.0, 'Color', [0	0.5	0.8]);
plot(fvec,LPlps(:,fix(a_time*100+1)),'Linewidth',1.5, 'color', 'k');
[a_pks,a_locs] = findpeaks(LPlps(:,fix(a_time*100+1)),fvec);
plot(a_locs,a_pks,'o', 'Linewidth',2.0, 'color', 'r');
xlim([0 x_freqlim]);
title('/a/');
xlabel('Frequency [Hz]'); ylabel('Relative Power [dB]');
grid on;set(gca,'FontSize',12, 'Fontname',"Calibri");

ax(2) = subplot(3,2,2);
plot(fvec,SGo(:,fix(i_time*100+1)),'Linewidth',0.3,'Color', [0.8 0.8 0.8]);hold on;
plot(fvec, SG(:,fix(i_time*100+1)),'Linewidth',1.0, 'Color', [0	0.5	0.8]);
plot(fvec,LPlps(:,fix(i_time*100+1)),'Linewidth',1.5, 'color', 'k');
[i_pks,i_locs] = findpeaks(LPlps(:,fix(i_time*100+1)),fvec);
plot(i_locs,i_pks,'o', 'Linewidth',2.0, 'color', 'r');
xlim([0 x_freqlim]);
title('/i/');
xlabel('Frequency [Hz]'); ylabel('Relative Power [dB]');
grid on;set(gca,'FontSize',12, 'Fontname',"Calibri");

ax(3) = subplot(3,2,3);
plot(fvec,SGo(:,fix(u_time*100+1)),'Linewidth',0.3,'Color', [0.8 0.8 0.8]);hold on;
plot(fvec, SG(:,fix(u_time*100+1)),'Linewidth',1.0, 'Color', [0	0.5	0.8]);
plot(fvec,LPlps(:,fix(u_time*100+1)),'Linewidth',1.5, 'color', 'k');
[u_pks,u_locs] = findpeaks(LPlps(:,fix(u_time*100+1)),fvec);
plot(u_locs,u_pks,'o', 'Linewidth',2.0, 'color', 'r');
xlim([0 x_freqlim]);
title('/u/');
xlabel('Frequency [Hz]'); ylabel('Relative Power [dB]');
grid on;set(gca,'FontSize',12, 'Fontname',"Calibri");

ax(4) = subplot(3,2,4);
plot(fvec,SGo(:,fix(e_time*100+1)),'Linewidth',0.3,'Color', [0.8 0.8 0.8]);hold on;
plot(fvec, SG(:,fix(e_time*100+1)),'Linewidth',1.0, 'Color', [0	0.5	0.8]);
plot(fvec,LPlps(:,fix(e_time*100+1)),'Linewidth',1.5, 'color', 'k');
[e_pks,e_locs] = findpeaks(LPlps(:,fix(e_time*100+1)),fvec);
plot(e_locs,e_pks,'o', 'Linewidth',2.0, 'color', 'r');
xlim([0 x_freqlim]);
title('/e/');
xlabel('Frequency [Hz]'); ylabel('Relative Power [dB]');
grid on;set(gca,'FontSize',12, 'Fontname',"Calibri");

ax(5) = subplot(3,2,5);
plot(fvec,SGo(:,fix(o_time*100+1)),'Linewidth',0.3,'Color', [0.8 0.8 0.8]);hold on;
plot(fvec, SG(:,fix(o_time*100+1)),'Linewidth',1.0, 'Color', [0	0.5	0.8]);
plot(fvec,LPlps(:,fix(o_time*100+1)),'Linewidth',1.5, 'color', 'k');
[o_pks,o_locs] = findpeaks(LPlps(:,fix(o_time*100+1)),fvec);
plot(o_locs,o_pks,'o', 'Linewidth',2.0, 'color', 'r');
xlim([0 x_freqlim]);
title('/o/');
xlabel('Frequency [Hz]'); ylabel('Relative Power [dB]');
grid on;set(gca,'FontSize',12, 'Fontname',"Calibri");

ax(6) = subplot(3,2,6);
axis(ax(6), 'off');

% ax(5)（/o/のプロット）のデータを使って凡例を作成
% ※ ラベル名は必要に応じて変更してください
lgd = legend(ax(5), 'Spectrum of Original Signal', 'Spectrum of Preemphasis Signal', 'Spectral Envelope of Linear Prediction', 'Estimated Formants', 'Box', 'off');

% 凡例を6番目のサブプロット領域に移動する
pos = ax(6).Position; % 6番目の領域の位置情報 [left bottom width height]を取得

% 領域の左側に合わせ、縦方向は中央に配置する計算
lgd.Position(1) = pos(1) - 0.2703; 
lgd.Position(2) = pos(2) + (pos(4) - lgd.Position(4)) / 2;

set(gcf, 'Name','power spectrum & estimated formant', 'Position', [60 40 800 600], 'color', 'w');

% Y-limit link
linkaxes(ax, 'xy');
% ylim([-100 20]);


% plot Formant1 & Formant2
figure(300);

plot(a_locs(1),a_locs(2),'o', 'Linewidth',3.0, 'color', 'r');hold on;
text(a_locs(1)-10,a_locs(2)+50,'/a/','FontSize',14, 'Fontname',"Calibri");
plot(i_locs(1),i_locs(2),'o', 'Linewidth',3.0, 'color', 'b');
text(i_locs(1)-10,i_locs(2)+50,'/i/','FontSize',14, 'Fontname',"Calibri");
plot(u_locs(1),u_locs(2),'o', 'Linewidth',3.0, 'color', 'g');
text(u_locs(1)-10,u_locs(2)+50,'/u/','FontSize',14, 'Fontname',"Calibri");
plot(e_locs(1),e_locs(2),'o', 'Linewidth',3.0, 'color', 'c');
text(e_locs(1)-10,e_locs(2)+50,'/e/','FontSize',14, 'Fontname',"Calibri");
plot(o_locs(1),o_locs(2),'o', 'Linewidth',3.0, 'color', 'm');
text(o_locs(1)-10,o_locs(2)+50,'/o/','FontSize',14, 'Fontname',"Calibri");
xlabel('Formant1 [Hz]'); ylabel('Formant2 [Hz]');
grid on;set(gca,'FontSize',12, 'Fontname',"Calibri");
set(gcf, 'Name','Formant1 & Formant2', 'Position', [900 40 800 600], 'color', 'w');

figure(100);
set(gcf,'Position', [900 300 800 600]);