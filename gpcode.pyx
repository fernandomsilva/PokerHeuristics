import pyximport; pyximport.install()
from poker import *

import random
import operator
import itertools
import marshal
import multiprocessing as mp
import time, datetime, os
from deap import creator, gp, base, tools, algorithms

DEFAULT_TREE_DEPTH = 2
machine_alias = "Typheus"

creator.create("FitnessMax", base.Fitness, weights=(1.0,))
#creator.create("Individual", list, fitness=creator.FitnessMax)
creator.create("GameHeuristicIndividualMax", gp.PrimitiveTree, fitness=creator.FitnessMax)

pset = gp.PrimitiveSetTyped("MoveSelector", [list, int, list], str)
#pset.renameArguments(ARG0="Hand", ARG1="PotSize")

pset.addTerminal(True, bool)
pset.addTerminal(False, bool)
for i in range(2,14):
    pset.addTerminal(i, int)
pset.addTerminal("raise", str)
pset.addTerminal("check", str)
pset.addTerminal("fold", str)
pset.addPrimitive(operator.and_, [bool, bool], bool)

pset.addPrimitive(IfThenElse, [bool, str, str], str)
#pset.addPrimitive(isSameSuit, [list], bool)
#pset.addPrimitive(notSameSuit, [list], bool)
#pset.addPrimitive(hasDoubles, [list], bool)
#pset.addPrimitive(notHasDoubles, [list], bool)
#pset.addPrimitive(cardDifferenceGE, [list, int], bool)
#pset.addPrimitive(cardDifferenceLE, [list, int], bool)
pset.addPrimitive(highestCardGE, [list, int], bool)
pset.addPrimitive(highestCardLE, [list, int], bool)
pset.addPrimitive(lowestCardGE, [list, int], bool)
pset.addPrimitive(lowestCardLE, [list, int], bool)
pset.addPrimitive(totalPotGE, [int, int], bool)
pset.addPrimitive(totalPotLE, [int, int], bool)
pset.addPrimitive(handValueGE, [list, int, list], bool)
pset.addPrimitive(handValueLE, [list, int, list], bool)

possible_strings = [
                "raise",
                "check",
                "fold"
               ]

possible_ints = range(2, 15)
possible_rank_ints = range(1, 11)
possible_pot_ints = range(1, 33)
#possible_bools_operations = ["and_", "isSameSuit", "notSameSuit", "hasDoubles", "notHasDoubles", "highestCardGE", "highestCardLE", "lowestCardGE", "lowestCardLE"]
possible_bools_operations = ["and_", "highestCardGE", "highestCardLE", "lowestCardGE", "lowestCardLE"]
possible_bools_operations.extend(["totalPotGE", "totalPotLE"])
possible_bools_operations.extend(["handValueLE", "handValueGE"])
#possible_bools_operations.extend(["cardDifferenceLE", "cardDifferenceGE"])

def generateBoolOp():
    operation = random.choice(possible_bools_operations)
    
    if operation == "and_":
        param1 = generateBoolOp()
        param2 = generateBoolOp()
    else:
        if "totalPot" in operation:
            param1 = "ARG1"
            param2 = str(random.choice(possible_pot_ints))
        else:
            param1 = "ARG0"
            if operation == "handValueLE" or operation == "handValueGE":
                param2 = str(random.choice(possible_rank_ints))
                return operation + "(" + param1 + "," + param2 + ",ARG2)"
            else:
                param2 = str(random.choice(possible_ints))
            
    return operation + "(" + param1 + "," + param2 + ")"

def generateTerminal():
    term = random.choice(possible_strings)

    return term #+ "(Moves," + param1 + "," + param2 + ")"
    
def generateIndividualString(depth):
    if depth == 0:
        return generateTerminal()
    else:
        result = ""
        for i in range(0, depth):
            result += "IfThenElse(" + generateBoolOp() + "," + generateTerminal() + ","
        
        result += generateTerminal()
        for i in range(0, depth):
            result += ")"
        
        return result

