require 'search'

#################################################################################
##                     This is an example that works!                          ##
##-----------------------------------------------------------------------------##
##                                                                             ##
##  Missionaries and Cannibals Problem                                         ##
##                                                                             ##
##                                                                             ##
## In the missionaries and cannibals problem, three missionaries and three     ##
## cannibals must cross a river using a boat which can carry at most two       ##
## people, under the constraint that, for both banks, if there are             ##
## missionaries present on the bank, they cannot be outnumbered by cannibals   ##
## (if they were, the cannibals would eat the missionaries.)                   ##
## The boat cannot cross the river by itself with no people on board.          ##
##                                                                             ##
#################################################################################

#Initial State [misioneros_izq, canivales_izq, misioneros_der, misioneros_der, posicion de la balsa]
INITIAL_STATE = [3, 3, 0, 0, :i]
OBJETIVE = [0, 0, 3, 3, :d]

ACTIONS = [[1, 0], [0, 1], [2, 0], [0, 2], [1, 1]]

class P_Misioneros < Problem
  def successor(state)
    return ACTIONS.collect{ |act| 
                            if valid_state?(sta = move(state, act))
                              [act, sta]
                            end
                          }.compact
  end
  
  def goal_test(state)
    return state == OBJETIVE
  end
  
  def move(state, action_array)
    sr = state[4] == :i ? -1 : 1
    return [state[0] + action_array[0] * sr,
            state[1] + action_array[1] * sr,
    
            state[2] - action_array[0] * sr,
            state[3] - action_array[1] * sr,
            
            state[4] == :i ? :d : :i]
  end
  
  def valid_state?(state)
    (state[0] >= state[1] || state[0] == 0) && (state[2] >= state[3] || state[2] == 0)
  end
end

#EJECUTION
pp = P_Misioneros.new INITIAL_STATE
puts breadth_first_tree_search(pp)