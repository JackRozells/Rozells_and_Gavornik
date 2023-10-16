function dc = deltachange(X,Y,numcols,indicator);
base = X(find(X==0))
y = zeros((length(indicator)),1)
for l = 1:length(indicator)
    y(l) = (Y(l) - Y(base));
end
    figure
    hold 'on'
    bar(X,y)
    title('Difference of sequence length')
    ylabel('∆T')
    xlabel('level Chr2')