def generateIndividual(depth, pset, type_=None):
    return gp.PrimitiveTree.from_string(generateIndividualString(depth), pset)

def parseAndCondition(condition):
    result = []
    i = 1
    while i < len(condition):
        if condition[i].name == "isSameSuit":
            result.append([isSameSuit])
            i += 1
        elif condition[i].name == "notSameSuit":
            result.append([notSameSuit])
            i += 1
        elif condition[i].name == "hasDoubles":
            result.append([hasDoubles])
            i += 1
        elif condition[i].name == "notHasDoubles":
            result.append([notHasDoubles])
            i += 1
        elif condition[i].name == "totalPotGE":
            result.append([totalPotGE, int(condition[i+2].name)])
        elif condition[i].name == "totalPotLE":
            result.append([totalPotLE, int(condition[i+2].name)])
        elif condition[i].name == "cardDifferenceLE":
            result.append([cardDifferenceLE, int(condition[i+2].name)])
        elif condition[i].name == "cardDifferenceGE":
            result.append([cardDifferenceGE, int(condition[i+2].name)])
        elif condition[i].name == "highestCardLE":
            result.append([highestCardLE, int(condition[i+2].name)])
        elif condition[i].name == "highestCardGE":
            result.append([highestCardGE, int(condition[i+2].name)])
        elif condition[i].name == "lowestCardLE":
            result.append([lowestCardLE, int(condition[i+2].name)])
        elif condition[i].name == "lowestCardGE":
            result.append([lowestCardGE, int(condition[i+2].name)])
        elif condition[i].name == "handValueLE":
            result.append([handValueLE, int(condition[i+2].name), operator.le])
        elif condition[i].name == "handValueGE":
            result.append([handValueGE, int(condition[i+2].name), operator.ge])
        i += 1
    
    return result

def parseCondition(condition):
    #print [x.name for x in condition]
    result = []
    
    if condition[0].name == "isSameSuit":
        result = [isSameSuit]
    elif condition[0].name == "notSameSuit":
        result = [notSameSuit]
    elif condition[0].name == "hasDoubles":
        result = [hasDoubles]
    elif condition[0].name == "notHasDoubles":
        result = [notHasDoubles]
    elif condition[0].name == "totalPotGE":
        result = [totalPotGE, int(condition[-1].name)]
    elif condition[0].name == "totalPotLE":
        result = [totalPotLE, int(condition[-1].name)]
    elif condition[0].name == "cardDifferenceLE":
        result = [cardDifferenceLE, int(condition[-1].name)]
    elif condition[0].name == "cardDifferenceGE":
        result = [cardDifferenceGE, int(condition[-1].name)]
    elif condition[0].name == "highestCardLE":
        result = [highestCardLE, int(condition[-1].name)]
    elif condition[0].name == "highestCardGE":
        result = [highestCardGE, int(condition[-1].name)]
    elif condition[0].name == "lowestCardLE":
        result = [lowestCardLE, int(condition[-1].name)]
    elif condition[0].name == "lowestCardGE":
        result = [lowestCardGE, int(condition[-1].name)]
    elif condition[0].name == "handValueLE":
        result = [handValueLE, int(condition[-2].name), operator.le]
    elif condition[0].name == "handValueGE":
        result = [handValueLE, int(condition[-2].name), operator.ge]
    elif condition[0].name == "and_":
        result = parseAndCondition(condition)
    
    return result

def parseAllConditions(conditions):
    result = []
    for condition in conditions:
        result.append(parseCondition(condition))
    
    return result

