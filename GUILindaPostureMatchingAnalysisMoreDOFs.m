%% POSTURE MATCHING ANALYSIS SCRIPT
% This script plots out a variety of possible figure for analyzing posture
% matching results

global x;
%% Add needed functions to working directory
if (ismac)
    fileSlash = '/';
else
    fileSlash = '\';
end
addpath(genpath(['..' fileSlash '..' fileSlash 'GeneralReferencedFunctions' fileSlash 'CurrentVersion']));
addpath(genpath(['..' fileSlash '..' fileSlash 'GeneralReferencedFunctions' fileSlash 'FreewareFunctions']));

%% Get Figure Position/Size
screenSize = get(0,'ScreenSize');
figurePosition = [0 50 screenSize(3) screenSize(4)-50-75];

%% Cumulative Figure Preparation
options = {'Completion Rates';'Movement Speed Histograms';'Metric Boxplots';'All Velocity Profiles (Recommended for Test sets only)';'Avg Velocity Profiles'};
[selections,ok] = listdlg('Name','Cumulative Figure Selection',...
    'PromptString','Select wanted cumulative figures:',...
    'SelectionMode','multiple','InitialValue',[],...
    'ListString',options);
if ok
    cumulativeCompletionRates = false;
    if any(selections==1)
        cumulativeCompletionRatesFig = figure('Name','Cumulative Completion Rates','Position',figurePosition);
        cumulativeCompletionRates = true;
        cumulativeCompletionRatesLegendHandles = [];
        cumulativeCompletionRatesLegendStrings = {};
    end
    cumulativeSpeedHistograms = false;
    if any(selections==2)
        cumulativeSpeedHistogramsFig = figure('Name','Cumulative Movement Speed Histograms','Position',figurePosition);
        cumulativeSpeedHistograms = true;
        cumulativeSpeedHistogramsLegendHandles = [];
        cumulativeSpeedHistogramsLegendStrings = {};
    end
    cumulativeMetricBoxplots = false;
    if any(selections==3)
        cumulativeMetricBoxplotsFig = figure('Name','Cumulative Posture Matching Metrics','Position',figurePosition);
        cumulativeMetricBoxplots = true;
    end
    if any(selections==4) || any(selections==5)
        cumulativeMovementSpeeds = {};
        cumulativect = {};
        cumulativectout = {};
        cumulativechit = {};
        cumulativeVelocityProfilesLegendStrings = {};
        previousROM = false;
        previousndof = false;
        previousdofLabels = false;
    end
    cumulativeVelocityProfiles = false;
    if any(selections==4)
        cumulativeVelocityProfilesFig = figure('Name','Cumulative Velocity Profiles','Position',figurePosition);
        cumulativeVelocityProfiles = true;
        cumulativeVelocityLimits = [0 0 0; 0 0 0];
        button = questdlg('Normalize X Axes of Cumulative Velocity Profiles?');
        switch button
            case 'Yes'
                NormalizeXAxis = true;
            case 'No'
                NormalizeXAxis = false;
            case 'Cancel'
                return;
        end
    end
    cumulativeAvgVelocityProfiles = false;
    if any(selections==5)
        cumulativeAvgVelocityProfilesFig = figure('Name','Cumulative Avg Velocity Profiles','Position',figurePosition);
        cumulativeAvgVelocityProfiles = true;
        windowBins = inputdlg('Enter the number of bins to be used for each trial average','Window Bins',1,{'20'},'on');
        if isempty(windowBins)
            cumulativeAvgVelocityProfiles = false;
        else
            windowBins = cell2mat(windowBins);
            windowBins(ismember(windowBins, '-+eEgG')) = '';
            if ~all(ismember(windowBins, '1234567890')) || isempty(windowBins)
                cumulativeAvgVelocityProfiles = false;
            else
                windowBins = sscanf(windowBins, '%u', 1);
            end
        end
    end
    
    options = {'Display Figures, Don''t Save',...
        'Display Figures, Save as .fig','Display Figures, Save as .png','Display Figures, Save as .png and .fig',...
        'Don''t Display Figures, but Save as .fig','Don''t Display Figures, but Save as .png','Don''t Display Figures, but Save as .png and .fig'};
    [selections,ok] = listdlg('Name','Display and Save?',...
        'PromptString','Select desired output:',...
        'SelectionMode','single','InitialValue',1,...
        'ListString',options);
    if ok
        displayFigs = false;
        if (selections==1)||(selections==2)||(selections==3)||(selections==4)
            displayFigs = true;
        end
        saveFigs = false;
        if (selections==2)||(selections==5)
            saveFigs = true;
            saveFormat = '.fig';
        elseif (selections==3)||(selections==6)
            saveFigs = true;
            saveFormat = '.png';
        elseif (selections==4)||(selections==7)
            saveFigs = true;
            saveFormat = {'.fig','.png'};
        end
        if (saveFigs)
            if (ismac)
                display('Select a Directory to Save Figures In');
            end
            savingDirectory = uigetdir(['..' fileSlash '..' fileSlash '..' fileSlash 'Prosthetics MR Data'],'Select a Directory to Save Figures In');
        end

        %% Main Loop
        moreData = questdlg('Would you like to add more data?','Continue?','Yes','No','No');
        while strcmp(moreData,'Yes')
            %% Get Data Path, Save Path, Labels, Wanted Figures, and DOF names
            
%             [dataFile,dataDirectory] = uigetfile(['..' fileSlash '..' fileSlash '..' fileSlash 'Prosthetics MR Data' fileSlash '*.mat'],'Select the Posture Matching Log File');
%             if isequal(dataFile,0)
%                 break;
%             end
%             load([dataDirectory fileSlash dataFile]);
            dataFile = get(x.EntriesListBox,{'Items', 'Value'});
            logLabel = inputdlg({'Posture Matching Control Name/Label'},'Data Label',1,{'S107 3DOF Agonist/Antagonist'});
            if isempty(logLabel)
                break;
            end
            options = {'Cursor vs Target';'Completion Rate';'Movement Speed Histogram';'Velocity Profile';'Posture Matching Metrics per DOF'};
            [selections,ok] = listdlg('Name','Figure Selection',...
                'PromptString','Select wanted figures for this log file:',...
                'SelectionMode','multiple','InitialValue',1,...
                'ListString',options);
            if ~ok
                break;
            end
            cursorVsTarget = any(selections==1);
            completionRate = any(selections==2);
            speedHistogram = any(selections==3);
            velocityProfile = any(selections==4);
            postureMatchingPerDOF = any(selections==5);
            firstMovementThreshold = 1;
            
            ndof = inputdlg({'Numbers of DOF'},'DOFs',1,{'4'});
            if isempty(ndof)
                break;
            end
            ndof = sscanf(ndof{1},'%u',1);
            if (ndof<1)%(ndof>3)||(ndof<1)
                error('Unsupported number of Degrees of Freedom chosen.');
            end
            if cumulativeVelocityProfiles || cumulativeAvgVelocityProfiles
                if islogical(previousndof)
                    previousndof = ndof;
                elseif (ndof~=previousndof)
                    warndlg('Number of DOFs does not equal that of previous log file, cumulative velocity profile will no longer be plotted');
                    cumulativeVelocityProfiles = false;
                    cumulativeAvgVelocityProfiles = false;
                end
            end
            
            dofPrompts = {};
            dofDefaults = {};
