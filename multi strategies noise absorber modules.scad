///Noise absorber structures targeted at Fused Deposition Modeling, low-cost, low definition 3D printers ($300-$2000)
//They are several modules, using different noise absorption strategies: 

// 1. Micro Perforated Panels with cone backing, 

// 2. Micro Perforated Panels with 3 length tunnel backing

// 3. Destructive interference – hard to tune, still quite large [not implemented]

// 4. Micro Perforated Panels with Coplanar coiled air chamber – allow low frequency absorption with very thin panels [preliminary, brittle implementation]

// Each strategy is an independant module that will have it's own absorption profile and drawbacks to be tested experimentally
// Modules are parametrized, and each strategy can be adjusted, giving a wide range of different modules: different depth of backing, different porosity, different channel length…
// By combining these modules we could achieve custom absorption profiles and wider band absorption.
// We can combine the modules in bigger panels directly in OpenSCDAD for direct printing of fully assembled sections, or print each module individually for manual assembly on the targeted surface.


// About Two Layers panels: 
// When trying to print a surface with sub-milimeters holes using a low-cost FDM 3D printer, most of the time the holes get clogged by the plastic expansion and movement imprecisions. You can use many slicing tricks to try and overcome this, but the challenge is to design a part that will consistently print on a wide range of 3D printers without specific slicing settings.
// Thus, Two Layers panels are a dedicated design that can consistently get sub-milimeters holes on low cost FDM printers, by superimposing two perpendicular layers of stripes. Stripes print much more consistently than holes, and by superimposing them at 90º we create square holes of sub-milimeter width.


// SETTINGS //

// Micro Perforated Panels 

perforation_density_in_percent = 1; // total surface of the holes. Less than 2% is better according to the litterature: [ref needed]
    // 1 percent is a good default  
    //Exception: For Coplanar Coiled 3 is a good default

perforation_size = 0.8 ; // must be sub-milimeter to be effective. 
    //Researchers often finds 0.5mm diameter to be very effective, but a real challenge for Fused Filament Deposition 3D printers, even with the two layers technique.
    // 0.8 is a good default that should print well using Two Layers setting.   
    //Exception: For Coplanar Coiled 4mm seems to be the default

perforation_surface = perforation_size*perforation_size;

panel_thickness = 0.8; // must be equal or slightly more than perforation diameter according to the litterature [ref needed - check if it's not the reverse !]

panel_size = 150;
panel_surface = panel_size*panel_size;

// Back
back_depth = 50 ; // a good target range is 50 to 80mm
//Exception: For Coplanar Coiled 4mm might be sufficient if we believe the latest litterature [ref needed].


// Cone back

cone_front_opening = 25 ; // 25mm value derived from "plastic horn arrays 144 per square foot" = 12 per 300mm. in Sound Absorptive Materials to Meet Specials Requirement Wirt 1975
cone_ratio = 3 ;
cone_back_opening = cone_front_opening / cone_ratio ;
cone_plus_spacing = cone_front_opening + 0 ;
cone_by_lines = panel_size / cone_plus_spacing;
cone_relative_length_in_percent = 95 ;


// Coiled air chamber back

coil_total_width = 20 ; 
coil_conduct_width = 4; 
wall = 0.8 ;


// MODULES //

// BASIC  //
    
module conduct (x, y, z, wall=0.6, closed_end = false) {
        
   inner_z = closed_end == true ? z-wall : z ; 
  
    difference () {
        
        cube ( [x, y, z], center=false ) ;
        
        translate ([wall/2, wall/2, 0]) cube ( [x-wall, y-wall, inner_z], center=false ) ; 
        
        } ; 


    }
    


// Perforations 
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

module panel_front(type, size_extension=0) {
    if (type == "onelayer") { panel_front_one_layer_with_single_holes(size_extension) ; }
    else { panel_front_two_layers_with_grooves (size_extension) ; }
    }   


module panel_front_one_layer_with_single_holes(size_extension){
    
    local_perforation_coordinates = perforations_positions(
            your_number_of_perforations=number_of_perforations, 
            size_to_cover=panel_size);
    
   echo ("Perforations coordinates", local_perforation_coordinates );
    
  linear_extrude (height= panel_thickness) difference () {
        square(panel_size+size_extension);
        #perforations (local_perforation_coordinates);
    } 
   
    }
    
    

module perforations_using_grooves (perforation_coordinates) {

    for ( i=[ 0:len(perforation_coordinates)-1 ] ) { // off by one
        
        translate ([ perforation_coordinates[i][0], 0, 0]) // x index
    
            cube ([perforation_size, panel_size, panel_thickness/2]);

        translate ([ 0, perforation_coordinates[i][1], panel_thickness/2 ]) // y index
    
            cube ([panel_size, perforation_size, panel_thickness/2]);
    }
    
    
    }
    