def handsThatMeetCondition(condition, hands):
    result = []
    
    if len(condition) == 1:
        for hand in hands:
            if condition[0](hand):
                result.append(hand)
    elif len(condition) == 2 and not isinstance(condition[0], list):
        for hand in hands:
            if condition[0](hand, condition[1]):
                result.append(hand)
    elif len(condition) == 3:
        for hand in hands:
            result.append(hand)
    else:
        compiled_conditions = condition
        #print compiled_conditions
        for hand in hands:
            flag = True
            for cond in compiled_conditions:
                if len(cond) == 1:
                    if not cond[0](hand):
                        flag = False
                        break
                elif len(cond) == 2:
                    if not cond[0](hand, cond[1]):
                        flag = False
                        break

            if flag:
                result.append(hand)
    
    return result

def ranksThatMeetCondition(condition, ranks):
    result = []
    
    for rank in ranks:
        if condition[2](rank, condition[1]):
            result.append(rank)
    
    return result

def testIfAllConditionsAreNotHandBased(condition):
    if isinstance(condition[0], list):
        flag = True
        for c in condition:
            if "totalPot" not in c[0].__name__ and "handValue" not in c[0].__name__:
                flag = False
                break
        
        return flag            
    else:
        if "totalPot" in condition[0].__name__ or "handValue" in condition[0].__name__:
            return True
    
    return False

def potValuesThatSatisfyCondition(condition, pots):
    result = set([])
    
    if not isinstance(condition[0], list):
        if "totalPot" in condition[0].__name__:
            for pot in pots:
                if condition[0](pot, condition[1]):
                    result.add(pot)
    else:
        for pot in pots:
            flag = True
            for cond in condition:
                if "totalPot" in cond[0].__name__:
                    if not cond[0](pot, cond[1]):
                        flag = False
                        break
            if flag:
                result.add(pot)
    
    return result

def testIfThereArePotCheckConditions(condition):
    if isinstance(condition[0], list):
        for c in condition:
            if "totalPot" in c[0].__name__:
                return True
    else:
        if "totalPot" in condition[0].__name__:
            return True
    
    return False

def testIfThereAreRankCheckConditions(condition):
    if isinstance(condition[0], list):
        for c in condition:
            if "handValue" in c[0].__name__:
                return True
    else:
        if "handValue" in condition[0].__name__:
            return True
    
    return False

def boardsThatSatisfyCondition(condition, boards):
    result = set([])
    
    if not isinstance(condition[0], list):
        for board in boards:
            if condition[0]([Card(2, "D"), Card(5, "S")], condition[1], list(board)):
                result.add(board)
    else:
        for board in boards:
            flag = True
            for cond in condition:
                if "handValue" in cond[0].__name__:
                    if not cond[0]([Card(2, "D"), Card(5, "S")], cond[1], list(board)):
                        flag = False
                        break
            if flag:
                result.add(board)
    
    return result

def isTreeValid(tree, hands):
    conditions = []
    for i in range(0, len(tree)):
        if tree[i].name == "IfThenElse":
            subtree_slice = tree.searchSubtree(i)
            if tree[subtree_slice.stop-1].ret == str and tree[subtree_slice.stop-2].ret == str and tree[subtree_slice.stop-1].name == tree[subtree_slice.stop-2].name:
                return False
        
            subtree_slice = tree.searchSubtree(i+1)
            conditions.append(tree[subtree_slice.start:subtree_slice.stop])
        
    conditions = parseAllConditions(conditions)
    #print conditions
    boards = boardSample()
    current_hands = set(hands)
    current_pots = set(range(0, 50))
    current_boards = set([tuple(b) for b in boards])
    for condition in conditions:
        temp = handsThatMeetCondition(condition, current_hands)
        
        if len(temp) == len(current_hands) or len(temp) == 0:
            if not testIfAllConditionsAreNotHandBased(condition):
                return False
            else:
                if testIfThereArePotCheckConditions(condition):
                    temp_pots = potValuesThatSatisfyCondition(condition, current_pots)
                    if len(current_pots) == len(temp_pots) or len(temp_pots) == 0:
                        return False

                    current_pots = current_pots.difference(temp_pots)
                    
                if boards != [] and testIfThereAreRankCheckConditions(condition):
                    temp_boards = boardsThatSatisfyCondition(condition, current_boards)
                    if len(current_boards) == len(temp_boards) or len(temp_boards) == 0:
                        return False
                
        #print "End: " + str(len(temp))
        current_hands = current_hands.difference(set(temp))
    
    return True

