#!/bin/bash
################################################################
# variables to set tasks performed
################################################################
MakeEval=yes
MakePlusMinus=yes

RunPlusTraining=yes
RunEval=yes
################################################################l
ModelName=ara-multi
DebugInterval=0
Lang=ara
BaseLang=Arabic
# local copy of traineddata with the old 'best' training set
bestdata_dir=../tessdata_best
# tessdata directory for lstm.train config files 
tessdata_dir=~/tessdata
# directory with training scripts - tesstrain.sh etc.
tesstrain_dir=~/tesseract/src/training
# downloaded directory with language data - ara.config, wordlists, numbers and punc
langdata_dir=~/langdata_lstm
# fonts directory for this system
fonts_dir=~/.fonts
# fonts to use for training - a minimal set for fast tests

# fonts for minus training of best model
fonts_for_minus=" \
'Amiri' \
'Scheherazade' \
'Traditional Arabic' \
'Sakkal Majalla' \
  "
  
# fonts for computing evals of finetuned model
fonts_for_eval=" \
'Amiri' \
'Scheherazade' \
'Traditional Arabic' \
'Sakkal Majalla' \
 "
 
# output directories for this run
eval_output_dir=./$ModelName-eval
minus_output_dir=./$ModelName-train
trained_output_dir=./$ModelName-from-$BaseLang

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
--workspace_dir ~/tmp \
--noextract_font_properties \
--langdata_dir $langdata_dir \
--tessdata_dir  $tessdata_dir \
--training_text ../langdata/ara/ara.evalnew.training_text \
--output_dir $eval_output_dir

fi


if [ $MakePlusMinus = "yes" ]; then

echo "#### This cleans out all previous checkpoints for training ####"
rm -rf $trained_output_dir
mkdir -p  $trained_output_dir

echo "###### MAKING PLUSMINUS DATA ######"
rm -rf $minus_output_dir
mkdir $minus_output_dir

  eval   bash $tesstrain_dir/tesstrain.sh \
--fonts_dir $fonts_dir \
--fontlist $fonts_for_minus \
--exposures "0" \
--lang $Lang \
--linedata_only \
--save_box_tiff \
--workspace_dir ~/tmp \
--noextract_font_properties \
--langdata_dir $langdata_dir \
--tessdata_dir  $tessdata_dir \
--training_text ../langdata/ara/ara.minusnew.training_text \
--output_dir $minus_output_dir

echo "#### combine_tessdata to extract lstm model from 'tessdata_best' for $BaseLang ####"
combine_tessdata -u $bestdata_dir/$BaseLang.traineddata $bestdata_dir/$BaseLang.
combine_tessdata -u $bestdata_dir/$Lang.traineddata $bestdata_dir/$Lang.

merge_unicharsets \
../langdata/ara/ara.zwnj.unicharset \
$minus_output_dir/$Lang/$Lang.unicharset \
$eval_output_dir/$Lang/$Lang.unicharset \
$minus_output_dir/$Lang.continue.unicharset

echo "#### build version string ####"
Version_Str="ara:shreeshrii`date +%Y%m%d`:from:"
sed -e "s/^/$Version_Str/" $bestdata_dir/$BaseLang.version > $minus_output_dir/$Lang.new.version

echo "#### rebuild starter traineddata using the merged unicharset ####"
combine_lang_model \
--input_unicharset    $minus_output_dir/$Lang.continue.unicharset \
--script_dir $langdata_dir \
--words $langdata_dir/$Lang/$Lang.wordlist \
--numbers $langdata_dir/$Lang/$Lang.numbers \
--puncs $langdata_dir/$Lang/$Lang.punc \
--output_dir $minus_output_dir \
--lang_is_rtl \
--pass_through_recoder \
--version_str ` cat $minus_output_dir/$Lang.new.version` \
--lang $Lang 

combine_tessdata -d ./ara-Amiri-train/ara/ara.traineddata

cp  $minus_output_dir/$Lang.training_files.txt $trained_output_dir/$Lang.training_files.txt 

fi

if [ $RunPlusTraining = "yes" ]; then

for ((PlusMinusIterations=5700; PlusMinusIterations<=7000; PlusMinusIterations+=100)); do
   
    lstmtraining \
        --model_output  $trained_output_dir/${ModelName} \
        --continue_from  $bestdata_dir/$BaseLang.lstm \
        --old_traineddata $bestdata_dir/$BaseLang.traineddata \
        --traineddata $minus_output_dir/$Lang/$Lang.traineddata \
        --max_iterations $PlusMinusIterations \
        --debug_interval $DebugInterval \
        --train_listfile $trained_output_dir/$Lang.training_files.txt 
        
    lstmtraining \
        --stop_training \
        --continue_from ${trained_output_dir}/${ModelName}_checkpoint \
        --old_traineddata $bestdata_dir/$BaseLang.traineddata \
        --traineddata $minus_output_dir/$Lang/$Lang.traineddata \
        --model_output $trained_output_dir/$ModelName.traineddata
        
    cp $trained_output_dir/$ModelName.traineddata    ../
	
    lstmeval \
        --model $trained_output_dir/$ModelName.traineddata \
        --verbosity 0 \
        --eval_listfile $eval_output_dir/$Lang.training_files.txt
    echo -e "\n*** Evaluation of $eval_output_dir done using $ModelName.traineddata at $PlusMinusIterations iterations.\n"
        
done

fi

if [ $RunEval = "yes" ]; then
           
echo -e "\n\n #### ************* wdiff tuned OCR against ground truth ***************  ####\n"

## sed -e 's/\(.\) .*$/\1/g'  $eval_output_dir/ara.Amiri.exp0.box >  ara.Amiri.exp0-gt.txt
##  sed -e :a -e '/$/N; s/\n//; ta' ara.Amiri.exp0-gt.txt >  ara.Amiri.exp0.txt

tesseract $eval_output_dir/ara.Amiri.exp0.tif ara.Amiri.exp0-$ModelName-eval --tessdata-dir $trained_output_dir  --oem 1 --psm 6 -l $ModelName

wdiff --no-common --statistics ./ara.Amiri.exp0-$ModelName-eval.txt ../langdata/$Lang/$Lang.evalnew.training_text 

tesseract /home/ubuntu/tessdata_arabic/Arabic-TOC.tif /home/ubuntu/tessdata_arabic/Arabic-TOC-$ModelName  --tessdata-dir $trained_output_dir  --oem 1 --psm 6 -l $ModelName
tesseract /home/ubuntu/tessdata_arabic/Arabic-TOC-numbers.png /home/ubuntu/tessdata_arabic/Arabic-TOC-numbers-$ModelName  --tessdata-dir $trained_output_dir  --oem 1 --psm 6 -l $ModelName

fi

