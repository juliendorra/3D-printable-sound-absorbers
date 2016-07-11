///Noise absorber modules targeted at FDM low-cost, low definition 3D printing
//They are 3 modules, using 3 noise absorbption strategies: 
// 1. Micro Perforated Panels with cone backing, 
// 2. Micro Perforated Panels with 3 length tunnel backing
// 3. Destructive interference
// Each strategy is a independant module that will have it's own absorption profile and drawbacks to be tested experimentally
// By combining the modules in various way, we could achieve custom absorption profiles, and maybe wider band absorption
// We can combine the modules in bigger panels directly in OpenSCDAD for direct printing of fully assembled sections, or print every module individually for manual assembly on the targeted surface.


// Micro Perforated Panels 

perforation_density_in_percent = 1; // total surface of the holes. Less than 2% is better according to the litterature: [ref needed]

perforation_size = 0.8; // must be sub-milimeter to be effective. Researchers often finds 0.5mm diameter to be very effective, but a real challenge for Fused Filament Deposition 3D printers, even with the dual layer technique.

perforation_surface = perforation_size*perforation_size;

panel_thickness = 0.8; // must be equal or slightly more than perforation diameter according to the litterature [ref needed - check if it's not the reverse !]

panel_size = 50;
panel_surface = panel_size*panel_size;

// Back
back_depth = 60 ;

// Cone back
cone_front_opening = 25 ; // 25mm value derived from "plastic horn arrays 144 per square foot" = 12 per 300mm. in Sound Absorptive Materials to Meet Specials Requirement Wirt 1975
cone_ratio = 3 ;
cone_back_opening = cone_front_opening / cone_ratio ;
cone_plus_spacing = cone_front_opening + 0.1 ;
cone_by_lines = panel_size / cone_plus_spacing ;
cone_relative_length_in_percent = 95 ;

// BASIC  //
    
module conduct (x, y, z, wall=0.6, closed_end = false) {
        
   inner_z = closed_end == true ? z-wall : z ; 
  
    difference () {
        
        cube ( [x, y, z], center=false ) ;
        
        translate ([wall/2, wall/2, 0]) cube ( [x-wall, y-wall, inner_z], center=false ) ; 
        
        } ; 


    }
    


// perforations 
// Given hole_density give me number of perforations to get this density.
// It should be turned into an utility function so we can vary the number of perforations on multipanel structures

number_of_perforations = ceil ( panel_surface * (perforation_density_in_percent/100) /perforation_surface ); 

// Given a number of perforations needed, how much on each line if perforated on a square surface?
function perforations_by_line_in_square (your_number_of_perforations) = ceil ( sqrt(your_number_of_perforations) ) ;

// we make perforation positions a function so we can call it repeatedly when producing many modules at once, avoiding the same pattern of perforations on all modules
// aligned on an uniform grid
function perforations_positions (your_number_of_perforations, size_to_cover) = 

    [for (
        
     x_order = [ 1:perforations_by_line_in_square (your_number_of_perforations) ], 
     y_order = [ 1:perforations_by_line_in_square (your_number_of_perforations) ]
    
          ) 
        
     let ( 
    
     perforations_by_line = perforations_by_line_in_square (your_number_of_perforations),
    
     grid_size = size_to_cover / perforations_by_line, 

     x= grid_size*x_order - grid_size/2, 
    
     y= grid_size*y_order - grid_size/2

           ) 

     [ x, y ] 

    ];


module perforations (perforation_coordinates){
    
    for ( i=[ 0:len(perforation_coordinates)-1 ] ) 
        translate ([ perforation_coordinates[i][0], perforation_coordinates[i][1], 0 ])
            square (perforation_size);
        
    
    }

module panel_front(type) {
    if (type == "onelayer") { panel_front_one_layer_with_single_holes() ; }
    else { panel_front_two_layers_with_grooves () ; }
    }   


module panel_front_one_layer_with_single_holes(){
    
    local_perforation_coordinates = perforations_positions(
            your_number_of_perforations=number_of_perforations, 
            size_to_cover=panel_size);
    
   echo ("Perforations coordinates", local_perforation_coordinates );
    
  linear_extrude (height= panel_thickness) difference () {
        square(panel_size);
        #perforations (local_perforation_coordinates);
    } 
   
    }
    
    

module perforations_using_grooves (perforation_coordinates) {

