/* [Global settings] */
// Generates shelf if true, drawer if false
shelf = false;

/* [Shelf settings] */
// Thickness of shelf walls
wall_thickness = 1.6;

// Whether the shelf should have a solid back
back_wall = false;

// Whether the material between the shelves should be removed
cut_middle_y = true;

// The width of the shelf rail if the middle is cut out
drawer_rail_size = 5;

// Number of drawers the shelf should hold horizontally
drawer_count_x = 1;

// Number of drawers the shelf should hold vertically
drawer_count_y = 2;

// Space to leave between the shelf and drawers
drawer_gap = 0.3;

/* [Drawer settings] */
// Thickness of drawer walls
drawer_wall_thickness = 1.6;

// Width of the drawer
drawer_width = 85;

// Height of the drawer
drawer_height = 19;

// Depth of the drawer
drawer_depth = 60;

/* [Drawer handle settings] */
// Depth
drawer_handle_depth = 8;

// Width
drawer_handle_width = 40;

// Height
drawer_handle_height = 8;

/* [Connectors] */
// Whether to generate connectors to link multiple shelves
use_connectors = true;

// Generate connector at top
connector_top = true;

// Generate connector to right
connector_right = true;

// Generate connector at bottom
connector_bottom = false;

// Generate connector at left
connector_left = false;

// Whether the last connector should have a square edge
square_edge_connectors = true;

// Thickness of connector
connector_thickness = 1.5;

// Width of narrow edge of connector
connector_narrow = 2;

// Width of broad edge of connector
connector_broad = 3;

// Number of connectors at each corner
connector_count = 3;

// Affects how round the connector's edges are
connector_radius = 0.3;

// Spacing between connectors to allow them to slide between each other
connector_clearance = 0.65; // [0.05:0.01:3]

/* [Test Connectors] */

// Generate a connector test
test_connectors = false;

// Number of connectors to generate to the positive side
test_connector_positive_count = 5; // [0:100]

// Number of connectors to generate to the negative side
test_connector_negative_count = 5; // [0:100]

// Height of connectors
test_connector_height = 5; // [2:20]

// Font size of connector label
test_font_size = 1.5; // [1:.1:10]

// Percentage to add or subtract from connector_clearance
test_amount = 0.05; // [0.00:.01:.5]

/* [Hidden] */
epsilon = 0.1;

module connector_trapezoid(h=10, center=false, sl=false, sr=false) {
    translate([center ? 0 : connector_thickness / 2,
               center ? 0 : connector_broad / 2,
               0])
    hull() {
        translate([-connector_thickness/2+connector_radius,-connector_narrow/2+connector_radius,0])
            cylinder(r=connector_radius, h=h, center=center);
        translate([-connector_thickness/2+connector_radius,connector_narrow/2-connector_radius,0])
            cylinder(r=connector_radius, h=h, center=center);
        translate([connector_thickness/2-connector_radius,-connector_broad/2+connector_radius,0])
            cylinder(r=connector_radius, h=h, center=center);
        translate([connector_thickness/2-connector_radius,connector_broad/2-connector_radius,0])
            cylinder(r=connector_radius, h=h, center=center);
        if (sr) {
            translate([-connector_thickness/2,connector_broad/2-epsilon,0])
                cube([epsilon,epsilon,h]);
        }
        if (sl) {
            translate([-connector_thickness/2,-connector_broad/2,0])
                cube([epsilon,epsilon,h]);
        }
    }
    
    connector_angle = atan(((connector_broad - connector_narrow) / 2) / (connector_thickness - connector_radius*2));
    rotated_angle = 90 + connector_angle;
    x_intercept = sin(connector_angle) * connector_radius;
    y_intercept = sin(180 - rotated_angle) * connector_radius;
    x_offset = connector_radius - sin(connector_angle) * connector_radius;
    y_offset = connector_radius - cos(connector_angle) * connector_radius;
    x_correction = x_intercept + connector_radius - x_offset;
    y_correction = x_correction * tan(connector_angle);
    
