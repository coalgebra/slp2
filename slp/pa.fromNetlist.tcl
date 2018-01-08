
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name VGAdemo -dir "C:/Users/common/Desktop/New folder - Copy - Copy - Copy5/New folder - Copy - Copy - Copy/New folder - Copy - Copy - Copy/planAhead_run_1" -part xc7k160tffg676-2L
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "C:/Users/common/Desktop/New folder - Copy - Copy - Copy5/New folder - Copy - Copy - Copy/New folder - Copy - Copy - Copy/Top.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {C:/Users/common/Desktop/New folder - Copy - Copy - Copy5/New folder - Copy - Copy - Copy/New folder - Copy - Copy - Copy} {ipcore_dir} }
add_files [list {ipcore_dir/background2.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/blockerip.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/horizon.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/picture2.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/player.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/testip.ncf}] -fileset [get_property constrset [current_run]]
set_property target_constrs_file "Sword_Original.ucf" [current_fileset -constrset]
add_files [list {Sword_Original.ucf}] -fileset [get_property constrset [current_run]]
link_design
