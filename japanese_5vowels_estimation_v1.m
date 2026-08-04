% Program: japanese_5vowels_estimation_v1.m
%  Author: Noboru SATO
%    Date: 4 August 2026
%
% This program predicts Japanese vowels in real time by estimating
% formants.
% Vowel estimation is performed by calculating the Euclidean distance
% between the pre-calculated formants (F1–F2) for the five vowels and the
% estimated formants.
% The pre-calculated formant values (F1–F2) were derived from data provided
% by the author and 17 participants in the TPU Voice Quality database v1[1] project.
%

clear; close all;

%% 設定
Fs           = 16000; % サンプリング周波数 (Hz)
frameSize    = 2^7;   % 1ループの読み込みサンプル数
bufferSize   = 2^10;  % 解析バッファサイズ
plotTime     = 1.0;   % 波形・スペクトログラムの表示時間 (秒)
drawInterval = 0.05;  % 描画の更新間隔 (秒)
rmsThreshold = 0.005; % ノイズ閾値
   
% マイク入力の設定
try
    audioReader = audioDeviceReader('SampleRate', Fs, 'SamplesPerFrame', frameSize);
    availableDevices = getAudioDevices(audioReader); % availableDevices内のデバイス名とIDを確認してください
    audioReader.Device = availableDevices{1};        % デバイスIDを指定して使用したいマイクを指定する
catch
    error('オーディオデバイスの初期化に失敗しました。マイクが接続されているか確認してください。');
end

% バッファの初期化
audioBuffer = zeros(bufferSize, 1);           % 解析バッファ
historySize = fix(plotTime * Fs / frameSize); % メモリのサイズ
waveHistory = zeros(plotTime * Fs, 1);        % 波形のメモリ

% スペクトログラム用の設定
NFFT        = 2^11;                         % FFT長さ
Nf          = (NFFT/2) + 1;                 % 周波数ビンの数
fvec        = (0:(Nf-1)) * Fs / NFFT;       % 周波数軸(Hz)
specHistory = -120 * ones(Nf, historySize); % スペクトルのメモリ

% 解析用パラメータ
LPOrder   = 18;               % LP次数
win       = hann(bufferSize); % ハニング窓
b         = 0.90;             % プリエンファシス係数
x_freqlim = 8000;             % 表示周波数上限

% 日本語5母音のフォルマント (F1, F2)
vowels = {'/a/', '/i/', '/u/', '/e/', '/o/'};

% 以下の5母音のF1F2は、作成者とTPU Voice Quality database v1[1]の音声データベースから算出した．
% 使用データベースは，16名(男性10名, ⼥性6名,19〜22歳)の日本語を母語とする素人話者によって録音された
% 9種類の声質の音声データである．そのうちの/aiueo/と連続で発声したデータの母音の中心フレームを解析した．

vowel_F1F2 = [
      760.57,  1449.91;  % /a/
      344.21,  2404.87;  % /i/
      365.72,  1550.78;  % /u/
      476.56,  2022.52;  % /e/
      470.59,   877.76;  % /o/
];

%% GUIの作成
fig = figure('Name', 'Real-Time Vowel Estimation', 'Position', [100 100 1200 900], 'Color', 'w');

% --- 波形プロット (左上) ---
axes('Position', [0.08 0.68 0.40 0.22]);
t_wave = linspace(-plotTime, 0, length(waveHistory));
hWave = plot(t_wave, waveHistory, 'Color', 'k');
ylim([-1 1]); xlim([-plotTime 0]);
xlabel('Time [s]'); ylabel('Amplitude'); title('Waveform');
set(gca, 'FontSize', 12, 'Fontname', "Calibri");

% --- スペクトログラム (左中) ---
axes('Position', [0.08 0.38 0.40 0.22]);
hSpec = imagesc([-plotTime 0], [fvec(1) fvec(end)], specHistory);
set(gca, 'YDir', 'normal'); colormap(jet);
ylim([0 x_freqlim]); xlim([-plotTime 0]);
xlabel('Time [s]'); ylabel('Frequency [Hz]'); title('Spectrogram');
set(gca, 'FontSize', 12, 'Fontname', "Calibri");

