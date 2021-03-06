function [recall, prec, ap, apUpperBound] = DetectionPartsToPascalVOCFiles(set, idxPart, idxClass, boxes, boxIms, boxClfs, compName, doEval, overlapNms)

% Filters overlapping boxes (near duplicates), creates official VOC
% detection files. Evaluates results.
%
% Modified to evaluate part detection using imdbTest struct in DATAopts

global DATAopts;

DATAopts.testset = set;

if ~exist('doEval', 'var')
    doEval = 0;
end


partName = DATAopts.prt_classes{idxPart};
objName = DATAopts.classes{idxClass};
% Sort scores/boxes/images
[boxClfs, sI] = sort(boxClfs, 'descend');
boxIms = boxIms(sI);
boxes = boxes(sI,:);

% Filter boxes if wanted
if exist('overlapNms', 'var') && overlapNms > 0
        [uIms, ~, uN] = unique(boxIms);
        keepIds = true(size(boxes,1), 1);
        fprintf('Filtering %d: ', length(uIms));
        for i=1:length(uIms)
            if mod(i,500) == 0
                fprintf('%d ', i);
            end
            currIds = find(uN == i);
            [~, goodBoxesI] = BoxNMS(boxes(currIds,:), overlapNms);
            keepIds(currIds) = goodBoxesI;
        end
        boxClfs = boxClfs(keepIds);
        boxIms = boxIms(keepIds);
        boxes = boxes(keepIds,:);
        fprintf('\n');
end



% Save detection results using detection results
savePath = fullfile(DATAopts.resdir, 'Main', ['%s_det_', set, '_%s.txt']);
resultsName = sprintf(savePath, compName, [objName '-' partName]);
fid = fopen(resultsName,'w');
for j=1:length(boxIms)
    fprintf(fid,'%s %f %f %f %f %f\n', boxIms{j}, boxClfs(j),boxes(j,:));
end
fclose(fid);
fprintf('\n');

if doEval
    [recall, prec, ap] = VOCevaldetParts_modified(DATAopts, partName, objName, resultsName, false);
    apUpperBound = max(recall);
else
    recall = 0;
    prec = 0;
    ap = 0;
    apUpperBound = 0;
end
