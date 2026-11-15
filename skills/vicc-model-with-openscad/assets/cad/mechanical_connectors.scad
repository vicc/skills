// OpenSCAD Mechanical Connectors for 3D Printing
// Units: millimeters.
// CAD target: OpenSCAD. Use `use <mechanical_connectors.scad>` from your part file.
//
// Process defaults:
// - FDM moving clearance: 0.25-0.50 mm
// - FDM snug clearance: 0.15-0.25 mm
// - FDM press/interference: 0.05-0.15 mm
// - Print flexing beams so bending happens in XY, not across Z layers.

$fn = $preview ? 32 : 72;
example = "showcase"; // "none", "showcase", "battery_door", "waterproof_cap", "magnetic_click", "rail_slide", "quick_release"

function _safe(v) = max(v, 0.01);
function _hook_len(hook_height, lead_angle, retention_angle, land) =
    max(hook_height / tan(lead_angle), 0.2) + land + max(abs(hook_height / tan(retention_angle)), 0.15);

module rounded_box(size=[10, 10, 10], r=0.4, center=false, fn=16) {
    rr = min(max(r, 0), min(size[0], min(size[1], size[2])) / 2 - 0.01);
    if (rr <= 0) {
        cube(size, center=center);
    } else {
        translate(center
            ? [-size[0] / 2 + rr, -size[1] / 2 + rr, -size[2] / 2 + rr]
            : [rr, rr, rr]
        )
        minkowski() {
            cube([_safe(size[0] - 2 * rr), _safe(size[1] - 2 * rr), _safe(size[2] - 2 * rr)]);
            sphere(r=rr, $fn=fn);
        }
    }
}

// Extrude 2D X/Z points along Y.
module prism_y(points=[[0, 0], [1, 0], [0, 1]], width=1) {
    rotate([90, 0, 0])
        linear_extrude(height=width, center=true, convexity=4)
            polygon(points=points);
}

// Extrude 2D Y/Z points along X.
module prism_x(points=[[-1, 0], [1, 0], [0, 1]], length=10, center=true) {
    converted = [for (p = points) [-p[1], p[0]]];
    rotate([0, 90, 0])
        linear_extrude(height=length, center=center, convexity=4)
            polygon(points=converted);
}

module snap_hook(
    width=6,
    hook_height=1.0,
    lead_angle=30,
    retention_angle=80,
    land=0.45
) {
    lead_len = max(hook_height / tan(lead_angle), 0.2);
    back_len = max(abs(hook_height / tan(retention_angle)), 0.15);
    prism_y(
        points=[
            [0, 0],
            [lead_len, hook_height],
            [lead_len + land, hook_height],
            [lead_len + land + back_len, 0]
        ],
        width=width
    );
}

// Cantilever snap-fit tab.
// Orient beam length along X; print flat so bending stays in XY.
module snap_tab(
    beam_length=24,
    beam_width=6,
    beam_thickness=1.6,
    hook_height=1.0,
    lead_angle=30,
    retention_angle=80,
    hook_land=0.45,
    base_length=5,
    root_radius=0.6,
    stop_gap=0.2,
    clearance=0.25,
    show_receiver=false
) {
    hook_length = _hook_len(hook_height, lead_angle, retention_angle, hook_land);
    union() {
        rounded_box([base_length, beam_width + 2.0, beam_thickness + hook_height + 1.0], r=root_radius);
        translate([base_length, 1.0, 0])
            rounded_box([beam_length, beam_width, beam_thickness], r=min(root_radius, beam_thickness / 2 - 0.05));
        translate([base_length + beam_length - hook_length, 1.0 + beam_width / 2, beam_thickness])
            snap_hook(width=beam_width, hook_height=hook_height, lead_angle=lead_angle, retention_angle=retention_angle, land=hook_land);
    }

    if (show_receiver) {
        translate([base_length + beam_length - hook_length - clearance, beam_width + 4, beam_thickness + hook_height + clearance])
            difference() {
                rounded_box([hook_length + 3, beam_width + 2, hook_height + beam_thickness + 1], r=0.35);
                translate([1.5, 1, -0.1])
                    cube([hook_length + clearance, beam_width, hook_height + stop_gap + 0.3]);
            }
    }
}

