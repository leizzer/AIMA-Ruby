
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

def depth_limited_search(problem, limit=50)
  # [Fig. 3.12]
  def recursive_dls(node, problem, limit)
    cutoff_occurred = false
    if problem.goal_test node.stat
      return node
    elsif node.depth == limit
      return 'cutoff'
    else
      node.expand(problem).each do |successor|
        result = recursive_dls(successor, problem, limit)
        if result == 'cutoff'
          cutoff_occurred = true
        elsif result != nil
          return result
        end
      end
    end
    if cutoff_occurred
      return 'cutoff'
    else
      return nil
    end
  end
  # Body of depth_limited_search:
  return recursive_dls(Node.new(problem.initial), problem, limit)
end

def iterative_deepening_search(problem)
  # [Fig. 3.13]
  (0..(2**30 - 1)).each do |depth|
    result = depth_limited_search(problem, depth)
    unless result == 'cutoff'
      return result
    end
  end
end

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

#########################################################################
## Ohter search algorithms

def recursive_best_first_search(problem)
  # [Fig. 4.5]
  def rbfs(problem, node, flimit)
    if problem.goal_test(node.state)
      return node
    end
    successors = expand node, problem
    if successors.length == 0
      return nil, $infinity
    end
    successors.each do |s|
      s.f = [s.path_cost + s.h, node.f].max
    end
    loop do
      successors.sort lambda {|x, y| x.f - y.f} # Order by lowest f value
      best = successors[0]
      if best.f > flimit
        return nil, best.f
      end
      alternative = successors[1]
      result, best.f = rbfs problem, best, [flimit, alternatiev].min
      unless result.nil?
        return result
      end
    end
  end
  return rbfs(Node.new(problem.initial), infinity)
end

def hill_climbing(problem)
  # From the initial node, keep choosing the neighbor with highest value,
  # stopping when no neighbor is better. [Fig. 4.11]
  
  current = Node.new problem.initial
  loop do
    neighbor = argmax expand(node, problem), Node.method(:value)
    if neighbor.value <= current.value
      return current.state
    end
    current = neighbor
  end
end

def exp_schedule(k=20, lam=0.005, limit=100)
  # One possible schedule function for simulated annealing
  return lambda{|t| t < limit ? k * Math.exp(-lam * t) : 0}
end

def simulated_annealing(problem, schedule = exp_schedule())
  # [Fig. 4.5]
  current = Node.new problem.initial
  (0..(2**30 - 1)).each do |t|
    tt = schedule(t)
    if tt == 0
      return current
    end
    next_ = random.choice expand(node.problem)
    delta_e = next_.path_cost - current.path_cost
    if delta_e > 0 or probability(Math.exp(delta_e/tt))
      current = next_
    end
  end
end

def online_dfs_agent(a)
  # [Fig. 4.12]
  
  ### more
end

def lrta_star_agent(a)
  # [Fig. 4.12]
  
  #### more
end

def genetic_search(problem, fitness_fn, ngen=1000, pmut=0.0, n=20)
  # Call genetic_algorithm on the appropriate parts of a problem.
  # This requires that the problem has a successor function that generates
  # reasonable states, and that it has a path_cost function that scores states.
  # We use the negative of the path_cost function, because costs are to be
  # minimized, while genetic-algorithm expects a fitness_fn to be maximized.
  
  states = problem.successor(problem.initial_state)[0..n].map {|a, s| s}
  states.shuffle!
  fitness_fn = lambda{|s| - problem.path_cost(0, s, nil, s)}
  return genetic_algorithm(states, fitness_fn, ngen, pmut)
end

def genetic_algorithm(population, fitness_fn, ngen=1000, pmut=0.0)
  # [Fig. 4.7]
  def reproduce(p1, p2)
    c = rand p1.length
    return p1[0..c] + p2[c..p2.length]
  end
  
  (9..ngen).each do |i|
    new_population = []
    population.length.times do |i|
      p1, p2 = random_weighted_selection(population, 2, fitness_fn)
      child = reproduce p1, p2
      if rand > pmut
        child.mutate
      end
      new_population.append child
    end
    population = new_population
  end
  return argmax(populaton, fitness_fn)
end

