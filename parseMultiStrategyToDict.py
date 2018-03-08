import json

strategy_filename = "strategy_refined.txt"

file_raw_data = open(strategy_filename, 'r')

file_data = []
for line in file_raw_data:
	file_data.append(line)
file_raw_data.close()

result = {}

k = 0
while k < len(file_data):
	if "PLAYER" in file_data[k] or len(file_data) < 3:
		k += 1
		continue
	
	state_line = file_data[k]
	action_str = state_line.split(":")[2]
	action_str = action_str.split("\n")[0]
	
	w = k+1
	while True:
		if w >= len(file_data) or "PLAYER" in file_data[w] or "STATE" in file_data[w]:
			break

		bucket_line = file_data[w]

		bucket_line = bucket_line.split(":")[1]
		temp_bucket_data = bucket_line.split("%")
		bucket_data = []
		for x in temp_bucket_data:
			temp_x = x.split(" ")
			for y in temp_x:
				if len(y) > 0:
					bucket_data.append(y)

		bucket_data[-1] = bucket_data[-1][:-1]

		temp = {}
		i = 0
		while i < len(bucket_data):
			key = bucket_data[i+1]
			value = float(bucket_data[i]) / 100.0
			
			temp[key] = value
			
			i += 2

		if action_str not in result:
			result[action_str] = {}
		result[action_str][w-k] = temp
		
		w += 1
		
	k = w

print len(result.keys())

output_filename = "strategy_refined_moreiters_dict.json"
output_file = open(output_filename, 'w')
output_file.write(json.dumps(result))
output_file.close()