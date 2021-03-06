#########################################
## runscript for rfesom                ##
## https://github.com/chrisdane/rfesom ##
#########################################

rfesompath <- "~/scripts/r/rfesom" 

# any variable already defined in rfesom/namelists/namelist.config.r can be overwritten here
if (F) {
    model <- "fesom"
    datainpaths <- "/work/ab0246/a270124/esm-experiments/awicm_pism/LIG01/outdata/fesom"
    fpatterns <- "LIG01_fesom_<varname_nc>_<YYYY>0101.nc"
    postprefix <- "LIG01"
    meshpath <- "/work/ab0246/a270064/meshes/CORE2_final"
    meshid <- "CORE2_final"
    rotate_mesh <- T 
    years <- 1935
    #varname <- "resolutionkm"
    varname <- "tos"
    recs <- 1:2
    regular_ltm_out <- T

} else if (F) { # awi-esm-1-1-lr piControl-1855:1954 = deck-1750:1849
    model <- "fesom"
    datainpaths <- "/mnt/lustre02/work/ik1017/CMIP6/data/CMIP6/CMIP/AWI/AWI-ESM-1-1-LR/piControl/r1i1p1f1/Omon/mlotst/gn/v20200212"
    fpatterns <- "<varname>_Omon_AWI-ESM-1-1-LR_piControl_r1i1p1f1_gn_<YYYY_from>01-<YYYY_to>12.nc"
    shifttime_minus1dt <- F
    postprefix <- "awi-esm-1-1-lr_piControl"
    meshpath <- "/work/ab0995/a270046/meshes_default/core"
    meshid <- "core"
    #years <- 1855:1856
    years <- 1855:1954
    season <- "SON" # "FMA"
    varname <- "mlotst"
    regular_ltm_out <- T
    regular_transient_out <- F
    transient_out <- F
    add_res_to_nc <- T
    #out_mode <- "fldmean"
    #area <- "LSboening"
    #area <- "mldWeddel"

} else if (F) { # awi-esm-1-1-lr piControl-1955:2104 = deck-1850:1999
    model <- "fesom"
    datainpaths <- "/work/ba0989/a270077/CMIP6_PMIP4/a270073/CMIP6/CMIP_PMIP/dynveg_true/PI-CTRL6/outdata/fesom"
    fpatterns <- "PI-CTRL6_fesom_<varname>_<YYYY>0101.nc"
    #postprefix <- "awi-esm-1-1-lr_piControl"
    postprefix <- "awi-esm-1-1-lr_piControl_monmax"
    meshpath <- "/work/ab0995/a270046/meshes_default/core"
    meshid <- "core"
    #years <- 2015:2016
    years <- 2015:2035 # awi-esm-1-1-lr piControl-2015:2035 = deck-1910:1930
    #years <- 1955:2104
    #season <- "SON" # "FMA" #"SON"
    #varname <- "mlotst"
    #frequency_post <- "monmean" # calc monthly means before any other stuff
    varname <- "omldamax"
    frequency_post <- "monmax"
    #varname <- "siextentn"
    regular_ltm_out <- T
    regular_transient_out <- F
    transient_out <- F
    #out_mode <- "select" # fldmean select
    #area <- "LSboening"
    #area <- "mldWeddel"

} else if (T) { # awi-esm-1-1-lr 1pctCO2
    model <- "fesom"
    datainpaths <- "/work/ba0989/a270077/CMIP6_PMIP4/a270073/CMIP6/CMIP_PMIP/dynveg_true/1percCO2/outdata/fesom"
    fpatterns <- "1percCO2_fesom_<varname>_<YYYY>0101.nc"
    #postprefix <- "awi-esm-1-1-lr_1percCO2"
    postprefix <- "awi-esm-1-1-lr_1percCO2_monmax"
    meshpath <- "/work/ab0995/a270046/meshes_default/core"
    meshid <- "core"
    years <- 1910:1930
    #season <- "SON" # "FMA"
    #varname <- "mlotst"
    #frequency_post <- "monmean" # calc monthly means before any other stuff
    varname <- "omldamax"
    frequency_post <- "monmax"
    regular_ltm_out <- T

} else if (F) { # awi-esm-1-1-lr lgm
    model <- "fesom"
    datainpaths <- "/mnt/lustre02/work/ik1017/CMIP6/data/CMIP6/PMIP/AWI/AWI-ESM-1-1-LR/lgm/r1i1p1f1/Omon/tob/gn/v20200212"
    fpatterns <- "<varname>_Omon_AWI-ESM-1-1-LR_lgm_r1i1p1f1_gn_<YYYY_from>01-<YYYY_to>12.nc"
    shifttime_minus1dt <- F
    postprefix <- "awi-esm-1-1-lr_lgm"
    meshpath <- "/work/ab0246/a270064/meshes/CORE2_lgmf"
    meshid <- "core"
    rotate_mesh <- T
    years <- 3901
    #years <- 3901:4000
    varname <- "mlotst"
    regular_ltm_out <- T

} else if (F) { # awi-cm-1-1-mr
    model <- "fesom"
    #datainpaths <- "/mnt/lustre02/work/ik1017/CMIP6/data/CMIP6/CMIP/AWI/AWI-CM-1-1-MR/piControl/r1i1p1f1/Oday/omldamax/gn/v20181218"
    #fpatterns <- "omldamax_Oday_AWI-CM-1-1-MR_piControl_r1i1p1f1_gn_<YYYY_from>0101-<YYYY_to>1231.nc"
    #postprefix <- "awi-cm-1-1-mr_piControl_monmax"
    #datainpaths <- "/mnt/lustre02/work/ik1017/CMIP6/data/CMIP6/CMIP/AWI/AWI-CM-1-1-MR/piControl/r1i1p1f1/Omon/mlotst/gn/v20181218"
    #fpatterns <- "mlotst_Omon_AWI-CM-1-1-MR_piControl_r1i1p1f1_gn_<YYYY_from>01-<YYYY_to>12.nc"
    #postprefix <- "awi-cm-1-1-mr_piControl"
    #datainpaths <- "/mnt/lustre02/work/ik1017/CMIP6/data/CMIP6/CMIP/AWI/AWI-CM-1-1-MR/historical/r1i1p1f1/Omon/mlotst/gn/v20181218"
    #fpatterns <- "mlotst_Omon_AWI-CM-1-1-MR_historical_r1i1p1f1_gn_<YYYY_from>01-<YYYY_to>12.nc"
    #postprefix <- "awi-cm-1-1-mr_historical"
    datainpaths <- "/mnt/lustre02/work/ik1017/CMIP6/data/CMIP6/CMIP/AWI/AWI-CM-1-1-MR/1pctCO2/r1i1p1f1/Oday/omldamax/gn/v20181218"
    fpatterns <- "omldamax_Oday_AWI-CM-1-1-MR_1pctCO2_r1i1p1f1_gn_<YYYY_from>0101-<YYYY_to>1231.nc"
    postprefix <- "awi-cm-1-1-mr_1pctCO2_monmax"
    #datainpaths <- "/mnt/lustre02/work/ik1017/CMIP6/data/CMIP6/CMIP/AWI/AWI-CM-1-1-MR/1pctCO2/r1i1p1f1/Omon/mlotst/gn/v20181218"
    #fpatterns <- "mlotst_Omon_AWI-CM-1-1-MR_1pctCO2_r1i1p1f1_gn_<YYYY_from>01-<YYYY_to>12.nc"
    #postprefix <- "awi-cm-1-1-mr_1pctCO2"
    shifttime_minus1dt <- F
    meshid <- "glob"
    meshpath <- paste0("/pool/data/AWICM/FESOM1/MESHES/", meshid)
    #years <- 2710:2730 # awi-cm-1-1-mr piControl-2710:2730 = deck-1910:1930
    years <- 1910:1930
    #season <- "FMA" # "SON" "FMA"
    #varname <- "mlotst" # MLD by sigma_theta
    varname <- "omldamax" # MLD by mixing scheme
    frequency_post <- "monmax" # calc monthly means before any other stuff
    #varnme <- "siextentn"
    regular_ltm_out <- T

}

postpath <- "/work/ab0246/a270073/post/fesom"
plotpath <- "/work/ab0246/a270073/plots/fesom"
derivpath <- paste0("/work/ba0941/a270073/mesh/", meshid, "/derivatives")
interppath <- paste0("/work/ba0941/a270073/mesh/", meshid, "/interp")


### do not change below this line
if (interactive()) {
    user_runscript_filename <- normalizePath(sys.frames()[[1]]$ofile)
} else {
    args <- commandArgs(trailingOnly=F)
    user_runscript_filename <- normalizePath(sub("--file=", "", args[grep("--file=", args)]))
}
source(paste0(rfesompath, "/lib/main_rfesom.r")) 