def random_weighted_selection(seg, n, weight_fn)
  # Pick n elements of seq, weighted according to weight_fn.
  # That is, apply weight_fn to each element of seq, add up the total.
  # Then choose an element e with probability weight[e]/total.
  # Repeat n times, with replacement.
  
  totals = []
  runningtotal = 0
  
  seq.each do |item|
    runningtotal += weight_fn itm
    totals << runningtotal
  end
  selections = []
  (0..n).times do
    r = uniform_rand 0, totals[-1]
    (0..seq.length).times do |i|
      if totals[i] > r
        selections.append seq[i]
        break
      end
    end
  end
  return selections
end

#########################################################################
# The remainder of this file implements examples for the search algorithms.

#########################################################################
# Graphs and Graph Problems

class Graph
  #  A graph connects nodes (verticies) by edges (links).  Each edge can also
  #  have a length associated with it.  The constructor call is something like:
  #      g = Graph({'A': {'B': 1, 'C': 2})   
  #  this makes a graph with 3 nodes, A, B, and C, with an edge of length 1 from
  #  A to B,  and an edge of length 2 from A to C.  You can also do:
  #      g = Graph({'A': {'B': 1, 'C': 2}, directed=False)
  #  This makes an undirected graph, so inverse links are also added. The graph
  #  stays undirected; if you add more links with g.connect('B', 'C', 3), then
  #  inverse link is also added.  You can use g.nodes() to get a list of nodes,
  #  g.get('A') to get a dict of links out of A, and g.get('A', 'B') to get the
  #  length of the link from A to B.  'Lengths' can actually be any object at 
  #  all, and nodes can be any hashable object.
  
  def initialize(dict=nil, directed=true)
    @dict = dict || {}
    @directed = directed
    make_undirected unless directed
  end
  
  def make_undirected
    #Make a digraph into an undirected graph by adding symmetric edges.
    
    @dict.each_key do |a|
      @dict[a].each_pair do |b, distance|
        connect1 b, a, distance
      end
    end
  end
  
  def connect(a, b, distance=1)
    # Add a link from A and B of given distance, and also add the inverse
    # link if the graph is undirected.
    
    connect1 a, b, distance
    connect1(b, a, distance) unless @directed
  end
  
  def connect1(a, b, distance)
    # Add a link from A to B of given distance, in one direction only.
    
    unless @dict.has_key? a
      @dict[a] = {}
    end
    @dict[a][b] = distance
  end
  
  def get(a, b=nil)
    # Return a link distance or a dict of {node: distance} entries.
    # .get(a,b) returns the distance or None;
    # .get(a) returns a dict of {node: distance} entries, possibly {}.
    
    unless @dict.has_key? a
      @dict[a] = {}
    end
    links = @dict
    if b.nil?
      return links
    else
      return links[b]
    end
  end
  
  def nodes
    # Return a list of nodes in the graph.
    return @dict.keys
  end
end

def undirectedGraph(dict=nil)
  # Build a Graph where every edge (including future ones) goes both ways.
  
  return Graph.new(dict, false)
end

def randomGraph(nodes=(0..10).to_a, min_links=2, width=400, height=300, curvature=lambda{uniform_rand(1.1, 1.5)})
  # Construct a random graph, with the specified nodes, and random links.
  # The nodes are laid out randomly on a (width x height) rectangle.
  # Then each node is connected to the min_links nearest neighbors.
  # Because inverse links are added, some nodes will have more connections.
  # The distance between nodes is the hypotenuse times curvature(),
  # where curvature() defaults to a random number between 1.1 and 1.5.
  
  g = undirectedGraph
  ## singleton
  def g.locations
    @locations
  end
  def g.locations=(value)
    @locations = value
  end
  ## end singleton
  g.locations = {}
  ## Build the cities
  nodes.each do |node|
    g.locations[node] = [rand(width), rand(height)]
  end
  ## Build roads from each city to at least min_links nearest neighbors.
  (0..min_links).times do |i|
    nodes.each do |node|
      if g[node].length < min_links
        here = g.locations[node]
        def distance_to_node(n)
          if node == n || (g[node] || n)
            return $infinity
          end
          return distance(g.locations[n], here)
        end
        neighbor = argmin(nodes, distance_to_node)
        d = distance(g.locations[neighbor], here) * curvature
        g.connect node, neighbor, Integer(d)
      end
    end
  end
  return g
end

