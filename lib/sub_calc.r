## R
##
## Variable specific things
##
## input:
##
##   'data_node': 
##     dim=(nfiles,nod2d_n,ndepths=1,nrecspf) if dim_tag=="2D"
##     dim=(nfiles,nod3d_n,ndepths=1,nrecspf) if dim_tag=="3D"
##
## output:
##  
##   'data_node' got overwritten by or extended 
##   with the calculated variable
##
## notes:
##
##   horizontal derivative
##     'bafux_2d', 'bafuy_2d': dim=(3,elem2d_n)
##     'bafux_3d', 'bafuy_3d': dim=(4,elem3d_n)
##
##   horizontal integral:
##     'cluster_area_2d': dim=nod2d_n 
##     'cluster_vol_3d': dim=nod2d_n 
##
##   vertical derivative/integral:      
##     needs 'data_node'
##

sub_calc <- function(data_node) {

    #data_global <<- data # for old stuff; need to update

    ## Select one component of loaded data
    if (any(varname == c("u", "v", "initudens", "potdens", "insitub", "potb"))) {

        data_node <<- data_node[varname,,,]
        dimnames(data_node)[[1]] <<- varname

    } # "u", "v"

    ## norm of vector
    if (any(varname == c("hvel", "wind", "tau", "hvelice"))) {

        varinds <<- c(1, 2)
        if (verbose > 1) {
            message(paste0(indent, varname, " = sqrt(",
                         vars[varinds[1]], "^2 + ",
                         vars[varinds[2]], "^2) ..."))
        }

        tmp <<- sqrt(data_node[varinds[1],,,]^2 + data_node[varinds[2],,,]^2)
        if (uv_out || horiz_deriv_tag) {
            data_node <<- abind(data_node, tmp, along=1, use.dnns=T)  
            dimnames(data_node)[[1]][3] <<- varname
        } else {
            data_node <<- tmp
            dimnames(data_node)[[1]] <<- varname
        }

    } # "hvel", "wind", "tau", "hvelice"

    ## norm of mean flux
    if (any(varname == c("uvtemp", "uvsalt", "uvrho", "uvb", 
                         "uvsgstemp", "uvsgssalt", "uvsgsrho", "uvsgsb",
                         "divuvt", "divuvs", "divuvrho", "divuvb",
                         "divuvsgst", "divuvsgss", "divuvsgsrho", "divuvsgsb"))) {

        if (any(varname == c("uvtemp", "divuvt"))) {
            varinds <<- c(which(vars == "u" | vars == "uo"),
                          which(vars == "v" | vars == "vo"),
                          which(vars == "temp" | vars == "thetao"))
        } else if (any(varname == c("uvsalt", "divuvs"))) {
            varinds <<- c(which(vars == "u" | vars == "uo"),
                          which(vars == "v" | vars == "vo"),
                          which(vars == "salt" | vars == "so"))
        } else if (any(varname == c("uvrho", "divuvrho"))) {
            if (insitudens_tag) {
                varinds <<- c(which(vars == "u" | vars == "uo"),
                              which(vars == "v" | vars == "vo"),
                              which(vars == "insitudens"))
            } else if (potdens_tag) {
                varinds <<- c(which(vars == "u" | vars == "uo"),
                              which(vars == "v" | vars == "vo"),
                              which(vars == "potdens"))
            }
        } else if (any(varname == c("uvb", "divuvb"))) {
            if (insitudens_tag) {
                varinds <<- c(which(vars == "u" | vars == "uo"),
                              which(vars == "v" | vars == "vo"),
                              which(vars == "insitub"))
            } else if (potdens_tag) {
                varinds <<- c(which(vars == "u" | vars == "uo"),
                              which(vars == "v" | vars == "vo"),
                              which(vars == "potb"))
            }
        } else if (any(varname == c("uvsgstemp", "divuvsgst"))) {
            varinds <<- c(which(vars == "sgs_u"),
                          which(vars == "sgs_v"),
                          which(vars == "temp" | vars == "thetao"))
        } else if (any(varname == c("uvsgssalt", "divuvsgst"))) {
            varinds <<- c(which(vars == "sgs_u"),
                          which(vars == "sgs_v"),
                          which(vars == "salt" | vars == "so"))
        } else if (any(varname == c("uvsgsrho", "divuvsgsrho"))) {
            if (insitudens_tag) {
                varinds <<- c(which(vars == "sgs_u"),
                              which(vars == "sgs_v"),              
                              which(vars == "insitudens"))
            } else if (potdens_tag) {
                varinds <<- c(which(vars == "sgs_u"),
                              which(vars == "sgs_v"),                          
                              which(vars == "potdens"))
            }
        } else if (any(varname == c("uvsgsb", "divuvsgsb"))) {
            if (insitudens_tag) {
                varinds <<- c(which(vars == "sgs_u"),
                              which(vars == "sgs_v"),           
                              which(vars == "insitub"))
            } else if (potdens_tag) {
                varinds <<- c(which(vars == "sgs_u"),
                              which(vars == "sgs_v"),                       
                              which(vars == "potb"))
            }
        }
        if (any(is.na(varinds))) stop("Could not find data.")
       
        if (verbose > 1) {
            message(paste0(indent, "Calc ",
                         vars[1], "X", vars[3], " = ",
                         vars[varinds[1]], "*", vars[varinds[3]], ", ",
                         vars[2], "X", vars[3], " = ",
                         vars[varinds[2]], "*", vars[varinds[3]], " ..."))
        }

        utmp <<- data_node[varinds[1],,,]*data_node[varinds[3],,,]
        dimnames(utmp)[[1]] <<- paste0(vars[1], "X", vars[3])
        vtmp <<- data_node[varinds[2],,,]*data_node[varinds[3],,,]
        dimnames(vtmp)[[1]] <<- paste0(vars[2], "X", vars[3])

        ## norm of mean flux is calculated now
        if (any(varname == c("uvtemp",  "uvsalt", "uvrho", "uvb",
                             "uvsgstemp", "uvsgssalt", "uvsgsrho", "uvsgsb"))) {
        
            if (verbose > 1) {
                message(paste0(indent, varname, " = sqrt[(", 
                             vars[varinds[1]], "*", 
                             vars[varinds[3]], ")^2 + (", 
                             vars[varinds[2]], "*", 
                             vars[varinds[3]], ")^2] ..."))
            }

            tmp <<- sqrt(utmp^2 + vtmp^2)
            dimnames(tmp)[[1]] <<- varname
            if (uv_out) {
                data_node <<- abind(utmp, vtmp, tmp, along=1, use.dnns=T)
            } else {
                data_node <<- tmp
            }

        ## norm of mean flux is calculated later
        } else if (any(varname == c("divuvt",  "divuvs", "divuvrho", "divuvb",
                                    "divuvsgst", "divuvsgss", "divuvsgsrho", "divuvsgsb"))) {
            
            data_node <<- abind(utmp, vtmp, along=1, use.dnns=T)
            
        } # norm of mean flux calculated nor or later

    } # "uvtemp", "uvsalt", "uvrho", "uvb", 
      # "uvsgstemp", "uvsgssalt", "uvsgsrho", "uvsgsb",
      # "divuvt", "divuvs", "divuvrho", "divuvb",
      # "divuvsgst", "divuvsgss", "divuvsgsrho", "divuvsgsb"

    ## norm of total flux 
    if (any(varname == c("uvtemptot", "uvsalttot", "uvrhotot", "uvbtot",
                         "uvsgstemptot", "uvsgssalttot",
                         "divuvttot", "divuvstot", "divuvrhotot", "divuvbtot",
                         "divuvsgsttot", "divuvsgsstot"))) {

        if (any(varname == c("uvtemptot", "divuvtemptot"))) {
            varinds <<- c(which(vars == "utemp" | vars == "uto"),
                          which(vars == "vtemp" | vars == "vto"))
        } else if (any(varname == c("uvsalttot", "divuvsalttot"))) {
            varinds <<- c(which(vars == "usalt" | vars == "uso"),
                          which(vars == "vsalt" | vars == "vso"))
        } else if (any(varname == c("uvrhotot", "uvbtot", 
                                    "divuvrhotot", "divuvbtot"))) {
            varinds <<- c(which(vars == "urho"),
                          which(vars == "vrho"))
        } else if (any(varname == c("uvsgstemptot", "divuvsgsttot"))) {
            varinds <<- c(which(vars == "sgs_ut"),
                          which(vars == "sgs_vt"))
        } else if (any(varname == c("uvsgssalttot", "divuvsgsstot"))) {
            varinds <<- c(which(vars == "sgs_us"),
                          which(vars == "sgs_vs"))
        }
        if (any(is.na(varinds))) stop("Could not find data.")

        if (any(varname == c("uvbtot", "divuvbtot"))) {
            data_node[varinds[1],,,] <<- -g/rho0*data_node[varinds[1],,,]
            dimnames(data_node)[[1]][varinds[1]] <<- "uinsitub"
            data_node[varinds[2],,,] <<- -g/rho0*data_node[varinds[2],,,]
            dimnames(data_node)[[1]][varinds[2]] <<- "vinsitub"
            vars <<- dimnames(data_node)[[1]]
        }

        utmp <<- data_node[varinds[1],,,]
        vtmp <<- data_node[varinds[2],,,]

        if (any(varname == c("uvtemptot", "uvsalttot", "uvrhotot", "uvbtot",
                             "uvsgstemptot", "uvsgssalttot"))) {
            if (verbose > 1) {
                message(paste0(indent, varname, " = sqrt(",
                             vars[varinds[1]], "^2 + ",
                             vars[varinds[2]], "^2)"))
            }
            tmp <<- sqrt(utmp^2 + vtmp^2)
            dimnames(tmp)[[1]] <<- varname
            if (uv_out) {
                data_node <<- abind(utmp, vtmp, tmp, along=1, use.dnns=T)
            } else {
                data_node <<- tmp
            }

        } else if (any(varname == c("divuvttot", "divuvstot", "divuvrhotot", "divuvbtot",
                                    "divuvsgsttot", "divuvsgsstot"))) {
            data_node <<- abind(utmp, vtmp, along=1, use.dnns=T)

        }

    } # "uvtemptot", "uvsalttot", "uvrhotot", "uvbtot",
      # "uvsgstemptot", "uvsgssalttot",
      # "divuvttot", "divuvstot", "divuvrhotot", "divuvbtot",
      # "divuvsgsttot", "divuvsgsstot"

    ## norm of eddy flux
    if (any(varname == c("uvteddy", "uvseddy", "uvrhoeddy", "uvbeddy",
                         "uvsgsteddy", "uvsgsseddy",
                         "divuvteddy", "divuvseddy", "diuvrhoeddy", "divuvbeddy",
                         "divuvsgsteddy", "divuvsgsseddy"))) {

        if (any(varname == c("uvteddy", "divuvteddy"))) {
            varinds <<- c(which(vars == "u" | vars == "uo"),
                          which(vars == "v" | vars == "vo"),
                          which(vars == "temp" | vars == "thetao"),
                          which(vars == "utemp" | vars == "uto"),
                          which(vars == "vtemp" | vars == "vto"))
        } else if (any(varname == c("uvseddy", "divuvseddy"))) {
            varinds <<- c(which(vars == "u" | vars == "uo"),
                          which(vars == "v" | vars == "vo"),
                          which(vars == "salt" | vars == "so"),
                          which(vars == "usalt" | vars == "uso"),
                          which(vars == "vsalt" | vars == "vso"))
        } else if (any(varname == c("uvrhoeddy", "uvbeddy", 
                                    "divuvrhoeddy", "divuvbeddy"))) {
            if (insitudens_tag) {
                varinds <<- c(which(vars == "u" | vars == "uo"),
                              which(vars == "v" | vars == "vo"),
                              which(vars == "insitudens"),
                              which(vars == "urho"),
                              which(vars == "vrho"))
            } else if (potdens_tag) {
                stop(paste0("Error: _potential_ density fluxes are not available. 
                             Set 'potdens_tag' to F."))
            }
        } else if (any(varname == c("uvsgsteddy", "divuvsgsteddy"))) {
            varinds <<- c(which(vars == "sgs_u"),
                          which(vars == "sgs_v"),
                          which(vars == "temp" | vars == "thetao"),
                          which(vars == "sgs_ut"),
                          which(vars == "sgs_vt"))
        } else if (any(varname == c("uvsgsseddy", "divuvsgsseddy"))) {
            varinds <<- c(which(vars == "sgs_u"),
                          which(vars == "sgs_v"),
                          which(vars == "salt" | vars == "so"),
                          which(vars == "sgs_us"),
                          which(vars == "sgs_vs"))
        }
        if (any(is.na(varinds))) stop("Could not find data.")

        if (any(varname == c("uvbeddy", "divuvbeddy"))) {
            data_node[varinds[3],,,] <<- -g/rho0*data_node[varinds[3],,,]
            dimnames(data_node)[[1]][varinds[3]] <<- "insitub"
            data_node[varinds[4],,,] <<- -g/rho0*data_node[varinds[4],,,]
            dimnames(data_node)[[1]][varinds[4]] <<- paste0(vars[varinds[1]], "insitub")
            data_node[varinds[5],,,] <<- -g/rho0*data_node[varinds[5],,,]
            dimnames(data_node)[[1]][varinds[5]] <<- paste0(vars[varinds[2]], "insitub")
            vars <<- dimnames(data_node)[[1]]
        }

        if (verbose > 1) {
            message(paste0(indent, "Calc ", 
                         vars[varinds[4]], "_eddy = ",
                         vars[varinds[4]], " - ", vars[varinds[1]], "*", vars[varinds[3]], ", ",
                         vars[varinds[5]], "_eddy = ", 
                         vars[varinds[5]], " - ", vars[varinds[2]], "*", vars[varinds[3]], " ..."))
        }

        utmp <<- data_node[varinds[4],,,] - data_node[varinds[1],,,]*data_node[varinds[3],,,]
        dimnames(utmp)[[1]] <<- paste0(vars[varinds[4]], "_eddy")
        vtmp <<- data_node[varinds[5],,,] - data_node[varinds[2],,,]*data_node[varinds[3],,,]
        dimnames(vtmp)[[1]] <<- paste0(vars[varinds[5]], "_eddy")

        ## norm of eddy flux is calculated now
        if (any(varname == c("uvteddy", "uvseddy", "uvrhoeddy", "uvbeddy",
                             "uvsgsteddy", "uvsgsseddy"))) {

            if (verbose > 1) {
                message(paste0(indent, varname, " = sqrt( [", vars[varinds[4]],
                             " - ", vars[varinds[1]], "*", vars[varinds[3]],
                             "]^2 + [", vars[varinds[5]],  " - ",
                             vars[varinds[2]], "*", vars[varinds[3]], "]^2 )"))
            }

            tmp <<- sqrt(utmp^2 + vtmp^2)
            dimnames(tmp)[[1]] <<- varname
            if (uv_out) {
                data_node <<- abind(utmp, vtmp, tmp, along=1, use.dnns=T)
            } else {
                data_node <<- tmp
            }

        ## norm of norm of eddy flux is calculated later
        } else if (any(varname == c("divuvteddy", "divuvseddy", "diuvrhoeddy", "divuvbeddy",
                                    "divuvsgsteddy", "divuvsgsseddy"))) {

            data_node <<- abind(utmp, vtmp, along=1, use.dnns=T)

        } # if  norm of eddy flux calculated nor or later 

    } # "uvteddy", "uvseddy", "uvrhoeddy", "uvbeddy",
      # "uvsgsteddy", "uvsgsseddy",
      # "divuvteddy", "divuvseddy", "diuvrhoeddy", "divuvbeddy",
      # "divuvsgsteddy", "divuvsgsseddy"

    ## mean(u)*mean(u), mean(v)*mean(v)
    if (any(varname == c("u_u", "v_v"))) {

        if (varname == "u_u") {
            varinds <<- which(vars == "u" | vars == "uo")
        } else if (varname == "v_v") {
            varinds <<- which(vars == "v" | vars == "vo")
        }
        if (any(is.na(varinds))) stop("Could not find data.")
        data_node <<- data_node[varinds[1],,,] * data_node[varinds[1],,,]
        dimnames(data_node)[[1]] <<- varname

    } # "u_u", "v_v"

    if (varname == "wb") {

        varinds <<- c(which(vars == "w" | vars == "wo"),
                      which(vars == "insitub"))
        if (any(is.na(varinds))) stop("Could not find data.")
        if (verbose > 1) {
            message(paste0(indent, varname, " = ", varinds[1], " * ", varinds[2], " ..."))
        }

        data_node <<- data_node[varinds[1],,,]*data_node[varinds[2],,,]
        dimnames(data_node)[[1]] <<- varname

    } # wb uvb

    if (varname == "wbeddy") {

        varinds <<- c(which(vars == "w" | vars == "wo"),
                      which(vars == "insitub"),
                      which(vars == "wrho"))
        if (any(is.na(varinds))) stop("Could not find data.")
        if (verbose > 1) {
            message(paste0(indent, varname, " = mean(", vars[varinds[3]], 
                         ") - mean(", vars[varinds[1]], ")*mean(",
                         vars[varinds[2]], ") ..."))
        }
        # Mean Eddy transport mean(u'T')
        # = mean( (u - mean(u))(T - mean(T)) )
        # = mean(uT) - mean( u*mean(T) ) - mean( mean(u)*T ) + mean( mean(u)*mean(T) )
        # =    1     -          2        -         3         +           4
        # 2 = 3 = 4
        # => mean(u'T') = mean(uT) - mean(u)*mean(T)
        #
        # = in FESOM language:
        # = mean(utemp_diag.oce) - mean(u_mean.oce)*mean(temp_mean.oce)
        # with 'mean()' in the line above indicating the average
        # over the time period chosen in this script and 'u_mean.oce'
        # and 'uu_diag.oce' indicating the output of FESOM output files
        # <id>.<year>.oce.mean.nc and <id>.<year>.oce.diag.nc respectively.
        data_node <<- data_node[varinds[3],,,] - data_node[varinds[2],,,]*data_node[varinds[3],,,]
        dimnames(data_node)[[1]] <<- varname

    } # "wbeddy"

    if (any(varname == c("Nsquared", "richardson", "rossbyrad", 
                         "PmPe", 
                         "c_barocline", "c_long_rossby", 
                         "wkb_hvel_mode", "wkb_vertvel_mode"))) {

        success <<- load_package("gsw")
        if (!success) stop()
        success <<- load_package("abind")
        if (!success) stop()

        ## Calculate Absolute Salinity from Practical Salinity, pressure, longitude, and latitude.
        ## gsw_SA_from_SP(SP, p, longitude, latitude)
        ##  SP          Practical Salinity (PSS-78) [ unitless ]
        ##  p           sea pressure [dbar], i.e. absolute pressure [dbar] minus 10.1325 dbar
        ##  longitude   longitude in decimal degrees, positive to the east of Greenwich.
        ##  latitude    latitude in decimal degrees, positive to the north of the equator.
        if (verbose > 0) {
            message(paste0(indent, "Calc absolute salinity ..."))
            if (verbose > 1) {
                message(paste0(indent, "   SA = gsw_SA_from_SP(SP, p, longitude, latitude)"))
                message(paste0(indent, "      with SP        Practical Salinity (PSS-78) [ unitless ]"))
                message(paste0(indent, "           p         sea pressure [dbar], i.e. absolute pressure [dbar] minus 10.1325 dbar"))
                message(paste0(indent, "           longitude longitude in decimal degrees, positive to the east of Greenwich."))
                message(paste0(indent, "           latitude  latitude in decimal degrees, positive to the north of the equator."))
            }
        }
        saltind <<- which(vars == "salt" | vars == "so")
        if (verbose > 0) {
            message(paste0(indent, "   p = gsw_p_from_z(z, latitude, ",
                         "geo_strf_dyn_height=0 [m2 s-2], sea_surface_geopotential=0 [m2 s-2])"))
            message(paste0(indent, "      with z = zero at surface and positive upwards [ m ]"))
        }
        p_node <<- gsw::gsw_p_from_z(z=nod_z, latitude=nod_y)
        # note: gsw::* functions do not keep the matrix dimensions!!!
        SA_node <<- array(NA, dim=dim(data_node[1,,,]),
                          dimnames=dimnames(data_node[saltind,,,]))
        dimnames(SA_node)[[1]] <<- "SA"
        for (i in 1:dim(data_node)[4]) { # for nrecspf
            SA_node[,,,i] <<- gsw::gsw_SA_from_SP(SP=drop(data_node[saltind,,,i]), p=p_node,
                                                 longitude=nod_x, latitude=nod_y)
        }

        ## Calculate Conservative Temperature from Potential Temperature
        ## gsw_CT_from_pt(SA, pt)
        ##  SA  Absolute Salinity [ g/kg ]
        ##  pt  potential temperature (ITS-90) [ degC ]
        if (verbose > 0) {
            message(paste0(indent, "Calc Conservative Temperature ..."))
            if (verbose > 1) {
                message(paste0(indent, "   CT = gsw_CT_from_pt(SA, pt)"))
                message(paste0(indent, "      with SA Absolute Salinity [ g/kg ]"))
                message(paste0(indent, "           pt potential temperature (ITS-90) [ degC ]"))
            }
        }
        tempind <<- which(vars == "temp" | vars == "thetao")
        # note: gsw::* functions do not keep the matrix dimensions!!!
        CT_node <<- array(NA, dim=dim(data_node[1,,,]),
                          dimnames=dimnames(data_node[tempind,,,]))
        dimnames(CT_node)[[1]] <<- "CT"
        for (i in 1:dim(data_node)[4]) { # for nrecspf
            CT_node[,,,i] <<- gsw::gsw_CT_from_pt(SA=drop(SA_node[,,,i]), 
                                                 pt=drop(data_node[tempind,,,i]))
        }   

        ## Calc N2
        if (F) { 
            if (verbose > 0) {
                message(paste0(indent, "Calc buoyancy (Brunt-Vaisala) frequency squared N2 ..."))
            }
            # use gsw::gsw_Nsquared --> seems not to work maybe due to irregular dz?
            ## The result is computed based on first-differencing a computed density with respect pressure, and
            ## this can yield noisy results with CTD data that have not been smoothed and decimated. It also yields
            ## infinite values, for repeated adjacent pressure (e.g. this occurs twice with the ctd dataset provided
            ## in the oce package)
            if (verbose > 1) {
                message(paste0(indent, "   N2 =  gsw_Nsquared(SA, CT, p, latitude)"))
                message(paste0(indent, "      with SA       Absolute Salinity [ g/kg ]"))
                message(paste0(indent, "           CT       Conservative Temperature [ degC ]"))
                message(paste0(indent, "           p        sea pressure [dbar], i.e. absolute pressure [dbar] minus 10.1325 dbar"))
                message(paste0(indent, "           latitude latitude in decimal degrees, positive to the north of the equator"))
            }
            # note: gsw::* functions do not keep the matrix dimensions!!!
            N2_node <<- array(NA, dim=dim(data_node[1,,,]),
                              dimnames=dimnames(data_node[tempind,,,]))
            dimnames(N2_node)[[1]] <<- "N2"
            for (i in 1:dim(data_node)[4]) { # for nrecspf
                tmp <<- gsw::gsw_Nsquared(SA=drop(SA_node[,,,i]),
                                          CT=drop(CT_node[,,,i]),
                                          p=p_node, latitude=nod_y)
                # how to treat Inf and -Inf values?
                tmp$N2[tmp$N2 == Inf] <<- NA
                tmp$N2[tmp$N2 == -Inf] <<- NA
                # replace 1st depth value
                tmp$N2 <<- c(NA, tmp$N2)
                N2_node[,,,i] <<- tmp$N2 # $p_mid
            }

        } else if (T) { # use own vertical derivative of potential density
         
            if (verbose > 0) {
                message(paste0(indent, "Calc potential density rho = gsw::gsw_rho(SA, CT, p) ..."))
                message(paste0(indent, "      with SA Absolute Salinity [ g/kg ]"))
                message(paste0(indent, "           CT Conservative Temperature [ degC ]"))
                message(paste0(indent, "           p  sea pressure [dbar], i.e. absolute pressure [dbar] minus 10.1325 dbar"))

            }
 
            # note: gsw::* functions do not keep the matrix dimensions!!!
            potdens_node <<- array(NA, dim=dim(data_node[1,,,]),
                                   dimnames=dimnames(data_node[tempind,,,]))
            dimnames(potdens_node)[[1]] <<- "potdens"
            for (i in 1:dim(data_node)[4]) { # for nrecspf
                potdens_node[,,,i] <<- gsw::gsw_rho(SA=SA_node[,,,i],
                                                    CT=CT_node[,,,i],
                                                    p=p_node)
            }

            if (!keep_gsw) {
                rm(SA_node, CT_node, p_node, envir=.GlobalEnv)
            }

            if (verbose > 1) {
                message(paste0(indent, "Calc buoyancy (Brunt-Vaisala) frequency squared N2 = -g/rho * drho/dz ..."))
            }

            # vertical derivative
            pb <<- mytxtProgressBar(min=0, max=aux3d_n-1, style=pb_style,
                                    char=pb_char, width=pb_width,
                                    indent=paste0("        ", indent)) # 5 " " for default message()
            tmp <<- potdens_node
            tmp[] <<- 0
            for (i in 1:(aux3d_n-1)) {
                nodes_up <<- aux3d[i,]
                nodes_low <<- aux3d[i+1,]
                inds <<- nodes_up > 0 & nodes_low > 0
                if (any(!is.na(inds))) {
                    dz <<- nod3d_z[nodes_up[inds]] - nod3d_z[nodes_low[inds]]
                    tmp[,nodes_up[inds],,] <<- (potdens_node[,nodes_up[inds],,] -
                                                potdens_node[,nodes_low[inds],,])/dz
                }
                # update progress bar
                setTxtProgressBar(pb, i)
            } # for i aux3d_n-1
            # close progress bar
            close(pb)

            if (!keep_gsw) rm(potdens_node, envir=.GlobalEnv)

            N2_node <<- -g/potdens_node*tmp
            dimnames(N2_node)[[1]] <<- "N2"
            
            if (F) {
                N2_node_rh0 <<- -g/rho0*tmp
            }

        } # use gsw::gsw_Nsquared or own vertical derivative of potential density

        if (varname == "Nsquared") {
            data_node <<- N2_node
            dimnames(data_node)[[1]] <<- varname

        } else if (varname == "richardson") {

            if (verbose > 1) {
                message(paste0(indent, varname_plot, " = N^2/[sqrt(dudz^2 + dvdz^2)]^2 ... (Thomas et al. 2008)"))
            }

            # vertical derivative needs 'data_node'
            if (verbose > 1) {
                message(paste0(indent, "Calc global vertical derivative for all depths ..."))
            }

            varinds <<- c(which(vars == "u" | vars == "uo"),
                          which(vars == "v" | vars == "vo"))
            if (any(is.na(varinds))) stop("Could not find data.")

            dvardz_node <<- array(0, 
                                  dim=c(length(varinds), dim(data_node)[3:4]))
            dimnames(dvardz_node)[[1]] <<- dimnames(data_node)[[1]][varinds]
            dimnames(dvardz_node)[2:4] <<- dimnames(data_node)[2:4]
            
            # vertical derivative
            for (ii in 1:nod2d_n) {
                for (k in 1:(aux3d_n-1)) {
                    if (aux3d[k,ii] > 0 && aux3d[k+1,ii] > 0) {
                        node_up <<- aux3d[k,ii]
                        node_low <<- aux3d[k+1,ii]
                        dz <<- nod3d_z[node_up] - nod3d_z[node_low]

                        dvardz_node[,aux3d[k,ii],,] <<- (data_node[varinds,node_up,,] -
                                                         data_node[varinds,node_low,,])/dz
                    }
                }
            }

            data_node <<- N2_node/(sqrt(dvardz_node[1,,,]^2 + dvardz_node[2,,,]^2))^2 
            dimnames(data_node)[[1]] <<- varname

        } else if (varname == "rossbyrad") {

            if (verbose > 1) {
                message(paste0(indent, varname, "_{m=1} = 1/(m*|f|*pi) * int_{z=-H}^{z=0} N dz ..."))
            }

            data_node <<- sqrt(N2_node)

            if (verbose > 1) {
                message(paste0(indent, "Run ", subroutinepath, "sub_vertical_integral.r ..."))
            }
            sub_vertical_integral(data_node) # produces tmp
            data_node <<- tmp # dim(data_node) = c(nvars,nod2d_n,ndepths=1,nrecspf)

            data_node <<- 1/(abs(coriolis_nod2d)*pi) * data_node # 1st bc rossby rad of def.
            dimnames(data_node)[[1]] <<- varname

        } else if (any(varname == c("c_barocline", "c_long_rossby", 
                                    "wkb_hvel_mode", "wkb_vertvel_mode"))) {

            if (!exists("mmodes") || any(mmodes == 0)) {
                stop(paste0("Set 'mmodes=1' (or c(1,2,3,...)) for variable ", varname, " in namelist.var.r."))
            }

            ## N = sqrt(N2)
            N_node <<- N2_node # R does not use more memory here
            N_node[N_node < 0] <<- 0 #NA # claudi uses 0 here
            N_node <<- sqrt(N_node)
            if (verbose > 2) {
                finite_inds <<- is.finite(N_node)
                if (any(finite_inds) && any(N_node > 0)) {
                    message(paste0(indent, "   min/max N_node = ", 
                                 paste0(range(N_node[finite_inds], na.rm=T), collapse="/"), " s-1"))
                } else {
                    stop(paste0(indent, "   Error: all values of N_node = sqrt(N_node) are < 0 and/or infinite.",
                                " Change to another location/time."))
                }
            }
            dimnames(N_node)[[1]] <<- "N"
            if (!keep_gsw) rm(N2_node,  envir=.GlobalEnv)

            if (F) {
                N_node_rho0 <<- N2_node_rh0
                N_node_rho0[N_node_rho0 < 0] <<- 0
                N_node_rho0 <<- sqrt(N_node_rho0)
            }

            ## rearrange N
            if (verbose > 1) {
                message(paste0(indent, "Bring N_node from (nod3d_n=", nod3d_n,
                             ") on (nod2d_n=", nod2d_n, " x ndepths=", ndepths, ") ..."))
                if (verbose > 2) {
                    message(paste0(indent, "   run ", subroutinepath, "sub_n3_to_n2xde.r ..."))
                }
            }
            sub_n3_to_n2xde(N_node) # produces tmp
            N_vert <<- tmp

            if (F) {
                sub_n3_to_n2xde(N_node_rho0)
                N_vert_rho0 <<- tmp
            }

            ## vertical integral of N
            if (F) { # not needed since N is also integrated from depth one step later
                if (verbose > 1) {
                    message(paste0(indent, "Integrate N_node between ", depths_plot, " m ..."))
                    if (verbose > 2) {
                        message(paste0(indent, "Run ", subroutinepath, "sub_vertical_integrate.r ..."))
                    }
                }
                sub_vertical_integral(N_node) # produces tmp
                N_intz_const <<- tmp
                if (verbose > 2) {
                    finite_inds <<- is.finite(N_intz_const)
                    message(paste0(indent, "   min/max N_intz_const = ",
                                 paste0(range(N_intz_const[finite_inds], na.rm=T), collapse="/"), " m s-1"))
                }
                dimnames(N_intz_const)[[1]] <<- "int_N_dz_const"
            } # F

            ## vertical integral of N from bottom: keep z dim
            if (verbose > 1) {
                message(paste0(indent, "Integrate N_node from ", interpolate_depths[ndepths], 
                             "-", interpolate_depths[1], " m and keep z dim ..."))
                if (verbose > 2) {
                    message(paste0(indent, "Run ", subroutinepath, "sub_vertical_integrate_keepz.r ..."))
                }
            }
            sub_vertical_integral_keepz(N_node)
            N_intz_z <<- tmp
            if (!keep_gsw) rm(N_node, envir=.GlobalEnv)
            if (verbose > 2) {
                finite_inds <<- is.finite(N_intz_z)
                message(paste0(indent, "   min/max N_intz_z = ",
                             paste0(range(N_intz_z[finite_inds], na.rm=T), collapse="/"), " m s-1"))
            }

            if (F) {
                sub_vertical_integral_keepz(N_node_rho0)
                N_intz_z_rho0 <<- tmp
            }
            
            ## rearrange N_intz_z
            if (verbose > 1) {
                message(paste0(indent, "Bring N_intz_z from (nod3d_n=", nod3d_n,
                             ") on (nod2d_n=", nod2d_n, " x ndepths=", ndepths, ") ..."))
                if (verbose > 2) {
                    message(paste0(indent, "   run ", subroutinepath, "sub_n3_to_n2xde.r ..."))
                }
            }
            sub_n3_to_n2xde(N_intz_z) # produces tmp
            N_intz_z_vert <<- tmp
            if (!keep_gsw) rm(N_intz_z, envir=.GlobalEnv)
            dimnames(N_intz_z_vert)[[1]] <<- "int_N_dz_z"
  
            if (F) {
                sub_n3_to_n2xde(N_intz_z_rho0)
                N_intz_z_vert_rho0 <<- tmp
            }
            
            # for testing
            if (F) {
                N_vert_mean <<- N_vert[,poly_node_inds_geogr,,]
                N_intz_const_mean <<- N_intz_const[,poly_node_inds_geogr,,]
                N_intz_z_vert_mean <<- N_intz_z_vert[,poly_node_inds_geogr,,]
                patch_area <<- cluster_area_2d[poly_node_inds_geogr]
                patch_area <<- replicate(patch_area, n=dim(N_vert_mean)[3]) # ndepths
                patch_area <<- replicate(patch_area, n=dim(N_vert_mean)[4]) # nrecspf
                patch_area <<- replicate(patch_area, n=dim(N_vert_mean)[1]) # nvars
                patch_area <<- aperm(patch_area, c(4, 1, 2, 3))
                
                # var * area
                N_vert_mean <<- N_vert_mean*patch_area
                N_intz_const_mean <<- N_intz_const_mean*patch_area[,,1,] # 1 depth
                N_intz_z_vert_mean <<- N_intz_z_vert_mean*patch_area
                
                # sum over nodes (var * area)
                N_vert_mean <<- apply(N_vert_mean, c(1, 3, 4), sum, na.rm=T) # c(var, recs, depth)
                N_intz_const_mean <<- apply(N_intz_const_mean, c(1, 3, 4), sum, na.rm=T)
                N_intz_z_vert_mean <<- apply(N_intz_z_vert_mean, c(1, 3, 4), sum, na.rm=T)
                
                # where there are no values at depth
                N_vert_mean[N_vert_mean == 0] <<- NA
                N_intz_const_mean[N_intz_const_mean == 0] <<- NA
                N_intz_z_vert_mean[N_intz_z_vert_mean == 0] <<- NA
               
                # divide through area for all depths
                for (i in 1:dim(N_vert_mean)[2]) { # for all depths
                    if (rec_tag && leap_tag && is.leap(year)) {
                        tmp_area <<- sum(patch_area_leap[1,,i,1]) # NA positions do not change in time
                    } else {
                        tmp_area <<- sum(patch_area[1,,i,1])
                    }
                    if (T && verbose > 2) {
                        message(paste0(indent, "         area in ", interpolate_depths[i], " m depth = ", tmp_area, " m^2"))
                    }

                    N_vert_mean[,i,] <<- N_vert_mean[,i,]/tmp_area
                    if (i == 1) N_intz_const_mean[,i,] <<- N_intz_const_mean[,i,]/tmp_area
                    N_intz_z_vert_mean[,i,] <<- N_intz_z_vert_mean[,i,]/tmp_area
                } # for i ndepths

                # average over time
                N_vert_mean <<- apply(N_vert_mean, c(1, 2), mean, na.rm=T)
                N_intz_const_mean <<- apply(N_intz_const_mean, c(1, 2), mean, na.rm=T) # single number
                N_intz_z_vert_mean <<- apply(N_intz_z_vert_mean, c(1, 2), mean, na.rm=T)

                xlim <<- range(N_vert_mean,
                               N_intz_const_mean,
                               N_intz_z_vert_mean,
                               na.rm=T)
                ylim <<- rev(range(interpolate_depths))
                dev.new()
                plot(N_vert_mean[1,], interpolate_depths, t="l",
                     xlim=xlim, ylim=ylim)
                lines(N_intz_z_vert_mean[1,], interpolate_depths, col="red")
                abline(v=N_intz_const_mean[1,1], col="blue")
                legend("top", c("N_vert", "N_intz_z_vert", "N_intz_const"),
                       col=c("black", "red", "blue"), lty=1, bty="n", cex=1.5)
            } # F for testing
            #stop("asd")

            # mode-m baroclinic gravity-wave speed
            if (verbose > 0) {
                message(paste0(indent, "Calc mode-m baroclinic gravity-wave speed (Killworth et al. 1997; Chelton et al. 1998; Ferrari et al. 2010 Appendix; Vallis 2017 p. 117) ..."))
            }
            c_vert <<- array(NA, dim=c(length(mmodes), dim(N_intz_z_vert)[2], 1, dim(N_intz_z_vert)[4]),
                             dimnames=c(list(paste0("c_", mmodes)),
                                        dimnames(N_intz_z_vert)[2],
                                        list(depths=paste0("int", depths_fname)),
                                        dimnames(N_intz_z_vert)[4]))
            if (F) {
                c_vert_rho0 <<- c_vert
            }

            for (i in 1:length(mmodes)) {
                if (verbose > 0) {
                    message(paste0(indent, "   c_", mmodes[i], " = 1/(", mmodes[i], " * pi) * int_z N dz"))
                }
                #c_vert[i,,,] <<- 1/(mmodes[i]*pi) * N_intz_const
                c_vert[i,,,] <<- 1/(mmodes[i]*pi) * N_intz_z_vert[,,1,] # same at the surface
                if (verbose > 2) {
                    message(paste0(indent, "   min/max c_vert[", i, ",,,] = ",
                                 paste0(range(c_vert[i,,,], na.rm=T), collapse="/"), " m s-1"))
                }
                if (F) {
                    c_vert_rho0[i,,,] <<- 1/(mmodes[i]*pi) * N_intz_z_vert_rho0[,,1,]
                }
            } # for i mmodes

            if (varname == "c_barocline") {
                data_node <<- c_vert

            } else if (any(varname == c("c_long_rossby", "internal_rossbyrad"))) {

                f_vert <<- 2*2*pi/86400*sin(ycsur*pi/180)
                beta_vert <<- 2*2*pi/86400*cos(ycsur*pi/180)/Rearth
                f_vert <<- replicate(f_vert, n=dim(c_vert)[1]) # nvars
                f_vert <<- replicate(f_vert, n=dim(c_vert)[3]) # ndepths = 1
                f_vert <<- replicate(f_vert, n=dim(c_vert)[4]) # nrecspf
                f_vert <<- aperm(f_vert, c(2, 1, 3, 4))
                beta_vert <<- replicate(beta_vert, n=dim(c_vert)[1]) # nvars
                beta_vert <<- replicate(beta_vert, n=dim(c_vert)[3]) # ndepths = 1
                beta_vert <<- replicate(beta_vert, n=dim(c_vert)[4]) # nrecspf
                beta_vert <<- aperm(beta_vert, c(2, 1, 3, 4))

                if (verbose > 0) {
                    message(paste0(indent, "internal_rossbyrad = c_barocline/|f|               for  |phi| >= 5° latitude"))
                    message(paste0(indent, "                   = sqrt( c_barocline/(2*beta) )  for  |phi| <= 5° latitude (Chelton et al. 1998) ..."))
                }
                int_rossbyrad_node <<- c_vert/abs(f_vert)
                eq_inds <<- which(abs(ycsur) <= 5)
                if (length(eq_inds) > 0) {
                    int_rossbyrad_node[,eq_inds,,] <<- sqrt( c_vert[,eq_inds,,]/(2*beta_vert[,eq_inds,,]) )
                }
                #rm(eq_inds, envir=.GlobalEnv)

                if (F) {
                    int_rossbyrad_node_rho0 <<- c_vert_rho0/abs(f_vert)
                }

                if (varname == "internal_rossbyrad") {
                    data_node <<- int_rossbyrad_node
                    dimnames(data_node)[[1]] <<- paste0(varname, "_", mmodes)
                
                } else if (varname == "c_long_rossby") {
                    if (verbose > 0) {
                        message(paste0(indent, varname, " = -beta * internal_rossbyrad^2 = -beta/f^2 * c_barocline^2 (Killworth et al. 1997; Chelton et al. 1998) ..."))
                    }
                    data_node <<- -beta_vert * int_rossbyrad_node^2
                    dimnames(data_node)[[1]] <<- paste0(varname, "_", mmodes)

                    if (F) {
                        data_node_rho0 <<- -beta_vert * int_rossbyrad_node_rho0^2
                        data_node <<- data_node_rho0 # differences between /rho0 and /rho are very small
                    }

                } # "c_long_rossby" "internal_rossbyrad"

                rm(f_vert, beta_vert, envir=.GlobalEnv)

            } else if (any(varname == c("wkb_hvel_mode", "wkb_vertvel_mode"))) {

                ## repeat c_vert for matrix multiplication
                c_vert <<- adrop(c_vert, drop=3) # drop depth placeholder dim
                c_vert <<- replicate(c_vert, n=dim(N_vert)[3]) # ndepths
                c_vert <<- aperm(c_vert, c(1, 2, 4, 3)) # c(mmodes,nod2d_n,ndepths,nrecspf)

                ## S0
                # Chelton et al. 1998: S0_C98 = (N/c)^(-1/2)
                # Ferrari et al. 2010: "S0 must have an inverse relation to the buoyancy frequency"
                # Vallis 2017 (p. 117): S0_V17 = (c/N)^(1/2) 
                # --> S0_C98 = S0_V17 !!!
               
                if (varname == "wkb_hvel_mode") {

                    # mode-m baroclinic horizontal velocity
                    if (verbose > 0) {
                        message(paste0(indent, "Calc baroclinic horizontal velocity modes (Ferrari et al. 2010 Appendix; Vallis 2017 p. 117) ..."))
                    }
                    R_vert <<- array(NA, dim=dim(c_vert),
                                     dimnames=dimnames(c_vert))
                    dimnames(R_vert)[[1]] <<- paste0("R_", mmodes)
                    for (i in 1:length(mmodes)) {
                        if (verbose > 0) {
                            message(paste0(indent, "   R_", mmodes[i], "(z) = -[c_", 
                                         mmodes[i], " * N(z) * S_", mmodes[i], "^0 / g] * cos(int_z N(z) dz / c_", 
                                         mmodes[i], ")"))
                            message(paste0(indent, "      with S_", mmodes[i], "^0 = (c_", mmodes[i], "/N)^(1/2)"))
                        }
                        S0 <<- (c_vert[i,,,]/N_vert)^(1/2) # from Vallis 2017
                        R_vert[i,,,] <<- -(c_vert[i,,,] * N_vert[1,,,] / g * S0) * cos(N_intz_z_vert[1,,,] / c_vert[i,,,]) # [#]
                        if (verbose > 2) {
                            message(paste0(indent, "   min/max R_vert[", i, ",,,] = ",
                                         paste0(range(R_vert[i,,,], na.rm=T), collapse="/"), " [#]"))
                        }
                    } # for i mmodes
                    dimnames(R_vert)[[1]] <<- paste0(varname, mmodes)

                    # cat everything together
                    #data_node <<- abind(N_vert, c_vert, R_vert, along=1, use.dnns=T)
                    data_node <<- R_vert
                    
                    if (!keep_gsw) rm(R_vert, envir=.GlobalEnv)

                } else if (varname == "wkb_vertvel_mode") {

                    # mode-m baroclinic vertical velocity
                    if (verbose > 0) {
                        message(paste0(indent, "Calc baroclinic vertical velocity modes (Chelton et al. 1998 Appendix; Ferrari et al. 2010 Appendix; Vallis 2017 p. 117) ..."))
                    }
                    S_vert <<- array(NA, dim=dim(c_vert),
                                     dimnames=dimnames(c_vert))
                    dimnames(S_vert)[[1]] <<- paste0("S_", mmodes)
                    for (i in 1:length(mmodes)) {
                        if (verbose > 0) {
                            # ferrari = chelton since (a/b)^(1/2) = (b/a)^(-1/2)
                            if (T) { # ferrari
                                message(paste0(indent, "   S_", mmodes[i], "(z) = S_", mmodes[i], 
                                             "^0 sin(int_z N(z) dz / c_", mmodes[i], ")"))
                            } else if (F) { # chelton
                                message(paste0(indent, "   S_", mmodes[i], "(z) = [N(z)/c_", mmodes[i], "]^(-1/2) ",
                                             " sin(int_z N(z) dz / c_", mmodes[i], ")"))
                            }
                            message(paste0(indent, "      with S_", mmodes[i], "^0 = (c_", mmodes[i], "/N)^(1/2)"))
                        }
                        S0 <<- (c_vert[i,,,]/N_vert)^(1/2) # from Vallis 2017
                        # ferrari = chelton since (a/b)^(1/2) = (b/a)^(-1/2)
                        if (T) { # ferrari
                            S_vert[i,,,] <<- S0 * sin(N_intz_z_vert[1,,,] / c_vert[i,,,]) # [#]
                        } else if (F) { # chelton (B = 1)
                            S_vert[i,,,] <<- (N_vert[1,,,]/c_vert[i,,,])^(-1/2) * sin(N_intz_z_vert[1,,,] / c_vert[i,,,])
                        }
                        if (verbose > 2) {
                            message(paste0(indent, "   min/max R_vert[", i, ",,,] = ",
                                         paste0(range(R_vert[i,,,], na.rm=T), collapse="/"), " [#]"))
                        }
                    } # for i mmodes
                    dimnames(S_vert)[[1]] <<- paste0(varname, mmodes)

                    if (F) {
                        S_vert_mean <<- apply(S_vert[,poly_node_inds_geogr,,], c(1, 3, 4), mean, na.rm=T)
                        S_vert_mean <<- apply(S_vert_mean, c(1, 2), mean, na.rm=T)
                        dev.new()
                        plot(S_vert_mean[1,], interpolate_depths, t="n", 
                             xlim=range(S_vert_mean, na.rm=T), ylim=rev(range(interpolate_depths)))
                        abline(v=0, col="gray")
                        for (i in 1:dim(S_vert_mean)[1]) lines(S_vert_mean[i,], interpolate_depths, col=i)
                        legend("bottomleft", paste0("S", mmodes),
                               lty=1, col=mmodes, bty="n", cex=1.5)
                        stop("asd")
                    }

                    #stop("asd")

                    # cat everything together
                    #data_node <<- abind(N_vert, c_vert, R_vert, along=1, use.dnns=T)
                    data_node <<- S_vert

                    if (!keep_gsw) rm(S_vert, envir=.GlobalEnv)

                } # wkb_hvel_mode or wkb_vertvel_mode

                if (!keep_gsw) rm(S0, envir=.GlobalEnv)

            } # "wkb_hvel_mode", "wkb_vertvel_mode"

            if (!keep_gsw) rm(c_vert, N_intz_z_vert, N_vert, envir=.GlobalEnv)

        } # "c_barocline", "c_long_rossby", "wkb_hvel_mode", "wkb_vertvel_mode"

    } # "Nsquared", "richardson", "rossbyrad", "PmPe", "c_barocline", "c_long_rossby", "wkb_hvel_mode", "wkb_vertvel_mode"

    if (varname == "mke") {

        varinds <<- c(which(vars == "u" | vars == "uo"),
                      which(vars == "v" | vars == "vo"))
        if (any(is.na(varinds))) stop("Could not find data.")
        if (verbose > 1) {
            message(paste0(indent, "MKE = 1/2 mean(", vars[varinds[1]], 
                         "^2 + ", vars[varinds[2]], "^2) ..."))
        }

        data_node <<- 1/2*(data_node[varinds[1],,,]^2 + 
                           data_node[varinds[2],,,]^2)
        dimnames(data_node)[[1]] <<- varname

    } # "mke"

    if (varname == "tke") {

        varinds <<- c(which(vars == "uu" | vars == "u2o"),
                      which(vars == "vv" | vars == "v2o"))
        if (any(is.na(varinds))) stop("Could not find data.")
        if (verbose > 1) {
            message(paste0(indent, "TKE = 1/2 mean(", vars[varinds[1]], 
                         "^2 + ", vars[varinds[2]], "^2) ..."))
        }

        data_node <<- 1/2*(data_node[varinds[1],,,]^2 +
                           data_node[varinds[2],,,]^2)
        dimnames(data_node)[[1]] <<- varname

    } # "tke"

    if (varname == "eke") {
        
        varinds <<- c(which(vars == "uu" | vars == "u2o"),
                      which(vars == "u" | vars == "uo"),
                      which(vars == "vv" | vars == "v2o"),
                      which(vars == "v" | vars == "vo"))
        if (any(is.na(varinds))) stop("Could not find data.")
        if (verbose > 1) {
            message(paste0(indent, "EKE = 1/2 [ mean(",
                         vars[varinds[1]], ") - mean(",
                         vars[varinds[2]], ")^2 + mean(",
                         vars[varinds[3]], ") - mean(",
                         vars[varinds[4]], ")^2 ] ..."))
        }
        
        # Eddy kinetic energy (EKE)
        # = 1/2 mean( \vec{v'_h}^2 ) (from kinetic energy definition)
        # with \vec{v'_h} = (\vec{i}*u' + \vec{j}*v')
        #               u = mean(u) + u' <=> u' = u - mean(u)
        #               v = mean(v) + v' <=> v' = v - mean(v)
        # = 1/2 [ mean( (u-mean(u))^2 ) + mean( (v-mean(v))^2 ) ]
        # = 1/2 [ mean(u^2) - mean(2 mean(u) u) + mean(mean(u)^2) +
        #         mean(v^2) - mean(2 mean(v) v) + mean(mean(v)^2) ]
        # = 1/2 [ mean(u^2) - 2 mean(u)^2 + mean(u)^2 +
        #         mean(v^2) - 2 mean(v)^2 + mean(v)^2 ]
        # = 1/2 [ mean(u^2) - mean(u)^2 + mean(v^2) - mean(v)^2 ]
        #
        # = in FESOM language:
        # = 1/2 [ mean(uu_diag.oce) - mean(u_mean.oce)^2 + mean(vv_diag.oce) - mean(v_mean.oce)^2 ]
        # with 'mean()' in the line above indicating the average
        # over the time period chosen in this script and 'u_mean.oce'
        # and 'uu_diag.oce' indicating the output of FESOM output files
        # <id>.<year>.oce.mean.nc and <id>.<year>.oce.diag.nc respectively.
        data_node <<- 1/2*(data_node[varinds[1],,,] - data_node[varinds[2],,,]^2 + 
                           data_node[varinds[3],,,] - data_node[varinds[4],,,]^2) # [m^2/s^2]
        dimnames(data_node)[[1]] <<- varname

    } # "eke"

    if (varname == "twindenergy") {

        varinds <<- c(which(vars == "utaux"),
                      which(vars == "vtauy"))
        if (any(is.na(varinds))) stop("Could not find data.")
        if (verbose > 2) {
            message(paste0(indent, "TWE = ", vars[varinds[1]], 
                         " + ", vars[varinds[2]], " ... (Waterhouse et al. 2014)"))
        }

        data_node <<- data_node[varinds[1],,,] + data_node[varinds[2],,,]
        dimnames(data_node)[[1]] <<- varname

    } # "twindenergy"

    if (any(varname == c("mwindenergy", "FmKm"))) {
        varinds <<- c(which(vars == "u" | vars == "uo"),
                      which(vars == "v" | vars == "vo"),
                      which(vars == "stress_x" | vars == "tauuo"),
                      which(vars == "stress_y" | vars == "tauvo"))
        if (any(is.na(varinds))) stop("Could not find data.")
        if (verbose > 1) {
            if (varname == "mwindenergy") {
                message(paste0(indent, "MWE = mean(", vars[varinds[1]], ")*mean(", vars[varinds[3]], 
                             ") + mean(", vars[varinds[2]], ")*mean(", vars[varinds[4]], 
                             ") ... (Waterhouse et al. 2014)"))
            } else if (varname == "FmKm") {
                message(paste0(indent, varname, " = 1/rho0 * mean(", vars[varinds[1]], 
                             ")*mean(", vars[varinds[3]], ") + mean(", vars[varinds[2]], 
                             ")*mean(", vars[varinds[4]], ") ... (Renault et al. 2016)"))
            }
        }

        data_node <<- data_node[varinds[1],,,]*data_node[varinds[3],,,] +
                      data_node[varinds[2],,,]*data_node[varinds[4],,,]
        if (varname == "FmKM") {
            data_node <<- 1/rho0*data_node
        }
        dimnames(data_node)[[1]] <<- varname

    } # "mwindenergy", "FmKm"

    if (any(varname == c("ewindenergy", "FeKe"))) {
        varinds <<- c(which(vars == "u" | vars == "uo"),
                      which(vars == "v" | vars == "vo"),
                      which(vars == "stress_x" | vars == "tauuo"),
                      which(vars == "stress_y" | vars == "tauvo"),
                      which(vars == "tauxu"),
                      which(vars == "tauyv"))
        if (any(is.na(varinds))) stop("Could not find data.")
        if (verbose > 1) {
            if (varname == "ewindenergy") {
                message(paste0(indent, "EWE = (", vars[varinds[5]], " - mean(", 
                             vars[varinds[1]], ")*mean(", vars[varinds[3]], 
                             ") + ", vars[varinds[6]], " - mean(", vars[varinds[2]], 
                             ")*mean(", vars[varinds[4]], ") ... (Waterhouse et al. 2014)"))
            } else if (varname == "FeKe") {
                message(paste0(indent, varname, "= 1/rho0 * (", vars[varinds[5]], " - mean(",
                             vars[varinds[1]], ")*mean(", vars[varinds[3]],
                             ") + ", vars[varinds[6]], " - mean(", vars[varinds[2]],
                             ")*mean(", vars[varinds[4]], ") ... (Renault et al. 2016)"))
            }
        }

        data_node <<- data_node[varinds[5],,,] - data_node[varinds[1],,,]*data_node[varinds[3],,,] + 
                      data_node[varinds[6],,,] - data_node[varinds[2],,,]*data_node[varinds[4],,,]
        if (varname == "FeKe") {
            data_node <<- 1/rho0*data_node
        }
        dimnames(data_node)[[1]] <<- varname

    } # "ewindenergy", "FeKe"

    if (varname == "uv_bott_force_mean") {
        stop("update")
        data <<- C_d * (data[1,,,]^2 + data[2,,,]^2) *
                      sqrt(data[1,,,]^2 + data[2,,,]^2)
    }

    if (varname == "uv_bott_force_eddy") {
        stop("implement uv_bott_force_eddy")
    }

    ## vertical mean flux divergence
    if (any(varname == c("dzwt", "dzws", "dzwrho", "dzwb"))) {

        # vertical derivative needs 'data_node'
        if (varname == "dzwt") {
            varinds <<- c(which(vars == "w" | vars == "wo"),
                          which(vars == "temp" | vars == "thetao"))
        } else if (varname == "dzws") {
            varinds <<- c(which(vars == "w" | vars == "wo"),
                          which(vars == "salt" | vars == "so"))
        } else if (varname == "dzwrho") {
            if (insitudens_tag) {
                varinds <<- c(which(vars == "w" | vars == "wo"),
                              which(vars == "insitudens"))
            } else if (potdens_tag) {
                varinds <<- c(which(vars == "w" | vars == "wo"),
                              which(vars == "potdens"))
            }
        } else if (varname == "dzwb") {
            if (insitudens_tag) {
                varinds <<- c(which(vars == "w" | vars == "wo"),
                              which(vars == "insitub"))
            } else if (potdens_tag) {
                varinds <<- c(which(vars == "w" | vars == "wo"),
                              which(vars == "potb"))
            }
        }
        if (any(is.na(varinds))) stop("Could not find data.")

        if (verbose > 1) {
            message(paste0(indent, varname, " = d(", vars[varinds[1]], "*", 
                         vars[varinds[2]], ")/dz ..."))
        }

        data_node <<- data_node[varinds[1],,,]*data_node[varinds[2],,,]
        dimnames(data_node)[[1]] <<- paste0(vars[varinds[1]], "*", vars[varinds[2]])

        # vertical derivative
        if (verbose > 1) {
            message(paste0(indent, "Calc global vertical derivative of '",
                         dimnames(data_node)[[1]], "' for all depths ..."))
        }

        dvardz <<- array(0, dim=dim(data_node))
        dimnames(dvardz)[[1]] <<- varname
        dimnames(dvardz)[2:4] <<- dimnames(data_node)[2:4]

        # create progress bar
        pb <<- mytxtProgressBar(min=0, max=aux3d_n-1, style=pb_style,
                                char=pb_char, width=pb_width,
                                indent=paste0("     ", indent)) # 5 " " for default message()

        for (i in 1:(aux3d_n-1)) {
            nodes_up <<- aux3d[i,]
            nodes_low <<- aux3d[i+1,]
            inds <<- nodes_up > 0 & nodes_low > 0
            if (any(!is.na(inds))) {
                dz <<- nod3d_z[nodes_up[inds]] - nod3d_z[nodes_low[inds]]
                dvardz[,nodes_up[inds],,] <<- (data_node[,nodes_up[inds],,] -
                                               data_node[,nodes_low[inds],,])/dz
            }

            # update progress bar
            setTxtProgressBar(pb, i)

        } # for i aux3d_n-1

        # close progress bar
        close(pb)

        data_node <<- dvardz

    } # "dzwt", "dzws", "dzwrho", "dzwb"

    ## vertical eddy flux divergence
    if (any(varname == c("dzwbeddy"))) {

        if (varname == "dzwbeddy") {
            if (insitudens_tag) {
                varinds <<- c(which(vars == "w" | vars == "wo"),
                              which(vars == "insitub"),
                              which(vars == "wrho"))
            } else if (potdens_tag) {
                stop(paste0("Error: _potential_ density fluxes are not available. 
                             Set 'potdens_tag' to F."))
            }
        }
        if (any(is.na(varinds))) stop("Could not find data.")

        if (varname == "dzwbeddy") {
            data_node[varinds[3],,,] <<- -g/rho0*data_node[varinds[3],,,]
            dimnames(data_node)[[1]][varinds[3]] <<- paste0(vars[varinds[1]], "insitub")
            vars <<- dimnames(data_node)[[1]]
        }

        if (verbose > 1) {
            message(paste0(indent, varname, " = d(", vars[varinds[3]], " - ", 
                         vars[varinds[1]], "*", vars[varinds[2]], ")/dz ..."))
        }

        data_node <<- data_node[varinds[3],,,] - data_node[varinds[1],,,]*data_node[varinds[2],,,]
        dimnames(data_node)[[1]] <<- paste0(vars[varinds[3]], "_eddy")

        # vertical derivative
        if (verbose > 1) {
            message(paste0(indent, "Calc global vertical derivative of '",
                         dimnames(data_node)[[1]], "' for all depths ..."))
        }

        dvardz <<- array(0, dim=dim(data_node))
        dimnames(dvardz)[[1]] <<- varname
        dimnames(dvardz)[2:4] <<- dimnames(data_node)[2:4]

        # create progress bar
        pb <<- mytxtProgressBar(min=0, max=aux3d_n-1, style=pb_style,
                                char=pb_char, width=pb_width,
                                indent=paste0("     ", indent)) # 5 " " for default message()

        for (i in 1:(aux3d_n-1)) {
            nodes_up <<- aux3d[i,]
            nodes_low <<- aux3d[i+1,]
            inds <<- nodes_up > 0 & nodes_low > 0
            if (any(!is.na(inds))) {
                dz <<- nod3d_z[nodes_up[inds]] - nod3d_z[nodes_low[inds]]
                dvardz[,nodes_up[inds],,] <<- (data_node[,nodes_up[inds],,] -
                                               data_node[,nodes_low[inds],,])/dz
            }

            # update progress bar
            setTxtProgressBar(pb, i)

        } # for i aux3d_n-1

        # close progress bar
        close(pb)

        data_node <<- dvardz

    } # "dzwbeddy"

    ## vertical tracer diffusion
    if (any(varname == c("vdifft", "vdiffs", "vdiffrho", "vdiffb"))) {

        message(paste0(indent, "Warning: Kv is probably snapshot data!!!!"))

        varinds <<- which(vars == "Kv")
        if (varname == "vdifft") {
            varinds <<- c(varinds, which(vars == "temp" | vars == "thetao"))
        } else if (varname == "vdiffs") {
            varinds <<- c(varinds, which(vars == "salt" | vars == "so"))
        } else if (varname == "vdiffrho") {
            if (insitudens_tag) {
                varinds <<- c(varinds, which(vars == "insitudens"))
            } else if (potdens_tag) {
                varinds <<- c(varinds, which(vars == "potdens"))
            }
        } else if (varname == "vdiffb") {
            if (insitudens_tag) {
                varinds <<- c(varinds, which(vars == "insitub"))
            } else if (potdens_tag) {
                varinds <<- c(varinds, which(vars == "potb"))
            }
        }
        if (any(is.na(varinds))) stop("Could not find data.")

        if (verbose > 1) {
            message(paste0(indent, varname, " = d[", vars[varinds[1]], 
                         " d(", vars[varinds[2]], ")/dz]/dz ..."))
        }

        # 1st vertical derivative
        if (verbose > 1) {
            message(paste0(indent, "Calc global vertical derivative of '",
                         dimnames(data_node)[[1]][varinds[2]], "' for all depths ..."))
        }

        dvardz1 <<- array(0, dim=c(1, dim(data_node)[2:4]))
        dimnames(dvardz1)[[1]] <<- paste0("dz_", vars[varinds[2]])
        dimnames(dvardz1)[2:4] <<- dimnames(data_node)[2:4]

        # create progress bar
        pb <<- mytxtProgressBar(min=0, max=aux3d_n-1, style=pb_style,
                                char=pb_char, width=pb_width,
                                indent=paste0("     ", indent)) # 5 " " for default message()

        for (i in 1:(aux3d_n-1)) {
            nodes_up <<- aux3d[i,]
            nodes_low <<- aux3d[i+1,]
            inds <<- nodes_up > 0 & nodes_low > 0
            if (any(!is.na(inds))) {
                dz <<- nod3d_z[nodes_up[inds]] - nod3d_z[nodes_low[inds]]
                dvardz[,nodes_up[inds],,] <<- (data_node[varinds[2],nodes_up[inds],,] -
                                               data_node[varinds[2],nodes_low[inds],,])/dz
            }

            # update progress bar
            setTxtProgressBar(pb, i)

        } # for i aux3d_n-1

        # close progress bar
        close(pb)

        # Kv times first vertical derivative of tracer
        Kv_dvardz1 <<- data_node[varind[1],,,] * dvar1dz
        dimnames(Kv_dvardz1)[[1]] <<- paste0(vars[varind[1]], "*", dimnames(dvardz1)[[1]])

        # 2nd vertical derivative
        if (verbose > 1) {
            message(paste0(indent, "Calc global vertical derivative of '",
                         dimnames(Kv_dvardz1)[[1]], "' for all depths ..."))
        }

        dvardz2 <<- array(0, dim=dim(Kv_dvardz1))
        dimnames(dvardz2)[[1]] <<- varname
        dimnames(dvardz2)[2:4] <<- dimnames(data_node)[2:4]

        # create progress bar
        pb <<- mytxtProgressBar(min=0, max=aux3d_n-1, style=pb_style,
                                char=pb_char, width=pb_width,
                                indent=paste0("     ", indent)) # 5 " " for default message()

        for (i in 1:(aux3d_n-1)) {
            nodes_up <<- aux3d[i,]
            nodes_low <<- aux3d[i+1,]
            inds <<- nodes_up > 0 & nodes_low > 0
            if (any(!is.na(inds))) {
                dz <<- nod3d_z[nodes_up[inds]] - nod3d_z[nodes_low[inds]]
                dvardz2[,nodes_up[inds],,] <<- (Kv_dvardz1[,nodes_up[inds],,] -
                                                Kv_dvardz1[,nodes_low[inds],,])/dz
            }

            # update progress bar
            setTxtProgressBar(pb, i)
        
        } # for i aux3d_n

        # close progress bar
        close(pb)

        data_node <<- dvardz2

    } # "vdifft", "vdiffs", "vdiffrho", "vdiffb"

    ## vertical reynolds stress
    if (any(varname == c("VRS", "KmKe"))) {

        # vertical derivative needs 'data_node'

        # eddy flux u'w'
        varinds <<- c(which(vars == "u" | vars == "uo"),
                      which(vars == "w" | vars == "wo"),
                      which(vars == "uw"))
        if (any(is.na(varinds))) stop("Could not find data.")
        if (verbose > 1) {
            message(paste0(indent, "u'w' = ", vars[varinds[3]], " - ", 
                         vars[varinds[1]], " * ", vars[varinds[2]], " ..."))
        }
        utmp <<- data_node[varinds[3],,,] - data_node[varinds[1],,,]*data_node[varinds[2],,,]
        dimnames(utmp)[[1]] <<- paste0(dimnames(data_node)[[1]][varinds[3]], "_eddy")

        # eddy flux v'w'
        varinds <<- c(which(vars == "v" | vars == "vo"),
                      which(vars == "w" | vars == "wo"),
                      which(vars == "vw"))
        if (any(is.na(varinds))) stop("Could not find data.")
        if (verbose > 1) {
            message(paste0(indent, "v'w' = ", vars[varinds[3]], " - ", 
                         vars[varinds[1]], " * ", vars[varinds[2]], " ..."))
        }
        vtmp <<- data_node[varinds[3],,,] - data_node[varinds[1],,,]*data_node[varinds[2],,,]
        dimnames(vtmp)[[1]] <<- paste0(vars[varinds[3]], "_eddy")

        # vertical derivative
        varinds <<- c(which(vars == "u" | vars == "uo"),
                      which(vars == "v" | vars == "vo")) 
        if (any(is.na(varinds))) stop("Could not find data.")
        if (verbose > 1) {
            message(paste0(indent, "Calc global vertical derivative of '",
                         paste0(vars[varinds], collapse="','"),
                         "' for all depths ..."))
        }
        dvardz <<- array(0, 
                         dim=c(length(varinds), dim(data_node)[2:4]))
        dimnames(dvardz)[[1]] <<- paste0("dz_", vars[varinds])
        dimnames(dvardz)[2:4] <<- dimnames(data_node)[2:4]

        # create progress bar
        pb <<- mytxtProgressBar(min=0, max=aux3d_n-1, style=pb_style,
                                char=pb_char, width=pb_width,
                                indent=paste0("     ", indent)) # 5 " " for default message()

        for (i in 1:(aux3d_n-1)) {
            nodes_up <<- aux3d[i,]
            nodes_low <<- aux3d[i+1,]
            inds <<- nodes_up > 0 & nodes_low > 0
            if (any(!is.na(inds))) {
                dz <<- nod3d_z[nodes_up[inds]] - nod3d_z[nodes_low[inds]]
                dvardz[,nodes_up[inds],,] <<- (data_node[varinds,nodes_up[inds],,] -
                                               data_node[varinds,nodes_low[inds],,])/dz
            }

            # update progress bar
            setTxtProgressBar(pb, i)

        } # for i aux3d_n-1

        # close progress bar
        close(pb)

        # calc VRS
        if (verbose > 1) {
            message(paste0(indent, "VRS = - u'w'*dudz - v'w'*dvdz"))
        }
        vrs <<- -utmp*dvardz[1,,,] - vtmp*dvardz[2,,,]
        dimnames(tmp)[[1]] <<- "VRS"
        if (varname == "VRS") {
            data_node <<- vrs
        }

    } # "VRS", "KmKe"

    ## slopeSx, slopeSy, slopeS, slopeSsq
    if (any(varname == c("slopeSx", "slopeSy", "slopeS", "slopeSsq"))) {

        # vertical derivative of rho
        stop("not yet")

    } # "slopeSx", "slopeSy", "slopeS", "slopeSsq"

    if (horiz_deriv_tag) {

        ## x,y-derivatives of which variables?
        dxinds <<- NULL
        dyinds <<- NULL

        if (any(varname == c("u_geo", "slopeSy"))) {
            dyinds <<- 1
        }

        if (any(varname == c("v_geo", "slopeSx"))) {
            dxinds <<- 1
        }

        if (any(varname == c("gradT", "gradB", "gradmld", 
                             "hvel_geo", "hdiffb", 
                             "slopeS", "slopeSsq"))) {
            dxinds <<- 1
            dyinds <<- 1
        }
        
        if (any(varname == c("divuvt", "divuvttot", "divuvteddy",
                             "divuvsgst", "divuvsgsttot", "divuvsgsteddy",
                             "divuvs", "divuvstot", "divuvseddy",
                             "divuvsgss", "divuvsgsstot", "divuvsgsseddy",
                             "divuvrho", "divuvrhotot", "divuvrhoeddy",
                             "divuvsgsrho", "divuvsgsrhotot", "divuvsgsrhoeddy",
                             "divuvb", "divuvbtot", "divuvbeddy",
                             "divuvsgsb", "divuvsgsbtot", "divuvsgsbeddy",
                             "strain_normal", "strain", "okubo",
                             "HRS", "KmKe",
                             "divuvt2"))) {
            dxinds <<- 1
            dyinds <<- 2
        } 

        if (any(varname == c("relvorti", "relvortisq", "relvortif",
                             "curlwind", "curltau",
                             "RossbyNo", "ekmanP",
                             "strain_shear", "strain", "okubo",
                             "HRS", "KmKe"))) {
            dxinds <<- 2
            dyinds <<- 1
        }

        if (varname == "PmPe") {
            stop("asd")
            dxinds <<- which("rho") 
            dyinds <<- which("rho")
        }

        # check
        if (any(is.na(dxinds)) || any(is.na(dyinds))) {
            stop(paste0("Could not find data to take the horizontal derivative from."))
        }
        if (is.null(dxinds) && is.null(dyinds)) {
            if (verbose > 0) {
                stop(paste("'horiz_deriv'=T but 'dxinds' and 'dyinds' are null."))
            }
        }
        ndxy <<- length(dxinds) + length(dyinds)

        ## do stuff before horizontal derivative
        if (varname == "ekmanP") {
            if (verbose > 1) {
                message(paste0(indent, varname, " = d(", varname_fesom[2], "/f)",
                             "dx - d(", varname_fesom[1], "/f)dy ..."))
            }
            # divide through f
        }

        
        ## horizontal derivative

        ## horizontal derivative in node-space (the correct way...)
        if (horiz_deriv_node3d) {

            if (!is.null(dxinds)) {
                # dim(bafux_2d) = c(3,elem2d_n)
                if (F) {
                    bafux_2d_time_depth <<- replicate(bafux_2d, n=dim(data_node)[3]) # ndepths=1 
                    bafux_2d_time_depth <<- replicate(bafux_2d_time_depth, n=dim(data_node)[4]) # nrecspf
                    bafux_2d_time_depth <<- replicate(bafux_2d_time_depth, n=length(dxinds)) # nvars
                    bafux_2d_time_depth <<- aperm(bafux_2d_time_depth, c(5, 1, 2, 3, 4))
                    # dim(bafux_2d_time_depth) = c(nvars,3,elem2d_n,ndepths=1,nrecspf)
                } else if (T) {
                    bafux_2d_time_depth <<- replicate(bafux_2d, n=length(dxinds)) # nvars
                    bafux_2d_time_depth <<- replicate(bafux_2d_time_depth, n=dim(data_node)[4]) # nrecspf
                    bafux_2d_time_depth <<- aperm(bafux_2d_time_depth, c(3, 1, 2, 4))
                }
                dvardx_node3d <<- array(0,
                                        dim=c(length(dxinds), dim(data_node)[2:4]),
                                        dimnames=c(list(var=paste0("dx_", dimnames(data_node)[[1]][dxinds])),
                                                   dimnames(data_node)[2:4]))
                dvardx_node3d_cnt <<- dvardx_node3d[1,,,]
            }
            if (!is.null(dyinds)) {
                bafuy_2d_time_depth <<- replicate(bafuy_2d, n=length(dyinds)) # nvars
                bafuy_2d_time_depth <<- replicate(bafuy_2d_time_depth, n=dim(data_node)[4]) # nrecspf
                bafuy_2d_time_depth <<- aperm(bafuy_2d_time_depth, c(3, 1, 2, 4))
                dvardy_node3d <<- array(0,
                                        dim=c(length(dyinds), dim(data_node)[2:4]),
                                        dimnames=c(list(var=paste0("dy_", dimnames(data_node)[[1]][dyinds])),
                                                   dimnames(data_node)[2:4]))
                dvardy_node3d_cnt <<- dvardy_node3d[1,,,]
            }

            if (verbose > 1) {
                if (!is.null(dxinds)) {
                    message(paste0(indent, "Calc ", 
                                 paste0("dx_", dimnames(data_node)[[1]][dxinds], collapse=", "), " ..."))
                }
                if (!is.null(dxinds)) {
                    message(paste0(indent, "Calc ", 
                                 paste0("dy_", dimnames(data_node)[[1]][dyinds], collapse=", "), " ..."))
                }
            }

            time1 <<- array(NA, c(aux3d_n, elem2d_n))
            time2 <<- time1
            `[` <<- fctbackup # restore to default for loop

            #stop("asd")
            # create progress bar
            pb <<- mytxtProgressBar(min=0, max=ndepths, style=pb_style,
                                    char=pb_char, width=pb_width,
                                    indent=paste0("     ", indent)) # 5 " " for default message()

            #for (i in 1:aux3d_n) {
            for (i in 1:ndepths) {
                for (j in 1:elem2d_n) {
                    nds_surf <<- elem2d[,j]
                    nds_layer <<- aux3d[i,nds_surf]
                    if (all(nds_layer != -999)) {

                        #stop("asd")

                        if (!is.null(dxinds)) {
                            #message(paste0(i, " ", j, " xxx"))
                            #aux <<- adrop(bafux_2d_time_depth[,,j,,], drop=3)*data_node[dxinds,nds_layer,,] 
                            # c(nvars,3,ndepths=1,nrecspf)*c(nvars,3,ndepths=1,nrecspf)
                           
                            if (F) {
                                ptm <<- proc.time()[3]
                                aux <<- bafux_2d_time_depth[,,j,]*data_node[dxinds,nds_layer,,]
                                aux <<- apply(aux, 4, sum) # sum over all nodes of 2d element
                                aux <<- replicate(aux, n=length(dxinds))
                                aux <<- replicate(aux, n=3) # 3 nodes per 2d element
                                aux <<- replicate(aux, n=1) # ndepths
                                dvardx_node3d[,nds_layer,,] <<- dvardx_node3d[,nds_layer,,] + aperm(aux, c(4, 3, 2, 1))
                                time1[i,j] <<- proc.time()[3] - ptm
                            } else if (F) {
                                ptm <<- proc.time()[3]
                                aux <<- bafux_2d_time_depth[,,j,]*data_node[dxinds,nds_layer,,]
                                tmp <<- array(0, dim=dim(aux))
                                aux <<- apply(aux, c(1, 3, 4), sum) # keep nvars,ndepths=1,nrecspf
                                tmp[,1,,] <<- aux
                                tmp[,2,,] <<- aux
                                tmp[,3,,] <<- aux
                                dvardx_node3d[,nds_layer,,] <<- dvardx_node3d[,nds_layer,,] + tmp
                                time1[i,j] <<- proc.time()[3] - ptm
                            ## for some reason this is the fastest:
                            } else if (T) { # with original `[`
                                ptm <<- proc.time()[3]
                                aux <<- bafux_2d_time_depth[,,j,,drop=F]*data_node[dxinds,nds_layer,,,drop=F]
                                for (k in 1:dim(aux)[1]) { # for all vars
                                    aux <<- apply(aux[k,,,,drop=F], c(1, 4), sum)[1,]
                                    dvardx_node3d[k,nds_layer,,] <<- dvardx_node3d[k,nds_layer,1,] + t(array(aux, c(length(aux), 3)))
                                }
                                time1[i,j] <<- proc.time()[3] - ptm
                            ## for some reason this is not correct:
                            } else if (F) { # with original `[`
                                ptm <<- proc.time()[3]
                                for (k in 1:dim(data_node)[4]) { # nrecspf
                                    for (l in 1:length(dxinds)) { # nvars
                                        aux <<- bafux_2d_time_depth[l,,j,k]*data_node[dxinds[l],nds_layer,1,k]
                                        dvardx_node3d[l,nds_layer,1,k] <<- dvardx_node3d[l,nds_layer,1,k] + aux
                                    }
                                }
                                time1[i,j] <<- proc.time()[3] - ptm
                            }
                            dvardx_node3d_cnt[,nds_layer,,] <<- dvardx_node3d_cnt[,nds_layer,,] + 1
                        } # if !is.null(dxinds)

                        if (!is.null(dyinds)) {
                            if (F) {
                                aux <<- bafuy_2d_time_depth[,,j,]*data_node[dyinds,nds_layer,,]
                                aux <<- apply(aux, 4, sum) # sum over all nodes of 2d element
                                aux <<- replicate(aux, n=length(dyinds))
                                aux <<- replicate(aux, n=3) # 3 nodes per 2d element
                                aux <<- replicate(aux, n=1) # ndepths
                                dvardy_node3d[,nds_layer,,] <<- dvardy_node3d[,nds_layer,,] + aperm(aux, c(4, 3, 2, 1))
                            } else if (F) {
                                aux <<- bafuy_2d_time_depth[,,j,]*data_node[dyinds,nds_layer,,]
                                tmp <<- array(0, dim=dim(aux))
                                aux <<- apply(aux, c(1, 3, 4), sum) # keep nvars,ndepths=1,nrecspf
                                tmp[,1,,] <<- aux
                                tmp[,2,,] <<- aux
                                tmp[,3,,] <<- aux
                                dvardy_node3d[,nds_layer,,] <<- dvardy_node3d[,nds_layer,,] + tmp
                            } else if (T) {
                                ptm <<- proc.time()[3]
                                aux <<- bafuy_2d_time_depth[,,j,,drop=F]*data_node[dyinds,nds_layer,,,drop=F]
                                for (k in 1:dim(aux)[1]) {
                                    aux <<- apply(aux[k,,,,drop=F], c(1, 4), sum)[1,]
                                    dvardy_node3d[k,nds_layer,,] <<- dvardy_node3d[k,nds_layer,1,] + t(array(aux, c(length(aux), 3)))
                                }
                                time2[i,j] <<- proc.time()[3] - ptm
                            } else if (F) {
                                ptm <<- proc.time()[3]
                                for (k in 1:dim(data_node)[4]) { # nrecspf
                                    for (l in 1:length(dyinds)) { # nvars
                                        aux <<- bafuy_2d_time_depth[l,,j,k]*data_node[dyinds[l],nds_layer,1,k]
                                        dvardy_node3d[l,nds_layer,1,k] <<- dvardy_node3d[l,nds_layer,1,k] + aux
                                    }   
                                }   
                                time2[i,j] <<- proc.time()[3] - ptm
                            }
                            dvardy_node3d_cnt[,nds_layer,,] <<- dvardy_node3d_cnt[,nds_layer,,] + 1
                        } # if !is.null(dyinds)

                    } # if not -999
                } # for j elem2d_n

                # update progress bar
                setTxtProgressBar(pb, i)

            } # for i ndepths

            # close progress bar
            close(pb)

            fctbackup <<- `[`; `[` <<- function(...) { fctbackup(..., drop=F) }

            if (!is.null(dxinds)) {
                dvardx_node3d <<- dvardx_node3d/dvardx_node3d_cnt
                dvardx_node3d[is.na(dvardx_node3d)] <<- 0
            } # if !is.null(dxinds)

            if (!is.null(dyinds)) {
                dvardy_node3d <<- dvardy_node3d/dvardy_node3d_cnt
                dvardy_node3d[is.na(dvardy_node3d)] <<- 0
            }

        } # if horiz_deriv_node3d


        ## horizontal derivative in level space which is much faster than in node-space
        ## but somehow it doenst work yet ...
        if (horiz_deriv_elem2d) {
        
            ## bring data on level space
            if (dim_tag == "2D" 
                || average_depth
                || (dim_tag == "3D" && ndepths == 1)) {

                # nothing to do
                data_vert <<- data_node # dim(data_vert) = c(nvars,nod2d_n,ndepths=1,nrecspf)

            } else {

                if (verbose > 1) { # rearrange first
                    message(paste0(indent, "Bring data from (nod3d_n=", nod3d_n,
                                 ") on (nod2d_n=", nod2d_n, " x ndepths=", ndepths, ") ..."))
                    message(paste0(indent, "   run ", subroutinepath, "sub_n3_to_n2xde.r ..."))
                }
                sub_n3_to_n2xde(data_node) # produces tmp
                data_vert <<- tmp # dim(data_vert) = c(nvars,nod2d_n,ndepths,nrecspf)

            } # if dim_tag == "3D" --> rearrange before horiz deriv

            ## bring derivative and data on same dimensions
            # dim(bafux_2d) = c(3,elem2d_n)
            bafux_2d_vert <<- replicate(bafux_2d, n=1) # only once for nvars
            bafuy_2d_vert <<- replicate(bafuy_2d, n=1)
            bafux_2d_vert <<- aperm(bafux_2d_vert, c(3, 1, 2)) # c(1, 3, elem2d_n)
            bafuy_2d_vert <<- aperm(bafuy_2d_vert, c(3, 1, 2))
            bafux_2d_vert <<- replicate(bafux_2d_vert, n=dim(data_vert)[3]) # ndepths
            bafuy_2d_vert <<- replicate(bafuy_2d_vert, n=dim(data_vert)[3])
            bafux_2d_vert <<- replicate(bafux_2d_vert, n=dim(data_vert)[4]) # nrecspf
            bafuy_2d_vert <<- replicate(bafuy_2d_vert, n=dim(data_vert)[4])
            # dim(bafux_2d_vert) = c(1,3,elem2d_n,ndepths,nrecspf)
            ## note: avoid using huge bafux_3d: dim=c(4,elem3d_n)

            ## put data from nodes on elems
            if (verbose > 1) {
                message(paste0(indent, "Bring data from (nod2d_n=", nod2d_n, " x ndepths=", 
                             dim(data_vert)[3], ") on (3 x elem2d_n=", elem2d_n, " x ndepths=", 
                             dim(data_vert)[3], ") for horizontal derivative ..."))
            }
            data_elem <<- array(data_vert[c(dxinds,dyinds),pos[elem2d],,],
                                dim=c(ndxy, 3, elem2d_n,           # nvars, 3 nodes per 2D-element, nelem2d
                                      dim(data_vert)[3:4]),        # ndepth, nrecspf
                                dimnames=c(list(var=dimnames(data_vert)[[1]][c(dxinds,dyinds)]),
                                           list(node=1:3, elem=NULL), # do not name elem dim saves memory
                                           dimnames(data_vert)[3:4]))
            # dim(data_elem) = c(nvars,3,elem2d_n,ndepths,nrecspf)

            ## horizontal derivatives
            if (!is.null(dxinds)) {
                if (verbose > 1) {
                    message(paste0(indent, "Calc dx for interpolated depths ..."))
                }
                dvardx_elem <<- array(0, 
                                      dim=c(length(dxinds), 1, dim(data_elem)[3:5]),
                                      dimnames=c(list(var=paste0("dx_", dimnames(data_elem)[[1]][dxinds], "_elem2d")),
                                                 list(node=NULL),
                                                 dimnames(data_elem)[3:5]))
                # dim(data_elem)     = c(nvars, 3,elem2d_n,ndepths,nrecspf)
                # dim(bafux_2d_vert) = c(1,     3,elem2d_n,ndepths,nrecspf)
                # dim(dvardx_elem)   = c(dxinds,1,elem2d_n,ndepths,nrecspf)
                for (i in 1:length(dxinds)) { # for all variables
                    for (j in 1:3) { # for all 3 nodes of a 2D-element
                        dvardx_elem[i,1,,,] <<- dvardx_elem[i,1,,,] + data_elem[dxinds[i],j,,,]*bafux_2d_vert[1,j,,,]
                    }
                }
            }
            if (!is.null(dyinds)) {
                if (verbose > 1) {
                    message(paste0(indent, "Calc dy for interpolated depths ..."))
                }
                dvardy_elem <<- array(0,
                                      dim=c(length(dyinds), 1, dim(data_elem)[3:5]),
                                      dimnames=c(list(var=paste0("dy_", dimnames(data_elem)[[1]][dyinds], "_elem2d")),
                                                 list(node=NULL),
                                                 dimnames(data_elem)[3:5]))
                for (i in 1:length(dyinds)) {
                    for (j in 1:3) {
                        dvardy_elem[i,1,,,] <<- dvardy_elem[i,1,,,] + data_elem[dyinds[i],j,,,]*bafuy_2d_vert[1,j,,,]
                    }
                }
            }

            ## bring derivative back from (elem2d_n x ndepths) to (nod2d_n x ndepths)
            if (verbose > 1) {
                message(paste0(indent, "Bring derivative back from (3 x elem2d_n=", elem2d_n, " x ndepths=", 
                             dim(dvardy_elem)[4], ") on (nod2d_n=", nod2d_n, " x ndepths=", 
                             dim(dvardy_elem)[4], ") ..."))
                message(paste0(indent, "   run ", subroutinepath, "sub_e2xde_to_n2xde.r ..."))
            }
            if (!is.null(dxinds)) {
                sub_e2xde_to_n2xde(dvardx_elem) # produces tmp
            }
            dvardx_vert <<- tmp # dim(dvardx_vert) = c(nvars,nod2d_n,ndepths,nrecspf)
            if (!is.null(dyinds)) {
                sub_e2xde_to_n2xde(dvardy_elem) 
            }
            dvardy_vert <<- tmp


            ## bring derivative back from (nod2d_n x ndepths) to (nod3d_n) if possible
            if (dim_tag == "2D" 
                || average_depth
                || (dim_tag == "3D" && ndepths == 1)) {

                # nothing to do
                if (!is.null(dxinds)) {
                    dvardx_node <<- dvardx_vert # dim(dvardx_node) = c(nvars,nod2d_n,ndepths=1,nrecspf)
                }
                if (!is.null(dyinds)) {
                    dvardy_node <<- dvardy_vert
                }

            } else {

                if (!is.null(dxinds)) {
                    if (verbose > 1) {
                        message(paste0(indent, "Bring dvardx_vert back from (nod2d_n=", nod2d_n,
                                     " x ndepths=", dim(dvardx_vert)[3], ") on (nod3d_n=", nod3d_n, ") ..."))
                        message(paste0(indent, "   run ", subroutinepath, "sub_n2xde_to_n3.r ..."))
                    }
                    sub_n2xde_to_n3(dvardx_vert) # produces tmp
                    dvardx_node <<- tmp # dim(dvardx_node) = c(nvars,nod3d_n,ndepths=1,nrecspf)
                    #stop("asd")
                    if (F) {
                        for (i in 1:dim(dvardx_vert)[3]) {
                            indz <<- ((i-1)*nod2d_n + 1):(i*nod2d_n)
                            message(paste0(i, ": ", min(indz), "/", max(indz)))
                            d <<- dvardx_node[,indz,,1] - dvardx_vert[,,i,1]
                            message(range(d, na.rm=T))
                        }
                    }
                }
                if (!is.null(dyinds)) {
                    if (verbose > 1) {
                        message(paste0(indent, "Bring dvardy_vert back from (nod2d_n=", nod2d_n,
                                     " x ndepths=", dim(dvardy_vert)[3], ") on (nod3d_n=", nod3d_n, ") ..."))
                        message(paste0(indent, "   run ", subroutinepath, "sub_n2xde_to_n3.r ..."))
                    }
                    sub_n2xde_to_n3(dvardy_vert) 
                    dvardy_node <<- tmp 
                }
            }

        } # if horiz_elem_2d

        ## At this point,
        ##  if dim_tag == "2D":
        ##      dim(data_node) = c(nvars,nod2d_n,ndepths=1,nrecspf)
        ##      dim(dvardx_node) = c(nvars,nod2d_n,ndepths=1,nrecspf)
        ##  if dim_tag == "3D":       
        ##      dim(data_node) = c(nvars,nod3d_n,ndepths=1,nrecspf)
        ##      dim(dvardx_node) = c(nvars,nod3d_n,ndepths=1,nrecspf)
        ##  if horiz_derive_node3d 
        ##      dim(dvardx_node3d) = c(nvars,nod3d_n,ndepths=1,nrecpsf)


        ## Do stuff after horizontal derivative
        if (varname == "gradT") {
            message(paste0(indent, varname_plot, " = sqrt[ (dT/dx)^2 + (dT/dy)^2 ] ..."))
                  data <<- sqrt(dvar1dx^2 + dvar1dy^2)
        }

        if (varname == "gradB") {
            message(paste0(indent, varname_plot, " = sqrt[ (-g/rho0)^2 * ( (drho/dx)^2 + (drho/dy)^2 ) ] ..."))
            data <<- sqrt((-g/rho0)^2 * (dvar1dx^2 + dvar1dy^2))

        }

        if (varname == "gradmld") {
            message(paste0(indent, varname_plot, " = sqrt[ (dmld/dx)^2 + (dmld/dy)^2 ] ..."))
        }
        if (varname == "u_geo") {
            message(paste0(indent, varname_plot, " = -g/f dSSH/dy ..."))
        }
        if (varname == "v_geo") {
            message(paste0(indent, varname_plot, " = g/f dSSH/dx ..."))
        }
        if (varname == "hvel_geo") {
            message(paste0(indent, varname_plot, " = sqrt([-g/f dSSH/dy]² + [g/f dSSH/dx]²) ..."))
        }
        if (varname == "hdiffb") {
            message(paste0(indent, varname, " = d(K_h*dbdx)/dx + d(K_h*dbdy)/dy ..."))
        }

        if (any(varname == c("divuvt", "divuvteddy", 
                             "divuvsgst", "divuvsgsteddy", "divuvsgsttot",
                             "divuvs", "divuvseddy",
                             "divuvsgss", "divuvsgsseddy", "divuvsgsstot"))) {

            varinds <<- c(1, 1)
           
            if (horiz_deriv_elem2d) {
                if (verbose > 1) {
                    message(paste0(indent, varname, " = ", dimnames(dvardx_node)[[1]][varinds[1]], 
                                 " + ", dimnames(dvardy_node)[[1]][varinds[2]], " ..."))
                }
                tmp <<- dvardx_node[varinds[1],,,] + dvardy_node[varinds[2],,,]
                dimnames(tmp)[[1]] <<- paste0(varname, "_elem2d")
                if (uv_out) {
                    data_node <<- abind(dvardx_node, dvardy_node, tmp, along=1, use.dnns=T)
                } else {
                    data_node <<- tmp
                }
            }

            if (horiz_deriv_node3d) {
                if (verbose > 1) {
                    message(paste0(indent, varname, " = ", dimnames(dvardx_node3d)[[1]][varinds[1]],
                                 " + ", dimnames(dvardy_node3d)[[1]][varinds[2]], " ..."))
                }
                tmp <<- dvardx_node3d[varinds[1],,,] + dvardy_node3d[varinds[2],,,]
                dimnames(tmp)[[1]] <<- varname
                if (uv_out) {
                    data_node3d <<- abind(dvardx_node3d, dvardy_node3d, tmp, along=1, use.dnns=T)
                } else {
                    data_node3d <<- tmp
                }
            }

            # for comparison cat both derivatives together ...
            if (horiz_deriv_elem2d && horiz_deriv_node3d) {
                data_node <<- abind(data_node, data_node3d, along=1, use.dnns=T)
            } else if (!horiz_deriv_elem2d && horiz_deriv_node3d) {
                data_node <<- data_node3d
            }
        
        } # "divuvt", "divuvteddy",
          # "divuvsgst", "divuvsgsteddy", "divuvsgsttot",
          # "divuvs", "divuvseddy",
          # "divuvsgss", "divuvsgsseddy", "divuvsgsstot"

        if (any(varname == c("relvorti", "relvortif", "relvortisq", 
                             "curlwind", "curltau", 
                             "ekmanP", "okubo"))) {
            message(paste0(indent, varname, " = d", varname_fesom[2],
                         "dx - d", varname_fesom[1], "dy ..."))
            data <<- dvar2dx - dvar1dy

        }
        if (varname == "RossbyNo") {
            message(paste0(indent, varname_plot, " = |d", varname_fesom[2],
                         "dx - d", varname_fesom[1], "dy|/f ..."))
        }
        if (varname == "potvorti_bc") {
            message(paste0(indent, varname_plot, " = db/dx(dw/dy - dv/dz) + db/dy(du/dz - dw/dx) ..."))
        }
        if (varname == "potvorti_vert") {
            message(paste0(indent, varname_plot, " = db/dz(f + dv/dx - du/dy) ..."))
        }
        if (varname == "potvorti") {
            message(paste0(indent, varname_plot, " = (vec{k}f + vec{nabla} x vec{u}) cdot vec{nabla} b ..."))
        }

            # Put everything together
            if (any(varname == c("potvorti_bc", "potvorti"))) {
                term1 <<- dvar4dx_node * (dvar3dy_node - dvar2dz)
                term2 <<- dvar4dy_node * (dvar1dz - dvar3dx_node)
            }

            if (any(varname == c("potvorti_vert", "potvorti"))) {
                if (ltm) f_mat <<- f_mat[,,1,1]
                term3 <<- dvar3dz * (dvar2dx_node - dvar1dy_node + f_mat)
            }

            if (varname == "potvorti_bc") {
                data <<- term1 + term2
            }

            if (varname == "potvorti_vert") {
                data <<- term3
            }

            if (varname == "potvorti") {
                data <<- term1 + term2 + term3
            }



        if (any(varname == c("strain_normal", "strain_shear", "strain",
                             "okubo"))) {
            if (any(varname == c("strain_normal", "strain", "okubo"))) {
            message(paste0(indent, varname_plot, " = (d", varname_fesom[1],
                         "dx + d", varname_fesom[2], "dy)² ..."))

                strain_normal <<- (dvar1dx + dvar2dy)^2
                if (varname == "strain_normal") {
                    data <<- strain_normal
                }
            }
            if (any(varname == c("strain_shear", "strain", "okubo"))) {
            message(paste0(indent, varname_plot, " = (d", varname_fesom[2],
                         "dx + d", varname_fesom[1],  "dy)² ..."))

                strain_shear <<- (dvar2dx + dvar1dy)^2

                if (varname == "strain_shear") {
                    data <<- strain_shear
                }
            }
            if (any(varname == c("strain", "okubo"))) {
            message(paste0(indent, varname_plot, " = (d",
                         varname_fesom[1], "dx + d", varname_fesom[2], "dy)² + (d",
                         varname_fesom[2], "dx + d", varname_fesom[1], "dy)² ..."))

                strain <<- strain_normal + strain_shear
                if (varname == "strain") {
                    data <<- strain
                }
            }
            if (varname == "okubo") {
            message(paste0(indent, varname_plot, " = (d",
                         varname_fesom[1], "dx + d", varname_fesom[2], "dy)² + (d",
                         varname_fesom[2], "dx + d", varname_fesom[1], "dy)² - (d",
                         varname_fesom[2], "dx - d", varname_fesom[1], "dy)² ..."))

                okubo <<- strain_normal + strain_shear - relvortisq
                data <<- okubo
            }

            # todo: okubo_budget ...

            dimnames(data)[1] <<- list(var=varname)

        } # if okubo etc..

        if (varname == "PmPe") {
            message(paste0(indent, varname_plot, " = - g/rho0/N^2  * [ u'rho' * (d rho)/(d x) +  v'rho' * (d rho)/(d y) ] ..."))
            stop("not yet")
                ## baroclinic energy conversion (mean potential -> eddy potential)
                # PmPe = -\vec{i}(u'b' * dbdx * N^-2) -\vec{j}(v'b' * dbdy * N-2)
                #      = -g/rho0/N2 * (u'rho'*dbdx + v'rho'*dbdy)
                term1 = (data_global[which(varname_fesom == "urho"),,,] -
                         data_global[which(varname_fesom == "u"),,,]*
                         data_global[which(varname_fesom == "rho"),,,])*dvar1dx_node
                term2 = (data_global[which(varname_fesom == "vrho"),,,] -
                         data_global[which(varname_fesom == "v"),,,]*
                         data_global[which(varname_fesom == "rho"),,,])*dvar1dy_node
                data = -g/rho0/data_global[which(varname_fesom == "N2"),,,] * (term1 + term2)

        }

        if (varname == "HRS" || varname == "KmKe") {
            message(paste0(indent, varname, " = - u'u'*dudx - u'v'*dudy - u'v'*dvdx - v'v'*dvdy"))

            ## hrs = -u'u'*dudx - u'v'*dudy - u'v'*dvdx - v'v'*dvdy
            ##     = 
            term1 = -(data[which(varname_fesom == "uu"),,,] -
                      data[which(varname_fesom == "u"),,,]^2)*dvar1dx_node
            term2 = -(data[which(varname_fesom == "uv"),,,] -
                      data[which(varname_fesom == "u"),,,]*
                      data[which(varname_fesom == "v"),,,])*(dvar1dy_node + dvar2dx_node)
            term3 = -(data[which(varname_fesom == "vv"),,,] -
                      data[which(varname_fesom == "v"),,,]^2)*dvar2dy_node
            hrs = term1 + term2 + term3

            if (varname == "HRS") {
                data <<- hrs
            }
        } # hrs || KmKe

        if (varname == "KmKe") {
            message(paste0(indent, varname, " = HRS + VRS"))
            message(paste0(indent, paste0(rep(" ", t=nchar(varname)), collapse=""),
                         " = - u'u'*dudx - u'v'*dudy - u'v'*dvdx - v'v'*dvdy - u'w'*dudz - v'w'*dvdz"))
        }
        
        if (varname == "slopeSx") {
            message(paste0(indent, varname, " = -[(drho/dx)/(drho/dz)] ..."))
        }
        
        if (varname == "slopeSy") {
            message(paste0(indent, varname, " = -[(drho/dy)/(drho/dz)] ..."))
        }
        
        if (varname == "slopeS") {
            message(paste0(indent, varname, " = sqrt{[-(drho/dx)/(drho/dz)]^2 + [-(drho/dy)/(drho/dz)]^2} ..."))
        }
        
        if (varname == "slopeSsq") {
            message(paste0(indent, varname, " = (sqrt{[-(drho/dx)/(drho/dz)]^2 + [-(drho/dy)/(drho/dz)]^2})^2 ..."))
        }

        if (varname == "divuvt2") { ## special!        
              
            stop("update")
            message(paste0(indent, varname, " = \vec{nabla_h} { laplace^-2 [ \vec{nabla_h} cdot ( \vec{u}*t ) ] } ..."))

            ## Retain vector information of tracer flux divergence by taking 
            ## first the inverse laplacian and then the gradient. 
            ## see Jayne and Marotzke 2002
            ## https://doi.org/10.1175/1520-0485(2002)032<3328:TOEHT>2.0.CO;2
            if (verbose > 1) {
                message(paste0(indent, "Calc inverted laplacian for interpolated depths only ..."))
            }
            if (T) {
                message("data")
                message(str(data))
            }

            ## Laplacian (dim = 3 x e2)
            laplace_2d <<- bafux_2d^2 + bafuy_2d^2

            ## Invert laplacian using singular value decomposition (SVD)
            ## of Matrix X = U D V'
            ## with U = left singular vectors of X  (dim = 3 x 3)
            ##      V = right singular vectors of X (dim = e2 x 3)
            ##      D = singular values of X        (length = 3)
            laplace_2d_svd <<- svd(laplace_2d) 

            ## Diagonal matrix with inverted singular values of X (dim = 3 x 3)
            laplace_2d_diag <<- diag(1/laplace_2d_svd$d) 

            ## Psuedoinverse of X is X^(-1) = V D^(-1) U' (dim = 3 x e2) 
            ## e.g. https://en.wikipedia.org/wiki/Generalized_inverse
            laplace_2d_inv <<- laplace_2d_svd$v %*% laplace_2d_diag %*% t(laplace_2d_svd$u)

            ## Repeat inverted laplacian in depth and time
            laplace_2d_inv_time <<- replicate(laplace_2d_inv, n=dim(data_global)[3]) # ntime per year
            laplace_2d_inv_time <<- replicate(laplace_2d_inv_time, n=dim(data)[4]) # ndepths

            ## Bring div_h(tracer flux) from elems to nodes
            if (verbose > 1) {
                message(paste0(indent, "Bring div_h(tracer flux) back from elem2d to nod2d ..."))
            }
            data_node <<- array(0,
                               dim=c(dim(data)[1],
                                     nod2d_n, dim(data)[3:4]),
                               dimnames=c(dimnames(data)[1],
                                          list(node=1:nod2d_n),
                                          dimnames(data)[3:4]))
            inds <<- data_node

            # create progress bar
            pb <<- mytxtProgressBar(min=0, max=elem2d_n, style=pb_style,
                                    char=pb_char, width=pb_width,
                                    indent=paste0("     ", indent)) # 5 " " for default message()

            ## put element values on 3 nodes
            for (i in 1:elem2d_n) {

                #progress_function(elem2d_n, i, indent=paste0(indent, "   "))
                elnodes <<- elem2d[,i]

                if (dim(data)[3] == 1 &&
                    dim(data)[4] == 1) { # 1 depth and 1 time
                    data_node[,elnodes,,] <<- data_node[,elnodes,,] +
                                                rep(data[,i,,], t=3)

                } else if (dim(data)[3] == 1 &&
                           dim(data)[4] != 1) { # several depths but 1 time
                    data_node[,elnodes,,] <<- data_node[,elnodes,,] +
                                                t(array(data[,i,,], c(ndepths, 3)))

                } else if (dim(data)[3] != 1 &&
                           dim(data)[4] == 1) { # 1 depth but several times
                    data_node[,elnodes,,] <<- data_node[,elnodes,,] +
                                                t(array(data[,i,,], c(dim(data)[3], 3)))

                } else {
                    data_node[,elnodes,,] <<- data_node[,elnodes,,] +
                                                aperm(replicate(data[,i,,], n=3),
                                                      c(3,1,2))

                }
                inds[,elnodes,,] <<- inds[,elnodes,,] + 1

                # update progress bar
                setTxtProgressBar(pb, i)

            } # for i elem2d_n

            # close progress bar
            close(pb)

            data_node <<- data_node/inds
            if (T) {
                message("data_node")
                message(str(data_node))
            }

            ## Bring div_h(tracer flux) from nodes to elements
            if (verbose > 1) {
                message(paste0(indent, "Bring div_h(tracer flux) from nodes on elements for inverted laplacian ..."))
            }
            var_elem <<- array(0, c(1, dim(elem2d), dim(data)[3:4]))
            dimnames(var_elem)[1] <<- list(var=dimnames(data)[[1]][1])
            for (i in 1:3) {
                var_elem[1,i,,,] <<- data_node[1,elem2d[i,],,] # here 'data_node' is the tracer flux divergence
            }

            if (F) {
                message("var_elem")
                message(str(var_elem))
                message("bafux_2d")
                message(str(bafux_2d))
                message("bafux_2d_time")
                message(str(bafux_2d_time))
                message("laplace_2d_inv")
                message(str(laplace_2d_inv))
                message("laplace_2d_inv_time")
                message(str(laplace_2d_inv_time))
            }

            ## Apply inverted laplacian
            laplace_inv_var_elem <<- array(0, c(1, dim(var_elem)[3:5]),
                                           dimnames=list(paste0("laplace_inv_", varname),
                                                         1:dim(var_elem)[3],
                                                         dimnames(data)[[3]],
                                                         dimnames(data)[[4]]))
            for (i in 1:3) {
                laplace_inv_var_elem[1,,,] <<- laplace_inv_var_elem[1,,,] + var_elem[1,i,,,]*laplace_2d_inv_time[,i,,]
            }

            ## Bring laplace^-2 [ div_h(tracer flux) ] from elems to nodes
            if (verbose > 1) {
                message(paste0(indent, "Bring laplacian^-2 [ div_h(tracer flux) ] back from elem2d to nod2d ..."))
            }
            laplace_inv_var_node <<- array(0,
                                           dim=c(dim(laplace_inv_var_elem)[1], 
                                                 nod2d_n, dim(laplace_inv_var_elem)[3:4]),
                                           dimnames=c(dimnames(laplace_inv_var_elem)[1],
                                                      list(node=1:nod2d_n),
                                                      dimnames(laplace_inv_var_elem)[3:4]))
            inds <<- laplace_inv_var_node

            # create progress bar
            pb <<- mytxtProgressBar(min=0, max=elem2d_n, style=pb_style,
                                    char=pb_char, width=pb_width,
                                    indent=paste0("     ", indent)) # 5 " " for default message()

            ## put element values on 3 nodes
            for (i in 1:elem2d_n) {

                #progress_function(elem2d_n, i, indent=paste0(indent, "   "))
                elnodes <<- elem2d[,i]

                if (dim(laplace_inv_var_elem)[3] == 1 && 
                    dim(laplace_inv_var_elem)[4] == 1) { # 1 depth and 1 time
                    laplace_inv_var_node[,elnodes,,] <<- laplace_inv_var_node[,elnodes,,] +
                                                rep(laplace_inv_var_elem[,i,,], t=3)

                } else if (dim(laplace_inv_var_elem)[3] == 1 && 
                           dim(laplace_inv_var_elem)[4] != 1) { # several depths but 1 time
                    laplace_inv_var_node[,elnodes,,] <<- laplace_inv_var_node[,elnodes,,] +
                                                t(array(laplace_inv_var_elem[,i,,], c(ndepths, 3)))

                } else if (dim(laplace_inv_var_elem)[3] != 1 && 
                           dim(laplace_inv_var_elem)[4] == 1) { # 1 depth but several times
                    laplace_inv_var_node[,elnodes,,] <<- laplace_inv_var_node[,elnodes,,] +
                                                t(array(laplace_inv_var_elem[,i,,], c(dim(data)[3], 3)))

                } else {
                    laplace_inv_var_node[,elnodes,,] <<- laplace_inv_var_node[,elnodes,,] +
                                                aperm(replicate(laplace_inv_var_elem[,i,,], n=3),
                                                      c(3,1,2))

                }
                inds[,elnodes,,] <<- inds[,elnodes,,] + 1

                # update progress bar
                setTxtProgressBar(pb, i)

            } # for i elem2d_n

            # close progress bar
            close(pb)

            laplace_inv_var_node <<- laplace_inv_var_node/inds
            
            if (F) {
                message("laplace_inv_var_elem")
                message(str(laplace_inv_var_elem))
            }

            ## Bring laplace^-2 [ div_h(tracer flux) ] from nodes to elements
            if (verbose > 1) {
                message(paste0(indent, "Bring laplacian^-2 [ div_h(tracer flux) ] from nodes on elements for horizontal derivative ..."))
            }
            var_elem <<- array(0, c(1, dim(elem2d), dim(data)[3:4]))
            dimnames(var_elem)[1] <<- list(var=dimnames(laplace_inv_var_node)[[1]][1])
            for (i in 1:3) {
                var_elem[1,i,,,] <<- laplace_inv_var_node[1,elem2d[i,],,]
            }

            ## Apply gradient to retain vector information
            if (verbose > 1) {
                message(paste0(indent, "Calc horizontal gradients for interpolated depths only ..."))
            }
            dvardx <<- array(0, c(1, dim(var_elem)[3:5]),
                            dimnames=list(paste0("d_", dimnames(var_elem)[[1]][1], "_dx"),
                                          1:dim(var_elem)[3],
                                          dimnames(data)[[3]],
                                          dimnames(data)[[4]]))
            dvardy <<- array(0, c(1, dim(var_elem)[3:5]),
                            dimnames=list(paste0("d_", dimnames(var_elem)[[1]][1], "_dy"),
                                          1:dim(var_elem)[3],
                                          dimnames(data)[[3]],
                                          dimnames(data)[[4]]))
            for (i in 1:3) {
                dvardx[1,,,] <<- dvardx[1,,,] + var_elem[1,i,,,]*bafux_2d_time[,i,,]
                dvardy[1,,,] <<- dvardy[1,,,] + var_elem[1,i,,,]*bafuy_2d_time[,i,,]
            }

            ## Save vector information of tracer flux divergence
            if (uv_out) {
                udata <<- dvardx
                vdata <<- dvardy
            }

            if (F) {
                message("udata")
                message(str(udata))
            }

        } # divuvt2

    } # if horiz_deriv_tag

    if (any(varname == c("Ftemp", "Fsalt", "Fsalt2"))) {

        stop("update")

        if (varname == "Ftemp") {
            if (verbose > 0) {
                message(paste0(indent, "Ftemp = Qnet/(rho*cp)"))
            }
            data <<- data[which(varname_fesom == "qnet"),,,]/(cp*data[which(varname_fesom == "rho"),,,])
        } # Ftemp

        if (varname == "Fsalt") {
            if (verbose > 0) {
                message(paste0(indent, "Fsalt = S/(1-S/1000)*(Evap - Snow - Rain - Runoff + ThdGr) + relax_salt_term ..."))
            }
            EminusP <<- data[which(varname_fesom == "snow"),,,]*-1 +
                       data[which(varname_fesom == "rain"),,,]*-1 +
                       data[which(varname_fesom == "evap"),,,] +
                       data[which(varname_fesom == "runoff"),,,]*-1 +
                       data[which(varname_fesom == "thdgr"),,,]

            #denom <<- 1 - data[which(varname_fesom == "salt"),,,]/1e6 # /1e3 or /1e6 almost no diff
            denom <<- 1
            data <<- data[which(varname_fesom == "salt"),,,]*EminusP/denom +
                    data[which(varname_fesom == "relax_salt"),,,]
        } # Fsalt

        if (varname == "Fsalt2") {
            if (verbose > 0) {
                message(paste0(indent, "Fsalt2 = virtual_salt + relax_salt"))
            }
            data <<- data[which(varname_fesom == "virtual_salt"),,,] + 
                    data[which(varname_fesom == "relax_salt"),,,]
        } # Fsalt2

        dimnames(data)[1] <<- list(var=varname)

    } # "Ftemp", "Fsalt", "Fsalt2"

    if (any(varname == c("Fthermal", "Fthermalbudget", 
                         "Fhaline", "Fhalinebudget",
                         "Frho", "Frhobudget",
                         "FthermalB", "FthermalBbudget",
                         "FhalineB", "FhalineBbudget",
                         "FrhoB", "FrhoBbudget",
                         "FrhoB2"))) {
        # use data since temp: 3d and qnet: 2d are already "depth averaged"

        stop("update")
        
        if (total_rec == 0 || (!anim_out && !regular_anim_output)) {
            if (sea_water == "EOS80") {
                ycsur_mat <<- replicate(ycsur, n=ndepths)
                depth_mat <<- replicate(interpolate_depths, n=nod2d_n)
                if (ndepths == 1) {
                    depth_mat <<- replicate(depth_mat, n=1)
                } else {
                    depth_mat <<- aperm(depth_mat, c(2,1))
                }
                pres_mat <<- sw_pres(DEPTH=depth_mat, LAT=ycsur_mat)
                pres_mat <<- replicate(pres_mat, n=dim(data_global_vert)[3])
                pres_mat <<- replicate(pres_mat, n=1)
                pres_mat <<- aperm(pres_mat, c(4,1,3,2))
            } else if (sea_water == "TEOS10") {
                stop("not implmented yet")
            }

            sea_water_fname <<- paste0("_", sea_water)

        } # if total_rec == 0
        
        # thermal expansion coefficient [K^(-1)]
        if (verbose == 2 || verbose == 3) {
            if (sea_water == "EOS80") {
                message(paste0(indent, "alpha = sw_alpha(S,T,P,keyword='ptmp') in K^-1..."))
            } else if (sea_water == "TEOS10") {

            }
        }
        if (sea_water == "EOS80") {
            alpha <<- sw_alpha(S=data[which(varname_fesom == "salt"),,,],
                              T=data[which(varname_fesom == "temp"),,,],
                              P=pres_mat, keyword="ptmp")
        } else if (sea_water == "TEOS10") {

        }
        dimnames(alpha)[1] <<- list("alpha")
        
        # saline contraction coefficient [kg g^(-1)]
        if (verbose == 2 || verbose == 3) {
            if (sea_water == "EOS80") {
                message(paste0(indent, "beta = sw_beta(S,T,P,keyword='ptmp') in psu^-1..."))
            } else if (sea_water == "TEOS10") {

            }
        }
        if (sea_water == "EOS80") {
            beta <<- sw_beta(S=data[which(varname_fesom == "salt"),,,],
                            T=data[which(varname_fesom == "temp"),,,],
                            P=pres_mat, keyword="ptmp")
        } else if (sea_water == "TEOS10") {
            
        }
        dimnames(beta)[1] <<- list("beta")

        # surface density
        if (any(varname == c("Fhaline", "Fhalinebudget",
                             "Frho", "Frhobudget", 
                             "FhalineB", "FhalineBbudget",
                             "FrhoB", "FrhoBbudget",
                             "FrhoB2"))) {
            if (verbose == 2 || verbose == 3) {
                if (sea_water == "EOS80") {
                    message(paste0(indent, "rho = sw_dens(S,T,P) ..."))
                } else if (sea_water == "TEOS10") {

                }
            }
            if (sea_water == "EOS80") {
                rho <<- sw_dens(S=data[which(varname_fesom == "salt"),,,],
                               T=data[which(varname_fesom == "temp"),,,],
                               P=pres_mat)
            } else if (sea_water == "TEOS10") {
                
            }
            dimnames(rho)[1] <<- list("rho")
        }
       
        if (any(varname == c("Fthermal", "Fthermalbudget",
                             "Frho", "Frhobudget",   
                             "FthermalB", "FthermalBbudget",
                             "FrhoB", "FrhoBbudget",
                             "FrhoB2"))) {

            if (verbose > 1) {
                message(paste0(indent, "Fthermal = -rho*alpha*Ftemp = -alpha/cp*Qnet ..."))
                message(paste0(indent, "   with Qnet = swrd + lwrd + olwout + osen + olat"))
                message(paste0(indent, "        cp = ", cp, " m^2 s^(-2) K^(-1)"))
                message(paste0(indent, "   from Josey (2003): doi:10.1029/2003JC001778"))
            }

            if (any(varname == c("Fthermal", "Frho",
                                 "FthermalB", "FrhoB",
                                 "FrhoB2"))) {
                
                Fthermal <<- -alpha/cp*data[which(varname_fesom == "qnet"),,,]
                if (varname == "Fthermal") {
                    data <<- Fthermal
                    dimnames(data)[1] <<- list(varname)
                } else if (varname == "FthermalB") {
                    data <<- -g/rho0*Fthermal
                    dimnames(data)[1] <<- list(varname)
                }
            }
           
            if (any(varname == c("Fthermalbudget", "Frhobudget",
                                 "FthermalBbudget", "FrhoBbudget"))) {
                inds <<- match(c("swrd", "lwrd", "olwout", "osen", "olat"), 
                              varname_fesom)

                # replicate alpha for all inds
                if (!any(search() == "package:abind")) library(abind)
                tmp <<- alpha
                for (i in 1:(length(inds) - 1)) {
                    tmp <<- abind(tmp, alpha, along=1, use.dnns=T)
                }
                alpha <<- tmp
                Fthermalbudget <<- -alpha/cp * data[inds,,,]
                dimnames(Fthermalbudget)[1] <<- list(varname_fesom[inds])
                
                # add Fthermal as sum of all components
                if (any(varname == c("Fthermalbudget", "FthermalBbudget"))) {
                    Fthermalbudget <<- abind(Fthermalbudget,
                                            array(apply(Fthermalbudget, c(2, 3, 4), sum), # sum of all components
                                                  c(1, dim(Fthermalbudget)[2:4])), # restore dimension
                                            along=1, use.dnns=T)
                    dimnames(Fthermalbudget)[[1]][dim(Fthermalbudget)[1]] <<- varname
                
                    if (varname == "Fthermalbudget") {
                        data <<- Fthermalbudget
                    } else if (varname == "FthermalBbudget") {
                        data <<- -g/rho0*Fthermalbudget
                    }
                } 
            } # if budget
        } # if Fthermal or Frho

        if (any(varname == c("Fhaline", "Fhalinebudget",
                             "Frho", "Frhobudget",
                             "FhalineB", "FhalineBbudget",
                             "FrhoB", "FrhoBbudget",
                             "FrhoB2"))) {
           
            if (any(varname == c("Fhaline", "Fhalinebudget",
                                 "Frho", "Frhobudget",
                                 "FhalineB", "FhalineBbudget",
                                 "FrhoB", "FrhoBbudget"))) {

                if (verbose > 0) {
                    message(paste0(indent, "Fhaline = Ffac * (E - P) + relax_salt_term ..."))
                    message(paste0(indent, "   with Ffac = rho * beta * S / (1 - S/1000)"))
                    message(paste0(indent, "        E - P = snow + rain + evap + runoff + thdgr"))
                    message(paste0(indent, "        relax_salt_term = rho * beta * relax_salt"))
                    message(paste0(indent, "        thdgr = thermodynamic growth rate of eff. sea ice thickness"))
                    message(paste0(indent, "   from Josey (2003): doi:10.1029/2003JC001778"))
                }

                salt <<- data[which(varname_fesom == "salt"),,,]
                
                FhalineFac <<- rho * beta * salt / (1 - salt/1000)
                dimnames(FhalineFac)[1] <<- list(var="FhalineFac")

                salt_relax_term <<- rho * beta * data[which(varname_fesom == "relax_salt"),,,]
                dimnames(salt_relax_term)[1] <<- list(var="salt_relax_term")
               
                if (any(varname == c("Fhaline", "Frho",
                                     "FhalineB", "FrhoB"))) {
                    EminusP <<- data[which(varname_fesom == "snow"),,,]*-1 +
                               data[which(varname_fesom == "rain"),,,]*-1 +
                               data[which(varname_fesom == "evap"),,,] +
                               data[which(varname_fesom == "runoff"),,,]*-1 +
                               data[which(varname_fesom == "thdgr"),,,]
                    Fhaline <<- FhalineFac * EminusP + salt_relax_term

                    if (varname == "Fhaline") {
                        data <<- Fhaline
                        dimnames(data)[1] <<- list(varname)
                    
                    } else if (varname == "FhalineB") {
                        data <<- -g/rho0*Fhaline
                        dimnames(data)[1] <<- list(varname)
                    }
                }
            } # if Fhaline Frho

            if (varname == "FrhoB2") {

                if (verbose > 0) {
                    message(paste0(indent, "Fhaline = rho * beta * (virtual_salt + relax_salt) ..."))
                }
                
                Fhaline <<- rho * beta * (data[which(varname_fesom == "virtual_salt"),,,] + 
                                         data[which(varname_fesom == "relax_salt"),,,])
            
            }

            if (any(varname == c("Fhalinebudget", "Frhobudget",
                                 "FhalineBbudget", "FrhoBbudget"))) {

                inds <<- match(c("snow", "rain", "evap", "runoff", "thdgr"),
                              varname_fesom)
                
                # replicate FhalineFac for all inds
                if (!any(search() == "package:abind")) library(abind)
                tmp <<- FhalineFac
                for (i in 1:(length(inds) - 1)) {
                    tmp <<- abind(tmp, FhalineFac, along=1, use.dnns=T)
                }
                FhalineFac <<- tmp
                
                Fhalinebudget <<- FhalineFac * data[inds,,,]
                dimnames(Fhalinebudget)[1] <<- list(varname_fesom[inds])
                
                # apply sign convention
                neg_inds <<- c(which(dimnames(Fhalinebudget)[[1]] == "snow"),
                              which(dimnames(Fhalinebudget)[[1]] == "rain"),
                              which(dimnames(Fhalinebudget)[[1]] == "runoff"))
                Fhalinebudget[neg_inds,,,] <<- -1*Fhalinebudget[neg_inds,,,]

                # add salt_relax term without FahlineFac
                Fhalinebudget <<- abind(Fhalinebudget, salt_relax_term, 
                                       along=1, use.dnns=1)

                if (any(varname == c("Fhalinebudget", "FhalineBbudget"))) {
                    # add Fhaline as sum of all components
                    Fhalinebudget <<- abind(Fhalinebudget,
                                           array(apply(Fhalinebudget, c(2, 3, 4), sum), # sum of all components
                                                 c(1, dim(Fhalinebudget)[2:4])), # restore dimension
                                  along=1, use.dnns=T)
                    dimnames(Fhalinebudget)[[1]][dim(Fhalinebudget)[1]] <<- varname

                    if (varname == "Fhalinebudget") {
                        data <<- Fhalinebudget
                    } else if (varname == "FhalineBbudget") {
                        data <<- -g/rho0*Fhalinebudget
                    }
                }
            }

        } # Fhaline Fhalinebudget Frho
        
        if (any(varname == c("Frho", "Frhobudget",
                             "FrhoB", "FrhoBbudget",
                             "FrhoB2"))) {
            if (verbose == 2 || verbose == 3) {
                message(paste0(indent, varname, " = Fthermal + Fhaline"))
            }
            
            if (any(varname == c("rho", "FrhoB", "FrhoB2"))) {
                data <<- Fthermal + Fhaline
                
                if (varname == "FrhoB" || varname == "FrhoB2") {
                    data <<- -g/rho0*data
                }
                
                dimnames(data)[1] <<- list(varname)
            }
            
            if (varname == "Frhobudget" || varname == "FrhoBbudget") {
                data <<- abind(Fthermalbudget, Fhalinebudget,
                              along=1, use.dnns=T)

                # add Frho as sum of all components
                data <<- abind(data,
                              array(apply(data, c(2, 3, 4), sum), # sum of all components
                                    c(1, dim(data)[2:4])), # restore dimension
                              along=1, use.dnns=T)
                
                if (varname == "FrhoBbudget") data <<- -g/rho0*data
                
                dimnames(data)[[1]][dim(data)[1]] <<- varname
            }
        }

    } # Fthermal Fhaline Frho

    if (varname == "MOCw") {
       
        if (verbose > 0) {
            message(paste0(indent, varname, "(lat,z) = cumsum_lat(sum(w[lat]*vol)) ... (like in fpost1.4)"))
        }

        # initialize array for every year
        moc <<- array(0, dim=c(1, length(moc_reg_lat_global), aux3d_n, dim(data_node)[4])) # c(nvars,nreg_lat,ndepths,ntime)
        if (!exists("moc_topo")) {
            moc_topo <<- array(1, dim=c(length(moc_reg_lat_global), aux3d_n))
        } # only once

        # create progress bar
        pb <<- mytxtProgressBar(min=0, max=elem2d_n, style=pb_style,
                                char=pb_char, width=pb_width,
                                indent=paste0("     ", indent)) # 5 " " for default message()

        for (i in 1:elem2d_n) {
            #progress_function(elem2d_n, i, indent=paste0(indent, "   "))
            elnodes <<- elem2d[,i]
            m <<- moc_mask[elnodes]
            
            if (!all(m == 0)) { # element is in area for moc calculation
                #x <<- mean(xcsur[elnodes])
                y <<- mean(ycsur[elnodes])
                V <<- voltriangle[i]
                inds <<- which(moc_reg_lat_global > y)[1]
                if (is.na(inds)) {
                    # find closest
                    inds <<- which(abs(moc_reg_lat_global - y)==min(abs(moc_reg_lat_global - y)))
                }
                for (j in 1:aux3d_n) { # calculate in aux3d space
                    elnode3 <<- aux3d[j,elnodes]
                    if (all(elnode3 > 0)) { # no boundary
                        w <<- data_node[,elnode3,,] # var, 
                        m <<- array(moc_mask[elnodes], dim(w)) # repeat mask in time dim
                        moc[1,inds,j,] <<- moc[1,inds,j,] + V*apply(w*m, 3, mean)*1.e-6 # Sv
                        moc_topo[inds,j] <<- NA
                    } # if no boundary
                } # for j aux3d_n
            } # if elem2d is in area for moc calculation
        
            # update progress bar
            setTxtProgressBar(pb, i)
        
        } # for i elem2d_n

        # close progress bar
        close(pb)
     
        # cumsum meridionally 
        # dim(moc) = c(1,nregy,ndepths,nrecspf)
        if (view != "moc_global") {
            #moc <<- apply(moc, 2, cumsum)
            for (i in (length(moc_reg_lat_global) - 1):1) {
                moc[1,i,,] <<- -moc[1,i,,] + moc[1,i+1,,]
            }
        } else if (view == "moc_global") { # global moc
            for (i in 2:length(moc_reg_lat_global)) { 
                moc[1,i,,] <<- moc[1,i,,] + moc[1,i-1,,]
            }
        } # if use_mask

        data_node <<- moc
        dimnames(data_node)[[1]] <<- varname

    } # "MOCw"

    ## variables that need cluster area
    if (any(varname == c("resolutionkm", "resolutiondeg", "mesharea",
                         "fwflux", 
                         "iceextent", "icevol"))) {
        
        # dim(cluster_area_2d) = nod2d_n  
        if (any(varname == c("fwflux", "iceextent", "icevol"))) {
            cluster_area_2d_vert <<- replicate(cluster_area_2d, n=1) # nvars
            cluster_area_2d_vert <<- replicate(cluster_area_2d_vert, n=dim(data_node)[3]) # ndepths
            cluster_area_2d_vert <<- replicate(cluster_area_2d_vert, n=dim(data_node)[4]) # nrecspf
            cluster_area_2d_vert <<- aperm(cluster_area_2d_vert, c(2, 1, 3, 4)) 
            # dim(cluster_area_2d_vert) = c(nvars,nod2d_n,ndepths=1,nrecspf)

        } else if (varname == "mesharea") {
            cluster_area_2d_vert <<- replicate(cluster_area_2d, n=1) # nvars
            cluster_area_2d_vert <<- replicate(cluster_area_2d_vert, n=1) # nrecs
            cluster_area_2d_vert <<- replicate(cluster_area_2d_vert, n=1) # ndepths
            cluster_area_2d_vert <<- aperm(cluster_area_2d_vert, c(2, 1, 3, 4))
            # dim(cluster_area_2d_vert) = c(nvars,nod2d_n,ndepths=1,nrecspf=1)
        
        }

        if (varname == "mesharea") {
            data_node <<- cluster_area_2d_vert

        } else if (varname == "fwflux") {
            if (verbose > 1) {
                message(paste0(indent, varname, " = runoff*cluster_area_2d"))
            }
            varinds <<- which(vars == "runoff")
            if (any(is.na(varinds))) stop("Could not find data.")

            data_node <<- data_node[varinds[1],,,]*cluster_area_2d_vert

        } else if (any(varname == c("resolutionkm", "resolutiondeg"))) {
            
            # dim(resolution) = elem2d_n
            resolution <<- replicate(resolution, n=dim(data_node)[1]) # nvars
            resolution <<- replicate(resolution, n=dim(data_node)[3]) # ndepths=1
            resolution <<- replicate(resolution, n=dim(data_node)[4]) # nrecspf=1

            ## bring derivative back from (elem2d_n x ndepths) to (nod2d_n x ndepths)
            if (verbose > 1) {
                message(paste0(indent, "Bring derivative back from (3 x elem2d_n=", elem2d_n, " x ndepths=",
                             ndepths, ") on (nod2d_n=", nod2d_n, " x ndepths=", ndepths, ") ..."))
                message(paste0(indent, "   run ", subroutinepath, "sub_e2xde_to_n2xde.r ..."))
            }
            sub_e2xde_to_n2xde(resolution) # produces tmp
            data_node <<- tmp # dim(data_node) = c(nvars,nod2d_n,ndepths=1,nrecspf=1)

            if (varname == "resolutiondeg") {
                
                stop("how?!")
                # matlab: km2deg(km,radius) = rad2deg( km2rad(km,radius) );
                #   with: km2rad(km,radius): rad = km/radius;
                #         rad2deg(R): D = R*180/pi;
                #data_node <<- resolution/Rearth*180/pi # resolution and Rearth have the same unit ([m] by default)

                a <<- (cos(yc[2,1]*pi/180)*sin(abs(diff(xc[1:2,1]))*pi/180))^2
                b <<- (cos(yc[1,1]*pi/180)*sin(yc[2,1]*pi/180) - sin(yc[1,1]*pi/180)*cos(yc[2,1]*pi/180)*cos(abs(diff(xc[1:2,1]))*pi/180))^2
                c <<- sin(yc[1,1]*pi/180)*sin(yc[2,1]*pi/180) + cos(yc[1,1]*pi/180)*cos(yc[2,1]*pi/180)*cos(abs(diff(xc[1:2,1]))*pi/180)
                #ds <<- atan2((sqrt(a+b)/c)*pi/180)
                ds <<- atan((sqrt(a+b)/c)*pi/180)

            } # "resolutiondeg"

        } else if (any(varname == c("iceextent", "icevol"))) {

            if (varname == "iceextent") {
                varinds <<- which(vars == "area" | vars == "sic")
            } else if (varname == "icevol") {
                varinds <<- c(which(vars == "area" | vars == "sic"),
                              which(vars == "hice" | vars == "sithick"))
            }
            if (any(is.na(varinds))) stop("Could not find data.")

            if (verbose > 1) {
                if (varname == "iceextent") {
                    message(paste0(indent, varname, " = ", vars[varinds[1]], " ..."))
                } else if (varname == "icevol") {
                    message(paste0(indent, varname, " = ", vars[varinds[1]], " * ", vars[varinds[2]], " ..."))
                }
                if (!is.null(sic_cond)) {
                    message(paste0(indent, "   with sea ice concentraion ", sic_cond, " ('sic_cond') ", sic_thr, 
                                 " ('sic_thr'). Change these to 'NULL' in namelist.var.r if you dont want a threshold ..."))
                }
            } # verbose
           
            si_area <<- cluster_area_2d_vert
            if (!is.null(sic_cond)) {
                if (sic_cond == ">") {
                    sic_inds <<- data_node[varinds[1],,,] > sic_thr
                    sic_cond_fname <<- "gt"
                
                } else if (sic_cond == ">=") {
                    sic_inds <<- data_node[varinds[1],,,] >= sic_thr
                    sic_cond_fname <<- "ge"
                
                } else if (sic_cond == "<") {
                    sic_inds <<- data_node[varinds[1],,,] < sic_thr
                    sic_cond_fname <<- "lt"
                
                } else if (sic_cond == "<=") {
                    sic_inds <<- data_node[varinds[1],,,] <= sic_thr
                    sic_cond_fname <<- "le"
                
                } else {
                    stop(paste0(indent, "Error: sea ice concentration condition '", sic_cond, 
                                 "' not defined. Choose among '>', '>=', '<', '<=' !"))
                }
                si_area[!sic_inds] <<- 0
            } # !is.null(sic_cond) 

            if (varname == "iceextent") {
                data_node <<- si_area

            } else if (varname == "icevol") {
                data_node <<- si_area * data_node[varinds[2],,,]

            }
        
        } # "iceextent", "icevol"
        
        dimnames(data_node)[[1]] <<- varname

    } # "resolutionkm", "resolutiondeg", "mesharea", "fwflux", "iceextent", "icevol"

    if (any(varname == c("bathy", "c_barotrop", "foverh"))) {

        ## how to determine depths correctly?
        patrick <<- T
        claudi <<- F
        
        if (patrick) {
            if (verbose > 1) {
                message(paste0(indent, "Read Bathymetry information from z coordinate from nod3d.out ..."))
            }
            z_2d <<- rep(0, nod2d_n)
            pb <<- mytxtProgressBar(min=0, max=aux3d_n-1, style=pb_style,
                                    char=pb_char, width=pb_width,
                                    indent=paste0("        ", indent)) # 5 " " for default message()
            for (l in 1:(aux3d_n-1)) {
                for (ii in 1:nod2d_n) {
                    if (aux3d[l,ii] != -999) {
                        a <<- nod3d_z[aux3d[l,ii]]
                        if (z_2d[ii] > a) z_2d[ii] <<- nod3d_z[aux3d[l,ii]]
                    }
                }
                # update progress bar
                setTxtProgressBar(pb, l)
            } # for i aux3d_n-1
            # close progress bar
            close(pb)
    
            bathy <<- abs(z_2d)
            # unique fesom depths
            fesom_depths <<- c(0, sort(unique(abs(bathy))))
        
        } else if (claudi) {
            if (verbose > 1) {
                message(paste0(indent, "Read Bathymetry information from z coordinate from ", 
                             meshpath, "depth.out ..."))
            }
            fid <<- paste0(meshpath, "depth.out")
            topo <<- scan(fid, quiet=T)
            bathy <<- abs(topo)
        }
        bathy <<- replicate(bathy, n=1)
        bathy <<- replicate(bathy, n=1)
        bathy <<- replicate(bathy, n=1)
        bathy <<- aperm(bathy, c(2, 1, 3, 4))

        if (varname == "bathy") {
            data_node <<- bathy
        }

        if (varname == "c_barotrop") {
            if (verbose > 0) {
                message(paste0(indent, varname, " = sqrt(gH) ..."))
            }
            data_node <<- sqrt(g*bathy)
        }

        if (varname == "foverh") {
            if (verbose > 1) {
                message(paste0(indent, varname_plot, " = f/H ..."))
            }
            message("ycsur")
            message(str(ycsur))
            message(range(ycsur))
            f <<- abs(2*omega*sin(ycsur*pi/180)) # nod_y
            message("f")
            message(str(f))
            message(range(f))
            data_node <<- f / bathy
        }

        dimnames(data_node)[1] <<- list(var=varname)

    } # "bathy", "c_barotrop", "foverh"

} # sub_calc function

