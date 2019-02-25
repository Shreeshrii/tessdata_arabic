#!/bin/bash
################################################################

text2image --find_fonts \
--fonts_dir ~/.fonts \
--text ./ara.plusminus.training_text \
--min_coverage .999  \
--outputbase ./ \
|& grep raw \
 | sed -e 's/ :.*/@ \\/g' \
 | sed -e "s/^/  '/" \
 | sed -e "s/@/'/g" >./ara.plus.fontslist.txt
 
 