%             if ndof<=3
%                 dofDefaults = {'Pronation/Supination';'Wrist Flexion/Extension';'Hand Close/Open'};
%                 truetimeIndex = 2;
%                 DOF1LIndex = 3;
%                 DOF2LIndex = 4;
%                 DOF3LIndex = 5;
%                 LSourceIndex = 6;
%                 DOF1RIndex = 8;
%                 DOF2RIndex = 9;
%                 DOF3RIndex = 10;
%                 RSourceIndex = 11;
%                 DOF1ToleranceIndex = 13;
%                 DOF2ToleranceIndex = 14;
%                 DOF3ToleranceIndex = 15;
%                 TrialNumberIndex = 16;
%                 BlockNumberIndex = 17;
%                 DifficultyIndex = 18;
%                 HitIndex = 19; 
%                 LAST_DOFLIndex = DOF3LIndex;
%                 LAST_DOFRIndex = DOF3RIndex;
%                 LAST_DOFToleranceIndex = DOF3ToleranceIndex;
%             else
                if ndof == 3
                    dofDefaults = {'Pronation/Supination';'Wrist Flexion/Extension';'Hand Close/Open'};
                elseif ndof == 6
                    dofDefaults = {'Pronation/Supination';'Wrist Flexion/Extension';'Thumb Close/Open';'Finger Close/Open';'Thump opposition';'Thumb flex/ext'};
                end
                truetimeIndex = 2;
                DOF1LIndex = 3;
                DOF2LIndex = 4;
                DOF3LIndex = 5;
                DOF4LIndex = 6;
                DOF5LIndex = 7;
                DOF6LIndex = 8;
                LSourceIndex = 9;
                DOF1RIndex = 11;
                DOF2RIndex = 12;
                DOF3RIndex = 13;
                DOF4RIndex = 14;
                DOF5RIndex = 15;
                DOF6RIndex = 16;
                RSourceIndex = 17;
                DOF1ToleranceIndex = 19;
                DOF2ToleranceIndex = 20;
                DOF3ToleranceIndex = 21;
                DOF4ToleranceIndex = 22;
                DOF5ToleranceIndex = 23;
                DOF6ToleranceIndex = 24;
                TrialNumberIndex = 25;
                BlockNumberIndex = 26;
                DifficultyIndex = 27;
                HitIndex = 28;
                LAST_DOFLIndex = DOF6LIndex;
                LAST_DOFRIndex = DOF6RIndex;
                LAST_DOFToleranceIndex = DOF6ToleranceIndex; 
%             end
            for i = 1 : ndof
                dofPrompts{end+1} = ['DOF ' num2str(i) ' Label'];
            end
            dofLabels = inputdlg(dofPrompts(1:ndof),'DOF Labels',1,dofDefaults(1:ndof));
            if isempty(dofLabels)
                break;
            end
            
            
            handvisDOFIndices = [];
            dofPrompts = {};
            dofDefaults = {};
            ROMdefaults = {};
            for i = 1 : ndof
                dofPrompts{end+1} = ['DOF ' num2str(i) ' HandvisIndex (1-6)'];
                if ~isempty(strfind(lower(dofLabels{i}),'ation'))
                    dofDefaults{end+1} = '1';
                    ROMdefaults{end+1} = ['0'];
                    ROMdefaults{end+1} = ['180'];
                elseif ~isempty(strfind(lower(dofLabels{i}),'wrist'))
                    dofDefaults{end+1} = '2';
                    ROMdefaults{end+1} = ['-60'];
                    ROMdefaults{end+1} = ['70'];
                elseif ~isempty(strfind(lower(dofLabels{i}),'thumb'))
                    if ~isempty(strfind(lower(dofLabels{i}),'duction'))
                        dofDefaults{end+1} = '3';
                    else
                        if ndof>3
                            dofDefaults{end+1} = '4';
                        else
                            dofDefaults{end+1} = num2str(i);
                        end
                    end
                elseif ~isempty(strfind(lower(dofLabels{i}),'index')) && ndof>3
                    dofDefaults{end+1} = '5';
                elseif (~isempty(strfind(lower(dofLabels{i}),'mrp')) || ~isempty(strfind(lower(dofLabels{i}),'middle')) || ~isempty(strfind(lower(dofLabels{i}),'ring')) || ~isempty(strfind(lower(dofLabels{i}),'pinky')) || ~isempty(strfind(lower(dofLabels{i}),'finger'))) && ndof>3
                    dofDefaults{end+1} = '6';
                else
                    dofDefaults{end+1} = num2str(i);
                end
            end
            handvisDOFIndicesStrings = inputdlg(dofPrompts(1:ndof),'DOF Handvis Indices',1,dofDefaults(1:ndof));
            if isempty(handvisDOFIndicesStrings)
                break;
            end
            for i=1:length(handvisDOFIndicesStrings)
                handvisDOFIndices = [handvisDOFIndices sscanf(handvisDOFIndicesStrings{i},'%g',1)];
            end
            
            if cumulativeVelocityProfiles || cumulativeAvgVelocityProfiles
                if islogical(previousdofLabels)
                    previousdofLabels = dofLabels;
                elseif (~isequal(previousdofLabels,dofLabels))
                    warndlg('Labels of DOFs does not equal that of previous log file, cumulative velocity profile will no longer be plotted');
                    cumulativeVelocityProfiles = false;
                    cumulativeAvgVelocityProfiles = false;
                end
            end            
            
            ROMprompts = {};
            for i = 1:ndof
                ROMprompts{end+1} = ['DOF' num2str(i) ' Lower Bound'];
                ROMprompts{end+1} = ['DOF' num2str(i) ' Higher Bound'];
                if length(ROMdefaults)<2*i
                    ROMdefaults{end+1} = ['0'];
                    ROMdefaults{end+1} = ['100'];
                end
            end
            if ndof==3 && isequal(dofLabels,dofDefaults)
                ROMdefaults = {'0';'180';'-60';'70';'0';'100'};
            end
            ROMstring = inputdlg(ROMprompts(1:2*ndof),'ROM',1,ROMdefaults(1:2*ndof));
            if isempty(ROMstring)
                break;
            end
            ROM = [];
            for i=1:2:length(ROMstring)
                ROM = [ROM [sscanf(ROMstring{i},'%g',1);sscanf(ROMstring{i+1},'%g',1)]];
            end
            
            
            if cumulativeVelocityProfiles || cumulativeAvgVelocityProfiles
                if islogical(previousROM)
                    previousROM = ROM;
                elseif (~isequal(previousROM,ROM))
                    warndlg('Ranges of DOFs does not equal that of previous log file, cumulative velocity profile will no longer be plotted');
                    cumulativeVelocityProfiles = false;
                    cumulativeAvgVelocityProfiles = false;
                end
            end
            
            if any(isnan(ndof))||any(any(isnan(ROM)))||any(isempty(ndof))||any(any(isempty(ROM)))
                error('Bad input provided.');
            end
            clear ROMstring dofPrompts dofDefaults ROMprompts ROMdefaults

            %% Parse Data
            % For all the more recent work, the following should be true
            % The ROM for the trials was
            % forearm: 0->180deg
            % wrist: -60->70deg
            % hand: 0->100%
            % the tolerance was +/-15% of ROM 

            % Loaded handvis data
            %  1. simulation time (s)
            %  2. truetime (s)
            %  3. forearm pron L (deg)
            %  4. wrist flexion/extension (deg)
            %  5. grasp aperture L (%)
            %  6. source L (1=EMG controlled, 2=kinematic, 3=target) *this will always be the target, except for those amputated on the left
            %  7. grasp type L (1=lateral, 2=palmer, 3=power) *you can ignore this, should be palmar
            %  8. forearm pron R (deg)
            %  9. wrist flexion/extension (deg)
            % 10. grasp aperture R (%)
            % 11. source R (1=EMG controlled, 2=kinematic, 3=target) *this will always be the EMG controlled hand, except for those amputated on the left
            % 12. grasp type R (1=lateral, 2=palmer, 3=power) *you can ignore this
            % 13. forearm pron tolerance (deg) 
            % 14. thumb opposition tolerance (deg)
            % 15. grasp aperture tolerance (%)
            % 16. trial#
            % 17. block#
            % 18. difficulty (% tolerance of ROM)
            % 19. hit (1=all DOF have been on target for required dwell time, indicates successful end of trial)
            % 20. forearm pron tolerance raw prediction (deg)  *In these trials, this always matches row 9 because we didn't apply any filtering on the host
            % 21. thumb opposition tolerance raw prediction (deg) *In these trials, this always matches row 10 because we didn't apply any filtering on the host
            % 22. grasp aperture tolerance raw prediction (%) *In these trials, this always matches row 11 because we didn't apply any filtering on the host           

% Joris modified the model to support up to 6DOF:
% 	1. Pronation
% 	2. Wrist Flex
% 	3. Thumb Abduction
% 	4. Thumb Flexion
% 	5. Index Flexion
%   6. MRP (middle ring pinky) flexion
            
