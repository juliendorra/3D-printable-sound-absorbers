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

perforation_diameter = 0.4; // must be sub-milimeter to be effective. A challenge for Fused Deposition 3D printers.

//perforation_surface =  PI*pow((perforation_diameter/2), 2);// forget the circles

perforation_surface = perforation_diameter*perforation_diameter;

panel_thickness = 0.4; // must be equal or slightly more than perforation diameter according to [ref needed - check if it's not the revers !]

panel_size = 50;

panel_surface = panel_size*panel_size;


// we need a poisson-disc uniform distribution 
// but let's start with a basic, pure random distribution that will be widly inexact because of clustering and super-imposing holes.
// But: Given hole_density give me random points to get aproximatively this density.

number_of_perforations = round( panel_surface * (perforation_density_in_percent/100) /perforation_surface ); 

// we make perforation positions a function so we can call it repeatedly when producing many modules at once, avoiding the same pattern of perforations on all modules

// we need to align the holes on a grid to better work with filament deposition

function perforations_positions(your_number_of_perforations, size_to_cover) = 

    [for (i = [ 1:your_number_of_perforations ]) 
        let ( 
            grid_size = size_to_cover/perforation_diameter, 
    
           // rands return a vector/array. we get the value out with [0]    
           
            x= perforation_diameter * round((rands(0, grid_size, 1)[0])), 
    
            y= perforation_diameter * round((rands(0, grid_size, 1)[0])) 

            ) 
    
            [ x, y ] 
    ];


module perforations (perforation_coordinates){
    
    for ( i=[ 0:len(perforation_coordinates) ] ) 
        translate ([ perforation_coordinates[i][0], perforation_coordinates[i][1], 0 ])
            square (perforation_diameter);
        
    
    }

module panel_front(){
    
    local_perforation_coordinates = perforations_positions(
            your_number_of_perforations=number_of_perforations, 
            size_to_cover=panel_size);
   
    
  linear_extrude (height= panel_thickness) difference () {
        square(panel_size);
        perforations(local_perforation_coordinates);
    } 
    
     
    }

module cone_back(){
    }

module segmented_back(){}

module panel_with_cone_back(){
union(){
panel_front();
cone_back();
}
}

module panel_with_segmented_back(){
    
    
union(){
panel_front();
segmented_back();
}
}


panel_front();

// Destructive interference panels
