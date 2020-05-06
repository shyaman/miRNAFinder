
   $fn =  @ARGV[0];

   if (!(-e "../data/$fn"))  
   { 
          die ("../data/$fn file not found...");
   } 
   system("cp ../data/$fn $fn");  

   #miPred features------------------------------------------------------------------------------------------------- 

   print("\n-microPred started...");
   print("\n-calculating features-------------\n");
   print("\t-folding original sequences...\n");
   system("miPred/./RNAfold < $fn > ../data/$fn.fold ");
   print("\t-calculating miPred sequential and structural features...\n");
   system("perl miPred/genRNAStats.pl < $fn > ../data/$fn.data1");
   system("miPred/./RNAspectral.exe < ../data/$fn.fold > ../data/$fn.data2");  
  
   print("\t-calculating z-features...(this might take some time as 1,000 random sequences are generated for each original sequence)\n");
   system("perl miPred/genRandomRNA.pl -n 1000 -m d < ../data/$fn > ../data/$fn.random.fasta");
   system("miPred/./RNAfold < ../data/$fn.random.fasta > ../data/$fn.random.fold");
   system("perl miPred/genRNARandomStats.pl -n 1000 -i ../data/$fn.random.fold -o ../data/$fn.zdata -m ../data/$fn.fold");
   system("rm ../data/$fn.random.fold");
   system("rm ../data/$fn.random.fasta");

   #MFEI1,2,3,4---------------------------------------------------------------------------------------------------

   print("\t-calculating MFEI1, MFEI2, MFEI3, MFEI4..... \n");
   system("java mfe14 $fn");
   system("java mfe23 $fn");

   #Basepairs-related features-----------------------------------------------------------------------------------

   print("\t-calculating basepair-related features...\n");
   system("java bpcount1 $fn");
   system("java bpcount2 $fn");  

   #RNAfold-related features-------------------------------------------------------------------------------------

   print("\t-calculating RNAfold-related features...\n");
   system("RNAfold/./RNAfold -p2 < $fn > ../data/$fn.RNAfold1");  
   system("java RNAfoldfilter $fn");
   system("rm *.ps");

   #Mfold-related features---------------------------------------------------------------------------------------

   print("\t-calculating mfold-related features...\n");
   system("perl melt.pl $fn > ../data/$fn.mfold");
   system("java Mfoldfilter $fn"); 
   system("rm $fn.*");
   system("rm $fn");
   print("---------------------------");	 

   print("\n\t-filtering all features...\n");
   system("java filter_all $fn");
   system("rm ../data/$fn.*");
#    system("python3 ../micropredid.py -i $fn -o ../data/$fn");
   #leaving script here(only features are required)
   exit;
   #Formating into libSVM input file
   print("\t-formating features...\n");
   system("java format1 $fn");

   #Scaling data
   print("\t-scaling features into [-1,+1]...\n");
   system("../SVM/svm-scale -r ../SVM/range ../SVM/$fn.formatted > ../SVM/$fn.scale ");
   
   #Predicting...
   print("\t-predicting...\n");
   system("../SVM/svm-predict ../SVM/$fn.scale ../SVM/best-smote.model ../data/$fn.predict");

   print("---------------------------------");
   print("\n-Results...\n");
   print("\t-Prediction results are written to the file /data/$fn.predict \n\t  (+1 indicates a pre-miRNA candidate, -1 indicates a negative candidate)");
   print("\n\t-All features extracted are written to the file /data/all.$fn.-48.features");
   print("\n\t-Best 21 features used for the prediction are written to the file /data/selected.$fn.-21.features"); 
   print("\n-microPred completed successfully...");
   print("\n----------------------------------\n");	

   system("rm ../SVM/$fn.*");
   
  
    
  


   
   
   
  


   
