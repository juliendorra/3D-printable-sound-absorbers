///Noise absorber modules targeted at FDM low-cost, low definition 3D printers ($300-$2000)
//They are several modules, using different noise absorbtion strategies: 

// 1. Micro Perforated Panels with cone backing, 
// 2. Micro Perforated Panels with 3 length tunnel backing
// 3. Destructive interference – hard to tune, still quite large
// 4. Micro Perforated Panels with Coplanar coiled air chamber – allow low frequency absorption with very thin panels

// Each strategy is a independant module that will have it's own absorption profile and drawbacks to be tested experimentally
// Modules are parametrized, and each strategy can be adjusted, giving a wide range of different modules: different depth of backing, different porosity, different channel length…
// By combining these modules we could achieve custom absorption profiles and wider band absorption.
// We can combine the modules in bigger panels directly in OpenSCDAD for direct printing of fully assembled sections, or print every module individually for manual assembly on the targeted surface.


// Micro Perforated Panels 

perforation_density_in_percent = 1; // total surface of the holes. Less than 2% is better according to the litterature: [ref needed]

perforation_size = 0.8; // must be sub-milimeter to be effective. Researchers often finds 0.5mm diameter to be very effective, but a real challenge for Fused Filament Deposition 3D printers, even with the dual layer technique.

perforation_surface = perforation_size*perforation_size;

panel_thickness = 0.8; // must be equal or slightly more than perforation diameter according to the litterature [ref needed - check if it's not the reverse !]

panel_size = 10;
panel_surface = panel_size*panel_size;

// Back
back_depth = 20 ;

// Cone back
cone_front_opening = 25 ; // 25mm value derived from "plastic horn arrays 144 per square foot" = 12 per 300mm. in Sound Absorptive Materials to Meet Specials Requirement Wirt 1975
cone_ratio = 3 ;
cone_back_opening = cone_front_opening / cone_ratio ;
cone_plus_spacing = cone_front_opening + 0 ;
cone_by_lines = panel_size / cone_plus_spacing;
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
        
     x_order = [ 0:cone_by_lines-1 ], 
     y_order = [ 0:cone_by_lines-1 ]
    
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
    
    wall = 0.6 ;
        
    cone_height = outer_height  * cone_relative_length_in_percent/100 ;
    
    inner_large_diameter = large_diameter - wall ;
    
    inner_small_diameter = small_diameter - wall ;
    
    
    for ( i=[ 0:len(positions)-1 ] ) {
        translate ([ positions[i][0] + cone_plus_spacing/2, 
                     positions[i][1] + cone_plus_spacing/2, 
                     panel_thickness ]) {
                    
                if (separator == "tube") {            
                    difference () {
                    cylinder(h=outer_height, d=large_diameter, center=false) ;
                    cylinder(h=outer_height, d=inner_large_diameter, center=false) ; } ;
                    
                    difference () {
                    cylinder(h=cone_height, d1=large_diameter, d2=small_diameter, center=false) ;
                    cylinder(h=cone_height, d1=inner_large_diameter, d2=inner_small_diameter, center=false) ; 
                    } ;
                } 
                
                if (separator == "wall") {
                    translate ([0,0,outer_height/2]) difference () {
                    cube([large_diameter, large_diameter, outer_height], center=true) ;
                    cube([inner_large_diameter, inner_large_diameter, outer_height], center=true) ; } ; 
                    difference () {
                    cylinder(h=cone_height, d1=large_diameter-wall*1.2, d2=small_diameter, center=false) ;
                    cylinder(h=cone_height, d1=inner_large_diameter-wall*1.2, d2=inner_small_diameter, center=false) ; 
                    } ;
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
    
    segment_wall = 0.6 ; //0.6
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


// COPLANAR COILED AIR CHANMBER //

module coil_angle (length, wall) { 
    
    cube ( [ length, wall, back_depth] ) ; 
    translate ([ length, 0,0]) rotate ([0, 0, 90]) cube ( [ length, wall, back_depth] ) ;
    }

module coil(coil_total_width, coil_conduct_width) {
   
    wall= 0.6;
//  angles_to_create = ceil(coil_total_width / (coil_conduct_width+wall) ) ;
    angles_to_create = 5 ;
 
    
    x_list = [ 5, 0, 4, 1, 3] ;
    y_list = [ 0, 5, 1, 4, 2] ;
    length_list = [ 5, 4, 3, 2, 1] ;
    
    
      #cube ( [ coil_total_width, wall, back_depth] ) ; // first outside wall
  
    for ( i = [ 0 : angles_to_create-1 ] ) { // off by one !
        
        angle = (i*180)+90 ; 
        length = length_list[i]/angles_to_create * coil_total_width ; // ex. 4/5th of coil_total_width
         
        translate ( [x_list[i], y_list[i], 0 ] ) rotate ([0, 0, angle])  
             coil_angle ( length = length, wall = wall) ;
        
     } // end for
   
   } // end module

module coplanar_coiled_air_chamber(coil_total_width, coil_conduct_width, wall) {

 translate ([0, 0, panel_thickness]) {

 local_perforation_coordinates = perforations_positions( your_number_of_perforations=number_of_perforations, size_to_cover=panel_size);
    
 for ( i=[ 0:len(local_perforation_coordinates)-1 ]  ) // starts from the origin of the hole 
     
        translate ([ local_perforation_coordinates[i][0]-wall, local_perforation_coordinates[i][1]-wall, 0 ]) {
            
            coil(coil_total_width, coil_conduct_width, wall) ;
        }
    
    } // END translate
}

module panel_with_coplanar_coiled_air_chamber(type){
union(){
%panel_front(type=type);
coplanar_coiled_air_chamber(coil_total_width = 5, coil_conduct_width = 2, wall = 0.6);
}
}



// How to call the modules : 

//panel_with_cone_back (type="twolayers", separator="wall"); // type: onelayer | twolayers, wall: tube | wall

// panel_with_segmented_back(type="twolayers") ; // type: onelayer | twolayers

panel_with_coplanar_coiled_air_chamber (type="twolayers") ; // type: onelayer | twolayers

// modifier_block_back() ;

module modifier_block_back () {
// modifier block for Slic3r
     translate ([0, 0, panel_thickness]) cube ([panel_size, panel_size, back_depth ]) ;
}