% --- パワースペクトルとLPC包絡線 (左下) ---
axes('Position', [0.08 0.08 0.40 0.22]);
hPow = plot(fvec, zeros(1, Nf), 'Color', [0.5 0.5 0.5]); hold on;
hLPC = plot(fvec, zeros(1, Nf), 'k', 'LineWidth', 1.5);
hPeaks = plot(0, 0, 'ro', 'MarkerSize', 6, 'LineWidth', 2);
xlim([0 x_freqlim]); ylim([-80 40]);
xlabel('Frequency [Hz]'); ylabel('Relative Power [dB]'); title('Spectrum & Estimated Formants');
set(gca, 'FontSize', 12, 'Fontname', "Calibri"); grid off;

% --- F1-F2 マップ (右側大きく・正方形に近い) ---
axes('Position', [0.55 0.38 0.40 0.52]);
colors = lines(5);
for i = 1:5
    plot(vowel_F1F2(i,1), vowel_F1F2(i,2), 'o', 'MarkerSize', 10, 'LineWidth', 2, 'Color', colors(i,:)); hold on;
    text(vowel_F1F2(i,1)+30, vowel_F1F2(i,2), vowels{i}(1:3), 'FontSize', 14, 'FontWeight', 'bold');
end
hCurrPoint = plot(0, 0, 'kx', 'MarkerSize', 18, 'LineWidth', 3);
xlim([0 1400]); ylim([500 3500]);
xlabel('Formant 1 [Hz]'); ylabel('Formant 2 [Hz]'); title('F1-F2 plane');
set(gca, 'FontSize', 12, 'Fontname', "Calibri"); grid off;