    for ( i=[ 0:len(perforation_coordinates)-1 ] ) {
        
        translate ([ perforation_coordinates[i][0], 0, 0]) // x index
    
            cube ([perforation_size, panel_size, panel_thickness/2]);

        translate ([ 0, perforation_coordinates[i][1], panel_thickness/2 ]) // y index
    
            cube ([panel_size, perforation_size, panel_thickness/2]);
    }
    
    
    }
    

module panel_front_two_layers_with_grooves () {
   
    
    local_perforation_coordinates = perforations_positions(
            your_number_of_perforations=number_of_perforations, 
            size_to_cover=panel_size);
    
   echo ("Perforations coordinates", local_perforation_coordinates );
    
difference () {
          linear_extrude (height= panel_thickness) square(panel_size);
        #perforations_using_grooves (local_perforation_coordinates);
    } 
    
    }   
    


// CONE BACK //

function cone_coordinates () =  

    [for (
        
     x_order = [ 0:cone_by_lines ], 
     y_order = [ 0:cone_by_lines ]
    
          ) 
        
     let ( 
    

     x= cone_plus_spacing * x_order, 
    
     y= cone_plus_spacing * y_order

           ) 

     [ x, y ] 

    ];

module cone_back(outer_height, large_diameter, small_diameter, separator="tube"){
    
    $fn = 24 ;
     
    positions = cone_coordinates() ;
    
    echo ( "small_diameter", small_diameter) ;
    echo ( "large_diameter", large_diameter) ;
        
    echo ( "Cone Positions", positions );
    
        
    cone_height = outer_height  * cone_relative_length_in_percent/100 ;
    
    inner_large_diameter = large_diameter -0.6 ;
    
    inner_small_diameter = small_diameter -0.6 ;
    
    
    for ( i=[ 0:len(positions)-1 ] ) {
        translate ([ positions[i][0] + cone_plus_spacing/2, 
                     positions[i][1] + cone_plus_spacing/2, 
                     panel_thickness ]) {
            

                difference () {
                    cylinder(h=cone_height, d1=large_diameter, d2=small_diameter, center=false) ;
                    cylinder(h=cone_height, d1=inner_large_diameter, d2=inner_small_diameter, center=false) ; 
                    } ;
                    
                if (separator == "tube") {            
                    difference () {
                    cylinder(h=outer_height, d=large_diameter, center=false) ;
                    cylinder(h=outer_height, d=inner_large_diameter, center=false) ; } ;
                } 
                
                if (separator == "wall") {
                    translate ([0,0,outer_height/2]) difference () {
                    cube([large_diameter, large_diameter, outer_height], center=true) ;
                    cube([inner_large_diameter, inner_large_diameter, outer_height], center=true) ; } ; 
                } 
                } ;
            };
}

module panel_with_cone_back(type="twolayers", separator="tube"){
    
    union(){
        
    panel_front (type=type);
    cone_back (outer_height=back_depth, large_diameter=cone_front_opening, small_diameter=cone_back_opening, separator=separator);
        
    }
}

// SEGMENTED BACK //

module segmented_back(){
    
    segment_wall = 2 ; //0.6
    shift = segment_wall ;
    
    translate ([0, 0, panel_thickness]) {
    
         // block
    
        conduct (x=panel_size, y=panel_size, z=back_depth, wall=segment_wall) ;
    
        // longer segment
       conduct (x=panel_size, y=panel_size/3, z=back_depth*2/3, wall=segment_wall) ;
            
        
        // middle segment
        translate ([0, panel_size/3, 0]) conduct (x=panel_size, y=panel_size/3, z=back_depth*2/3, wall=segment_wall, closed_end = true) ;
        
        // smaller segment
       translate ([0, panel_size*2/3, 0]) conduct (x=panel_size, y=panel_size/3, z=back_depth*1/3, wall=segment_wall, closed_end = true) ;
     
        
    
    } // end translate z = panel_thickness
    }

module panel_with_segmented_back(type){
    
union(){
panel_front(type=type);
segmented_back();
}

}


// panel_with_cone_back (type="twolayers", separator="wall"); // type: onelayer | twolayers, wall: tube | wall

 panel_with_segmented_back(type="twolayers") ; // // type: onelayer | twolayers




module modifier_block_back () {
// modifier block for Slic3r
     translate ([0, 0, panel_thickness]) cube ([panel_size, panel_size, back_depth ]) ;
}