// Male bayonet ring with lugs and tactile detents.
// Pair with matching receiver slots in the mating part.
module bayonet_mount(
    inner_radius=16,
    wall=2.4,
    height=5,
    lug_count=3,
    lug_width=7,
    lug_depth=2.0,
    lug_height=1.4,
    detent_height=0.35,
    stop_height=1.2,
    clearance=0.30
) {
    outer_radius = inner_radius + wall;
    lug_start = outer_radius - 0.2;
    stop_overlap = min(lug_width / 4, 0.4);
    detent_overlap = min(lug_height / 2, detent_height / 2);
    difference() {
        cylinder(h=height, r=outer_radius);
        translate([0, 0, -0.1])
            cylinder(h=height + 0.2, r=inner_radius);
    }

    for (i = [0:lug_count - 1]) {
        rotate([0, 0, i * 360 / lug_count]) {
            translate([lug_start, -lug_width / 2, height - lug_height])
                rounded_box([lug_depth, lug_width, lug_height], r=0.22);
            // Extend both features into the lug while preserving their exposed reach.
            if (stop_height > 0)
                translate([lug_start + lug_depth - min(lug_depth / 2, 0.35),
                           lug_width / 2 - stop_overlap, height - lug_height])
                    rounded_box([0.8, stop_height + clearance + stop_overlap, lug_height], r=0.18);
            if (detent_height > 0)
                translate([outer_radius + lug_depth / 2, 0, height + (detent_height - detent_overlap) / 2])
                    rotate([0, 90, 0])
                        cylinder(h=lug_depth * 0.9, r=(detent_height + detent_overlap) / 2, center=true);
        }
    }
}

// Dovetail rail or socket. base_width is the wide head, top_width the mounting
// neck. The rail flips over to enter the upward-facing socket from an end.
module dovetail_joint(
    length=50,
    base_width=12,
    top_width=8,
    height=4,
    clearance=0.25,
    wall=2.0,
    male=true,
    end_stop=true
) {
    half_head = base_width / 2;
    half_neck = top_width / 2;
    socket_head = half_head + clearance;
    socket_neck = half_neck + clearance;
    margin = 0.05;
    mouth_z = wall + height + clearance;

    if (male) {
        overlap = end_stop ? margin : 0;
        translate([overlap / 2, 0, 0])
            prism_x(
                points=[[-half_neck, 0], [half_neck, 0], [half_head, height], [-half_head, height]],
                length=length + overlap,
                center=true
            );
        if (end_stop) {
            // The shoulder sits outside the channel and limits insertion.
            translate([length / 2, -socket_head - margin, 0])
                cube([1.2, 2 * (socket_head + margin), height]);
        }
    } else {
        outer_width = 2 * (socket_head + wall);
        difference() {
            translate([-length / 2, -outer_width / 2, 0])
                rounded_box([length, outer_width, mouth_z], r=0.35);
            // Mirror the rail about the opening and add lateral clearance at
            // both flank endpoints. Keep floor clearance below the wide head.
            translate([0, 0, mouth_z])
                prism_x(
                    points=[
                        [-socket_head, -height - clearance], [socket_head, -height - clearance],
                        [socket_head, -height], [socket_neck, 0],
                        [socket_neck, margin], [-socket_neck, margin],
                        [-socket_neck, 0], [-socket_head, -height]
                    ],
                    length=length + 2 * margin,
                    center=true
                );
        }
    }
}

// Cylindrical socket with crush ribs for reliable press/snug fits.
// clearance can be negative for intentional interference.
module friction_socket(
    pin_diameter=8,
    depth=10,
    wall=2.0,
    clearance=0.15,
    rib_height=0.15,
    rib_width=0.9,
    rib_count=3,
    entry_chamfer=0.8
) {
    bore_radius = (pin_diameter + clearance) / 2;
    outer_radius = bore_radius + wall + rib_height;
    difference() {
        cylinder(h=depth, r=outer_radius);
        translate([0, 0, -0.1])
            cylinder(h=depth + 0.2, r=bore_radius);
        translate([0, 0, -0.05])
            cylinder(h=entry_chamfer + 0.1, r1=bore_radius + entry_chamfer, r2=bore_radius);
    }
    for (i = [0:rib_count - 1]) {
        rotate([0, 0, i * 360 / rib_count])
            translate([bore_radius - rib_height, -rib_width / 2, entry_chamfer])
                rounded_box([rib_height, rib_width, depth - entry_chamfer], r=min(rib_height / 2, 0.08));
    }
}

