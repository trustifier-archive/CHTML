m4_define([old_ac_config_files], m4_defn([AC_CONFIG_FILES]))
m4_define([old_ac_init], m4_defn([AC_INIT]))
m4_define(ac_gti_package_ver, [m4_if(m4_index($1,-),-1,$1,m4_substr($1,0,m4_index($1,-)))])
m4_undefine([AC_INIT])
m4_define([AC_INIT], [
        old_ac_init([$1], ac_gti_package_ver($2), [$3])
        ac_gti_package_package_rel=`echo $2 | (IFS=- read a b ; echo $b)`  #''
        PACKAGE_RELEASE=${ac_gti_package_package_rel:-1}
        AC_SUBST([PACKAGE_RELEASE])
        echo "***************************************************"
        echo "$PACKAGE_NAME version $PACKAGE_VERSION release $PACKAGE_RELEASE"
        echo "***************************************************"
])