%  1. simulation time (s)
%  2. truetime (s)
%  3. DOF1 L (%)
%  4. DOF2 L (%)
%  5. DOF3 L (%)
%  6. DOF4 L (%)
%  7. DOF5 L (%)
%  8. DOF6 L (%)
%  9. source L (1=EMG controlled, 2=kinematic, 3=target)
% 10. grasp type L (1=lateral, 2=palmer, 3=power) IS THIS STILL AROUND?
% 11. DOF1 R (%)
% 12. DOF2 R (%)
% 13. DOF3 R (%)
% 14. DOF4 R (%)
% 15. DOF5 R (%)
% 16. DOF6 R (%)
% 17. source R (1=EMG controlled, 2=kinematic, 3=target)
% 18. grasp type R (1=lateral, 2=palmer, 3=power)
% 19. DOF1 tolerance (%) 
% 20. DOF2 tolerance (%)
% 21. DOF3 tolerance (%)
% 22. DOF4 tolerance (%) 
% 23. DOF5 tolerance (%)
% 24. DOF6 tolerance (%)
% 25. trial#
% 26. block#
% 27. difficulty (% tolerance of ROM)
% 28. hit (1=all DOF have been on target for required dwell time, indicates successful end of trial)
% 29. DOF1 tolerance raw prediction (%)
% 30. DOF2 tolerance raw prediction (%)
% 31. DOF3 tolerance raw prediction (%)
% 32. DOF4 tolerance raw prediction (%)
% 33. DOF5 tolerance raw prediction (%)
% 34. DOF6 tolerance raw prediction (%)
            
            %% Data Parsing and Preparation
            % set variables based on rows in log file (above)
            t = handvis(truetimeIndex,:);
            fill = 1;
            if handvis(LSourceIndex,end) == 3 % Check handedness
                target = handvis([DOF1LIndex:LAST_DOFLIndex],:);
                cursor   = handvis([DOF1RIndex:LAST_DOFRIndex],:);
            else
                if handvis(RSourceIndex,end) ~= 3, fill = 0; end;    
                target = handvis([DOF1RIndex:LAST_DOFRIndex],:);
                cursor   = handvis([DOF1LIndex:LAST_DOFLIndex],:);
            end
            nsamp = size(handvis,2);
            trial = handvis(TrialNumberIndex,:);
            block = handvis(BlockNumberIndex,:);
            difficulty = handvis(DifficultyIndex,:); % The tolerance of 15%
            if ~sum(difficulty)
                difficulty = 15*ones(size(difficulty));
            end
            hit = handvis(HitIndex,:); % 1=all DOF have been on target for required dwell time, indicates successful end of trial
            tol = handvis([DOF1ToleranceIndex:LAST_DOFToleranceIndex],:);
            timeout = 30; %TODO: Import settings?

            % Remove first few data points with incomplete trial or block numbering
            removeZeroesIndex = max(find(block,1),find(trial,1));
            if ~isempty(removeZeroesIndex)
                t = t(removeZeroesIndex:end);
                target = target(:,removeZeroesIndex:end);
                cursor = cursor(:,removeZeroesIndex:end);
                nsamp = nsamp - (removeZeroesIndex-1);
                trial = trial(removeZeroesIndex:end);
                block = block(removeZeroesIndex:end);
                hit = hit(removeZeroesIndex:end);
                tol = tol(:,removeZeroesIndex:end);
                difficulty = difficulty(removeZeroesIndex:end);
            end

            % Normalize block and trial numbering
            trial = trial-(trial(1)-1);
            block = block-(block(1)-1);
            nblocks = max(block);
            ntrials = [];
            starttrials = [];
            for i=1:nblocks
                ntrials(i) = max(trial(find(block==i)));
                starttrials(i) = min(trial(find(block==i)));
            end

            %% Remove any unused DOFs
            if ndof<6
