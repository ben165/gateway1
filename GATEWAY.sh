#!/bin/bash

progs=$(pgrep GATEWAY)
open=$(echo $progs | wc -w)
#echo "Running $open"

if [[ $open -gt 1 ]]; then
 echo $(date) "Already running" >> debug.txt
 exit 0
fi


if [[ "$PATH" == *"litecoin"* ]]; then
 :
else
 #export PATH="/home/user23/.local/share/solana/install/active_release/bin:$PATH"
 #export PATH="/home/user23/download:$PATH"
 #export PATH="/home/user23/download/litecoin-0.18.1/bin:$PATH"
 #export PATH="/home/user23/download/dogecoin-1.14.5/bin:$PATH"

 export PATH="/home/asdf/.local/share/solana/install/active_release/bin:$PATH"
 export PATH="/home/asdf/Downloads:$PATH"
 export PATH="/home/asdf/Downloads/litecoin-0.18.1/bin:$PATH"
 export PATH="/home/asdf/Downloads/dogecoin-1.14.5/bin:$PATH"

 solana config set --url https://api.mainnet-beta.solana.com > /dev/null 2>&1
fi





DB="db.sqlite"
NANOSEED="" #fill it with your private seed from the atto wallet (https://github.com/codesoap/atto)
SOLANACLUSTER=https://api.mainnet-beta.solana.com
COINS=("None", "Litecoin" "Dogecoin" "NANO" "SOLANA" "Litecoin Test", "Stella", "Stellatest")
MAXTIME=90

PRICES=(0 0.013 10.5 0.7 0.014 0.001 7.4 10)
WEB="http://localhost:7890/project1" #Replace it with the page online if you go live


PASS1="YourSecretPassword"



generate_address() {
 #generate_address $coin 2 $id $timestmp
 #echo "coin $1, status $2, id $3, time $4"
 if (($1 == 1)); then
  # Litecoin
  address1=$(litecoin-cli getnewaddress)
  if (($? == 0)); then
   nr=$(echo "select count(*) from keys where coin=$1" | sqlite3 $DB)
   nr=$(echo $nr+1 | bc)
   echo "INSERT INTO keys(address, coin, addressnr, status, picid, timestamp) VALUES('$address1', $1, $nr, $2, $3, $4)" | sqlite3 $DB
  else
   return 1
  fi
  #echo "Coin $coin, Nr $nr, Addr $address1"
 elif (($1 == 2)); then
  # Dogecoin
  address1=$(dogecoin-cli getnewaddress)
  if (($? == 0)); then
   nr=$(echo "select count(*) from keys where coin=$1" | sqlite3 $DB)
   nr=$(echo $nr+1 | bc)
   echo "INSERT INTO keys(address, coin, addressnr, status, picid, timestamp) VALUES('$address1', $1, $nr, $2, $3, $4)" | sqlite3 $DB
  else
   return 1
  fi
  #echo "Coin $coin, Nr $nr, Addr $address1"
 elif (($1 == 3)); then
  # Nano
  nr=$(echo "select count(*) from keys where coin=$1" | sqlite3 $DB)
  nr=$(echo $nr+1 | bc)
  address1=$(echo $NANOSEED | atto -a $nr address)
  if (($? == 0)); then
   echo "INSERT INTO keys(address, coin, addressnr, status, picid, timestamp) VALUES('$address1', $1, $nr, $2, $3, $4)" | sqlite3 $DB
  else
   return 1
  fi
  #echo "Coin $coin, Nr $nr, Addr $address1"
 elif (($1 == 4)); then
  # Solana
  # solana_keys
  nr=$(echo "select count(*) from keys where coin=$1" | sqlite3 $DB)
  nr=$(echo $nr+1 | bc)
  solana-keygen new --no-bip39-passphrase -s --outfile solana_keys/$nr.sol
  if (($? == 0)); then
   address1=$(solana-keygen pubkey solana_keys/$nr.sol)
   echo "INSERT INTO keys(address, coin, addressnr, status, picid, timestamp) VALUES('$address1', $1, $nr, $2, $3, $4)" | sqlite3 $DB
  else
   return 1
  fi
  #echo "Coin $coin, Nr $nr, Addr $address1"
 elif (($1 == 5)); then
  # Litecoin Testnet
  address1=$(litecoin-cli -testnet getnewaddress)
  if (($? == 0)); then
   #echo $address1
   nr=$(echo "select count(*) from keys where coin=$1" | sqlite3 $DB)
   nr=$(echo $nr+1 | bc)
   echo "INSERT INTO keys(address, coin, addressnr, status, picid, timestamp) VALUES('$address1', $1, $nr, $2, $3, $4)" | sqlite3 $DB
  else
   return 1
  fi
 elif (($1 == 6)); then
  # Stella
  # stella_keys
  nr=$(echo "select count(*) from keys where coin=$1" | sqlite3 $DB)
  nr=$(echo $nr+1 | bc)
  stella create stella_keys/$nr.st
  if (($? == 0)); then
   address1=$(stella show stella_keys/$nr.st)
   echo "INSERT INTO keys(address, coin, addressnr, status, picid, timestamp) VALUES('$address1', $1, $nr, $2, $3, $4)" | sqlite3 $DB
  else
   return 1
  fi
 elif (($1 == 7)); then
  # Stella testnet
  # stella_keys testnet
  nr=$(echo "select count(*) from keys where coin=$1" | sqlite3 $DB)
  nr=$(echo $nr+1 | bc)
  stella create stella_keys/test$nr.st
  if (($? == 0)); then
   address1=$(stellatest show stella_keys/test$nr.st)
   echo "INSERT INTO keys(address, coin, addressnr, status, picid, timestamp) VALUES('$address1', $1, $nr, $2, $3, $4)" | sqlite3 $DB
  else
   return 1
  fi
 fi

}