def sameCondition(cond1, cond2):
    if len(cond1) != len(cond2):
        return False

    if len(cond1) == 1:
        if cond1[0] == cond2[0]:
            return True
        return False
    
    if len(cond1) == 2:
        if cond1[0] == cond2[0] and cond1[1] == cond2[1]:
            return True
    
    if cond1[0] == cond2[0] and cond1[1] == cond2[1] and cond1[2] == cond2[2]:
        return True

    return False

def conditionToString(condition):
    result = ""
    if len(condition) == 1:
        result += condition[0].__name__ + "(ARG0)"
    else:
        if "totalPot" in condition[0].__name__:
            result += condition[0].__name__ + "(ARG1, " + str(condition[1]) + ")"
        elif "handValue" in condition[0].__name__:
            result += condition[0].__name__ + "(ARG0, " + str(condition[1]) + ", ARG2)"
        else:
            result += condition[0].__name__ + "(ARG0, " + str(condition[1]) + ")"
    
    return result

def parseListOfTreeToString(list_tree, original):
    result = "IfThenElse("
    
    k = 1
    count = 1
    for i in range(0, len(list_tree)):
        condition = list_tree[i]
        if not isinstance(condition[0], list):
            result += conditionToString(condition)
        else:
            temp_result = ""
            temp_result += "and_(" + conditionToString(condition[-2]) + ", " + conditionToString(condition[-1]) + ")"
            for j in range(3, len(condition)+1):
                temp_result = "and_(" + conditionToString(condition[-j]) + ", " + temp_result + ")"
            result += temp_result

        subtree_slice = original.searchSubtree(k)
        k = subtree_slice.stop
        result += ", '" + original[k].name + "', "
        k += 1
        #if original[k].ret == str:
        if i == len(list_tree) - 1:
            result += ", '" + original[k].name + "'"
        else:
            result += "IfThenElse("
            k += 1
            count += 1
    
    for i in range(count):
        result += ")"
    
    return result

def makeAllVariationsOfHeuristic(ind):
    index_of_statements = []
    list_of_variations = []
    for i in range(0, len(ind)):
        if ind[i].name == "IfThenElse":
            subtree_slice = ind.searchSubtree(i)
            index_of_statements.append(subtree_slice.start)
            
    index_of_statements.append(len(ind)-1)
    
    for x in range(0, len(index_of_statements)-1):
        #list_of_statements.append(ind[index_of_statements[x]:index_of_statements[x+1]])
        temp = ind[0:index_of_statements[x]]
        temp.extend(ind[index_of_statements[x+1]:len(ind)])
        list_of_variations.append(gp.PrimitiveTree.from_string(str(gp.PrimitiveTree(temp)), pset))
    
    return list_of_variations

def boardSample():
    result = []
    #Nothing - rank 0
    result.append([])
    #One Pair - rank 2
    result.append([Card(50, 'H'), Card(50, 'C'), Card(48, 'H'), Card(47, 'C'), Card(46, 'H')])
    #Two Pair - rank 3
    result.append([Card(50, 'H'), Card(50, 'C'), Card(60, 'H'), Card(60, 'C'), Card(46, 'H')])
    #Three of a Kind - rank 4
    result.append([Card(50, 'H'), Card(50, 'C'), Card(50, 'D'), Card(60, 'C'), Card(46, 'H')])
    #Straight - rank 5
    result.append([Card(50, 'H'), Card(49, 'C'), Card(48, 'H'), Card(47, 'C'), Card(46, 'H')])
    #Straight - rank 6
    result.append([Card(80, 'H'), Card(70, 'H'), Card(60, 'H'), Card(50, 'H'), Card(40, 'H')])
    #Full House - rank 7
    result.append([Card(50, 'H'), Card(50, 'C'), Card(50, 'H'), Card(40, 'C'), Card(40, 'H')])
    #Four of a Kind - rank 8
    result.append([Card(50, 'H'), Card(50, 'C'), Card(50, 'D'), Card(50, 'S'), Card(40, 'H')])
    #Straight Flush - rank 9
    result.append([Card(80, 'H'), Card(79, 'H'), Card(78, 'H'), Card(77, 'H'), Card(76, 'H')])
    #Royal Straight Flush - rank 10
    result.append([Card(14, 'H'), Card(13, 'H'), Card(12, 'H'), Card(11, 'H'), Card(10, 'H')])
    
    return result

