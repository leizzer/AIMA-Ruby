
# Implement Agents and Environments (Chapters 1-2).
# 
# The class hierarchies are as follows:
# 
# Object ## A physical object that can exist in an environment
#     Agent
#         Wumpus
#         RandomAgent
#         ReflexVacuumAgent
#         ...
#     Dirt
#     Wall
#     ...
#     
# Environment ## An environment holds objects, runs simulations
#     XYEnvironment
#         VacuumEnvironment
#         WumpusEnvironment
# 
# EnvFrame ## A graphical representation of the Environment

=begin
## python stuff ##
from utils import *
import random, copy
=end

#########################################################################

class E_Object
  #  This represents any physical object that can appear in an Environment.
  #  You subclass Object to get the objects you want.  Each object can have a
  #  .__name__  slot (used for output only).
  def to_s
    "<#{@name}:#{self.class}>" if self.respond_to? :name
  end
  
  def is_alive?
    # Objects that are 'alive' should return true.
    @alive if self.respond_to? :alive
  end
  
  def display(canvas, x, y, width, height)
    # Display an image of this Object on the canvas.
  end
end

class Agent < E_Object
  # An Agent is a subclass of Object with one required slot,
  # .program, which should hold a function that takes one argument, the
  # percept, and returns an action. (What counts as a percept or action
  # will depend on the specific environment in which the agent exists.) 
  # Note that 'program' is a slot, not a method.  If it were a method,
  # then the program could 'cheat' and look at aspects of the agent.
  # It's not supposed to do that: the program can only look at the
  # percepts.  An agent program that needs a model of the world (and of
  # the agent itself) will have to build and maintain its own model.
  # There is an optional slots, .performance, which is a number giving
  # the performance measure of the agent in its environment.
=begin  
  attr_accessor :program
=end
  
  def initialize
    def program(percept)
      print "Percept=#{percept}; action? "
      gets.strip!
    end
=begin    
   @program = method :program
=end ## <<<<--- I dont use it
    @alive = true
  end
end
=begin
def traceAgent(agent)
    # Wrap the agent's program to print its input and output. This will let
    # you see what the agent is doing in the environment.
    
    $agent = agent
    $old_program = agent.method :program
    def new_program(percept)
      action = $old_program.call(percept)
      puts "#{$agent} perceives #{percept} and does #{action}"
      return action
    end
    
    agent.program = method :new_program
    return agent
end
=end ## <<<<----- Changend for something more ruby

def traceAgent(agent)
    # Wrap the agent's program to print its input and output. This will let
    # you see what the agent is doing in the environment.

    agent.instance_eval do
      def program(percept)
        action = super
        puts "#{self} perceives #{percept} and does #{action}"
        return action
      end
    end
    return agent
end

#########################################################################

=begin
class TableDrivenAgent < Agent
    # This agent selects an action based on the percept sequence.
    # It is practical only for tiny domains.
    # To customize it you provide a table to the constructor. [Fig. 2.7]
    
    def initialize(table)
      # Supply as table a dictionary of all {percept_sequence:action} pairs.
      #  ## The agent program could in principle be a function, but because
      #  ## it needs to store state, we make it a callable instance of a class.
      
      super
      
      $table = table
      $percepts = []
      def program(percept)
        $percepts << percept
        action = $table[$percepts]
        return action
      end
      
      @program = method :program
    end
end
=end ## <<<<----- Changend for something more ruby

class TableDrivenAgent < Agent
    # This agent selects an action based on the percept sequence.
    # It is practical only for tiny domains.
    # To customize it you provide a table to the constructor. [Fig. 2.7]
    
    def initialize(table)
      # Supply as table a dictionary of all {percept_sequence:action} pairs.
      #  ## The agent program could in principle be a function, but because
      #  ## it needs to store state, we make it a callable instance of a class.
      
      @table = table
      @percepts = []
      def program(percept)
        @percepts << percept
        action = @table[@percepts]
        return action
      end
=begin      
      @program = method :program
=end ## <<<<---- I don't use it
      @alive = true
    end
end

=begin
class RandomAgent < Agent
  # An agent that chooses an action at random, ignoring all percepts.
  
  def initialize(actions)
    super
    
    @actions = actions
    @program = lambda {|percept| @actions[rand(@actions.length)]}
  end
end
=end ## <<<--- Doesnt work

class RandomAgent < Agent
  # An agent that chooses an action at random, ignoring all percepts.

  def initialize(actions)
    @actions = actions
    def program(percept)
      @actions[rand(@actions.length)]
    end

    @alive = true
  end
end


#########################################################################

 # loc_A, loc_B = [0, 0], [1, 0] # The two locations for the Vacuum world
class ReflexVacuumAgent < Agent
  # A reflex agent for the two-state vacuum environment. [Fig. 2.8]
  
  def initialize
    super
    
    def program(hash={})
      loc_A, loc_B = [0, 0], [1, 0] # The two locations for the Vacuum world
      if hash[:status] == 'Dirty'
        'Suck'
      elsif hash[:location] == loc_A
        'Right'
      elsif hash[:location] == loc_B
        'Left'
      end
    end
=begin
    @program = method :program
=end ## <<--- I dont use it!
  end
end

def randomVacuumAgent
  # Randomly choose one of the actions from the vaccum environment.
  
  RandomAgent.new ['Right', 'Left', 'Suck', 'NoOp']
end

def tableDrivenVacuumAgent
  # [Fig. 2.3]
  loc_A, loc_B = [0, 0], [1, 0] # The two locations for the Vacuum world
  table = {
            [[loc_A, 'Clean'],] => 'Right',
            [[loc_A, 'Dirty'],] => 'Suck',
            [[loc_B, 'Clean'],] => 'Left',
            [[loc_B, 'Dirty'],] => 'Suck',
            [[loc_A, 'Clean'], [loc_A, 'Clean']] => 'Right',
            [[loc_A, 'Clean'], [loc_A, 'Dirty']] => 'Suck',
            # ...
            [[loc_A, 'Clean'], [loc_A, 'Clean'], [loc_A, 'Clean']] => 'Right',
            [[loc_A, 'Clean'], [loc_A, 'Clean'], [loc_A, 'Dirty']] => 'Suck',
            # ...
          }
  return TableDrivenAgent.new table
end

class ModelBasedVacuumAgent < Agent
  # An agent that keeps track of what locations are clean or dirty.
  
  def initialize
    super
    
    @loc_A, @loc_B = [0, 0], [1, 0] # The two locations for the Vacuum world
    @model = {@loc_A => nil, @loc_B => nil}
    def program(hash={})
      # Same as ReflexVacuumAgent, except if everything is clean, do NoOp
      
      @model[hash[:location]] = hash[:status] ## Update the model here
      if @model[@loc_A] == @model[@loc_B] && @model[@loc_A] == 'Clean'
        'NoOp'
      elsif hash[:status] == 'Dirty'
        'Suck'
      elsif hash[:location] == @loc_A
        'Right'
      elsif hash[:location] == @loc_B
        'Left'
      end
    end
  end
end






