// Magnetic alignment plate with a mechanical detent and locating pin.
// Magnets locate and preload; detent and stops carry shear.
module magnetic_latch(
    plate=[28, 16, 3],
    magnet_diameter=6,
    magnet_thickness=2,
    pocket_clearance=0.20,
    detent_diameter=4,
    detent_height=0.45,
    alignment_pin_diameter=3,
    alignment_pin_height=1.2,
    edge_radius=0.5,
    show_mate=false
) {
    magnet_radius = (magnet_diameter + pocket_clearance) / 2;
    difference() {
        rounded_box(plate, r=edge_radius);
        translate([plate[0] * 0.28, plate[1] / 2, plate[2] - magnet_thickness + 0.01])
            cylinder(h=magnet_thickness + 0.2, r=magnet_radius);
        translate([plate[0] * 0.28 + magnet_radius, plate[1] / 2, plate[2] - magnet_thickness + 0.25])
            cube([0.8, 0.5, magnet_thickness], center=true); // glue vent notch
    }
    translate([plate[0] * 0.68, plate[1] / 2, plate[2]])
        cylinder(h=detent_height, r1=detent_diameter / 2, r2=max(detent_diameter / 2 - 0.25, 0.2));
    translate([plate[0] * 0.50, plate[1] * 0.25, plate[2]])
        cylinder(h=alignment_pin_height, r=alignment_pin_diameter / 2);

    if (show_mate) {
        translate([0, plate[1] + 4, 0])
            difference() {
                rounded_box(plate, r=edge_radius);
                translate([plate[0] * 0.28, plate[1] / 2, plate[2] - magnet_thickness + 0.01])
                    cylinder(h=magnet_thickness + 0.2, r=magnet_radius);
                translate([plate[0] * 0.68, plate[1] / 2, plate[2] - detent_height])
                    cylinder(h=detent_height + 0.3, r=detent_diameter / 2 + 0.20);
                translate([plate[0] * 0.50, plate[1] * 0.25, plate[2] - alignment_pin_height])
                    cylinder(h=alignment_pin_height + 0.3, r=alignment_pin_diameter / 2 + 0.20);
            }
    }
}

// U-style compliant flexure clip with paired spring arms.
// Use PETG/Nylon/TPU; avoid PLA for high-cycle service.
module flexure_clip(
    arm_length=28,
    arm_width=4,
    arm_thickness=1.4,
    gap=8,
    hook_height=0.8,
    lead_angle=30,
    retention_angle=70,
    root_radius=0.7,
    base_length=7,
    stop_gap=0.25
) {
    hook_length = _hook_len(hook_height, lead_angle, retention_angle, 0.35);
    rounded_box([base_length, gap + 2 * arm_width, arm_thickness + 2.0], r=root_radius);

    for (y = [0, gap + arm_width]) {
        translate([base_length, y, 1.0])
            rounded_box([arm_length, arm_width, arm_thickness], r=min(root_radius, arm_thickness / 2 - 0.05));
        translate([base_length + arm_length - hook_length, y + arm_width / 2, 1.0 + arm_thickness])
            snap_hook(width=arm_width, hook_height=hook_height, lead_angle=lead_angle, retention_angle=retention_angle, land=0.35);
    }

    translate([base_length + arm_length - 2, arm_width, 0])
        rounded_box([2.0, gap, arm_thickness + hook_height + stop_gap], r=0.25); // overtravel stop bridge
}

// Alternating hinge knuckles. Use side="a", "b", or "all".
module hinge_knuckle(
    length=36,
    knuckle_count=5,
    barrel_od=5,
    pin_diameter=2.8,
    clearance=0.25,
    gap=0.4,
    leaf_width=12,
    leaf_thickness=2,
    side="a"
) {
    segment = (length - gap * (knuckle_count - 1)) / knuckle_count;
    difference() {
        union() {
            for (i = [0:knuckle_count - 1]) {
                use_segment =
                    side == "all" ||
                    (side == "a" && i % 2 == 0) ||
                    (side == "b" && i % 2 == 1);
                if (use_segment) {
                    translate([-length / 2 + segment / 2 + i * (segment + gap), 0, barrel_od / 2])
                        rotate([0, 90, 0])
                            cylinder(h=segment, r=barrel_od / 2, center=true);
                }
            }

            translate([-length / 2, -leaf_width, 0])
                rounded_box([length, leaf_width, leaf_thickness], r=0.35);
        }

        // Clear the pin through the leaf as well as all the knuckles.
        translate([0, 0, barrel_od / 2])
            rotate([0, 90, 0])
                cylinder(h=length + 0.4, r=(pin_diameter + clearance) / 2, center=true);
    }
}

