from dataInitial import *
from dataC import *
from dataCR import *
from dataCRR import *
from dataCRRR import *
from dataR import *
from dataRR import *
from dataRRR import *

decision_map = {}
decision_map["n"] = {}
decision_map["c"] = {}
decision_map["cr"] = {}
decision_map["crr"] = {}
decision_map["crrr"] = {}
decision_map["r"] = {}
decision_map["rr"] = {}
decision_map["rrr"] = {}

for k in decision_map.keys():
	for i in range(2, 15):
		decision_map[k][i] = {}
		for j in range(2, 15):
			decision_map[k][i][j] = {}
			decision_map[k][i][j][True] = {}
			decision_map[k][i][j][False] = {}

def parseCardToInt(card):
	value = 0
	try:
		value = int(card)
	except:
		if card == 'T':
			value = 10
		elif card == 'J':
			value = 11
		elif card == 'Q':
			value = 12
		elif card == 'K':
			value = 13
		elif card == 'A':
			value = 14

	return value

data = js_data_initial["data"]
for d in data:
	same_suit = (d["cards"][1] == d["cards"][3])
	card1 = parseCardToInt(d["cards"][0])
	card2 = parseCardToInt(d["cards"][2])
	values = {
				'raise': float(d["raise"]),
				'check': float(d["call"]),
				'fold': float(d["fold"]),
			}
	
	decision_map["n"][card1][card2][same_suit] = dict(values)
	decision_map["n"][card2][card1][same_suit] = dict(values)

data = js_data_c["data"]
for d in data:
	same_suit = (d["cards"][1] == d["cards"][3])
	card1 = parseCardToInt(d["cards"][0])
	card2 = parseCardToInt(d["cards"][2])
	values = {
				'raise': float(d["raise"]),
				'check': float(d["call"]),
				'fold': float(d["fold"]),
			}
	
	decision_map["c"][card1][card2][same_suit] = dict(values)
	decision_map["c"][card2][card1][same_suit] = dict(values)

data = js_data_cr["data"]
for d in data:
	same_suit = (d["cards"][1] == d["cards"][3])
	card1 = parseCardToInt(d["cards"][0])
	card2 = parseCardToInt(d["cards"][2])
	values = {
				'raise': float(d["raise"]),
				'check': float(d["call"]),
				'fold': float(d["fold"]),
			}
	
	decision_map["cr"][card1][card2][same_suit] = dict(values)
	decision_map["cr"][card2][card1][same_suit] = dict(values)

data = js_data_crr["data"]
for d in data:
	same_suit = (d["cards"][1] == d["cards"][3])
	card1 = parseCardToInt(d["cards"][0])
	card2 = parseCardToInt(d["cards"][2])
	values = {
				'raise': float(d["raise"]),
				'check': float(d["call"]),
				'fold': float(d["fold"]),
			}
	
	decision_map["crr"][card1][card2][same_suit] = dict(values)
	decision_map["crr"][card2][card1][same_suit] = dict(values)

data = js_data_crrr["data"]
for d in data:
	same_suit = (d["cards"][1] == d["cards"][3])
	card1 = parseCardToInt(d["cards"][0])
	card2 = parseCardToInt(d["cards"][2])
	values = {
				'raise': float(d["raise"]),
				'check': float(d["call"]),
				'fold': float(d["fold"]),
			}
	
	decision_map["crrr"][card1][card2][same_suit] = dict(values)
	decision_map["crrr"][card2][card1][same_suit] = dict(values)

data = js_data_r["data"]
for d in data:
	same_suit = (d["cards"][1] == d["cards"][3])
	card1 = parseCardToInt(d["cards"][0])
	card2 = parseCardToInt(d["cards"][2])
	values = {
				'raise': float(d["raise"]),
				'check': float(d["call"]),
				'fold': float(d["fold"]),
			}
	
	decision_map["r"][card1][card2][same_suit] = dict(values)
	decision_map["r"][card2][card1][same_suit] = dict(values)

data = js_data_rr["data"]
for d in data:
	same_suit = (d["cards"][1] == d["cards"][3])
	card1 = parseCardToInt(d["cards"][0])
	card2 = parseCardToInt(d["cards"][2])
	values = {
				'raise': float(d["raise"]),
				'check': float(d["call"]),
				'fold': float(d["fold"]),
			}
	
	decision_map["rr"][card1][card2][same_suit] = dict(values)
	decision_map["rr"][card2][card1][same_suit] = dict(values)

data = js_data_rrr["data"]
for d in data:
	same_suit = (d["cards"][1] == d["cards"][3])
	card1 = parseCardToInt(d["cards"][0])
	card2 = parseCardToInt(d["cards"][2])
	values = {
				'raise': float(d["raise"]),
				'check': float(d["call"]),
				'fold': float(d["fold"]),
			}
	
	decision_map["rrr"][card1][card2][same_suit] = dict(values)
	decision_map["rrr"][card2][card1][same_suit] = dict(values)

keys = decision_map.keys()
for i in range(0, len(keys)):
	for j in range(0, len(keys)):
		if i != j:
			flag = True
			for m in range(2, 15):
				for n in range(2, 15):
					for l in [True, False]:
						temp1 = decision_map[keys[i]][m][n][l]
						temp2 = decision_map[keys[j]][m][n][l]
						if 'raise' in temp1:
							if temp1['raise'] != temp2['raise'] or temp1['check'] != temp2['check'] or temp1['fold'] != temp2['fold']:
								flag = False
								break
					if not flag:
						break
				if not flag:
					break
			if flag:
				print "DUPLICATED DATA"
				print (keys[i], keys[j])

print "DONE"

import pickle
pickle_out = open("Alberta-bot.dat","wb")
pickle.dump(decision_map, pickle_out)
pickle_out.close()


pickle_in = open("Alberta-bot.dat","rb")
example_dict = pickle.load(pickle_in)

