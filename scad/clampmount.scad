$fa=2;
$fs=.05;

gopro_length = 15;
gopro_finger_width = 2.8;
gopro_finger_gap = 3.3;

function gopro_width(n) = (n-1)*(gopro_finger_width+gopro_finger_gap) + gopro_finger_width;

module goproN(n) {
    module finger() {
        difference() {
            hull() {
                translate([0, gopro_length/2, 8]) rotate([0, 90, 0])
                    cylinder(d=gopro_length, h=gopro_finger_width);
                cube([gopro_finger_width, gopro_length, 8]);
            }
            translate([-.1, gopro_length/2, 8]) rotate([0, 90, 0]) cylinder(d=5, h=3);
        }
    }
    union() {
        cube([gopro_width(n), gopro_length, thickness]);
        translate([0, 0, thickness]) {
            for (i = [0:n-1]) {
                translate([i*(gopro_finger_width+gopro_finger_gap), 0, 0]) finger();
            }
        }
    }
}

module gopro_host() {
    translate([3.5, 0, 0])
        union() {
        translate([-3.5, 3.5/2, 0]) {
            difference() {
                hull() {
                    translate([0, 11/2, 8]) rotate([0, 90, 0]) cylinder(d=11, h=3.5);
                    cube([3.5, 11, 3.5]);
                }
                translate([-.1, 11/2, 8]) rotate([0, 90, 0]) cylinder(d=5, h=4);
                translate([-.1, 11/2, 8]) rotate([0, 90, 0]) cylinder(d=9, h=4, $fn=6);
            }
        }
        goproN(3);
    }
}

difference() {
    union() {
        translate([(-gopro_width(3)+3.5)/2, 0, -4]) cube([30, 17, 4]);
        gopro_host();
    }
    translate([((-gopro_width(3)+3.5)/2)-.5, -.1, -3.5 ]) cube([31, 15, 2.6]);
}