    translate([center ? -connector_thickness/2 : 0,
               center ? -connector_broad/2 : 0,
               center ? -h/2 : 0])
    intersection() {
        union () {
            translate([-x_intercept + x_offset + x_correction,
                       -y_intercept + y_offset + (connector_broad - connector_narrow)/2 - y_correction,
                       0])
            rotate([0,0,90-connector_angle])
                rotate_extrude(angle=rotated_angle)
                    translate([connector_radius,0,0])
                        square([wall_thickness, h]);
            
            translate([-x_intercept + x_offset + x_correction,
                       y_intercept - y_offset + y_correction + connector_broad - (connector_broad - connector_narrow)/2,
                       h])
            rotate([180,0,270+connector_angle])
                rotate_extrude(angle=rotated_angle)
                    translate([connector_radius,0,0])
                        square([wall_thickness, h]);
        }
        translate([0,0,0])
            cube([connector_thickness, connector_broad, h]);
    }
}

module connector_group(l=10, sr=false, sl=false) {
    for (i=[0:connector_count-1]) {
        translate([0,
                   (i*(connector_narrow + connector_broad + connector_clearance*2)),
                   0])
            connector_trapezoid(h=l, sr=(sr && i==connector_count-1), sl=(sl && i==0));
    }
}

module shelf_connectors() {
    spacing = wall_thickness + drawer_gap*2;
    temp_top = wall_thickness + (spacing + drawer_height)*drawer_count_y - drawer_height/2;
    temp_left = wall_thickness + (spacing + drawer_width)*drawer_count_x - drawer_width/2;
    temp_right = - drawer_width/2;
    temp_bottom = - drawer_height/2;
    temp_connector_width = (connector_broad + connector_narrow)/2 + connector_clearance;
    if (use_connectors) {
        if (connector_top) {
            translate([temp_right + temp_connector_width,
                       -(back_wall ? wall_thickness : 0)-drawer_depth / 2-drawer_gap,
                       temp_top])
            rotate([90,270,180])
                connector_group(drawer_depth + drawer_gap - (drawer_wall_thickness + drawer_gap) + (back_wall ? wall_thickness : 0));
            
            translate([temp_left,
                       drawer_depth / 2 - drawer_wall_thickness-drawer_gap,
                       temp_top])
            rotate([90,270,0])
                connector_group(drawer_depth + drawer_gap - (drawer_wall_thickness + drawer_gap) + (back_wall ? wall_thickness : 0), sl=square_edge_connectors);
        }

        if (connector_left) {
            translate([temp_left,
                       -(back_wall ? wall_thickness : 0)-drawer_depth / 2 - drawer_gap,
                       temp_top - temp_connector_width])
            rotate([90,180,180])
                connector_group(drawer_depth + drawer_gap + (back_wall ? wall_thickness : 0));
            
            translate([temp_left,
                       drawer_depth / 2,
                       temp_bottom])
            rotate([270,180,180])
                connector_group(drawer_depth + drawer_gap + (back_wall ? wall_thickness : 0), sl=square_edge_connectors);
        }

        if (connector_bottom) {
            translate([temp_left - temp_connector_width,
                       -(back_wall ? wall_thickness : 0)-drawer_depth / 2 - drawer_gap,
                       temp_bottom])
            rotate([90,90,180])
                connector_group(drawer_depth + drawer_gap + (back_wall ? wall_thickness : 0));
            
            translate([temp_right,
                       drawer_depth / 2,
                       temp_bottom])
            rotate([90,90,0])
                connector_group(drawer_depth + drawer_gap + (back_wall ? wall_thickness : 0), sl=square_edge_connectors);
        }

        if (connector_right) {
            translate([temp_right,
                       -(back_wall ? wall_thickness : 0)-drawer_depth / 2 - drawer_gap,
                       temp_bottom + temp_connector_width])
            rotate([270,180,0])
                connector_group(drawer_depth + drawer_gap + (back_wall ? wall_thickness : 0));
            
            translate([temp_right,
                       drawer_depth / 2,
                       temp_top])
            rotate([90,180,0])
                connector_group(drawer_depth + drawer_gap + (back_wall ? wall_thickness : 0), sl=square_edge_connectors);
        }
    }
}