def mapHandsToResults(ind, all_hands):
    result = {}
    sample_boards = boardSample()
    
    func = toolbox.compile(ind)
    for i in range(0, 35):
        result[i] = {}
        for j in range(1, 11):
            result[i][j] = {}
    for hand in all_hands:
        for i in range(0, 35):
            for j in range(1, 11):
                result[i][j][str(hand[0]) + ", " + str(hand[1])] = func(hand, i, sample_boards[j-1])
    
    return result

def checkIfDictionariesAreTheSame(dict1, dict2):
    for x in dict1:
        for y in dict1[x]:
            for k in dict1[x][y]:
                if dict1[x][y][k] != dict2[x][y][k]:
                    return False

    return True

def simplifyByRemovingStatements(ind, all_hands):
    all_variations = makeAllVariationsOfHeuristic(ind)
    
    original_result_mapping = mapHandsToResults(ind, all_hands)
    for variation in all_variations:
        var_result_mapping = mapHandsToResults(variation, all_hands)
        if checkIfDictionariesAreTheSame(original_result_mapping, var_result_mapping):
            return simplifyByRemovingStatements(variation, all_hands)
    
    return ind

def returnTreeDepth(ind):
    depth = 0
    for x in ind:
        if x.name == "IfThenElse":
            depth += 1
    
    return depth

def simplifyTree(tree, hands):
    conditions = []
    for i in range(0, len(tree)):
        if tree[i].name == "IfThenElse":
            subtree_slice = tree.searchSubtree(i)
            #if tree[subtree_slice.stop-1].ret == str and tree[subtree_slice.stop-2].ret == str and tree[subtree_slice.stop-1].name == tree[subtree_slice.stop-2].name:
            #    return False
        
            subtree_slice = tree.searchSubtree(i+1)
            conditions.append(tree[subtree_slice.start:subtree_slice.stop])
        
    conditions = parseAllConditions(conditions)
    #print conditions
    current_hands = set(hands)
    current_ranks = set(range(11))
    result = []
    changes = False
    for condition in conditions:
        hands_dict = {}
        ranks_dict = {}
        #print condition
        if isinstance(condition[0], list):
            #print condition
            for i in range(len(condition)):
                hands_dict[i] = set(handsThatMeetCondition(condition[i], current_hands))
                if "handValue" in condition[i][0].__name__:
                    ranks_dict[i] = set(ranksThatMeetCondition(condition[i], current_ranks))
            to_remove = set([])
            keys = hands_dict.keys()
            for i in range(0, len(keys)-1):
                handValue_i_flag = False
                if "totalPot" in condition[i][0].__name__:
                    continue
                elif "handValue" in condition[i][0].__name__:
                    handValue_i_flag = True
                for j in range(i+1, len(keys)):
                    if "totalPot" in condition[j][0].__name__:
                        continue
                    elif "handValue" in condition[j][0].__name__:
                        if not handValue_i_flag:
                            continue
                        else:
                            intersection = ranks_dict[i].intersection(ranks_dict[j])
                            length_of_intersection = len(intersection)
                            if length_of_intersection == len(ranks_dict[i]):
                                to_remove.add(j)
                            if length_of_intersection == len(ranks_dict[j]):
                                cond1 = condition[i]
                                cond2 = condition[j]
                                if not sameCondition(cond1, cond2):
                                    to_remove.add(i)                             
                    else:
                        if handValue_i_flag:
                            continue
                        intersection = hands_dict[i].intersection(hands_dict[j])
                        length_of_intersection = len(intersection)
                        if length_of_intersection == len(hands_dict[i]):
                            to_remove.add(j)
                        if length_of_intersection == len(hands_dict[j]):
                            cond1 = condition[i]
                            cond2 = condition[j]
                            if not sameCondition(cond1, cond2):
                                to_remove.add(i)

            if len(to_remove) > 0:
                new_condition = []
                for i in range(0, len(condition)):
                    if i not in to_remove:
                        new_condition.append(condition[i])
                
                if len(new_condition) == 1:
                    new_condition = new_condition[0]
                if len(new_condition) == 0:
                    new_condition = condition[0]
                changes = True

                result.append(list(new_condition))
            else:
                result.append(condition)
        else:
            result.append(condition)
    
    if not changes:
        return tree
    
    return gp.PrimitiveTree.from_string(parseListOfTreeToString(result, tree), pset)

