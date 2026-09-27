function h = bar_colored(values, width, colors)
% BAR_COLORED  Bar chart with one colour per bar (MATLAB + Octave).
%
%   h = bar_colored(values, width, colors)
%
% colors is an N x 3 RGB matrix. Each bar is drawn as its own bar object,
% which avoids the MATLAB-only 'FaceColor','flat' + CData syntax and the
% handle dot-notation (b.FaceColor = ...) that GNU Octave does not support.

values = values(:)';
h = zeros(size(values));
wasHeld = ishold;
hold on;
for i = 1:numel(values)
    h(i) = bar(i, values(i), width, 'FaceColor', colors(i, :));
end
if ~wasHeld
    hold off;
end
xlim([0.4, numel(values) + 0.6]);
end