module connector_test(h=10, test_count_positive=4, test_count_negative=4) {
    distance = test_amount * connector_clearance;
    font_size = test_font_size;
    test_count = test_count_positive + test_count_negative + 1;
    for (i=[-test_count_negative:test_count_positive]) {
        temp_spacing = distance * i;
        prev_position = i * (connector_narrow + connector_broad + (temp_spacing + connector_clearance*2));
        temp_separation = prev_position + (connector_clearance+temp_spacing)*2;
        translate([0,temp_separation,0]) connector_trapezoid(h=h, center=true);

        if (i < test_count_positive && $preview)
           %translate([0,
                       temp_separation + (connector_broad+connector_narrow+(distance*(i+1)+connector_clearance)*2)/2,
                        0])
            rotate([0,0,180])
                connector_trapezoid(h=h, center=true);
        translate([-connector_thickness/2 - (wall_thickness+2)/2,temp_separation,h/2])
            linear_extrude(height=.5)
                rotate([0,0,-90])
                    text(str(round((temp_spacing + connector_clearance)*100)/100),
                         font_size,
                         halign="center",
                         valign="center");
    }
    positive_width = test_count_positive * (connector_narrow + connector_broad + (distance * test_count_positive + connector_clearance*2)) + (connector_clearance + distance * test_count_positive)*2;
    negative_width = test_count_negative * (connector_narrow + connector_broad + (-distance * test_count_negative + connector_clearance*2)) + (connector_clearance + distance * test_count_negative)*2;
    middle_width = connector_broad;
    temp_width = negative_width + positive_width + middle_width;
    translate([-connector_thickness/2 - (wall_thickness + 2)/2,-temp_width/2+positive_width+middle_width/2,0])
        cube([(wall_thickness+2),temp_width,h], center=true);
    
    translate([connector_thickness + 5,0,0]) rotate([0,0,180]) connector_trapezoid(h=h,center=true);
    temp_top = 1.5*connector_thickness + 5;
    temp_x = connector_broad/2;
    tool_depth = 25;
    tool_angle = 6;
    temp_bottom = temp_top + tool_depth;
    temp_x_wide = temp_x + sin(tool_angle) * tool_depth;
    hull() {
        translate([temp_top + .5,-temp_x + .5,0]) cylinder(h=h, r=.5, center=true);
        translate([temp_top + .5,temp_x - .5,0]) cylinder(h=h, r=.5, center=true);
        translate([temp_bottom - .5,-temp_x_wide + .5,0]) cylinder(h=h, r=.5, center=true);
        translate([temp_bottom - .5,temp_x_wide - .5,0]) cylinder(h=h, r=.5, center=true);
    }
}

module drawer_handle() {
    temp_handle_height = drawer_wall_thickness + (drawer_handle_width - (cos(asin(1/2)) * drawer_handle_width));

    intersection() {
        translate([0,drawer_wall_thickness/2,-temp_handle_height/2 + drawer_wall_thickness/2])
            cube([drawer_handle_width - 4, drawer_handle_depth+drawer_wall_thickness, temp_handle_height], center=true);

        union() {
            cube([drawer_handle_width - 4, drawer_handle_depth, drawer_wall_thickness], center=true);

            translate([0,drawer_wall_thickness + drawer_handle_depth / 2,(cos(asin(1/2)) * drawer_handle_width) - drawer_wall_thickness/4])
            rotate([90,0,0])
                cylinder(r=drawer_handle_width, h=drawer_wall_thickness);
        }
    }
}

