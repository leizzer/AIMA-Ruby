
# Search (Chapters 3-4)
# 
# The way to use this code is to subclass Problem to create a class of problems,
# then create problem instances and solve them with calls to the various search
# functions.

=begin
## python stuff ##
from __future__ import generators
from utils import *
import agents
import math, random, sys, time, bisect, string
=end

require 'agents.rb'
require 'utils.rb'

#########################################################################

class Problem
  # The abstract class for a formal problem.  You should subclass this and
  # implement the method successor, and possibly __init__, goal_test, and
  # path_cost. Then you will create instances of your subclass and solve them
  # with the various search functions.
  attr_accessor :initial, :goal

  def initialize(initial, goal=nil)
    # The constructor specifies the initial state, and possibly a goal
    # state, if there is a unique goal.  Your subclass's constructor can add
    # other arguments.
    
    @initial = initial
    @goal = goal
  end
  
  def successor(state)
    # Given a state, return a sequence of (action, state) pairs reachable
    # from this state. If there are many successors, consider an iterator
    # that yields the successors one at a time, rather than building them
    # all at once. Iterators will work fine within the framework.
  end
  
  def goal_test(state)
    # Return True if the state is a goal. The default method compares the
    # state to self.goal, as specified in the constructor. Implement this
    # method if checking against a single self.goal is not enough.
    
    state == @goal
  end
  
  def path_cost(c, state1, action, state2)
    # Return the cost of a solution path that arrives at state2 from
    # state1 via action, assuming cost c to get up to state1. If the problem
    # is such that the path doesn't matter, this function will only look at
    # state2.  If the path does matter, it will consider c and maybe state1
    # and action. The default method costs 1 for every step in the path.    
    
    c + 1
  end
  
  def value
    # For optimization problems, each state has a value.  Hill-climbing
    # and related algorithms try to maximize this value.
  end
end

#########################################################################

class Node
  # A node in a search tree. Contains a pointer to the parent (the node
  # that this is a successor of) and to the actual state for this node. Note
  # that if a state is arrived at by two paths, then there are two nodes with
  # the same state.  Also includes the action that got us to this state, and
  # the total path_cost (also known as g) to reach the node.  Other functions
  # may add an f and h value; see best_first_graph_search and astar_search for
  # an explanation of how the f and h values are handled. You will not need to
  # subclass this class.

  attr_reader :state, :parent, :action, :path_cost, :depth
   
  def initialize(state, parent=nil, action=nil, path_cost=0)
    # Create a search tree Node, derived from a parent by an action.
    
    @state = state
    @parent = parent
    @action = action
    @path_cost = path_cost
    @depth = 0
    
    if parent
      @depth = parent.depth + 1
    end      
  end
  
  def to_s
    "<Node #{@state}>"
  end
  
  def path
    # Create a list of nodes from the root to this node.
    x, result = self, [self]
    
    while x.parent
      result << x.parent
      x = x.parent
    end
    
    return result
  end
  
  
  def expand(problem)
    # Return a list of nodes reachable from this node. [Fig. 3.8]
    list = []
    problem.successor(self.state).each do |act, next_|
      list << Node.new(next_, self, act, problem.path_cost(self.path_cost, self.state, act, next_))
    end
    return list
  end
end

#########################################################################


class SimpleProblemSolvingAgent < Agent
  # Abstract framework for problem-solving agent. [Fig. 3.1]
  def initialize
    super
    state = []
    seq = []

    def program(percept)
      state = self.update_state(state, percept)
      
      if not seq:
        goal = self.formulate_goal(state)
        problem = self.formulate_problem(state, goal)
        seq = self.search(problem)
      end
      
      action = seq[0]
      seq[0,1] = []
      return action
    end
  end
end

#########################################################################
## Uninformed Search algorithms

def tree_search(problem, fringe)
    # Search through the successors of a problem to find a goal.
    # The argument fringe should be an empty queue.
    # Don't worry about repeated paths to a state. [Fig. 3.8]
    fringe << Node.new(problem.initial)  
    while not fringe.empty?
      node = fringe.pop
      if problem.goal_test node.state
        return node
      end
      fringe.concat node.expand(problem)
    end
    return nil
end

def breadth_first_tree_search(problem)
  # Search the shallowest nodes in the search tree first. [p 74]
  return tree_search(problem, FIFOQueue.new)
end

def depth_first_tree_search(problem)
  # Search the deepest nodes in the search tree first. [p 74]
  return tree_search(problem, stack)
end

def graph_search(problem, fringe)
  # Search through the successors of a problem to find a goal.
  # The argument fringe should be an empty queue.
  # If two paths reach a state, only use the best one. [Fig. 3.18]
  
  closed = {}
  fringe << Node.new(problem.initial)
  while not fringe.empty?
    node = fringe.pop
    if problem.goal_test node.state
      return node
    end
    
    unless closed.include? node.state
      closed[node.state] = true
      fringe.concat node.expand(problem)
    end
  end
  
  return nil
end

def breadth_first_graph_search(problem)
    # Search the shallowest nodes in the search tree first. [p 74]
    return graph_search(problem, FIFOQueue.new)
end
    
def depth_first_graph_search(problem)
    # Search the deepest nodes in the search tree first. [p 74]
    return graph_search(problem, stack)
end

=begin
  more stuff here
=end

#########################################################################
# Informed (Heuristic) Search

def best_first_graph_search(problem, f)
  # Search the nodes with the lowest f scores first.
  # You specify the function f(node) that you want to minimize; for example,
  # if f is a heuristic estimate to the goal, then we have greedy best
  # first search; if f is node.depth then we have depth-first search.
  # There is a subtlety: the line "f = memoize(f, 'f')" means that the f
  # values will be cached on the nodes as they are computed. So after doing
  # a best first search you can examine the f values of the path returned.
  #f = memoize(f, '@f')
  return graph_search(problem, PriorityQueue.new(:min, f))
end
  
greedy_best_first_graph_search = method :best_first_graph_search
  # Greedy best-first search is accomplished by specifying f(n) = h(n).
  
def astar_search(problem, h=nil)
  # A* search is best-first graph search with f(n) = g(n)+h(n).
  # You need to specify the h function when you call astar_search.
  # Uses the pathmax trick: f(n) = max(f(n), g(n)+h(n)).
  h = h or problem.method(:h)
  
  f = proc{|n| [(n.respond_to?(:f) ? n.method(:f) : -$infinity), n.path_cost + h.call(n)].max}
  
  return best_first_graph_search(problem, f)
end