%                 keptDOFs = [];
%                 for k = 1:3
%                     if any(target(k,:)~=0)
%                         keptDOFs = [keptDOFs k];
%                     end
%                 end
%                 if (ndof)~=length(keptDOFs)
%                     error('Could not find removable DOF.');
%                 end
%                 target = target(keptDOFs,:);
%                 cursor = cursor(keptDOFs,:);
%                 tol = tol(keptDOFs,:);
%                 difficulty = difficulty(keptDOFs,:);
                target = target(handvisDOFIndices,:);
                cursor = cursor(handvisDOFIndices,:);
                tol = tol(handvisDOFIndices,:);
            end

            %% Break data up into blocks (rows) and trials (columns)
            ct = cell(nblocks, max([(ntrials-starttrials) diff(ntrials)]));
            ctarget = cell(nblocks, max([(ntrials-starttrials) diff(ntrials)]));
            ccursor = cell(nblocks, max([(ntrials-starttrials) diff(ntrials)]));
            nctarget = cell(nblocks, max([(ntrials-starttrials) diff(ntrials)])); % Target normalized to ROM (0-100)
            nccursor = cell(nblocks, max([(ntrials-starttrials) diff(ntrials)])); % Cursor normalized to ROM (0-100)
            ctol = cell(nblocks, max([(ntrials-starttrials) diff(ntrials)])); % Tolerance in ROM by degrees (18, 18, and 15)
            chit = cell(nblocks, max([(ntrials-starttrials) diff(ntrials)])); % 1 to hit
            cdifficulty = cell(nblocks, max([(ntrials-starttrials) diff(ntrials)])); % Tolerance of 15%
            ctout = cell(nblocks, max([(ntrials-starttrials) diff(ntrials)]));
            for i=1:nblocks
               for j=1:ntrials(i)-(starttrials(i)-1) 
                   k = intersect(find(trial == (j+(starttrials(i)-1))),find(block == i));
                   ct{i,j} = t(k);
                   ct{i,j} = ct{i,j}-ct{i,j}(1);
                   ctarget{i,j} = target(:,k);
                   ccursor{i,j} = cursor(:,k);
                   %normalized by ROM to 0-100
                   nctarget{i,j} = (target(:,k)-repmat(ROM(1,:)',1, length(k)))./repmat(ROM(2,:)'-ROM(1,:)',1,length(k))*100;
                   nccursor{i,j} = (cursor(:,k)-repmat(ROM(1,:)',1, length(k)))./repmat(ROM(2,:)'-ROM(1,:)',1,length(k))*100;
                   ctol{i,j} = tol(:,k);
                   chit{i,j} = hit(:,k);
                   cdifficulty{i,j} = difficulty(k);

                   ctout{i,j} = nan(size(ct{i,j}));
                   if ~chit{i,j}(end), ctout{i,j}(end) =  1; end
               end
            end

            %% Calculate metrics using normalized cursor/targets, including overshoots
            patheff = zeros(nblocks, max([ntrials-(starttrials-1) diff(ntrials)]));
            movementSpeeds = cell(nblocks, max([ntrials-(starttrials-1) diff(ntrials)]));
            movementSpeedTrialAverages = zeros(nblocks, max([ntrials-(starttrials-1) diff(ntrials)]), ndof);
            tolerance = zeros(nblocks,ndof);
            difficulty = zeros(nblocks,1);
            success = zeros(nblocks, max([ntrials-(starttrials-1) diff(ntrials)]));
            timetotarget = zeros(nblocks, max([ntrials-(starttrials-1) diff(ntrials)]));
            successrate = zeros(nblocks, 1);
            overshoots = zeros(nblocks, max([ntrials-(starttrials-1) diff(ntrials)]), ndof);
            movementStart = zeros(nblocks, max([ntrials-(starttrials-1) diff(ntrials)]), ndof);
            for i=1:nblocks
                for j = 1:ntrials(i)-(starttrials(i)-1)
                    if chit{i,j}(end)
                        success(i,j) = 1;
                    end
                    %timetotarget is actually the trial time...if they didn't reach target, timetotarget=timeout 
                    timetotarget(i,j) = ct{i,j}(end);

                    %Get the actual path length
                    pathdiff = abs(diff(nccursor{i,j},1,2)); %first order difference across rows
                    %pathdiff(pathdiff > 180) = 360 - pathdiff(pathdiff > 180);  %account for infinite wrist rotation
                    %first get the length for each segment, then sum up lengths
                    pathlength = sum(sqrt(sum(pathdiff.^2))); 

                    %movementSpeeds{i,j} = [[0;0;0] pathdiff./[diff(ct{i,j});diff(ct{i,j});diff(ct{i,j})]];
                    movementSpeeds{i,j} = [zeros(ndof,1) pathdiff./repmat(diff(ct{i,j}),ndof,1)];
                    %movementSpeedTrialAverages(i,j,:) = mean(pathdiff./[diff(ct{i,j});diff(ct{i,j});diff(ct{i,j})],2);
                    movementSpeedTrialAverages(i,j,:) = mean(pathdiff./repmat(diff(ct{i,j}),ndof,1),2);
                    
                    %Get the minimum pathlength
                    pathdiff = abs(nctarget{i,j}(:,1) - nccursor{i,j}(:,1));
                    %pathdiff(pathdiff > 180) = 360 - pathdiff(pathdiff > 180);  %account for infinite wrist rotation 
                    minpathlength = sqrt(sum(pathdiff.^2)); 

                    if ~success(i,j)
                        %get distance between target and cursor at end of trial
                        initialdist = minpathlength;
                        finaldist = sqrt(sum((nctarget{i,j}(:,end) - nccursor{i,j}(:,end)).^2));
                        if initialdist == finaldist %avoid divide by 0
                            pathlength = 0; %no movement occured
                        else
                            %assume pathlength (had they reached target)
                            pathlength = pathlength * initialdist/(initialdist-finaldist);
                            %if initialdist<finaldist, then pathlength will be negative,
                            %and patheff will be negative
                        end
                    end

                    if pathlength == 0 %avoid divide by 0
                        patheff(i,j) = 0;
                    else
                        patheff(i,j) = minpathlength/pathlength*100;
                        %saturate at 0 and 100%
                        patheff(i,j) = min(patheff(i,j), 100); 
                        patheff(i,j) = max(patheff(i,j), 0); 
                    end
                    %Alternative: Path inefficiency (work wasted): patheff(i,j) = max((pathlength-minpathlength)/minpathlength*100, 0); 

                    % Calculate overshoots and the first sign of movement
                    for k = 1:ndof
                        % First movement
                        if ~isempty(find(movementSpeeds{i,j}(k,:)>firstMovementThreshold,1))
                            movementStart(i,j,k) = find(movementSpeeds{i,j}(k,:)>firstMovementThreshold,1);
                        else
                            movementStart(i,j,k) = 1;
                        end
                        movementStart(i,j,k) = ct{i,j}(movementStart(i,j,k));
                        
                        % Overshoots
                        inRange = ((nccursor{i,j}(k,1)<=nctarget{i,j}(k,1)+cdifficulty{i,j}(1))&&(nccursor{i,j}(k,1)>=nctarget{i,j}(k,1)-cdifficulty{i,j}(1)));
                        previousSide = sign(nccursor{i,j}(k,1)-nctarget{i,j}(k,1))*(~inRange); 
                        for index = 1:length(nccursor{i,j})
                            inRange = ((nccursor{i,j}(k,index)<=nctarget{i,j}(k,index)+cdifficulty{i,j}(index))&&(nccursor{i,j}(k,index)>=nctarget{i,j}(k,index)-cdifficulty{i,j}(index)));
                            currentSide = sign(nccursor{i,j}(k,index)-nctarget{i,j}(k,index))*(~inRange);
                            if (previousSide==0)
                                previousSide = currentSide;
                            elseif ~inRange&&(currentSide~=previousSide)
                                overshoots(i,j,k) = overshoots(i,j,k)+1;
                                previousSide = currentSide;
                            end
                        end
                    end
               end
               tolerance(i,:)= ctol{i,1}(:,1)';
               difficulty(i)= cdifficulty{i,1}(1);
            end
            timeuse = timetotarget/timeout*100;

            %% Calculate averaged metrics
            oneDimensionalPathEff = [];
            oneDimensionalTimeToTarget = [];
            oneDimensionalTrialAvgMovementSpeedDOFAveraged = [];
            oneDimensionalOvershootDOFSummed = [];
            oneDimensionalSuccess = [];
            for i = 1:nblocks
                oneDimensionalPathEff = [oneDimensionalPathEff patheff(i,1:ntrials(i)-(starttrials(i)-1))];
                oneDimensionalTimeToTarget = [oneDimensionalTimeToTarget timetotarget(i,1:ntrials(i)-(starttrials(i)-1))]; %CHANGE THIS BACK TO timeuse if wanting it as a percent
                oneDimensionalTrialAvgMovementSpeedDOFAveraged = [oneDimensionalTrialAvgMovementSpeedDOFAveraged mean(movementSpeedTrialAverages(i,1:ntrials(i)-(starttrials(i)-1),:),3)];
                oneDimensionalOvershootDOFSummed = [oneDimensionalOvershootDOFSummed sum(overshoots(i,1:ntrials(i)-(starttrials(i)-1),:),3)];
                oneDimensionalSuccess = [oneDimensionalSuccess success(i,1:ntrials(i)-(starttrials(i)-1))];
            end
            meanpatheff = mean(oneDimensionalPathEff);
            stdvpatheff = std(oneDimensionalPathEff);
            meantimetotarget = mean(oneDimensionalTimeToTarget);
            stdvtimetoTarget = std(oneDimensionalTimeToTarget);
            meanmovementspeed = mean(oneDimensionalTrialAvgMovementSpeedDOFAveraged);
            stdvmovementspeed = std(oneDimensionalTrialAvgMovementSpeedDOFAveraged);
            meanovershoot = mean(oneDimensionalOvershootDOFSummed);
            stdvovershoot = std(oneDimensionalOvershootDOFSummed);
            successrate = sum(oneDimensionalSuccess)/sum(ntrials-(starttrials-1))*100;

            %% Plot Cursor vs Target for all DOFs
            if cursorVsTarget
                h = figure('Name',[cell2mat(logLabel) ' Cursor vs Targets'],'Position',figurePosition);

                tend = zeros(1, nblocks+1);
                % Each dof is a separate subplot
                for k=1:ndof
                    % Plot normalized curves (all 0-100%)
                    toff = 0;
                    for i = 1:nblocks
                        for j = 1:ntrials(i)-(starttrials(i)-1)
                            subplot(ndof,1,k),
                            %plot targets +/- tolerance as filled areas JML
                            jbfill(ct{i,j}+toff, nctarget{i,j}(k,:)+difficulty(i), nctarget{i,j}(k,:)-difficulty(i), [.35 .35 .75], 'none'); hold on;
                            %plot cursor signal
                            plot(ct{i,j}+toff, nccursor{i,j}(k,:), 'k');
                            %plot 'X' at end of target if unsuccessful
                            plot(ct{i,j}+toff, ctout{i,j}.*nctarget{i,j}(k,:), 'rx');
                            %adjust toffset by length of current trial
                            toff = ct{i,j}(end)+toff;
                        end
                        if k==1,
                            title(['Cursor vs Targets for ' cell2mat(logLabel)]);
                            %save the end time for the block (same for each dof)
                            tend(i+1)=toff;
                            %label the blocks (only above first subplot)
                            text(mean([tend(i) tend(i+1)]), 110, num2str(i), 'HorizontalAlignment', 'Center', 'Color', 'r')
                        end
                         %mark the beginning and end of each block on each subplot
                         plot([tend(i+1) tend(i+1)], [0 100], 'r');
                    end
                    %plot scale indicators for time and dof angles
                    plot([toff+10 toff+10], [0 100], 'k', 'LineWidth', 3); 

                    if (ROM(1,k)==0) && (ROM(2,k)==100)
                        text(toff+20, 0, [num2str(ROM(1,k)) '%'], 'VerticalAlignment', 'Middle', 'HorizontalAlignment', 'Left');
                        text(toff+20, 100, [num2str(ROM(2,k)) '%'], 'VerticalAlignment', 'Middle', 'HorizontalAlignment', 'Left');
                    else
                        text(toff+20, 0, [num2str(ROM(1,k)) '\circ'], 'VerticalAlignment', 'Middle', 'HorizontalAlignment', 'Left');
                        text(toff+20, 100, [num2str(ROM(2,k)) '\circ'], 'VerticalAlignment', 'Middle', 'HorizontalAlignment', 'Left');
                    end

                    %make axes slightly bigger than necessary to accomodate scale
                    %indicators (add space to right and below)
                    axis([0 toff+20 0-20 100]);  
                    axis off;
                    plot([0 60], [-10 -10], 'k', 'LineWidth', 3); 
                    text(30, -15, '60s', 'VerticalAlignment', 'Top', 'HorizontalAlignment', 'Center')
                    %label the subplot (can't use ylabel, because axis is hidden)
                    text(0, 50, dofLabels(k), 'VerticalAlignment', 'Middle', 'HorizontalAlignment', 'Right', 'FontWeight', 'bold')
                    %set background color to white (default is gray)
                    set(gcf, 'Color', [1 1 1])
                    hold off;
                end
                if saveFigs
                    if iscell(saveFormat)
                        for i = 1:length(saveFormat)
                            saveas(h,[savingDirectory fileSlash strrep(get(h,'Name'),'/','_') saveFormat{i}]);
                        end
                    else
                        saveas(h,[savingDirectory fileSlash strrep(get(h,'Name'),'/','_') saveFormat]);
                    end
                end
                if ~displayFigs
                    close(h)
                end
            end

            %% Plot this log's completion rate vs seconds
            if completionRate || cumulativeCompletionRates
                oneDimensionalTimeToTarget = [];
                for i = 1:nblocks
                    oneDimensionalTimeToTarget =[oneDimensionalTimeToTarget timetotarget(i,1:ntrials(i)-(starttrials(i)-1))];
                end
                sortedtimetotarget = sort(oneDimensionalTimeToTarget);
                y = zeros(1,sum(ntrials-(starttrials-1)));
                if length(sortedtimetotarget)~=length(y)
                    error('Dimensionality Error');
                end
                for i = 1:length(y)
                    y(i) = 100*(sum((sortedtimetotarget<=sortedtimetotarget(i)))/length(y));
                end
                clear oneDimensionalTimeToTarget
            end
            if completionRate
                h = figure('Name',[cell2mat(logLabel) ' Completion Rate'],'Position',figurePosition);
                scatter(sortedtimetotarget,y);
                legend(logLabel);
                axis([0 timeout 0 100]);
                ylabel('% Trials Complete');
                xlabel('Seconds');
                title([cell2mat(logLabel) ' Completion Rate']);
                if saveFigs
                    if iscell(saveFormat)
                        for i = 1:length(saveFormat)
                            saveas(h,[savingDirectory fileSlash strrep(get(h,'Name'),'/','_') saveFormat{i}]);
                        end
                    else
                        saveas(h,[savingDirectory fileSlash strrep(get(h,'Name'),'/','_') saveFormat]);
                    end
                end
                if ~displayFigs
                    close(h)
                end
            end

            %% Plot this log's speed histogram
            if speedHistogram
                h = figure('Name',[cell2mat(logLabel) ' Movement Speed Histogram'],'Position',figurePosition);
                oneDimensionalAvgedMovementSpeeds = [];
                for i = 1:nblocks
                    for j = 1:ntrials(i)-(starttrials(i)-1)
                        oneDimensionalAvgedMovementSpeeds =[oneDimensionalAvgedMovementSpeeds mean(movementSpeeds{i,j}(:,:),1)];
                    end
                end
                h2 = histogram(oneDimensionalAvgedMovementSpeeds);
                h2.Normalization = 'probability';
                legend(logLabel);
                ylabel('Probability');
                xlabel('% of Range of Motion per Second (as Averaged Across All DOFs)');
                title([cell2mat(logLabel) ' Movement Speed Histogram']);
                clear oneDimensionalAvgedMovementSpeeds;  
                if saveFigs
                    if iscell(saveFormat)
                        for i = 1:length(saveFormat)
                            saveas(h,[savingDirectory fileSlash strrep(get(h,'Name'),'/','_') saveFormat{i}]);
                        end
                    else
                        saveas(h,[savingDirectory fileSlash strrep(get(h,'Name'),'/','_') saveFormat]);
                    end
                end
                if ~displayFigs
                    close(h)
                end
            end
            
            %% Plot this log's Posture Matching metrics
            if postureMatchingPerDOF
                h = figure('Name',[cell2mat(logLabel) ' Posture Matching Metrics per DOF'],'Position',figurePosition);
                
                overshootsPerDOFmeans = NaN(1,ndof);
                overshootsPerDOFstderr = NaN(1,ndof);
                movementStartPerDOFmeans = NaN(1,ndof);
                movementStartPerDOFstderr = NaN(1,ndof);
                movementSpeedAveragePerDOFmeans = NaN(1,ndof);
                movementSpeedAveragePerDOFstderr = NaN(1,ndof);
                
                for k = 1:ndof
                    currentDOFovershoots = [];
                    currentDOFMovementStart = [];
                    currentDOFMovementSpeedAverages = [];
                    for i = 1:nblocks
                        for j = 1:ntrials(i)-(starttrials(i)-1)
                            currentDOFovershoots = [currentDOFovershoots overshoots(i,j,k)];
                            currentDOFMovementStart = [currentDOFMovementStart movementStart(i,j,k)];
                            currentDOFMovementSpeedAverages = [currentDOFMovementSpeedAverages movementSpeedTrialAverages(i,j,k)];
                        end
                    end
                    overshootsPerDOFmeans(k) = mean(currentDOFovershoots);
                    overshootsPerDOFstderr(k) = std(currentDOFovershoots)/sqrt(sum(ntrials-(starttrials-1)));
                    movementStartPerDOFmeans(k) = mean(currentDOFMovementStart);
                    movementStartPerDOFstderr(k) = std(currentDOFMovementStart)/sqrt(sum(ntrials-(starttrials-1)));
                    movementSpeedAveragePerDOFmeans(k) = mean(currentDOFMovementSpeedAverages);
                    movementSpeedAveragePerDOFstderr(k) = std(currentDOFMovementSpeedAverages)/sqrt(sum(ntrials-(starttrials-1)));
                end
                
                % Plot overshoots
                subplot(1,3,1);
                handle=barweb(overshootsPerDOFmeans,overshootsPerDOFstderr, [], [], 'Overshoots', [], 'Average Overshoots per Trial',[],[],dofLabels);
                
                % Plot Movement Start (note threshold)
                subplot(1,3,2);
                handle=barweb(movementStartPerDOFmeans,movementStartPerDOFstderr, [], [], 'Start of Movement', [], 's',[],[]);
                
                % Plot Avg Movement Speed
                subplot(1,3,3);
                handle=barweb(movementSpeedAveragePerDOFmeans,movementSpeedAveragePerDOFstderr, [], [], 'Average Movement Speed per Trial', [], '% of Range of Motion per Second',[],[]);

                if saveFigs
                    if iscell(saveFormat)
                        for i = 1:length(saveFormat)
                            saveas(h,[savingDirectory fileSlash strrep(get(h,'Name'),'/','_') saveFormat{i}]);
                        end
                    else
                        saveas(h,[savingDirectory fileSlash strrep(get(h,'Name'),'/','_') saveFormat]);
                    end
                end
                if ~displayFigs
                    close(h)
                end   
            end
            
            %% Plot this log's velocity (speed) profile
            if velocityProfile || cumulativeVelocityProfiles || cumulativeAvgVelocityProfiles
                % Find speed Maxes and Mins 
                velocityLimits = zeros(2,ndof);
                for k=1:ndof
                    for i = 1:nblocks
                        for j = 1:ntrials(i)-(starttrials(i)-1)
                            %search for maxes and mins for plotting limits
                            velocityLimits(:,k) = [min([velocityLimits(1,k) movementSpeeds{i,j}(k,:)]); max([velocityLimits(2,k) movementSpeeds{i,j}(k,:)])];
                            if cumulativeVelocityProfiles
                                cumulativeVelocityLimits(:,k) = [min([cumulativeVelocityLimits(1,k) velocityLimits(1,k)]); max([cumulativeVelocityLimits(2,k) velocityLimits(2,k)]); ];
                            end
                        end
                    end
                end
            end
            
            if cumulativeVelocityProfiles || cumulativeAvgVelocityProfiles
                cumulativeVelocityProfilesLegendStrings = [cumulativeVelocityProfilesLegendStrings logLabel];
                cumulativeMovementSpeeds{end+1}=movementSpeeds;
                cumulativect{end+1}=ct;
                cumulativectout{end+1}=ctout;
                cumulativechit{end+1}=chit;
            end
            
            if velocityProfile
                h = figure('Name',[cell2mat(logLabel) ' Velocity Profile'],'Position',figurePosition);

                tend = zeros(1, nblocks+1);
                
                % Normalized (0-100) movementSpeeds
                nMovementSpeeds = cell(nblocks, max([ntrials-(starttrials-1) diff(ntrials)]));
                for i = 1:nblocks
                    for j = 1:ntrials(i)-(starttrials(i)-1)
                        temp = [];
                        for k = 1:ndof
                            temp = [temp; ((movementSpeeds{i,j}(k,:)-velocityLimits(1,k))/(velocityLimits(2,k)-velocityLimits(1,k)))*100];
                        end
                        nMovementSpeeds{i,j} = temp;
                    end
                end
                
                % Each dof is a separate subplot
                for k=1:ndof
                    fillPlot = false;
                    toff = 0;
                    for i = 1:nblocks
                        for j = 1:ntrials(i)-(starttrials(i)-1)                            
                            subplot(ndof,1,k);
                            %plot shade to help distinguish trials
                            if fillPlot
                                jbfill(ct{i,j}+toff, 100*ones(1,length(ct{i,j}+toff)), zeros(1,length(ct{i,j}+toff)), [.35 .35 .75], 'none'); hold on;
                                fillPlot = false;
                            else
                                fillPlot = true;
                            end
                            %plot velocity profile
                            plot(ct{i,j}+toff, nMovementSpeeds{i,j}(k,:), 'k');
                            %plot 'X' at end of target if unsuccessful
                            plot(ct{i,j}+toff, ctout{i,j}.*nMovementSpeeds{i,j}(k,:), 'rx');
                            %adjust toffset by length of current trial
                            toff = ct{i,j}(end)+toff;
                        end
                        if k==1,
                            title(['Velocity Profile for ' cell2mat(logLabel)]);
                            %save the end time for the block (same for each dof)
                            tend(i+1)=toff;
                            %label the blocks (only above first subplot)
                            text(mean([tend(i) tend(i+1)]), 110, num2str(i), 'HorizontalAlignment', 'Center', 'Color', 'r')
                        end
                         %mark the beginning and end of each block on each subplot
                         plot([tend(i+1) tend(i+1)], [0 100], 'r');
                    end
                    %plot scale indicators for time and dof angles
                    plot([toff+10 toff+10], [0 100], 'k', 'LineWidth', 3); 
                    
                    text(toff+20, 0, [num2str(velocityLimits(1,k)) '% ROM/s'], 'VerticalAlignment', 'Middle', 'HorizontalAlignment', 'Left');
                    text(toff+20, 100, [num2str(velocityLimits(2,k)) '% ROM/s'], 'VerticalAlignment', 'Middle', 'HorizontalAlignment', 'Left');

                    %make axes slightly bigger than necessary to accomodate scale
                    %indicators (add space to right and below)
                    axis([0 toff+20 0-20 100]);  
                    axis off;
                    plot([0 60], [-10 -10], 'k', 'LineWidth', 3); 
                    text(30, -15, '60s', 'VerticalAlignment', 'Top', 'HorizontalAlignment', 'Center')
                    %label the subplot (can't use ylabel, because axis is hidden)
                    text(0, 50, dofLabels(k), 'VerticalAlignment', 'Middle', 'HorizontalAlignment', 'Right', 'FontWeight', 'bold')
                    %set background color to white (default is gray)
                    set(gcf, 'Color', [1 1 1])
                    hold off;
                end
                if saveFigs
                    if iscell(saveFormat)
                        for i = 1:length(saveFormat)
                            saveas(h,[savingDirectory fileSlash strrep(get(h,'Name'),'/','_') saveFormat{i}]);
                        end
                    else
                        saveas(h,[savingDirectory fileSlash strrep(get(h,'Name'),'/','_') saveFormat]);
                    end
                end
                if ~displayFigs
                    close(h)
                end
            end

            %% Cumulative Completion Rate Plot
            if cumulativeCompletionRates
                cumulativeCompletionRatesLegendStrings = [cumulativeCompletionRatesLegendStrings logLabel];
                set(0, 'CurrentFigure', cumulativeCompletionRatesFig)
                hold on;
                h = scatter(sortedtimetotarget,y);
                cumulativeCompletionRatesLegendHandles = [cumulativeCompletionRatesLegendHandles h];
                hold off;
            end

            %% Cumulative Speed Histogram
            if cumulativeSpeedHistograms
                cumulativeSpeedHistogramsLegendStrings = [cumulativeSpeedHistogramsLegendStrings logLabel];
                set(0, 'CurrentFigure', cumulativeSpeedHistogramsFig)
                oneDimensionalAvgedMovementSpeeds = [];
                for i = 1:nblocks
                    for j = 1:ntrials(i)-(starttrials(i)-1)
                        oneDimensionalAvgedMovementSpeeds =[oneDimensionalAvgedMovementSpeeds mean(movementSpeeds{i,j}(:,:),1)];
                    end
                end
                hold on;
                h = histogram(oneDimensionalAvgedMovementSpeeds);
                hold off;
                clear oneDimensionalAvgedMovementSpeeds;
                h.Normalization = 'probability';
                cumulativeSpeedHistogramsLegendHandles = [cumulativeSpeedHistogramsLegendHandles h];
                if ~exist('binWidth')
                    binWidth = h.BinWidth;
                else
                    h.BinWidth = binWidth;
                end
            end

            %% Cumulative Metric Boxplots
            if cumulativeMetricBoxplots
                if ~exist('PostureMatchingTotalMetrics') %TODO: This means the script compound this variable if run multiple times, fix this
                    PostureMatchingTotalMetrics(:,1) = [{'Metrics'};{'Mean Path Efficiency'};{'StDev Path Efficiency'};{'StErr Path Efficiency'};...
                                                        {'Mean Time To Target'};{'StDev Time To Target'};{'StErr Time To Target'};...
                                                        {'Mean Movement Speed'};{'StDev Movement Speed'};{'StErr MovementSpeed'};...
                                                        {'Mean Overshoot'};{'StDev Overshoot'};{'StErr Overshoot'}; {'Completion Rate'}; {'Grouping'}; {'Group Name'}; {'N'};...
                                                        {'Trial Path Efficiencies'};{'Trial Overshoots'};{'Movement Speed Trial Averages'};{'Trial Movement Starts'};{'Trial Time to Targets'};{'DOF Labels'}];
                end
                PostureMatchingTotalMetrics{1,end+1} = logLabel{1};
                PostureMatchingTotalMetrics{2,end} = meanpatheff;
                PostureMatchingTotalMetrics{3,end} = stdvpatheff;
                PostureMatchingTotalMetrics{4,end} = stdvpatheff/sqrt(sum(ntrials-(starttrials-1)));
                PostureMatchingTotalMetrics{5,end} = meantimetotarget;
                PostureMatchingTotalMetrics{6,end} = stdvtimetoTarget;
                PostureMatchingTotalMetrics{7,end} = stdvtimetoTarget/sqrt(sum(ntrials-(starttrials-1)));
                PostureMatchingTotalMetrics{8,end} = meanmovementspeed;
                PostureMatchingTotalMetrics{9,end} = stdvmovementspeed;
                PostureMatchingTotalMetrics{10,end} = stdvmovementspeed/sqrt(sum(ntrials-(starttrials-1)));
                PostureMatchingTotalMetrics{11,end} = meanovershoot;
                PostureMatchingTotalMetrics{12,end} = stdvovershoot;
                PostureMatchingTotalMetrics{13,end} = stdvovershoot/sqrt(sum(ntrials-(starttrials-1)));
                PostureMatchingTotalMetrics{14,end} = successrate;
                PostureMatchingTotalMetrics{17,end} = sum(ntrials-(starttrials-1));
                PostureMatchingTotalMetrics{18,end} = patheff;
                PostureMatchingTotalMetrics{19,end} = overshoots;
                PostureMatchingTotalMetrics{20,end} = movementSpeedTrialAverages;
                PostureMatchingTotalMetrics{21,end} = movementStart;
                PostureMatchingTotalMetrics{22,end} = timetotarget;
                PostureMatchingTotalMetrics{23,end} = dofLabels;
                
%                 grouping = inputdlg({'What boxplot group is this data?'},'Boxplot Group Number',1,{'1'});
%                 if isempty(grouping)
%                     break;
%                 end
%                 grouping = sscanf(ndof{1},'%u',1);
%                 if (grouping<1)
%                     error('Unsupported boxplot grouping chosen.');  %TODO: Finish Grouping. 0 for no Grouping? So I can check Agonist/Antagonist, DOFs, and Subject. Check /Users/Hendrik/Documents/GraduateSchool/Summer2016/NIBIB/Figures/ANNFigures_11_19_2015/FigureMakingScript.m
%                 end
%                 if ~any(cell2mat(PostureMatchingTotalMetrics(15,2:end))==grouping)
%                     groupName = inputdlg({'What is the title for this new boxplot group?'},'Boxplot Group Name',1,{'Agonist/Antagonist Control'});
%                     if isempty(groupName)
%                         break;
%                     end
%                     PostureMatchingTotalMetrics{16,end} = groupName;
%                 else
%                     groupNameIndices = find(cell2mat(PostureMatchingTotalMetrics(15,2:end))==grouping)+1;
%                     PostureMatchingTotalMetrics{16,end} = PostureMatchingTotalMetrics{16,groupNameIndices(1)};
%                 end
%                 PostureMatchingTotalMetrics{15,end} = grouping;
            end

            %% Check for more data
            moreData = questdlg('Would you like to add more data?','Continue?','Yes','No','No');
        end

        %% Finish and save completion rate, histogram cumulative plots, and cumulative velocity profiles
        if cumulativeCompletionRates
            set(0, 'CurrentFigure', cumulativeCompletionRatesFig)
            axis([0 timeout 0 100]);
            ylabel('% Trials Complete');
            xlabel('Seconds');
            clear legend;
            legend(cumulativeCompletionRatesLegendHandles,cumulativeCompletionRatesLegendStrings);
            title('Cumulative Completion Rates');
            if saveFigs
                if iscell(saveFormat)
                    for i = 1:length(saveFormat)
                        saveas(cumulativeCompletionRatesFig,[savingDirectory fileSlash get(cumulativeCompletionRatesFig,'Name') saveFormat{i}]);
                    end
                else
                    saveas(cumulativeCompletionRatesFig,[savingDirectory fileSlash get(cumulativeCompletionRatesFig,'Name') saveFormat]);
                end
            end
            if ~displayFigs
                close(cumulativeCompletionRatesFig)
                clear cumulativeCompletionRatesFig;
            end
        end
        if cumulativeSpeedHistograms
            set(0, 'CurrentFigure', cumulativeSpeedHistogramsFig)
            ylabel('Probability');
            xlabel('% of Range of Motion per Second (as Averaged Across All DOFs)');
            title('Movement Speed across Control Schemes');
            legend(cumulativeSpeedHistogramsLegendHandles,cumulativeSpeedHistogramsLegendStrings);
            if saveFigs
                if iscell(saveFormat)
                    for i = 1:length(saveFormat)
                        saveas(cumulativeSpeedHistogramsFig,[savingDirectory fileSlash get(cumulativeSpeedHistogramsFig,'Name') saveFormat{i}]);
                    end
                else
                    saveas(cumulativeSpeedHistogramsFig,[savingDirectory fileSlash get(cumulativeSpeedHistogramsFig,'Name') saveFormat]);
                end
            end
            if ~displayFigs
                close(cumulativeSpeedHistogramsFig)
                clear cumulativeSpeedHistogramsFig;
            end
        end
        
        %% Cumulative Velocity Profile Plot
        if cumulativeVelocityProfiles
            %Display axes for the sake of zooming in
            %Don't display the text DOF names, use ylabel instead?

            set(0, 'CurrentFigure', cumulativeVelocityProfilesFig)

            if license('test', 'image_toolbox')
                if length(cumulativeMovementSpeeds) == 3
                    colorList = [ 0 0 1; 1 0 0; 0 0 0];
                else
                    colorList = distinguishable_colors(length(cumulativeMovementSpeeds));
                end
            else
                %TODO Implement a color alternative
            end
            
            tend = zeros(1, nblocks+1);
            cumulativeVelocityProfilesLegendHandles = [];
            
            for log=1:length(cumulativeMovementSpeeds)
                for k=1:ndof
                    toff = 0;
                    for i = 1:nblocks
                        for j = 1:ntrials(i)-(starttrials(i)-1) 
                            subplot(ndof,1,k);
                            hold on;
                            
                            X = [];
                            if NormalizeXAxis
                                X = (cumulativect{log}{i,j} - min(cumulativect{log}{i,j}))/(max(cumulativect{log}{i,j})-min(cumulativect{log}{i,j}));
                            else
                                X = cumulativect{log}{i,j};
                            end
                            
                            %plot velocity profile
                            if license('test', 'image_toolbox')
                                h = plot(X+toff, cumulativeMovementSpeeds{log}{i,j}(k,:),'Color',colorList(log,:),'LineWidth',2);
                            else
                                
                            end
                            
                            %plot 'X' at end of target if unsuccessful
                            failct = cumulativectout{log}{i,j}.*X;
                            failIndices = find(failct);
                            failct(isnan(failct)) = [];
                            failSpeeds = [];
                            for x = 1:length(failIndices)
                                failSpeeds = [failSpeeds cumulativeMovementSpeeds{log}{i,j}(k,failIndices(x))];
                            end
                            if ~isempty(failct)
                                plot(failct+toff, failSpeeds,'Color',colorList(log,:),'Marker','x');
                            end
                            
                            %plot 'O' at end of movement if successful
                            successct = cumulativechit{log}{i,j}.*X;
                            successIndices = find(successct);
                            successct(successct==0) = [];
                            successSpeeds = [];
                            for x = 1:length(successIndices)
                                successSpeeds = [successSpeeds cumulativeMovementSpeeds{log}{i,j}(k,successIndices(x))];
                            end
                            if ~isempty(successct)
                                plot(successct+toff, successSpeeds,'Color',colorList(log,:),'Marker','o');
                            end

                            %adjust toffset by max trial length
                            if NormalizeXAxis
                                toff = toff + 1;
                            else
                                toff = toff + timeout;
                            end
                        end
                        if k==1 && log==1
                            title('Cumulative Velocity Profile Plot');
                            %save the end time for the block (same for each dof)
                            tend(i+1)=toff;
                            %label the blocks (only above first subplot)
                            text(mean([tend(i) tend(i+1)]), cumulativeVelocityLimits(2,k)+10, num2str(i), 'HorizontalAlignment', 'Center', 'Color', 'r')
                        end
                        if (log == 1);
                            %mark the beginning and end of each block on each subplot
                            plot([tend(i+1) tend(i+1)], [cumulativeVelocityLimits(1,k) cumulativeVelocityLimits(2,k)], 'r');
                        end
                    end
                    
                    if log==1
                        axis([0 toff+20 cumulativeVelocityLimits(1,k)-5 cumulativeVelocityLimits(2,k)+5]); % TODO: ADJUST WITH SLIDER?
                        ylabel([dofLabels(k) ' %ROM/s']);
                        if k==ndof
                            if NormalizeXAxis
                                xlabel('Trial');
                            else
                                xlabel('Seconds');
                            end
                        else
                            set(gca, 'XTickLabelMode', 'Manual')
                        end
                    end
                    hold off;
                    
                end
                cumulativeVelocityProfilesLegendHandles(end+1) = h;
            end
            legend(cumulativeVelocityProfilesLegendHandles,cumulativeVelocityProfilesLegendStrings,'Location','northeast');
            
            if saveFigs
                if iscell(saveFormat)
                    for i = 1:length(saveFormat)
                        saveas(cumulativeVelocityProfilesFig,[savingDirectory fileSlash get(cumulativeVelocityProfilesFig,'Name') saveFormat{i}]);
                    end
                else
                    saveas(cumulativeVelocityProfilesFig,[savingDirectory fileSlash get(cumulativeVelocityProfilesFig,'Name') saveFormat]);
                end
            end
            if ~displayFigs
                close(cumulativeVelocityProfilesFig)
                clear cumulativeVelocityProfilesFig;
            end  
            
        end
        
        %% Cumulative Average Velocity Profile Plot
        if cumulativeAvgVelocityProfiles
            set(0, 'CurrentFigure', cumulativeAvgVelocityProfilesFig)

            if license('test', 'image_toolbox')
                if length(cumulativeMovementSpeeds) == 3
                    colorList = [ 0 0 1; 1 0 0; 0 0 0];
                else
                    colorList = distinguishable_colors(length(cumulativeMovementSpeeds));
                end
            else
                %TODO Implement a color alternative
            end
            
            X = (((1:windowBins)-1)/(windowBins-1))*100;
            transparent = 0;
            if transparent
                set(cumulativeAvgVelocityProfilesFig,'renderer','openGL')
            else
                set(cumulativeAvgVelocityProfilesFig,'renderer','painters')
            end
            cumulativeVelocityProfilesLegendHandles = [];
           
            % Calculate the average and stddev
            for log=1:length(cumulativeMovementSpeeds)
                MovementSpeedN = zeros(ndof,windowBins);
                MovementSpeedBinned = cell(ndof,windowBins);
                % Std error patch colors
                edgeColor=colorList(log,:)+(1-colorList(log,:))*0.55;
                patchSaturation=0.15; %How de-saturated or transparent to make patch
                if transparent
                    faceAlpha=patchSaturation;
                    patchColor=colorList(log,:);
                else
                    faceAlpha=1;
                    patchColor=colorList(log,:)+(1-colorList(log,:))*(1-patchSaturation);
                end
                
                for k=1:ndof
                    for i = 1:nblocks
                        for j = 1:ntrials(i)-(starttrials(i)-1) 
                            [N,edges,binArray] = histcounts(cumulativect{log}{i,j},windowBins);
                            MovementSpeedN(k,:) = MovementSpeedN(k,:) + N;                          
                            for n = 1:length(cumulativeMovementSpeeds{log}{i,j}(k,:))
                                MovementSpeedBinned{k,binArray(n)} = [MovementSpeedBinned{k,binArray(n)} cumulativeMovementSpeeds{log}{i,j}(k,n)];
                            end
                        end
                    end
                end
                MovementSpeedAverages = zeros(ndof,windowBins);
                MovementSpeedStDev = zeros(ndof,windowBins);
                for n = 1:windowBins
                    for k = 1:ndof
                        MovementSpeedAverages(k,n) = sum(MovementSpeedBinned{k,n})/MovementSpeedN(k,n);
                        MovementSpeedStDev(k,n) = std(MovementSpeedBinned{k,n});
                    end
                end
                MovementSpeedStErr = MovementSpeedStDev./sqrt(MovementSpeedN);
                for k = 1:ndof
                    subplot(ndof,1,k)
                    hold on;
                    %plot average velocity profile and std error range
                    if license('test', 'image_toolbox')
                        H.mainLine = plot(X,MovementSpeedAverages(k,:),'Color',colorList(log,:),'LineWidth',2);
                        %Calculate the error bars
                        uE=MovementSpeedAverages(k,:)+MovementSpeedStErr(k,:);
                        lE=MovementSpeedAverages(k,:)-MovementSpeedStErr(k,:);
                        %Make the patch
                        yP=[lE,fliplr(uE)];
                        xP=[X,fliplr(X)];
                        H.patch=patch(xP,yP,1,'facecolor',patchColor,...
                              'edgecolor','none',...
                              'facealpha',faceAlpha);
                        %Make pretty edges around the patch. 
                        H.edge(1)=plot(X,lE,'-','color',edgeColor);
                        H.edge(2)=plot(X,uE,'-','color',edgeColor);
                        %Now replace the line (this avoids having to bugger about with z coordinates)
                        uistack(H.mainLine,'top')
                    else
                    
                    end
                    ylabel([dofLabels(k) ' %ROM/s']);
                    if k==1 && log==1
                        title('Averaged Velocity Profile Plot');
                    end
                    hold off;
                end                
                if log==1
                    if k==ndof
                        xlabel('% of Trial Time');
                    else
                        set(gca, 'XTickLabelMode', 'Manual')
                    end
                end
                cumulativeVelocityProfilesLegendHandles(end+1) = H.mainLine;
            end
            
            legend(cumulativeVelocityProfilesLegendHandles,cumulativeVelocityProfilesLegendStrings,'Location','northeast');
            
            if saveFigs
                if iscell(saveFormat)
                    for i = 1:length(saveFormat)
                        saveas(cumulativeAvgVelocityProfilesFig,[savingDirectory fileSlash get(cumulativeAvgVelocityProfilesFig,'Name') saveFormat{i}]);
                    end
                else
                    saveas(cumulativeAvgVelocityProfilesFig,[savingDirectory fileSlash get(cumulativeAvgVelocityProfilesFig,'Name') saveFormat]);
                end
            end
            if ~displayFigs
                close(cumulativeAvgVelocityProfilesFig)
                clear cumulativeAvgVelocityProfilesFig;
            end  
        end

        %% Cumulative Bar Plot
        if cumulativeMetricBoxplots
            set(0, 'CurrentFigure', cumulativeMetricBoxplotsFig)

            %PostureMatchingTotalMetrics{15,end} = grouping;
            %function handles = barweb(barvalues, errors, width, groupnames, bw_title, bw_xlabel, bw_ylabel, bw_colormap, gridstatus, bw_legend, error_sides, legend_type)


            % Group all information together
            legend = {};
            PathEffmeans = [];
            PathEfferrs = [];
            TrialTimemeans = [];
            TrialTimeerrs = [];
            MovementSpeedmeans = [];
            MovementSpeederrs = [];
            Overshootsmeans = [];
            Overshootserrs = [];
            SuccessRate = [];
            index = 1;
            for j = 2:size(PostureMatchingTotalMetrics,2)
                legend(index) = {PostureMatchingTotalMetrics{1,j}};
                PathEffmeans = [PathEffmeans cell2mat(PostureMatchingTotalMetrics(2,j))];
                PathEfferrs = [PathEfferrs cell2mat(PostureMatchingTotalMetrics(4,j))];
                TrialTimemeans = [TrialTimemeans cell2mat(PostureMatchingTotalMetrics(5,j))];
                TrialTimeerrs = [TrialTimeerrs cell2mat(PostureMatchingTotalMetrics(7,j))];
                MovementSpeedmeans = [MovementSpeedmeans cell2mat(PostureMatchingTotalMetrics(8,j))];
                MovementSpeederrs = [MovementSpeederrs cell2mat(PostureMatchingTotalMetrics(10,j))];
                Overshootsmeans = [Overshootsmeans cell2mat(PostureMatchingTotalMetrics(11,j))];
                Overshootserrs = [Overshootserrs cell2mat(PostureMatchingTotalMetrics(13,j))];
                SuccessRate = [SuccessRate cell2mat(PostureMatchingTotalMetrics(14,j))];
                index = index+1;
            end
            % Path Efficiency
            subplot(2,3,1);
            handle = barweb(PathEffmeans, PathEfferrs, [], [], 'Path Efficiency', [], '%',[],[],legend);
            % Percent Trial Time Needed
            subplot(2,3,2);
            handle = barweb(TrialTimemeans, TrialTimeerrs, [], [], 'Trial Time to Target', [], 's',[],[]);
            % Average Overall (MultiDOF) Movement Speed
            subplot(2,3,3);
            handle = barweb(MovementSpeedmeans, MovementSpeederrs, [], [], 'Average Movement Speed', [], '% of Range of Motion per Second (as Averaged Across All DOFs)',[],[]);
            % Average Overshoots per Trial for all DOFs
            subplot(2,3,4);
            handle = barweb(Overshootsmeans, Overshootserrs, [], [], 'Overshoots', [], 'Average Overshoots per Trial (Across All DOFs)',[],[]);
            % Success Rate
            subplot(2,3,5);
            handle = barweb(SuccessRate, zeros(size(SuccessRate)), [], [], 'Success Rate', [], '%',[],[]);

            %TODO: move legend to free subplot

            if saveFigs
                if iscell(saveFormat)
                    for i = 1:length(saveFormat)
                        saveas(cumulativeMetricBoxplotsFig,[savingDirectory fileSlash get(cumulativeMetricBoxplotsFig,'Name') saveFormat{i}]);
                    end
                else
                    saveas(cumulativeMetricBoxplotsFig,[savingDirectory fileSlash get(cumulativeMetricBoxplotsFig,'Name') saveFormat]);
                end
                save(strcat(savingDirectory,fileSlash,'PostureMatchingAnalysisOutput',datestr(now,'_yyyy_mm_dd__HH_MM_SS')),'PostureMatchingTotalMetrics');
                %%
                fileID = fopen(strcat(savingDirectory,fileSlash,'PostureMatchingAnalysisOutput',datestr(now,'_yyyy_mm_dd__HH_MM_SS'),'.txt'),'wt');
                PostureMatchingAnalysisOutput = PostureMatchingTotalMetrics(1:17,:);
                formatSpec1 = [];
                formatSpec2 = ['%s'];
                for i = 1:size(PostureMatchingAnalysisOutput,2)
                    formatSpec1 = [formatSpec1 '%s, '];
                    %PostureMatchingTotalMetrics{1,i} = strrep(PostureMatchingTotalMetrics{1,i},' ','_');
                    formatSpec2 = [formatSpec2 ', %2.2f'];
                end
                formatSpec1 = [formatSpec1 '\r\n'];
                formatSpec2 = [formatSpec2 ' \r\n ' 10 13];
                fprintf(fileID,formatSpec1,PostureMatchingAnalysisOutput{1,:});
                for i = 2:size(PostureMatchingAnalysisOutput,1)
                    fprintf(fileID,formatSpec2,PostureMatchingAnalysisOutput{i,:});
                    fprintf(fileID,'\r\n');
                end
                fclose(fileID)
                save(strcat(savingDirectory,fileSlash,'PostureMatchingAnalysisOutput',datestr(now,'_yyyy_mm_dd__HH_MM_SS')),'PostureMatchingTotalMetrics');
            end
            if ~displayFigs
                close(cumulativeMetricBoxplotsFig)
                clear cumulativeMetricBoxplotsFig;
            end
        end
    end
end
% TODO: Make new posture pictures for data collection program because of new ranges

% Run as a batch so I can be allowed to close figures when dialog boxes are open? I don't think the dialog boxes work then
% 
% missing text prompts for directory dialog boxes? note that it's a mac problem