all_hands = []
for i in range(2, 15):
    for j in range(i, 15):
        all_hands.append((Card(i, "D"), Card(j, "S")))
        if i != j:
            all_hands.append((Card(i, "D"), Card(j, "D")))

def isThereCopyOfIndividual(pop, ind):
    for p in pop:
        if primitiveTreeDistance(p, ind) == 0.0:
            return True
    return False

def makePopulation(n, individual_creation_function):
    population = []
    while len(population) < n:
        ind = individual_creation_function()
        ind = simplifyTree(ind, all_hands)
        
        if not isThereCopyOfIndividual(population, ind) and isTreeValid(ind, all_hands): #and depth == temp_depth:
            population.append(ind)
    
    return population

def individualForMutation(depth, pset, type_=None, parent_function=None):
    result = ""
    if type_ == bool:
        result = generateBoolOp()
    if type_ == int:
        if "totalPot" in parent_function:
            result = str(random.choice(possible_pot_ints))
        elif "handValue" in parent_function:
            result = str(random.choice(possible_rank_ints))
        else:
            result = str(random.choice(possible_ints))
    if type_ == str:
        result = random.choice(possible_strings)

    return gp.PrimitiveTree.from_string(result, pset)

def makeMutation(indv, chosen, removed_elements):
    parent_function = None
    parent_function_index = (indv.index(chosen))-2
    if parent_function_index > 0:
        #print str(indv)
        #print len(indv)
        #print parent_function_index
        parent_function = indv[parent_function_index].name
    new_gene = toolbox.heuristic_mut(depth=1, pset=pset, type_=chosen.ret, parent_function=parent_function)
    #if chosen.ret != str and chosen.ret != bool and chosen.ret != int:
    while (chosen.name == new_gene[0].name):
        new_gene = toolbox.heuristic_mut(depth=1, pset=pset, type_=chosen.ret, parent_function=parent_function)

    index_for_mutation = indv.index(chosen)

    temp = []
    if chosen.name == "and_":
        temp_indv = gp.PrimitiveTree.from_string(str(gp.PrimitiveTree(indv)), pset)
        subtree_slice = temp_indv.searchSubtree(index_for_mutation)
        temp = indv[:index_for_mutation] + new_gene + indv[subtree_slice.stop:]
        for temp_element in indv[subtree_slice.start:subtree_slice.stop]:
            removed_elements.add(temp_element)
    elif isinstance(chosen, gp.Terminal):
        temp = indv[:index_for_mutation] + new_gene + indv[index_for_mutation+1:]
    elif isinstance(chosen, gp.Primitive):
        temp_indv = gp.PrimitiveTree.from_string(str(gp.PrimitiveTree(indv)), pset)
        subtree_slice = temp_indv.searchSubtree(index_for_mutation)
        temp = indv[:index_for_mutation] + new_gene + indv[subtree_slice.stop:]
        for temp_element in indv[subtree_slice.start:subtree_slice.stop]:
            removed_elements.add(temp_element)
    
    return list(temp)

