import csv
from deap import gp

machine_alias = "Enchilada"

class Individual:
    def __init__(self, heuristic, complexity, fitness):
        temp_heuristic = heuristic
        if temp_heuristic[-1] == ',':
            temp_heuristic = temp_heuristic[:-1]
        if temp_heuristic[-1] == '"' or temp_heuristic[-1] == "'":
            temp_heuristic = temp_heuristic[:-1]
        if temp_heuristic[0] == "'" or temp_heuristic[0] == '"':
            temp_heuristc = temp_heuristic[1:]
        self.heuristic = temp_heuristic
        
        self.complexity = int(complexity)
        
        temp_fitness = fitness
        if temp_fitness[0] == "(":
            temp_fitness = temp_fitness[1:]
        if temp_fitness[-2:] == ",)":
            temp_fitness = temp_fitness[:-2]
        self.fitness = float(temp_fitness)
    
    def __lt__(self, ind):
        return self.fitness < ind.fitness
    
    def __eq__(self, ind):
        return self.fitness == ind.fitness
    
    def __str__(self):
        return self.heuristic + ' | ' + str(self.complexity) + ' | ' + str(self.fitness)

class MatchUp:
    def __init__(self, heuristic_p1, fitness_p1, heuristic_p2, fitness_p2):
        self.heuristic_p1 = heuristic_p1
        self.fitness_p1 = float(fitness_p1)
        self.heuristic_p2 = heuristic_p2
        self.fitness_p2 = float(fitness_p2)
    
    def __lt__(self, ind):
        return self.fitness < ind.fitness
    
    def __eq__(self, ind):
        return self.fitness == ind.fitness
    
    def __str__(self):
        return self.heuristic_p1 + ' | ' + str(self.fitness_p1) + ' | ' + self.heuristic_p2 + ' | ' + str(self.fitness_p2) 

def extractDictFromCSV(filename):
    data = []
    data_order = []
    data_dict_format = {}

    with open(filename, 'rb') as csvfile:
        spamreader = csv.reader(csvfile, delimiter=';', quotechar='|')
        for x in spamreader.next():
            temp = x
            if x != '':
                if x[0] == ' ':
                    temp = x[1:]
                data_order.append(temp)
                data_dict_format[temp] = None

        for row in spamreader:
            data.append(dict(data_dict_format))
            count = len(data_dict_format.keys())
            #print "========="
            for x in row:
                temp = x
                if x != '':
                    if x[0] == ' ':
                        temp = x[1:]

                    data[-1][data_order[len(data_dict_format.keys())- count]] = temp
                    count -= 1
    return data

def extractIndividualsFromAASData(data, ind_field=['EndTree'], fitness_field=['Fitness'], condition=[]):
    population = []
    for d in data:
        flag = False
        if condition != []:
            for cond in condition:
                if not cond[0](cond[2](d[cond[1]]), cond[3]):
                    flag = True
                    break
        if flag:
            continue
        for k in range(0, len(ind_field)):
            ind_key = ind_field[k]
            fit_key = fitness_field[k]
            population.append(Individual(d[ind_key], 0, d[fit_key]))
    
    return population

def extractIndividualsFromData(data, ind_field=['EndTree'], fitness_field=['Fitness'], complexity_field=['Complexity'], condition=[]):
    population = []
    for d in data:
        flag = False
        if condition != []:
            for cond in condition:
                if not cond[0](cond[2](d[cond[1]]), cond[3]):
                    flag = True
                    break
        if flag:
            continue
        for k in range(0, len(ind_field)):
            ind_key = ind_field[k]
            fit_key = fitness_field[k]
            compl_key = complexity_field[k]
            population.append(Individual(d[ind_key], d[compl_key], d[fit_key]))
    
    return population


def extractIndividualsFromMatchUpData(data, ind_field=['Player1'], fitness_field=['Fitness-p1'], opp_ind_field=['Player2'], opp_fitness_field=['Fitness-p2'], condition=[]):
    population = []
    for d in data:
        flag = False
        if condition != []:
            for cond in condition:
                if not cond[0](cond[2](d[cond[1]]), cond[3]):
                    flag = True
                    break
        if flag:
            continue
        for k in range(0, len(ind_field)):
            ind_key = ind_field[k]
            fit_key = fitness_field[k]
            opp_ind_key = opp_ind_field[k]
            opp_fit_key = opp_fitness_field[k]
            population.append(MatchUp(d[ind_key], d[fit_key], d[opp_ind_key], d[opp_fit_key]))
    
    return population

def topK(population, k):
    if k > len(population):
        return population
    return population[:k]

def heuristicDepthGE(ind, val):
    count = ind.count("IfThenElse")
    
    return count >= val

def heuristicDepthLE(ind, val):
    count = ind.count("IfThenElse")
    
    return count <= val

def heuristicDepthEQ(ind, val):
    count = ind.count("IfThenElse")
    
    return count == val