# Check if paid
addresses=$(echo "select coin, addressnr, address, picid from keys where status=2" | sqlite3 $DB -csv)
for i in $addresses;
do
 data1=($(echo "$i" | tr ',' '\n'))
 
 coin=${data1[0]}
 nr=${data1[1]}
 address=${data1[2]}
 picid=${data1[3]}
 
 if ((coin == 1)); then
  # Litecoin
  amount=$(litecoin-cli getreceivedbyaddress $address)
  if (($? == 0)); then
   paid=$(echo "$amount >= ${PRICES[$coin]}" | bc -q)
   #echo "${COINS[$coin]} $amount ${PRICES[$coin]} Paid: $paid"
  else
   paid=0
  fi

 elif ((coin == 2)); then
  # Dogecoin
  amount=$(dogecoin-cli getreceivedbyaddress $address)
  if (($? == 0)); then
   paid=$(echo "$amount >= ${PRICES[$coin]}" | bc -q)
  else
   paid=0
  fi
  #echo "${COINS[$coin]} $amount ${PRICES[$coin]} Paid: $paid"

 elif ((coin == 3)); then
  # Nano
  amount=$(echo $(echo $NANOSEED | atto -a $nr balance) | cut -f1 -d" ")
  if (($? == 0)); then
   paid=$(echo "$amount >= ${PRICES[$coin]}" | bc -q)
  else
   paid=0
  fi
  #echo "${COINS[$coin]} $amount ${PRICES[$coin]} Paid: $paid"

 elif ((coin == 4)); then
  # Solana
  # solana_keys
  address=$(solana-keygen pubkey solana_keys/$nr.sol)
  amount=$(solana balance $address --url $SOLANACLUSTER | cut -f1 -d" ")
  if (($? == 0)); then
   #echo $amount
   paid=$(echo "$amount >= ${PRICES[$coin]}" | bc -q)
   #echo "${COINS[$coin]} $amount ${PRICES[$coin]} Paid: $paid"
  else
   paid=0
  fi

 elif ((coin == 5)); then
  #Litecoin Test
  amount=$(litecoin-cli -testnet getreceivedbyaddress $address)
  if (($? == 0)); then
   paid=$(echo "$amount >= ${PRICES[$coin]}" | bc -q)
  #echo ${COINS[4]}
  #echo "${COINS[$coin]} $amount ${PRICES[$coin]} Paid: $paid"
  else
   paid=0
  fi

 elif ((coin == 6)); then
  # Stella
  # stella_keys
  amount=$(stella balance stella_keys/$nr.st)
  if (($? == 0)); then
   #echo $amount
   paid=$(echo "$amount >= ${PRICES[$coin]}" | bc -q)
   #echo "${COINS[$coin]} $amount ${PRICES[$coin]} Paid: $paid"
  else
   paid=0
  fi
 
 elif ((coin == 7)); then
  # Stella
  # stella_keys
  amount=$(stellatest balance stella_keys/test$nr.st)
  if (($? == 0)); then
   #echo $amount
   paid=$(echo "$amount >= ${PRICES[$coin]}" | bc -q)
   #echo "${COINS[$coin]} $amount ${PRICES[$coin]} Paid: $paid"
  else
   paid=0
  fi
 fi

 if ((paid == 1)); then
  #echo "$picid Paid"
  #echo "UPDATE keys SET status=3 WHERE picid=$picid"
  wget -qO- "$WEB/paid.php?id=$picid&password=$PASS1"
  if (($? == 0)); then
   echo "UPDATE keys SET status=3 WHERE picid=$picid" | sqlite3 $DB
   echo $(date) "Paid $picid   $amount" >> debug.txt
  fi
 fi
