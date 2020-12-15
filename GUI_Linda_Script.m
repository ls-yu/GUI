clear all
global x;
global y;
global S;
S = struct;
x=GUI_Linda;

%     
% ndof = 0; % number of dofs
%         dofLabels = {}; % labels for the dofs
%         
%         ROM = []; % Range of motion 0,-60,0,0,0,0; 180,70,100,100,100,100
%         
%                 truetimeIndex % = 2;
%                 DOF1LIndex % = 3;
%                 DOF2LIndex % = 4;
%                 DOF3LIndex % = 5;
%                 DOF4LIndex % = 6;
%                 DOF5LIndex % = 7;
%                 DOF6LIndex % = 8;
%                 LSourceIndex % = 9;
%                 DOF1RIndex % = 11;
%                 DOF2RIndex % = 12;
%                 DOF3RIndex % = 13;
%                 DOF4RIndex % = 14;
%                 DOF5RIndex % = 15;
%                 DOF6RIndex % = 16;
%                 RSourceIndex % = 17;
%                 DOF1ToleranceIndex % = 19;
%                 DOF2ToleranceIndex % = 20;
%                 DOF3ToleranceIndex % = 21;
%                 DOF4ToleranceIndex % = 22;
%                 DOF5ToleranceIndex % = 23;
%                 DOF6ToleranceIndex % = 24;
%                 TrialNumberIndex % = 25;
%                 BlockNumberIndex % = 26;
%                 DifficultyIndex % = 27;
%                 HitIndex % = 28;
%                 LAST_DOFLIndex % = DOF6LIndex;
%                 LAST_DOFRIndex % = DOF6RIndex;
%                 LAST_DOFToleranceIndex % = DOF6ToleranceIndex;
%                 nsamp;
%                 trial;
%                 block;
%                 nblocks;
%                 trials = [];
%                 ntrials;
%                 starttrials = [];
%                 hit;
%                 ct;
%                 target;
%                 cursor;
%                 difficulty;
%                 tol;
%                 ctarget;
%                 ccursor;
%                 nctarget; % Target normalized to ROM (0-100)
%                 nccursor; % Cursor normalized to ROM (0-100)
%                 ctol; % Tolerance in ROM by degrees (18, 18, and 15)
%                 chit; % 1 to hit
%                 cdifficulty; % Tolerance of 15%
%                 ctout;
%                 t; %truetime
%                 toff;
%                 timeout;
%                 tend;
%                 patheff;
%                 movementSpeeds;
%                 movementSpeedTrialAverages;
%                 tolerance;
%                 timetotarget;
%                 successrate;
%                 overshoots;
%                 movementStart;
%                 
%                 oneDimensionalPathEff = [];
%                 oneDimensionalTimeToTarget = [];
%                 oneDimensionalTrialAvgMovementSpeedDOFAveraged = [];
%                 oneDimensionalOvershootDOFSummed = [];
%                 oneDimensionalSuccess = [];
%                 meanpatheff;
%                 stdvpatheff;
%                 meantimetotarget;
%                 stdvtimetoTarget;
%                 meanmovementspeed;
%                 stdvmovementspeed;
%                 meanovershoot;
%                 stdvovershoot;
        