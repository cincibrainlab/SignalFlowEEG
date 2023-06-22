classdef inflow_SimulateEEG < SignalFlowSuperClass
    % Description: Simulate EEG data
    % ShortTitle: Simulate EEG Signal
    % Category: Analysis
    % Tags: Simulation
    %      adapted from Michael X Cohen
    %      https://github.com/mikexcohen/NeuroscienceSourceSeparation/blob/main/ANT_temporalFiltering.m
    %      adapted from https://data.mrc.ox.ac.uk/data-set/simulated-eeg-data-generator
    %% Syntax:
    %   obj = inflow_SimulateEEG(varargin)
    %
    %% Function Specific Inputs:
    %   'num_srate' -
    %                  default: 500
    %
    %   'num_duration' -
    %                  default: 30
    %
    %   'mat_freqs' -
    %                  default: [5 10 30]
    %
    %   'num_noiselevel' -
    %                  default: 3
    %
    %   'num_nchan' -
    %                  default: 128
    %
    %   'log_showplot' -
    %                  default: false
    %
    %   'log_erp' -
    %                  default: false
    %
    %   'num_trials' -
    %                  default: 30
    %
    %   'num_addFreq' -
    %                  default: []
    %
    %% Disclaimer:
    %  This file is part of the Cincinnati Childrens Brain Lab SignalFlowEEG Pipeline
    %
    %  Please see http://github.com/cincibrainlab
    %
    %% Contact:
    %  https://github.com/cincibrainlab/SignalFlowEEG/issues

    methods
        function obj = inflow_SimulateEEG(varargin)

            % Define Custom Flow Function
            setup.flabel = 'Simulate EEG Signal';
            setup.flowMode = 'inflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end


        function EEG = run(obj)
            % run() - Process the EEG data.
            % Signal Processing Code Below

            timestamp = datestr(now, 'yymmddHHMMSS'); % timestamp
            functionstamp = mfilename; % function name for logging/output

            args.num_srate = 500;
            args.num_trials = 30;
            args.num_nchan = 128;
            args.log_erp = false;
            args.num_addFreq = [];
            args.log_showplot = false;

            % Create EEG structure
            EEG = eeg_emptyset;
            EEG.srate = args.num_srate;

            EEG.comments = sprintf('created with %s', functionstamp);
            EEG.setname = ['S' timestamp];
            EEG.filename = ['S' timestamp '.set'];
            EEG.trials = args.num_trials;
            EEG.nbchan = args.num_nchan;
            EEG.data = squeeze(zeros([EEG.nbchan EEG.trials*EEG.srate]));

            generate_continuous = @(trials,srate) obj.noise(trials*EEG.srate, 1,EEG.srate);
            generate_added_freq = @(freq, time) sin(2*pi*freq*time);

            if args.log_erp
            else % continuous data
                for i = 1 : EEG.nbchan
                    EEG.data(i,:) = generate_continuous(EEG.trials, EEG.srate);
                    if ~isempty(args.num_addFreq)
                        for fi = 1 : numel(args.num_addFreq)
                            EEG.data(i,:) = EEG.data(i,:) + generate_added_freq(args.num_addFreq(fi), 1:size(EEG.data(i,:),2));
                        end
                    end
                end
                EEG.trials;
            end

            EEG = readegilocs(EEG);
            EEG = eeg_checkset(EEG);

            if args.log_showplot
                pop_spectopo(EEG);
                pop_eegplot(EEG);
            end

            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            EEG = obj.HistoryTable(EEG, args);
            return;
            % Signal Processing Code Below
        end

    end
    methods (Static)

        function signal = noise (frames, epochs, srate)

            % function signal = noise (frames, epochs,EEG.srate)
            %
            % Function generates noise with the power spectrum of human EEG
            % Inputs:
            %  frames - number of signal frames per each trial
            %  epochs - number of simulated trials
            % EEG.srate - sampling rate of simulated signal
            % Output:
            %  signal - simulated EEG signal; vector: 1 by frames*epochs containing concatenated trials
            % Implemented by: Rafal Bogacz and Nick Yeung, Princeton Univesity, December 2002

            meanpower = [0.00151243569173697	0.000849223536944086	0.000608752425250503 ...
                0.000489867308383088	0.000423523265977786	0.000391618386509393	0.000362738792062194 ...
                0.000340569245455927	0.000343160355023564	0.000397260174112541	0.000425746453940879 ...
                0.000346931131917678	0.000294289430151734	0.000255611495931532	0.000235583560243938 ...
                0.000222742526568670	0.000213952243732669	0.000207728801970987	0.000204820204871842 ...
                0.000201717903923470	0.000200788327800687	0.000197943781977520	0.000195550571921030 ...
                0.000191312074959167	0.000186647245431341	0.000183094400053000	0.000178247683448868 ...
                0.000175988284698843	0.000171656869739803	0.000169295263974102	0.000164186511582571 ...
                0.000161186150423923	0.000159568756646949	0.000157424621923049	0.000155313331767683 ...
                0.000154694176253348	0.000152165638447053	0.000149566698255081	0.000147188323939302 ...
                0.000146533177708546	0.000145121493658231	0.000144906144100869	0.000143416297613493 ...
                0.000144491786408331	0.000141908841027976	0.000143482634006504	0.000143049549612224 ...
                0.000141165563007797	0.000142527800761601	0.000140531668311820	0.000140642278894550 ...
                0.000138159564176203	0.000138326553083662	0.000136819950846468	0.000137051416203615 ...
                0.000137326727439770	0.000137105891541355	0.000135918993566046	0.000136789083753154 ...
                0.000144840331753105	0.000135570847809515	0.000136702841990426	0.000136083067837125 ...
                0.000133392271676577	0.000132932292488171	0.000132626787059828	0.000130951806676875 ...
                0.000131944548148930	0.000130269144619112	0.000129712907357010	0.000128817718803735 ...
                0.000128068873891260	0.000129026987009852	0.000131145119722146	0.000128813051243851 ...
                0.000129327299578058	0.000127481945852502	0.000126366011391417	0.000127830483992299 ...
                0.000125903230149386	0.000126250142106203	0.000125271519631519	0.000125630757314871 ...
                0.000126959877190012	0.000125385538460308	0.000125860301742732	0.000123259391560676 ...
                0.000124788768190275	0.000123555112270985	0.000123301221103579	0.000122969277266741 ...
                0.000123238484456097	0.000121531193095858	0.000122164904223949	0.000122641847296605 ...
                0.000121279001779279	0.000122435411994741	0.000122247505651699	0.000120499303553678 ...
                0.000121017533939185	0.000121913726964212	0.000120804220816675	0.000119154793073560 ...
                0.000119216522507451	0.000119611391243747	0.000119072621468055	0.000118505610389452 ...
                0.000118462775624295	0.000120311550299626	0.000118922656327391	0.000117918481199700 ...
                0.000120233814294065	0.000119726487982067	0.000120083720065635	0.000117433607437090 ...
                0.000117780626727059	0.000119545300142496	0.000121051578111552	0.000118272269672927 ...
                0.000117591143981717	0.000117234706098935	0.000117217370076375	0.000118885430625311 ...
                0.000117501421933697	0.000118331572692417];
            sumsig = 50;	%number of sinusoids from which each simulated signal is composed of

            signal = zeros (1, epochs * frames);
            for trial = 1:epochs
                freq=0;
                range = [(trial-1)*frames+1:trial*frames];
                for i = 1:sumsig
                    freq = freq + (4*rand(1));
                    freqamp = meanpower(min (ceil(freq), 125)) / meanpower(1);
                    phase = rand(1)*2*pi;
                    signal (range) = signal (range) + sin ([1:frames]/srate*2*pi*freq + phase) * freqamp;
                end
            end
        end
    end
end
