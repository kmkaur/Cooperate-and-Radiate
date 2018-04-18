### script to build the list of ant species in Springer articles
#$ -q workq -l h_vmem=32G -l mem=32G
#!/bin/bash
rm springer_matrix_ant.txt
rm pam*
for sant in `cat ./list_sant.txt`
do
  surl=($"http://api.springer.com/metadata/pam?p=1&q=type:Journal&api_key=1537d66942e06546234fabe061390200&q="$sant)
  wget -nv $surl  
  sintern_numb=$(cat pam* | grep "apiKey" | awk -F"<" '{print $8}' | awk -F">" '{print $2}')
  echo "$sant $sintern_numb" >> springer_matrix_ant.txt
  rm pam*
done

### script to fill in the ant/trait matrix with the Springer ant sublist
#$ -q workq -l h_vmem=32G -l mem=32G
#!/bin/bash
rm springer_matrix_anttrait.txt
for sant in `cat ./list_sant2.txt`
do
  sintern_list=($sant)
  for strait in `cat ./list_strait.txt`
  do
     surl=($"http://api.springer.com/metadata/pam?p=1&q=type:Journal&api_key=1537d66942e06546234fabe061390200&q="$sant%20AND%20%28$strait%29)
     wget -nv $surl
     sintern_numb=$(cat pam* | grep "apiKey" | awk -F"<" '{print $8}' | awk -F">" '{print $2}')
     sintern_list="$sintern_list $sintern_numb"
     rm pam*
  done
  echo $sintern_list >> springer_matrix_anttrait.txt
done

### script to download relevant Springer abstracts 100 by 100
#$ -q workq -l h_vmem=32G -l mem=32G
#!/bin/bash
for y in `seq 2016 -1 1800`
do
  echo $y
  url=($"http://api.springer.com/metadata/pam?q=ant&q=type:Journal&q=year:"$y"&p=1&api_key=1537d66942e06546234fabe061390200&s=1")
  curl $url > ./filefirst.txt
  number=`awk 'BEGIN { FS = "<total>" } ; { print $2 }' ./filefirst.txt | awk 'BEGIN { FS = "</total>" } ; { print $1 }'`
  echo "$y$number" >> year_list.txt
  for i in `seq 1 100 $number`
  do
    echo $i
    url=($"http://api.springer.com/metadata/pam?q=ant&q=type:Journal&q=year:"$y"&p=100&api_key=1537d66942e06546234fabe061390200&s="$i)
    filename=($"./springer_abstracts/"$i"_abstract.txt")
    curl $url > "$filename"
    ls -l $filename | awk -F" " '{print $5}'
    while [ "$(ls -l $filename | awk -F" " '{print $5}')" -lt 150000 ]
    do
      curl $url > "$filename"
      du $filename | cat
    done
  done
done

### script to download relevant Springer abstracts 100 by 100, and by year
#$ -q workq -l h_vmem=32G -l mem=32G
#!/bin/bash
for y in `seq 2016 -1 1800`
do
  echo $y
  filename=($"./springer_abstracts/"$y"_abstract.txt")
  url=($"http://api.springer.com/metadata/pam?q=ant&q=type:Journal&q=year:"$y"&p=1&api_key=1537d66942e06546234fabe061390200&s=1")
  curl -s $url > ./filefirst.txt
  number=`awk 'BEGIN { FS = "<total>" } ; { print $2 }' ./filefirst.txt | awk 'BEGIN { FS = "</total>" } ; { print $1 }'`
  echo $y' '$number >> year_list.txt
  for i in `seq 1 100 $number`
  do
    echo $i
    url=($"http://api.springer.com/metadata/pam?q=ant&q=type:Journal&q=year:"$y"&p=100&api_key=1537d66942e06546234fabe061390200&s="$i)
    curl -s $url >> "$filename"
  done
done

### script to concatenate all teh abstracts
for y in `seq 2016 -1 1800`
do
  echo $y
  filename=($"./springer_abstracts/"$y"_abstract.txt")
  cat "$filename" | tr -s '\n ' | tr '\n' '_' | sed "{s/<\/p><p>/ /g;}" | sed "{s/<dc:title>/\n<dc:title>/g;}" | sed "{s/<p>/\n<p>/g;}" | sed -n "{s/.*<dc:title>/TITLE /p;s/.*<p>/ABSTRACT /p;}" | sed -n "{s/<\/dc:title>.*//p;s/<\/p>.*//p;}" >> ./clean_springer/all.txt
done




