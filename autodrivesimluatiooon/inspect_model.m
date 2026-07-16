load_system('example_husky');
blockPath = 'example_husky/AutoDRIVE Husky';
ph = get_param(blockPath, 'PortHandles');
inLines = get_param(blockPath, 'LineHandles');
for i = 1:numel(inLines.Inport)
    line = inLines.Inport(i);
    if line ~= -1
        srcBlock = get_param(get_param(line, 'SrcBlockHandle'), 'Name');
        srcPort = get_param(line, 'SrcPort');
        fprintf('Input Port %d is connected to block: %s (Port %d)\n', i, srcBlock, srcPort);
    else
        fprintf('Input Port %d is not connected.\n', i);
    end
end