def mutateExpressionTree(indv, mut_prob, pset):
    mutable_elements = set([])
    removed_elements = set([])
    
    for expr in indv:
        if expr.name != 'IfThenElse' and expr.name != "ARG0" and expr.name != "ARG1" and expr.name != "ARG2":
            mutable_elements.add(expr)
    
    count = 0
    for element in mutable_elements:
        if element not in removed_elements:
            removed_elements.add(element)
            n = random.uniform(0, 1)
            #print n
            if n <= mut_prob:
                count += 1
                chosen = element
                
                #print (element, index)
                indv = makeMutation(indv, chosen, removed_elements)
    
    if count == 0:
        chosen = random.choice(list(mutable_elements))

        indv = makeMutation(indv, chosen, removed_elements)        
    
    return gp.PrimitiveTree.from_string(str(gp.PrimitiveTree(indv)), pset)

def mateIndividuals(ind1, ind2, depth, pset):
    r = random.randint(1,depth) # which level to crossover in
    n = random.randint(0,2) # which child to crossover
    
    index_of_ind1_tree = 0
    index_of_ind2_tree = 0
    
    counter = 1
    for i in range(0, len(ind1)):
        if ind1[i].arity == 3 and "IfThenElse" in ind1[i].name:
            if counter == r:
                index_of_ind1_tree = i
                break
            counter += 1

    counter = 1
    for i in range(0, len(ind2)):
        if ind2[i].arity == 3 and "IfThenElse" in ind2[i].name:
            if counter == r:
                index_of_ind2_tree = i
                break
            counter += 1
    
    subtree_slice_ind1 = ind1.searchSubtree(index_of_ind1_tree+1)
    for i in range(0, n):
        subtree_slice_ind1 = ind1.searchSubtree(subtree_slice_ind1.stop)

    subtree_slice_ind2 = ind2.searchSubtree(index_of_ind2_tree+1)
    for i in range(0, n):
        subtree_slice_ind2 = ind2.searchSubtree(subtree_slice_ind2.stop)

    new_ind1 = ind1[0:subtree_slice_ind1.start] + ind2[subtree_slice_ind2.start:subtree_slice_ind2.stop] + ind1[subtree_slice_ind1.stop:]
    new_ind2 = ind2[0:subtree_slice_ind2.start] + ind1[subtree_slice_ind1.start:subtree_slice_ind1.stop] + ind2[subtree_slice_ind2.stop:]
    
    return (gp.PrimitiveTree.from_string(str(gp.PrimitiveTree(new_ind1)), pset), gp.PrimitiveTree.from_string(str(gp.PrimitiveTree(new_ind2)), pset))

tree_depth = DEFAULT_TREE_DEPTH

toolbox = base.Toolbox()
toolbox.register("compile", gp.compile, pset=pset)
toolbox.register("heuristic", generateIndividual, depth=tree_depth, pset=pset)
toolbox.register("individual", tools.initIterate, creator.GameHeuristicIndividualMax, toolbox.heuristic)
toolbox.register("population", makePopulation, individual_creation_function=toolbox.individual)
toolbox.register("select", tools.selBest)
toolbox.register("mate", mateIndividuals, depth=tree_depth, pset=pset)
toolbox.register("heuristic_mut", individualForMutation, depth=tree_depth)
toolbox.register("mutate", mutateExpressionTree, pset=pset)

toolbox.decorate("mate", gp.staticLimit(key=operator.attrgetter("height"), max_value=tree_depth)) #Depth to allow ANDs

def primitiveTreeDistance(ind1, ind2):
    result = 0.0
    
    min_length = min(len(ind1), len(ind2))
    factor = 1.0 / float(min_length)
    for i in range(0, min_length):
        if ind1[i].name != ind2[i].name:
            result += factor

    if len(ind1) != len(ind2):
        result += factor
        
    return result if result <= 1.0 else 1.0

