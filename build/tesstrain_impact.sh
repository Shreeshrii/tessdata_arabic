#!/bin/bash
    ################################################################
# variables to set tasks performed
MakeTraining=no
MakePlusMinus=no
MakeEval=no
RunTraining=yes
RunPlusTraining=no
RunEval=yes
################################################################
ImpactIterations=400
PlusMinusIterations=10000
DebugInterval=-1
Lang=ara
BaseLang=ara
# local copy of traineddata with the old 'best' training set
bestdata_dir=../tessdata_best
# tessdata directory for lstm.train config files 
tessdata_dir=~/tessdata
# directory with training scripts - tesstrain.sh etc.
tesstrain_dir=~/tesseract/src/training
# downloaded directory with language data - ara.config, wordlists, numbers and punc
langdata_dir=../langdata
# fonts directory for this system
fonts_dir=~/.fonts/myfonts
# fonts to use for training - a minimal set for fast tests
fonts_for_training=" \
  'Scheherazade Regular' \
 "
# fonts for plusminus of best  model
fonts_for_plusminus=" \
  'Scheherazade Regular' \
 "
 
 # fonts for computing evals of best fit model
fonts_for_eval=" \
  'Scheherazade Regular' \
 "
 
# output directories for this run
eval_output_dir=./$Lang-eval
train_output_dir=./$Lang-train
plusminus_output_dir=./$Lang-plusminus
trained_output_dir=./$Lang-trained-from-$BaseLang

if [ $MakeTraining = "yes" ]; then

echo "###### MAKING TRAINING DATA ######"
 rm -rf $train_output_dir
 mkdir $train_output_dir

echo "#### run tesstrain.sh ####"
# the EVAL handles the quotes in the font list
eval   bash $tesstrain_dir/tesstrain.sh \
--lang $Lang \
--linedata_only \
--save_box_tiff \
--noextract_font_properties \
--exposures "0" \
--fonts_dir $fonts_dir \
--fontlist $fonts_for_training \
--langdata_dir $langdata_dir \
--tessdata_dir  $tessdata_dir \
--training_text $langdata_dir/$Lang/$Lang.orig.training_text \
--output_dir $train_output_dir

echo "#### combine_tessdata to extract lstm model from 'tessdata_best' for $BaseLang ####"
combine_tessdata -u $bestdata_dir/$BaseLang.traineddata $bestdata_dir/$BaseLang.
combine_tessdata -u $bestdata_dir/$Lang.traineddata $bestdata_dir/$Lang.

echo "#### This cleans out all previous checkpoints for training ####"
rm -rf $trained_output_dir
mkdir -p  $trained_output_dir

fi

if [ $MakePlusMinus = "yes" ]; then

echo "###### MAKING PLUSMINUS DATA ######"
rm -rf $plusminus_output_dir
mkdir $plusminus_output_dir

  eval   bash $tesstrain_dir/tesstrain.sh \
--fonts_dir $fonts_dir \
--fontlist $fonts_for_plusminus \
--exposures "-1 0 1" \
--lang $Lang \
--linedata_only \
--save_box_tiff \
--noextract_font_properties \
--langdata_dir $langdata_dir \
--tessdata_dir  $tessdata_dir \
--training_text $langdata_dir/$Lang/$Lang.plusminus.training_text \
--output_dir $plusminus_output_dir

fi

if [ $MakeEval = "yes" ]; then

echo "###### MAKING EVAL DATA ######"
 rm -rf $eval_output_dir
  mkdir $eval_output_dir

  eval   bash $tesstrain_dir/tesstrain.sh \
--fonts_dir $fonts_dir \
--fontlist $fonts_for_eval \
--exposures "0" \
--lang $Lang \
--linedata_only \
--save_box_tiff \
--noextract_font_properties \
--langdata_dir $langdata_dir \
--tessdata_dir  $tessdata_dir \
--training_text $langdata_dir/$Lang/$Lang.eval.training_text \
--output_dir $eval_output_dir

fi


