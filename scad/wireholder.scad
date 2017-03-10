// https://gist.github.com/dustin/0b48e7e7b7d318752acccaaaf4f590a5
$fa = 2;
$fs = 0.5;
smooth = 0;

// Thanks, http://kitwallace.tumblr.com/post/87637876144/list-comprehension-in-openscad
function reverse(v) = [ for (i = [0:len(v)-1])  v[len(v) -1 - i] ];

module sinething(length, width, thickness) {
    table = [for(i = [0 : 10 : 360]) [i / (360/length), width * sin(i)]];
    right = [for(i = table) [i[0], i[1] + (thickness/2)]];
    left = [for(i = table) [i[0], i[1] - (thickness/2)]];
    polygon(concat(left, reverse(right)));
}

module wireholder(width, gap) {
    difference() {
        translate([width/2, 0, 0]) sphere(d=width);
        linear_extrude(width/2 + .1) sinething(width, 5.2, gap);
        translate([0, -width/2, -width/2-2]) cube([width, width, width/2]);
        translate([0, -width/4, 0]) cube([width, width/2, gap+.5]);
    }
}


if (smooth > 0) {
    minkowski() {
        wireholder(25, 5);
        sphere(d=smooth);
    }
} else {
    wireholder(25, 5);
}