done






# Check payment time
addresses=$(echo "select picid, timestamp from keys where status=2" | sqlite3 $DB -csv)
 
for i in $addresses;
do
 picid=$(echo $i | cut -f1 -d",")
 timestamp=$(echo $i | cut -f2 -d",")
 
 time1=$(date +%s)
 
 amount=$(echo "($time1-$timestamp)/60" | bc -l) # | cut -f1 -d"."
 #echo $picid $amount
 overtime=$(echo "($time1-$timestamp)/60 > $MAXTIME" | bc -l)
 
 #echo $picid $address $amount $ifpaid
 if ((overtime == 1)); then
  wget -qO- "$WEB/burn.php?id=$picid&password=$PASS1"
  if (($? == 0)); then
   echo "UPDATE keys SET status=4 WHERE picid=$picid" | sqlite3 $DB
  fi
 #else
 # echo "Still time!"
 fi
done






# Create new address if needed
data2=$(wget -q -O- $WEB/waiting.php?password=$PASS1)
#sleep 0.5

for i in $data2;
do
 coin=$(echo $i | cut -f2 -d"-")
 id=$(echo $i | cut -f1 -d"-")
 timestmp=$(date +%s)
 amount_check=$(echo "select count(*) from keys where picid=$id and status=2" | sqlite3 $DB)
 if ((amount_check == 0)); then
  generate_address $coin 2 $id $timestmp
  address1=$(echo "select address from keys where picid=$id and status=2" | sqlite3 $DB)
  echo $(date) "Create $id   $coin" >> debug.txt
 else
  address1=$(echo "select address from keys where picid=$id and status=2" | sqlite3 $DB)
 fi
 # If this one fails, time is running anyways. Not solved yet.
 wget -qO- "$WEB/give_address.php?id=$id&address=$address1&password=$PASS1" &> /dev/null
 #sleep 0.5
done



# Fill stats
ltc=$(echo "select count(id) from keys where coin=1 and status=3" | sqlite3 $DB)
nano=$(echo "select count(id) from keys where coin=3 and status=3" | sqlite3 $DB)
sol=$(echo "select count(id) from keys where coin=4 and status=3" | sqlite3 $DB)
doge=$(echo "select count(id) from keys where coin=2 and status=3" | sqlite3 $DB)
xlm=$(echo "select count(id) from keys where coin=6 and status=3" | sqlite3 $DB)
tmp=$(date +%s)

#echo "$WEB/putstats.php?ltc=$ltc&nano=$nano&sol=$sol&tmp=$tmp&password=$PASS1"

wget -qO- "$WEB/putstats.php?ltc=$ltc&nano=$nano&doge=$doge&sol=$sol&xlm=$xlm&tmp=$tmp&password=$PASS1" &> /dev/null
