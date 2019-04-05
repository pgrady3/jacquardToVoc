function corners = xyaojToCorners(in)
%xyaojToCorners Convery jacquard x, y, angle, opening, jaw width to 4
%corners

    x = in(1);
    y = in(2);
    angle = in(3);
    opening = in(4);
    jaws = in(5);
    
    corners = zeros(4, 2);
    corners(1, 1) = -opening/2;
    corners(1, 2) = jaws/2;
    corners(2, 1) = opening/2;
    corners(2, 2) = jaws/2;
    corners(3, 1) = opening/2;
    corners(3, 2) = -jaws/2;
    corners(4, 1) = -opening/2;
    corners(4, 2) = -jaws/2;
    
    angle = angle / 180 * pi; %to radians;
    
    rot = [cos(angle) sin(angle); -sin(angle) cos(angle)];
    
    corners = corners * rot;%rotate
    
    corners = corners + [x, y];%offset
end

