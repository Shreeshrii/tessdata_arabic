# tessdata_arabic
Finetuned traineddata files for Arabic using Scheherazade font

Test files for https://github.com/tesseract-ocr/tesseract/issues/2132

### finetuned for Impact 

```
combine_tessdata -d ara-Scheherazade_Impact_400.traineddata

Version string:4.00.00alpha:ara:synth20170629:[1,48,0,1Ct3,3,16Mp3,3Lfys64Lfx96Lrx96Lfx512O1c1]
0:config:size=545, offset=192
17:lstm:size=11582395, offset=737
18:lstm-punc-dawg:size=1986, offset=11583132
19:lstm-word-dawg:size=999442, offset=11585118
20:lstm-number-dawg:size=13250, offset=12584560
21:lstm-unicharset:size=5061, offset=12597810
22:lstm-recoder:size=769, offset=12602871
23:version:size=80, offset=12603640
```

### Finetuned for PlusMinus

```
combine_tessdata -d ara-Scheherazade_PlusMinus_400.traineddata
Version string:4.0.0-118-gd44b5
0:config:size=405, offset=192
17:lstm:size=11619331, offset=597
18:lstm-punc-dawg:size=98, offset=11619928
19:lstm-word-dawg:size=1644290, offset=11620026
20:lstm-number-dawg:size=2898, offset=13264316
21:lstm-unicharset:size=6460, offset=13267214
22:lstm-recoder:size=850, offset=13273674
23:version:size=16, offset=13274524
```