// Clevis-style captive pin joint with optional printed pin.
module captive_pin_joint(
    length=16,
    inner_gap=7,
    ear_width=4,
    ear_height=9,
    base_thickness=3,
    pin_diameter=3,
    clearance=0.25,
    pin_head_extra=1.2,
    include_pin=true
) {
    total_width = inner_gap + 2 * ear_width;
    hole_z = base_thickness + ear_height / 2;

    translate([-length / 2, -total_width / 2, 0])
        rounded_box([length, total_width, base_thickness], r=0.35);

    for (ear_y = [-(inner_gap / 2 + ear_width / 2), inner_gap / 2 + ear_width / 2]) {
        difference() {
            translate([-length / 2, ear_y - ear_width / 2, base_thickness])
                rounded_box([length, ear_width, ear_height], r=0.35);
            translate([0, ear_y, hole_z])
                rotate([90, 0, 0])
                    cylinder(h=ear_width + 0.4, r=(pin_diameter + clearance) / 2, center=true);
        }
    }

    if (include_pin) {
        translate([0, 0, hole_z])
            rotate([90, 0, 0])
                cylinder(h=total_width + 0.8, r=pin_diameter / 2, center=true);
        for (head_y = [-(total_width / 2 + 0.35), total_width / 2 + 0.35]) {
            translate([0, head_y, hole_z])
                rotate([90, 0, 0])
                    cylinder(h=0.7, r=(pin_diameter + pin_head_extra) / 2, center=true);
        }
    }
}

module battery_door_example() {
    // Sliding door: dovetail carries shear; snap tab gives final click.
    panel = [54, 32, 2.2];
    rounded_box(panel, r=0.7);
    translate([panel[0] / 2, panel[1] * 0.30, panel[2] - 0.05])
        dovetail_joint(length=42, base_width=8, top_width=5.5, height=3, clearance=0.25, male=true, end_stop=false);
    translate([panel[0] / 2, panel[1] * 0.70, panel[2] - 0.05])
        dovetail_joint(length=42, base_width=8, top_width=5.5, height=3, clearance=0.25, male=true, end_stop=false);
    translate([36, 11, panel[2]])
        snap_tab(beam_length=16, beam_width=5, beam_thickness=1.4, hook_height=0.8, base_length=4, root_radius=0.5);
}

module waterproof_cap_example() {
    // Bayonet cap skeleton with visual gasket land. Add elastomer in production.
    cap_radius = 18;
    wall = 2.4;
    cap_height = 8;
    difference() {
        cylinder(h=cap_height, r=cap_radius + wall);
        translate([0, 0, 1.2])
            cylinder(h=cap_height, r=cap_radius);
        translate([0, 0, 1.0])
            cylinder(h=1.4, r=cap_radius - 1.6); // gasket groove relief
    }
    translate([0, 0, cap_height - 1.5])
        bayonet_mount(inner_radius=cap_radius - 1.2, wall=1.4, height=3.0, lug_count=3, lug_width=6.5, lug_depth=1.8);
}

module magnetic_click_lock_example() {
    magnetic_latch(show_mate=true);
}

module rail_slide_example() {
    translate([0, -10, 0])
        dovetail_joint(male=true, length=54, base_width=12, top_width=8, height=4, clearance=0.25);
    translate([0, 14, 0])
        dovetail_joint(male=false, length=54, base_width=12, top_width=8, height=4, clearance=0.25);
}

module quick_release_mount_example() {
    rounded_box([48, 28, 3], r=0.8);
    translate([8, 6, 3])
        flexure_clip(arm_length=26, arm_width=4, gap=9, hook_height=0.9);
    translate([34, 14, 3])
        friction_socket(pin_diameter=8, depth=8, clearance=0.12);
}

module connector_showcase() {
    translate([-70, 0, 0]) battery_door_example();
    translate([0, 0, 0]) waterproof_cap_example();
    translate([45, -16, 0]) magnetic_click_lock_example();
    translate([-50, 55, 0]) rail_slide_example();
    translate([35, 48, 0]) quick_release_mount_example();
    translate([85, 42, 0]) hinge_knuckle(side="all");
    translate([85, -8, 0]) captive_pin_joint();
}

if (example == "showcase") connector_showcase();
if (example == "battery_door") battery_door_example();
if (example == "waterproof_cap") waterproof_cap_example();
if (example == "magnetic_click") magnetic_click_lock_example();
if (example == "rail_slide") rail_slide_example();
if (example == "quick_release") quick_release_mount_example();
