#!/usr/bin/python3

import ast


with open("all_address.txt", "r") as f:
 list1 = f.read()


#dict
content = ast.literal_eval(list1)


#print(content)

#counter = 0
list2 = []
for i in content:
 #print(i)
 received = content[i]
 
 #print(received["purpose"])
 
 if received["purpose"] == "receive":
  #print("lite getreceivedbyaddress " + '"' + i + '"')
  list2.append(i)
 #for j in i:
 # print(j)
 #counter += 1;

for i in list2:
 print(i)
#for i in range(0, len(content)):
# content[i]