module drawer() {
    temp_handle_height = drawer_wall_thickness + (drawer_handle_width - (cos(asin(1/2)) * drawer_handle_width));

    difference() {
        cube([drawer_width, drawer_depth, drawer_height], center=true);
        translate([0, 0, drawer_wall_thickness/2])
            cube([drawer_width-2*drawer_wall_thickness, drawer_depth-2*drawer_wall_thickness, drawer_height - drawer_wall_thickness/2 + epsilon], center=true);
    }

    translate([0,drawer_depth/2 - drawer_wall_thickness/2+epsilon,(drawer_gap + wall_thickness)/2])
        cube([drawer_width,drawer_wall_thickness,drawer_height + drawer_gap + wall_thickness], center=true);
    translate([0,
               drawer_depth / 2 + drawer_handle_depth / 2,
               temp_handle_height/2])
        drawer_handle();
}

module drawers() {
    spacing = wall_thickness + drawer_gap*2;
    for(i=[0:drawer_count_x-1]) {
		for(j=[0:drawer_count_y-1]) {
            translate([spacing - drawer_gap + ((drawer_width + spacing) * i),
                       0,
                       spacing -drawer_gap + ((drawer_height + spacing) * j)])
                drawer();
        }
    }
}

module shelf() {
    spacing = wall_thickness + drawer_gap*2;
    for(i=[0:drawer_count_x]) {
        translate([-drawer_width/2 + (i*(drawer_width + spacing)),
                   -drawer_depth/2 - drawer_gap,
                   -drawer_height/2])
            cube([wall_thickness,
                  drawer_depth + drawer_gap,
                  wall_thickness + (spacing + drawer_height)*drawer_count_y]);
    }
    difference() {
        union() {
            for(j=[0:drawer_count_y]) {
                translate([-drawer_width/2,
                           -drawer_depth/2 - drawer_gap,
                           -drawer_height/2 + (j*(drawer_height + spacing))])
                    cube([wall_thickness + (spacing + drawer_width)*drawer_count_x,
                          drawer_depth + drawer_gap - (j==0 ? 0 : drawer_wall_thickness + drawer_gap),
                          wall_thickness]);
            }
        }
        if(cut_middle_y) {
            for(i=[0:drawer_count_x-1]) {
                translate([-drawer_width/2 + wall_thickness + drawer_gap + drawer_rail_size + (i*(drawer_width + spacing)),
                   -drawer_depth/2 - spacing - epsilon,
                   -drawer_height/2 + spacing - drawer_gap])
                cube([drawer_width - 2*drawer_rail_size,
                      drawer_depth + spacing + 2*epsilon,
                      -spacing + (spacing + drawer_height)*drawer_count_y]);
            }
        }
    }
    
    if (back_wall) {
        translate([-drawer_width/2,
                   -drawer_depth/2 - spacing + drawer_gap,
                   -drawer_height/2])
            cube([wall_thickness + (spacing + drawer_width)*drawer_count_x,
                  wall_thickness,
                  wall_thickness + (spacing + drawer_height)*drawer_count_y]);
    }
    
    shelf_connectors();
}

module drawer_set() {
    translate([0,10+drawer_wall_thickness,0]) drawers();
    shelf();
}

$fn=100;
if (!$preview) {
    if (test_connectors) {
        connector_test(h=test_connector_height, test_count_positive=test_connector_positive_count, test_count_negative=test_connector_negative_count);
    } else if (shelf) {
        rotate([90,0,0]) shelf();
    } else {
        rotate([0,0,0]) drawer();
    }
}
if ($preview) {
    if (test_connectors) {
        connector_test(h=test_connector_height, test_count_positive=test_connector_positive_count, test_count_negative=test_connector_negative_count);
    } else if (shelf) {
        shelf();
    } else {
        drawer_set();
    }
}
