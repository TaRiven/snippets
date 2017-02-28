$fn=30;

module diamond(w, w2, h1, h2) {
    $fn=9;
    cylinder(d1=0, d2=w, h=h1);
    translate([0, 0, h1]) cylinder(d1=w, d2=w2, h=h2);
}

module dvase(w, w2, h1, h2) {
    difference() {
            diamond(w, w2, h1, h2);
            translate([0, 0, 3]) diamond(w-3, w2-3, h1-3, h2);
            translate([0, 0, h1-.1]) cylinder(d=w2-4, h=h2+1);
    }
}

rotate([180, 0, 0]) dvase(50, 32, 35, 10);
