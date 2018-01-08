/**********************************************************************/
/*   ____  ____                                                       */
/*  /   /\/   /                                                       */
/* /___/  \  /                                                        */
/* \   \   \/                                                       */
/*  \   \        Copyright (c) 2003-2009 Xilinx, Inc.                */
/*  /   /          All Right Reserved.                                 */
/* /---/   /\                                                         */
/* \   \  /  \                                                      */
/*  \___\/\___\                                                    */
/***********************************************************************/

#include "xsi.h"

struct XSI_INFO xsi_info;



int main(int argc, char **argv)
{
    xsi_init_design(argc, argv);
    xsi_register_info(&xsi_info);

    xsi_register_min_prec_unit(-12);
    work_m_00000000003266574342_1222131070_init();
    work_m_00000000003266574342_1129804446_init();
    work_m_00000000002428017387_2532022638_init();
    work_m_00000000001662062654_1931955998_init();
    work_m_00000000002738371156_2002060500_init();
    work_m_00000000000197330456_0182372474_init();
    work_m_00000000001304455177_4283663877_init();
    work_m_00000000000339650694_1532905740_init();
    work_m_00000000000897832967_0619962294_init();
    xilinxcorelib_ver_m_00000000001358910285_2552235230_init();
    xilinxcorelib_ver_m_00000000001687936702_0886988209_init();
    xilinxcorelib_ver_m_00000000000277421008_2622597481_init();
    xilinxcorelib_ver_m_00000000001603977570_3776907865_init();
    work_m_00000000002489990758_0967094757_init();
    xilinxcorelib_ver_m_00000000001358910285_3209518318_init();
    xilinxcorelib_ver_m_00000000001687936702_3826022683_init();
    xilinxcorelib_ver_m_00000000000277421008_2110283980_init();
    xilinxcorelib_ver_m_00000000001603977570_4160708712_init();
    work_m_00000000002489990758_0945855002_init();
    xilinxcorelib_ver_m_00000000001358910285_1704595891_init();
    xilinxcorelib_ver_m_00000000001687936702_3705012626_init();
    xilinxcorelib_ver_m_00000000000277421008_1727907267_init();
    xilinxcorelib_ver_m_00000000001603977570_1016489306_init();
    work_m_00000000002489990758_4286724315_init();
    work_m_00000000001304455177_3383072609_init();
    work_m_00000000000915225795_3376253697_init();
    work_m_00000000003766269350_2668991232_init();
    work_m_00000000004134447467_2073120511_init();


    xsi_register_tops("work_m_00000000003766269350_2668991232");
    xsi_register_tops("work_m_00000000004134447467_2073120511");


    return xsi_run_simulation(argc, argv);

}