module panel_front_two_layers_with_grooves (size_extension) {
   
    
    local_perforation_coordinates = perforations_positions(
            your_number_of_perforations=number_of_perforations, 
            size_to_cover=panel_size);
    
   echo ("Perforations coordinates", local_perforation_coordinates );
    
difference () {
          linear_extrude (height= panel_thickness) square(panel_size+size_extension);
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
    
module cone_with_wall (outer_height, large_diameter, inner_large_diameter, cone_height, small_diameter, inner_small_diameter) {
    
      translate ([0,0,outer_height/2]) difference () {
                    cube([large_diameter, large_diameter, outer_height], center=true) ;
                    cube([inner_large_diameter, inner_large_diameter, outer_height], center=true) ; } ; 
                    difference () {
                    cylinder(h=cone_height, d1=large_diameter-wall*1.2, d2=small_diameter, center=false) ;
                    cylinder(h=cone_height, d1=inner_large_diameter-wall*1.2, d2=inner_small_diameter, center=false) ; 
                    } ;
    
    }

module cone_back(outer_height, large_diameter, small_diameter, separator="wall"){
    
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
                    
                  cone_with_wall (outer_height, large_diameter, inner_large_diameter, cone_height, small_diameter, inner_small_diameter) ;
                
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

module segmented_back(wall = 0.6){
    
    segment_wall = wall ;
    shift = segment_wall ;
    
    translate ([0, 0, panel_thickness]) {
    
         // block
    
        conduct (x=panel_size, y=panel_size, z=back_depth, wall=segment_wall) ;
    
        // longer segment
       conduct (x=panel_size, y=panel_size/3, z=back_depth*2/3, wall=segment_wall) ;
            
        
        // middle segment
        translate ([0, panel_size/3, 0]) 
            conduct (x=panel_size, y=panel_size/3, z=back_depth*2/3, wall=segment_wall, closed_end = true) ;
        
        // smaller segment
       translate ([0, panel_size*2/3, 0]) 
            conduct (x=panel_size, y=panel_size/3, z=back_depth*1/3, wall=segment_wall, closed_end = true) ;
     
        
    
    } // end translate z = panel_thickness
    }
    
function separator_coordinates (number_of_separators, spacing) =  

    [for (
        
     x_order = [ 1:number_of_separators-1 ] // start at 1 because no need for a separator a the origin, there's a wall already.
    
          ) 
        
     let ( 

     x = spacing * x_order 

           ) 
     x 

    ];
    
module segmented_back_separators(wall = 0.6, gap = 20) {
    
    separator_wall = wall ;
    
    spacing = (gap+separator_wall) ;
    
    number_of_separators = panel_size / spacing ;
    
    positions = separator_coordinates (
        number_of_separators = number_of_separators , 
        spacing = spacing
         ) ;
    
    echo (positions) ;
    
    for ( i=[ 0:len(positions)-1 ] ) {
        
       translate ([ positions[i],  panel_size*1/3 , panel_thickness ])
            cube ([ separator_wall, panel_size/3, back_depth*2/3 ]) ; 
        
       translate ([ positions[i],  panel_size*2/3 , panel_thickness ])
            cube ([ separator_wall, panel_size/3, back_depth*1/3 ]);         
        }
    
    
}

module panel_with_segmented_back(type="twolayers", wall= 0.6){
    
union(){
panel_front(type=type) ;
segmented_back(wall=wall) ;
segmented_back_separators(wall=wall) ;
}

}


// COPLANAR COILED AIR CHANMBER //

module coil_angle (length, wall) { 
    
    cube ( [ length, wall, back_depth] ) ; 
    translate ([ length, 0,0]) rotate ([0, 0, 90]) cube ( [ length, wall, back_depth] ) ;
    }

module coil(coil_total_width, coil_conduct_width, wall) {
   
   angles_to_create = floor( coil_total_width/ (coil_conduct_width+wall) ) ; // ex. 5 ;
               
    x_list = [ for ( i = [ 0 : 0.5 : floor(angles_to_create/2) ] )   // ex. i = 0, 0, 1, 1, 2
                     
                   (i*2) % 2 == 0 ? angles_to_create-floor(i) : floor(i) ] ; // ex. [ 5, 0, 4, 1, 3 ]
              
    
     y_list = [ for ( i = [ 0 : 0.5 : floor(angles_to_create/2) ] )   // ex. i = 0, 0, 1, 1, 2
                     
                   (i*2) % 2 == 0 ? floor(i) : angles_to_create-floor(i) ] ; // ex. [ 0, 5, 1, 4, 2 ]
     
    
    length_list = [ for ( i = [ angles_to_create : -1 : 1 ] ) i ] ; // ex. [ 5, 4, 3, 2, 1 ]
        
    unit_size = 1 / angles_to_create * coil_total_width     ; // ex. 1/5th of coil_total_width
   
    #cube ( [ coil_total_width, wall, back_depth] ) ; // first outside wall
  
    for ( i = [ 0 : 1 : angles_to_create-1 ] ) { // off by one -1, and we skip the last, too narrow angle, so -2
        
        angle = (i*180)+90 ; 
        
        length = length_list[i]/angles_to_create * coil_total_width ; // ex. 4/5th of coil_total_width
        
        x_position = x_list[i] * unit_size  ;
        y_position = y_list[i] * unit_size  ;   
        
        translate ( [x_position, y_position, 0 ] ) rotate ([0, 0, angle])  
             coil_angle ( length = length, wall = wall) ;
        
     } // end for
     
         #translate ([0, wall, 0]) cube ( [ wall, coil_conduct_width+wall, back_depth] ) ; // close the end of conduct

   
   } // end module

module coplanar_coiled_air_chamber(coil_total_width, coil_conduct_width, wall) {

 translate ([0, 0, panel_thickness]) {

 local_perforation_coordinates = perforations_positions( your_number_of_perforations=number_of_perforations, size_to_cover=panel_size);
    
 for ( i=[ 0:len(local_perforation_coordinates)-1 ]  ) // starts from the origin of the hole 
     
        translate ([ local_perforation_coordinates[i][0], local_perforation_coordinates[i][1], 0 ]) {
            
           translate ([-coil_total_width/2+coil_conduct_width+wall/2, -coil_total_width/2-wall/2, 0]) coil(coil_total_width, coil_conduct_width, wall) ;
        }
    
    } // END translate
}


module panel_with_coplanar_coiled_air_chamber(type, size_extension=coil_conduct_width){
union(){
panel_front(type=type, size_extension=size_extension);
color ("blue") coplanar_coiled_air_chamber(coil_total_width, coil_conduct_width, wall);    
}
}



// How to call the modules : 

//panel_with_cone_back (type="twolayers", separator="wall"); // type: onelayer | twolayers, wall: tube | wall 

panel_with_segmented_back(type="twolayers") ; // type: onelayer | twolayers 

// panel_with_coplanar_coiled_air_chamber (type="onelayer", size_extension=coil_conduct_width) ; // type: onelayer | twolayers, size_extension : coil_conduct_width


//-------- FINISHING MODULE -------------//

// GLUEING PAD

glueing_pad () ;

module glueing_pad (size=40, thickness=0.30) { // to limit warping in corners
    
translate ([0, 0, panel_thickness + back_depth]) 
    intersection () {
    
  union () {  
  translate  ( [0, 0, 0 ] )  
      rotate ([0, 0, 45]) 
      cube ([size, size, thickness], center=true)  ;
   translate  ( [panel_size, 0, 0 ] )  
      rotate ([0, 0, 45]) 
      cube ([size, size, thickness], center=true) ;
  translate  ( [0, panel_size, 0 ] )  
      rotate ([0, 0, 45]) cube ([size, size, thickness], center=true) ;
  translate  ( [panel_size, panel_size, 0 ] )  
      rotate ([0, 0, 45]) cube ([size, size, thickness], center=true) ;
  }
  
  translate  ( [0, 0, -thickness/2 ] ) cube ( [panel_size, panel_size, thickness] ) ;       
      
      } 
}


// SLICING AND PRINTING AIDS

// How to call the printing aid modules : 

// modifier_block_back() ;

circular_brim () ;


module modifier_block_back () { // modifier block for use in Slic3r, to apply different printing settings to the panel and the back

     translate ([0, 0, panel_thickness]) cube ([panel_size, panel_size, back_depth ]) ;
}

module circular_brim (diameter=30, printer_first_layer_height=0.30) { // to limit warping in corners
    
  difference () {  
    
  union () {  
  translate  ( [0, 0, 0 ] )   cylinder (d = diameter, h = printer_first_layer_height)  ;
  translate  ( [panel_size, 0, 0 ] )   cylinder (d = diameter, h = printer_first_layer_height)  ;
  translate  ( [0, panel_size, 0 ] )   cylinder (d = diameter, h = printer_first_layer_height)  ;
  translate  ( [panel_size, panel_size, 0 ] )   cylinder (d = diameter, h = printer_first_layer_height)  ;
  }
  
  cube ( [panel_size, panel_size, printer_first_layer_height] ) ;    
      
      
  }
} 

