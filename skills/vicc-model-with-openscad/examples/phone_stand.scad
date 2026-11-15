// Adjustable Phone/Tablet Stand
// Parametric stand with customizable angle and size

// === Device Parameters ===
device_width = 80;       // [50:200] Device width in mm
device_thickness = 12;   // [6:20] Device thickness (with case)

// === Stand Parameters ===
stand_angle = 65;        // [45:85] Viewing angle in degrees
stand_depth = 80;        // [50:150] Base depth in mm
stand_height = 100;      // [60:200] Back support height in mm

// === Construction ===
material_thickness = 4;  // [2:0.5:8] Material thickness
slot_depth = 15;         // [10:30] How deep device sits in slot

// === Features ===
cable_hole = true;       // Add cable pass-through hole
cable_diameter = 15;     // [8:25] Cable hole diameter
add_feet = true;         // Add feet (use supports under the raised base)

// === Internal ===
$fn = 48;
cradle_depth = max(slot_depth, device_thickness / sin(stand_angle));
support_x = material_thickness + cradle_depth;
support_z = material_thickness * 0.75;
lip_height = material_thickness + cradle_depth / tan(stand_angle);
foot_height = 2;

module side_brace() {
    brace_length = min(stand_height / 2, (stand_depth - support_x) / cos(stand_angle));
    rotate([90, 0, 0])
        linear_extrude(height=material_thickness)
            polygon([
                [support_x, support_z],
                [stand_depth, support_z],
                [support_x + brace_length * cos(stand_angle),
                 support_z + brace_length * sin(stand_angle)]
            ]);
}

module back_support() {
    // The support rises from just behind the cradle and overlaps the base.
    translate([support_x, 0, support_z])
        rotate([0, -stand_angle, 0])
            translate([0, 0, -material_thickness])
                cube([stand_height, device_width, material_thickness]);
}

module cable_cutout() {
    if (cable_hole) {
        translate([stand_depth/2, device_width/2, -1])
            cylinder(h = material_thickness + 2, d = cable_diameter);
    }
}

module foot() {
    // Overlap the base so the foot and stand export as one solid.
    cylinder(h = foot_height + 0.1, d1 = 10, d2 = 8);
}

module stand_body() {
    assert(stand_depth > support_x, "Stand depth must leave room for the cradle and support.");
    difference() {
        union() {
            for (y = [material_thickness, device_width])
                translate([0, y, 0]) side_brace();

            // Base plate
            cube([stand_depth, device_width, material_thickness]);

            // Front lip
            cube([material_thickness, device_width, lip_height]);

            // Back support
            back_support();
        }

        // Cable hole
        cable_cutout();
    }
}

module stand() {
    translate([0, 0, add_feet ? foot_height : 0]) stand_body();

    if (add_feet) {
        for (x = [10, stand_depth - 10], y = [10, device_width - 10])
            translate([x, y, 0]) foot();
    }
}

stand();
