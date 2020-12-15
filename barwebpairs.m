function barwebpairs(h, pairsBG, pairsWG)
% BARWEBPAIRS Add pairing brackets to barweb plot (e.g. to indicate
% statically significant differences) 
% 
% Usage: barwebpairs(h, pairsBG, pairsWG) 
% * h: handle returned by barweb
% * pairsBG: between groups pairs: 1 x n cell array (where n is number of 
%   subgroups), each cell contains p x 2 matrix  with pairings (where p 
%   is the number of pairings for the subgroup, may differ in each cell).  
%   The bracket will be drawn in color of subgroup
%      Ex. PairsBG = {[1 2; 1 3; 2 4] , [2 3]}  
%           pairs groups 1->2, 1->3, and 2->4 for subgroup1 
%           and groups 2->3 for subgroup2
% * pairsWG: within group pairs: 1 x m cell array (where m is number of 
%   groups), each cell contains p x 2 matrix with pairings where p 
%   is the number of pairings in the group, may differ in each cell).  The 
%   bracket will be drawn in black
%
% NOTES: 
% 1. Groups are labeled by group names and clustered together. Subgroups are 
%    different colors (according to the colormap). 
% 2. The barweb plot must be the active axis
% 3. The axes will be adjusted to fit the brackets
% 4. To only include within group pairings set pairsBG = []
% 5. Within group brackets are plotted first.  Each bracket is plotted at the
%    minimum y-value (above bars and errorbars between the paired subgroups).
%    No two brackets within the same group will be plotted at the same y-value. 
%    They will be plotted in the order of the pairing matrix, with row 1 lowest.
% 6. Between group brackets are plotted second.  Each bracket is drawn at the
%    minimum y-value (above any within-group brackets, bars, and errorbars 
%    between the paired groups).  No two brackets will be plotted at the same 
%    y-value; they are plotted in the order of the pairing matrix, with row1 lowest.
% 7. barweb ver 2.3 by Bolu Ajiboye (also on Matlab Central)
%
% Joris Lambrecht
% May 5, 2009
% revisions:
% none

%get info from plot
hold on;

barvals = cell2mat(get(h.bars, 'Ydata'))'; 
errvals = cell2mat(get(h.errors, 'Ldata')'); 
posX = cell2mat(get(h.errors, 'Xdata')'); 
yRange = diff(get(h.ax, 'Ylim'));
color = colormap;

[nGroups nSubGroups] = size(barvals);

%error checking for inputs
if nargin < 1
    error('barwebpairs requires handle returned by barweb');
elseif nargin < 2
    pairsBG = cell(1, nSubGroups);
    pairsWG = cell(1, nGroups);
elseif nargin < 3
    pairsWG = cell(1, nGroups);
end
if ~iscell(pairsBG) 
    if ~isempty(pairsBG)
        warning('pairsBG ignored: must be cell arrays');
    end
    pairsBG = cell(1, nSubGroups);
elseif size(pairsBG,1) ~=  1 || size(pairsBG,2) ~= nSubGroups
    warning('pairsBG ignored: must be 1 X n cell arrays, where n is number of subgroups');
    pairsBG = cell(1, nSubGroups);
end
if ~iscell(pairsWG) 
    if ~isempty(pairsWG)
        warning('pairsWG ignored: must be cell arrays');
    end
    pairsWG = cell(1, nGroups);
elseif size(pairsWG,1) ~=  1 || size(pairsWG,2) ~= nGroups
    warning('pairsWG ignored: must be 1 X n cell arrays, where n is number of groups');
    pairsWG = cell(1, nGroups);       
end

%bracket parameters
bHeightP = 1;  %percent of (original) Y-axis that each bracket will take
bGapP = 1;     %percent of (original) Y-axis that each gap between brackets will take

bHeight = bHeightP*yRange*0.01;
bGap = bGapP*yRange*0.01;

yMinWG = barvals + errvals;
yMinBG = zeros(nGroups,1);

%Do pairs within groups first
for j = 1:nGroups
    nPairs = size(pairsWG{j},1);
    %determine minimum Y-val to place bracket
    yWG = zeros(1,nPairs); 
    for i = 1:nPairs
        %initially set the minimum Y-val to be bGap above all the bars between the
        %paired indices
        yWG(i) = max(yMinWG(j, pairsWG{j}(i,1):pairsWG{j}(i,2))) + bGap; 
    end
    %sort the Y-vals (low to high) and save the sort order
    [dummy sortorder] = sort(yWG);
    bY = 0;
    for i = sortorder %draw the brackets from lowest to highest
        if (yWG(i) - bY) < (bGap + bHeight)
            yWG(i) = bY + bGap + bHeight;
        end
        bY = yWG(i);
        yMinBG(j) = max(yWG) + bGap;
        bX = [posX(j,pairsWG{j}(i,1)) posX(j,pairsWG{j}(i,2))];
        plot([bX(1) bX(1) bX(2) bX(2)],...
                 [bY bY+bHeight bY+bHeight bY], 'LineWidth', 2, 'Color', 'k');
    end
end

yMinBG = max([yMinBG, max(yMinWG,[],2)],[],2); 
yWGmax = max(yMinBG);

%Do pairs between groups second
%reorganize the cell array into a single matrix (n X 2) where n is total
%number of pairs 
matPairs = cell2mat(pairsBG');
%add a 3rd column that indicates the subgroup # (now n X 3 matrix)
totPairs = 0;
for k = 1:nSubGroups
    nPairs = size(pairsBG{k},1);
    matPairs(totPairs + 1:nPairs + totPairs, 3) = k;
    totPairs = totPairs + nPairs;
end

yBG = zeros(1,totPairs); 
for i = 1:totPairs
    j = matPairs(i,3); %subgroup #
    %determine minimum Y-val to place bracket
    yBG(i) = max(yMinBG(matPairs(i,1):matPairs(i,2))) + bGap; 
end
%sort the Y-vals (low to high) and save the sort order
[dummy sortorder] = sort(yBG);

bY = 0;
for i = sortorder %draw the brackets from lowest to highest
    j = matPairs(i,3); %subgroup #
    %get index of color in color map based on subgroup #
    iColor = max([1 (j-1)*size(color, 1)/(nSubGroups-1)]);
    
    if (yBG(i) - bY) < (bGap + bHeight)
        yBG(i) = bY + bGap + bHeight;
    end
    bY = yBG(i);
    bX = [posX(matPairs(i,1),j) posX(matPairs(i,2),j)];
    plot([bX(1) bX(1) bX(2) bX(2)],...
             [bY bY+bHeight bY+bHeight bY], 'LineWidth', 2, 'Color', color(iColor,:));
end
yBGmax = max(yBG);

%adjust axis to put all the brackets in view
yLim = get(h.ax, 'Ylim');
yMax = max([yBGmax yWGmax yLim(2)-2*bGap]) + 2*bGap; 
set(h.ax, 'Ylim', [yLim(1) yMax]);

hold off;