def findFitness(population):
    pop = population
    
    pool = mp.Pool(mp.cpu_count())
    temp = []
    for i in range(0, len(pop)):
        temp.append(HeuristicAI())
        temp[i].setHeuristic(marshal.dumps(toolbox.compile(pop[i]).func_code))
    fitness_list = pool.map(toolbox.evaluate, temp)
    pool.terminate()
    
    for i in range(0, len(fitness_list)):
        pop[i].fitness = fitness_list[i]
    
    return pop

def readjustFitnessByDistance(population):
    pop = population
    best = toolbox.select(pop, 1)[0]
    weight = 10000.0
    
    for ind in pop:
        if ind != best:
            dist = 1.0 - primitiveTreeDistance(best, ind)
            ind.fitness = (ind.fitness[0] - (weight * dist), )

def mateBest(best):
    new_indv = []
    
    for i in range(0, len(best)-1):
        for j in range(i+1, len(best)):
            children = toolbox.mate(gp.PrimitiveTree.from_string(str(best[i]), pset), gp.PrimitiveTree.from_string(str(best[j]), pset))
            children = [simplifyTree(children[0], all_hands), simplifyTree(children[1], all_hands)]
            new_indv.extend(children)

    return new_indv

def mateElite(elite, size_of_children=60):
    children = []
    
    pairings = tuple(itertools.combinations(elite, 2))
    selected = random.sample(pairings, int(float(size_of_children) / 2.0))
    
    for i in range(0, len(selected)):
        temp = toolbox.mate(gp.PrimitiveTree.from_string(str(selected[i][0]), pset), gp.PrimitiveTree.from_string(str(selected[i][1]), pset))
        temp = [simplifyTree(temp[0], all_hands), simplifyTree(temp[1], all_hands)]
        children.extend(temp)

    return children
        
def mutateChildren(children, mut_prob, pop):
    mut_children = []
    
    for child in children:
        while isThereCopyOfIndividual(pop + mut_children, child) or not isTreeValid(child, all_hands):
            child = simplifyTree(toolbox.mutate(child, mut_prob, pset=pset), all_hands)
        
        mut_children.append(child)

    return mut_children

def createMutationIndv(indv, mut_prob, pop):
    mutation = gp.PrimitiveTree.from_string(str(indv), pset)
    mut_indv = toolbox.mutate(mutation, mut_prob, pset=pset)
    
    while isThereCopyOfIndividual(pop, mut_indv) or not isTreeValid(mut_indv, all_hands):
        mut_indv = simplifyTree(toolbox.mutate(mutation, mut_prob, pset=pset), all_hands)
    
    return mut_indv

def generation(population, mut_prob, children_mut_prob, k):
    pop = population
    pop_size = len(pop)

    elite_size = int(0.5 * pop_size)
    elite = toolbox.select(pop, elite_size)
    elite_mutations = []
    for i in range(0, int(len(elite) * 0.4)):
        elite_mutations.append(simplifyTree(createMutationIndv(elite[i], mut_prob, elite + elite_mutations), all_hands))

    children = mateElite(elite, int(0.3 * pop_size))
    children = mutateChildren(children, children_mut_prob, elite + elite_mutations)

    pop = elite + elite_mutations + children
    pop = findFitness(pop)
    
    return pop

def gen0(population):
    pop = population
    pop = findFitness(pop)
    
    return pop

def createLogFile(filename, start_string):
    f = open(filename, 'w')
    f.write(start_string)
    f.close()

def logToFile(filename, input_string):
    f = open(filename, 'a')
    f.write(input_string)
    f.close()
    
def findComplexity(ind):
    complexity = 0
    
    for expr in ind:
        if expr.name != "IfThenElse" and expr.name != "and_":
            if isinstance(expr, gp.Terminal):
                if expr.name == "raise" or expr.name == "fold" or expr.name == "check":
                    complexity += 1
            else:
                complexity += 1
    
    return complexity