if [ $RunTraining = "yes" ]; then

echo "#### plusminus training files list to use for LSTM training ####"

echo "#### IMPACT training using original text #####"
nice lstmtraining \
--continue_from  $bestdata_dir/$BaseLang.lstm \
--traineddata $bestdata_dir/$BaseLang.traineddata \
--max_iterations $ImpactIterations \
--debug_interval $DebugInterval \
--train_listfile $plusminus_output_dir/$Lang.training_files.txt \
--model_output  $trained_output_dir/Scheherazade_Impact

echo "#### stop training                                       ####"
lstmtraining \
--stop_training \
--continue_from $trained_output_dir/Scheherazade_Impact_checkpoint \
--traineddata $bestdata_dir/$BaseLang.traineddata \
--model_output $trained_output_dir/$Lang-Scheherazade_Impact_$ImpactIterations.traineddata


fi

if [ $RunPlusTraining = "yes" ]; then

echo "#### Plus-Minus training Using plusminus text #####"
nice lstmtraining \
-sequential_training \
--continue_from  $bestdata_dir/$BaseLang.lstm \
--old_traineddata $bestdata_dir/$BaseLang.traineddata \
--traineddata $plusminus_output_dir/$Lang/$Lang.traineddata \
--max_iterations $PlusMinusIterations \
--debug_interval $DebugInterval \
--train_listfile $plusminus_output_dir/$Lang.training_files.txt \
--model_output  $trained_output_dir/Scheherazade_PlusMinus

echo "#### stop training                                       ####"
lstmtraining \
--stop_training \
--continue_from $trained_output_dir/Scheherazade_PlusMinus_checkpoint \
--old_traineddata $bestdata_dir/$BaseLang.traineddata \
--traineddata $plusminus_output_dir/$Lang/$Lang.traineddata \
--model_output $trained_output_dir/$Lang-Scheherazade_PlusMinus_$PlusMinusIterations.traineddata

cp $trained_output_dir/$Lang-Scheherazade*.traineddata    ~/tessdata_best/
cp $trained_output_dir/$Lang-Scheherazade*.traineddata    ../

fi

if [ $RunEval = "yes" ]; then

echo -e "\n #### eval files using original ara.traineddata   ####\n"
lstmeval \
--model $bestdata_dir/$BaseLang.traineddata \
--eval_listfile $eval_output_dir/$Lang.training_files.txt

echo -e "\n #### eval files using $Lang-Scheherazade_Impact_$ImpactIterations.traineddata   ####\n"
lstmeval \
--model $trained_output_dir/$Lang-Scheherazade_Impact_$ImpactIterations.traineddata \
--eval_listfile $eval_output_dir/$Lang.training_files.txt

echo -e "\n #### eval files using $Lang-Scheherazade_PlusMinus_$PlusMinusIterations.traineddata   ####\n"
lstmeval \
--model $trained_output_dir/$Lang-Scheherazade_PlusMinus_$PlusMinusIterations.traineddata \
--eval_listfile $eval_output_dir/$Lang.training_files.txt

echo -e "\n\n #### ************* EVAL TEXT***************  ####\n"

time tesseract ara-eval/ara.Scheherazade_Regular.exp0.tif ara.Scheherazade.exp0-Impact --tessdata-dir $trained_output_dir  --oem 1 --psm 6 -l $Lang-Scheherazade_Impact_$ImpactIterations

wdiff --no-common --statistics ./ara.Scheherazade.exp0-Impact.txt $langdata_dir/$Lang/$Lang.eval.training_text 

time tesseract ara-eval/ara.Scheherazade_Regular.exp0.tif ara.Scheherazade.exp0-PlusMinus --tessdata-dir $trained_output_dir  --oem 1 --psm 6 -l $Lang-Scheherazade_PlusMinus_$PlusMinusIterations

wdiff --no-common --statistics ./ara.Scheherazade.exp0-PlusMinus.txt $langdata_dir/$Lang/$Lang.eval.training_text 

fi

