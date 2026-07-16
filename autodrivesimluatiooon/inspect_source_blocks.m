load_system('example_husky');
b1 = 'example_husky/Linear Velocity';
b2 = 'example_husky/Angular Velocity';
fprintf('Block 1 (%s) type: %s\n', b1, get_param(b1, 'BlockType'));
fprintf('Block 2 (%s) type: %s\n', b2, get_param(b2, 'BlockType'));

% If they are From Workspace or Constant, print their values/variables
if strcmp(get_param(b1, 'BlockType'), 'Constant')
    fprintf('Block 1 Value: %s\n', get_param(b1, 'Value'));
elseif strcmp(get_param(b1, 'BlockType'), 'FromWorkspace')
    fprintf('Block 1 Variable: %s\n', get_param(b1, 'VariableName'));
end

if strcmp(get_param(b2, 'BlockType'), 'Constant')
    fprintf('Block 2 Value: %s\n', get_param(b2, 'Value'));
elseif strcmp(get_param(b2, 'BlockType'), 'FromWorkspace')
    fprintf('Block 2 Variable: %s\n', get_param(b2, 'VariableName'));
end