% --- 判定結果のテキスト (右下) ---
axes('Position', [0.55 0.08 0.40 0.22]);
axis off;
hVowelText = text(0.5, 0.6, 'Please voice the vowel...', 'FontSize', 48, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
hFormantText = text(0.5, 0.2, 'F1: --- Hz, F2: --- Hz', 'FontSize', 20, 'HorizontalAlignment', 'center', 'Color', [0.3 0.3 0.3]);
hStatusText = text(0.5, 0.9, '【RUNNING】', 'FontSize', 16, 'HorizontalAlignment', 'center', 'Color', [0.3922    0.8314    0.0745], 'FontWeight', 'bold');

% --- 操作ボタンの作成 ---
uicontrol('Style', 'pushbutton', 'String', 'Start', 'Units', 'normalized', 'Position', [0.08 0.93 0.08 0.05], ...
    'FontSize', 14, 'BackgroundColor', [0.3922 0.8314 0.0745], ...
    'Callback', 'setappdata(gcf, ''is_running'', true); set(findobj(gcf, ''String'', ''【STOPPED】''), ''String'', ''【RUNNING】'', ''Color'', [0.3922 0.8314 0.0745]);');
uicontrol('Style', 'pushbutton', 'String', 'Stop', 'Units', 'normalized', 'Position', [0.17 0.93 0.08 0.05], ...
    'FontSize', 14, 'BackgroundColor', [0.6353 0.0784 0.1843],'ForegroundColor', 'w', ...
    'Callback', 'setappdata(gcf, ''is_running'', false); set(findobj(gcf, ''String'', ''【RUNNING】''), ''String'', ''【STOPPED】'', ''Color'', [0.6353 0.0784 0.1843]);');
uicontrol('Style', 'pushbutton', 'String', 'Exit', 'Units', 'normalized', 'Position', [0.26 0.93 0.08 0.05],'ForegroundColor', 'w', ...
    'FontSize', 14, 'BackgroundColor', [0.5020 0.5020 0.5020], ...
    'Callback', 'setappdata(gcf, ''run_loop'', false);');

%% 処理ループ
setappdata(fig, 'run_loop', true);
setappdata(fig, 'is_running', true);
disp('音声解析を開始します．');

lastDrawTime = tic;

try
    while getappdata(fig, 'run_loop') && ishandle(fig)
        
        if getappdata(fig, 'is_running')
            % 音声入力とバッファ更新
            audioIn = step(audioReader);
            audioBuffer = [audioBuffer(frameSize+1:end); audioIn];
            waveHistory = [waveHistory(frameSize+1:end); audioIn];
            
            % プリエンファシス
            x_pre = filter([1 -b], 1, audioBuffer);
            sig_rms = rms(audioBuffer);
            
            % スペクトログラム用FFT
            if sig_rms > rmsThreshold 
                wxx = win .* x_pre;
                X = fft(wxx, NFFT);
                powSpec = 20.0 * log10(abs(X(1:Nf)) + eps);
            else
                powSpec = -100 * ones(Nf, 1);
            end
            
            specHistory = [specHistory(:, 2:end), powSpec]; 
            
            % 描画・解析処理
            if toc(lastDrawTime) >= drawInterval
                
                if sig_rms > rmsThreshold % 判定しきい値を調整
                    % LPC分析
                    [LPa, LPg] = lpc(wxx, LPOrder);
                    LPlps = -20.0 * log10(abs(fft(LPa, NFFT)) ./ sqrt(LPg * bufferSize) + eps);
                    LPlps = LPlps(1:Nf)';
                    
                    % ピーク検出
                    [pks, locs_idx] = findpeaks(LPlps);
                    f_peaks = fvec(locs_idx);
                    
                    % 100Hz以下のピークは除外
                    valid_idx = f_peaks > 100;
                    f_peaks = f_peaks(valid_idx);
                    pks = pks(valid_idx);
                    
                    % 母音判定
                    if length(f_peaks) >= 2
                        F1 = f_peaks(1);
                        F2 = f_peaks(2);
                        
                        % ユークリッド距離で判定
                        dists = (vowel_F1F2(:,1) - F1).^2 + (vowel_F1F2(:,2) - F2).^2;
                        [~, min_idx] = min(dists);
                        detected_vowel = vowels{min_idx};
                        
                        % GUIテキスト更新
                        set(hCurrPoint, 'XData', F1, 'YData', F2);
                        set(hVowelText, 'String', detected_vowel, 'Color', 'k');
                        set(hFormantText, 'String', sprintf('F1: %.0f Hz,  F2: %.0f Hz', F1, F2));
                    else
                        set(hCurrPoint, 'XData', NaN, 'YData', NaN);
                        set(hVowelText, 'String', '...', 'Color', 'k');
                    end
                    
                    % グラフ更新
                    set(hPow, 'YData', powSpec);
                    set(hLPC, 'YData', LPlps);
                    if ~isempty(f_peaks)
                        set(hPeaks, 'XData', f_peaks, 'YData', pks);
                    else
                        set(hPeaks, 'XData', NaN, 'YData', NaN);
                    end
                    
                else
                    % 無音状態
                    set(hVowelText, 'String', '');
                    set(hFormantText, 'String', 'F1: --- Hz, F2: --- Hz');
                    set(hPow, 'YData', powSpec);
                    set(hLPC, 'YData', -100 * ones(Nf, 1));
                    set(hPeaks, 'XData', NaN, 'YData', NaN);
                    set(hCurrPoint, 'XData', NaN, 'YData', NaN);
                end
                
                % 波形とスペクトログラムの更新
                set(hWave, 'YData', waveHistory);
                set(hSpec, 'CData', specHistory);
                
                drawnow limitrate;
                lastDrawTime = tic;
            end
            
        else
            % 一時停止中
            try
                step(audioReader);
            catch
            end
            pause(0.05);
            drawnow limitrate;
        end
    end
catch ME
    release(audioReader);
    rethrow(ME);
end

% 終了処理
release(audioReader);
if ishandle(fig)
    close(fig);
end
disp('プログラムを終了しました．');

% --- References ---
% [1]Parham Mokhtari, Daisuke Morikawa, "Introducing a Japanese multi-talker database of
%    laryngeal voice qualities," in Proceedings of the Spring Meeting of the Acoustical Society of
%    Japan, Paper 2-3Q-10, pp.1165-1166. (2022)
%
% [2]Part of the development of this program was supported by gemini.
% 