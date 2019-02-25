#!/bin/bash
################################################################
#traineddata from script/Arabic is really bad
#
#time OMP_THREAD_LIMIT=1  tesseract Arabic-TOC.tif Arabic-TOC-best-Arabic --tessdata-dir ~/tessdata_be~/script  --oem 1 --psm 6 -l Arabic
#time OMP_THREAD_LIMIT=1  tesseract Arabic-TOC.tif Arabic-TOC-fast-Arabic --tessdata-dir ~/tessdata_be~/script  --oem 1 --psm 6 -l Arabic
#
#traineddata for ara does not recognize numerals in Arabic script
#
# time OMP_THREAD_LIMIT=1  tesseract Arabic-TOC.tif Arabic-TOC-best-ara --tessdata-dir ~/tessdata_best  --oem 1 --psm 6 -l ara
# time OMP_THREAD_LIMIT=1  tesseract Arabic-TOC.tif Arabic-TOC-best-int-ara --tessdata-dir ~/tessdata  --oem 1 --psm 6 -l ara
# time OMP_THREAD_LIMIT=1  tesseract Arabic-TOC.tif Arabic-TOC-fast-ara --tessdata-dir ~/tessdata_fast  --oem 1 --psm 6 -l ara
#########################################################################

for ModelName in ara-Amiri ;
do
	time OMP_THREAD_LIMIT=1  tesseract Arabic-TOC.png Arabic-TOC-$ModelName --tessdata-dir ./  --oem 1 --psm 6 -l $ModelName
	time OMP_THREAD_LIMIT=1  tesseract Arabic-TOC-numbers.png Arabic-TOC-numbers-$ModelName --tessdata-dir ./  --oem 1 --psm 6 -l $ModelName
done