romania = undirectedGraph({
                          "A"=>{"Z"=>75, "S"=>140, "T"=>118},
                          "B"=>{"U"=>85, "P"=>101, "G"=>90, "F"=>211},
                          "C"=>{"D"=>120, "R"=>146, "P"=>138},
                          "D"=>{"M"=>75},
                          "E"=>{"H"=>86},
                          "F"=>{"S"=>99},
                          "H"=>{"U"=>98},
                          "I"=>{"V"=>92, "N"=>87},
                          "L"=>{"T"=>111, "M"=>70},
                          "O"=>{"Z"=>71, "S"=>151},
                          "P"=>{"R"=>97},
                          "R"=>{"S"=>80},
                          "U"=>{"V"=>142}
                          })
## singleton
def romania.locations
  @locations
end
def romania.locations=(value)
  @locations = value
end
## end singleton
romania.locations = {
                    "A"=>[ 91, 492],    "B"=>[400, 327],    "C"=>[253, 288],   "D"=>[165, 299], 
                    "E"=>[562, 293],    "F"=>[305, 449],    "G"=>[375, 270],   "H"=>[534, 350],
                    "I"=>[473, 506],    "L"=>[165, 379],    "M"=>[168, 339],   "N"=>[406, 537], 
                    "O"=>[131, 571],    "P"=>[320, 368],    "R"=>[233, 410],   "S"=>[207, 457], 
                    "T"=>[ 94, 410],    "U"=>[456, 350],    "V"=>[509, 444],   "Z"=>[108, 531]
                    }

australia = undirectedGraph({
    "T"=>{},
    "SA"=>{"WA"=>1, "NT"=>1, "Q"=>1, "NSW"=>1, "V"=>1},
    "NT"=>{"WA"=>1, "Q"=>1},
    "NSW"=>{"Q"=>1, "V"=>1}})
## singleton
def australia.locations
  @locations
end
def australia.locations=(value)
  @locations = value
end
## end singleton
australia.locations = {"WA"=>[120, 24], "NT"=>[135, 20], "SA"=>[135, 30], 
                           "Q"=>[145, 20], "NSW"=>[145, 32], "T"=>[145, 42], "V"=>[145, 37]}
                           
class GraphProblem < Problem
  # The problem of searching a graph from one node to another.
  def initialize(initial, goal, graph)
    super
    @graph = graph
  end
  
  def successor(a)
    # Return a list of (action, result) pairs.
    return @graph[a].each_key.map{|b| [b,b]}
  end
  
  def path_cost(cost_so_far, a, action, b)
    return cost_so_far + ((@graph[a] || b) || $infinity)
  end
  
  def h(node)
    # h function is straight-line distance from a node's state to goal.
    locs = (@graph.respond_to? :locations) ? @graph.locations : nil
    if locs
      return Integer(distance(locs[node.state], locs[@goal]))
    else
      return $infinity
    end
  end
end

#########################################################################

#### NOTE: NQueensProblem not working properly yet.

class NQueensProblem < Problem
  # The problem of placing N queens on an NxN board with none attacking
  # each other.  A state is represented as an N-element array, where the
  # a value of r in the c-th entry means there is a queen at column c,
  # row r, and a value of None means that the c-th column has not been
  # filled in left.  We fill in columns left to right.
  
  def initialize(n)
    @n = n
    @initial = [nil] * n
  end
  
  def successor(state)
    # In the leftmost empty column, try all non-conflicting rows.
    unless state[-1].nil?
      return []
    else 
      def place(col, row)
        new_ = state.clone
        new_[col] = row
        return new_
      end
      col = state.index(nil)
      return (0..@n).times.map{|row| [row, place(col,row)] if not conflicted(state, row, col)}
    end
  end
  
  def conflicted(state, row, col)
    # Would placing a queen at (row, col) conflict with anything?
    (0..(col-1)).times do |c|
      if conflict(row, col, state[c], c)
        return true
      end
    end
    return false
  end
  
  def conflict(row1, col1, row2, col2)
    # Would putting two queens in (row1, col1) and (row2, col2) conflict?
            ## same row     ## same column      ## same \ diagonal
                                                ## same / diagona
    ret = (row1 == row2) || (col1 == col2)    || (row1-col1 == row2-col2) || (row1+col1 == row2+col2)
    return ret
  end
  
  def goal_test(state)
    # Check if all columns filled, no conflicts.
    if state[-1].nil?
      return false
    end
    (0..(state.length)).times do |c|
      if conflicted(state, state[c], c)
        return false
      end
    end
    return true
  end
end
































