import json

input_filename = "strategy_dict.json"

input_file = open(input_filename, "r")
result = json.loads(input_file.read())
input_file.close()

print len(result.keys())
print result[""]
print result[""]["c"]
print result["r"]