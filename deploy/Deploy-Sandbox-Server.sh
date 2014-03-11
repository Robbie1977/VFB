#!/bin/bash

branch=Sandbox-Server

echo Deploying ${branch}...

if [ -d .git ]
then
#    test and add git server filters if required.
    if [ ! -f .git/info/attributes ]
    then
        echo "Adding git Smudge/Clean filters..."
        cp deploy/config .git/
        if [ ! -d .git/info ]
        then
            mkdir .git/info
        fi
        cp deploy/attributes .git/info/
        sed -i 's/BRANCH_NAME/${branch}/g' .git/config
    else
        echo 'Git Smudge/Clean filters already added.' 
        echo 'Note: to manually modify, use instructions in filters folder, only if a change is required'
    fi

    echo "Decompressing any *.gz or *.gz.part-?? data..."
    for filename in find . -name '*.gz.part-aa'
    do
        mergedname=${filename/gz.part-aa/gz}
        echo merging files to reconstruct ${mergedname}
        cat ${filename/part-aa/part-??} > ${mergedname}
        echo decompressing and removing gzip copy of ${mergedname} 
        pigz -df ${mergedname}
        echo completed deploying ${mergedname/.qz/}
    done
    for filename in find . -name '*.gz'
    do
        decomname=${filename/.gz/}
        echo decompressing and keeping gzip copy of ${filename} 
        pigz -dkf ${filename}
        echo completed deploying ${decomname}
    done   

    echo "recording git branch and version details"
    git describe --long > revision
    echo $branch > branch
    echo "which are:"
    cat branch
    cat revision
    echo "checking filters to use correct branch names"
    find filters/ -name 'Filt*Smudge.sed' | xargs sed -i -f filters/Local-General-Clean.sed
    find filters/ -name 'Filt*Smudge.sed' | xargs sed -i -f filters/Local-${branch}-Smudge.sed
    echo "checking image json files"
    find data/flybrain/ -name 'tiledImageModelD*.jso' | xargs sed -i -f filters/FiltTiledImageModelDataClean.sed
    find data/flybrain/ -name 'tiledImageModelD*.jso' | xargs sed -i -f filters/FiltTiledImageModelDataSmudge.sed
    echo "checking resources.properties"
    find src/ -name 'resources.properties' | xargs sed -i -f filters/FiltResPropClean.sed  
    find src/ -name 'resources.properties' | xargs sed -i -f filters/FiltResPropSmudge.sed  
    echo "checking web.xml"
    find WEB-INF -name 'web.xml' | xargs sed -i -f filters/FiltWebXmlClean.sed
    find WEB-INF -name 'web.xml' | xargs sed -i -f filters/FiltWebXmlSmudge.sed
    echo "checking google analytics code"
    find jsp/ -name 'ga.jsp' | xargs sed -i -f filters/FiltGoogleAnClean.sed
    find jsp/ -name 'ga.jsp' | xargs sed -i -f filters/FiltGoogleAnSmudge.sed
    echo "checking any direct references to website url is set to the branch site"
    find ./ -name 's*.xml' -or -name '*.jsp' -or -name '*.htm' -or -name '*.html' -or -name '*.js' -or -name '*.owl' | xargs sed -i -f filters/FiltGenClean.sed
    find ./ -name 's*.xml' -or -name '*.jsp' -or -name '*.htm' -or -name '*.html' -or -name '*.js' -or -name '*.owl' | xargs sed -i -f filters/FiltGenSmudge.sed 
    echo "Compiling the site..."
    ant
    echo "Done."
else
    echo "Error: Git directory not found! This script should be run in the git base directory e.g. /disk/data/tomcat/fly/webapps/vfb?/"
fi
