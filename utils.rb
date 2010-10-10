#______________________________________________________________________________
# Functions on sequences of numbers
# NOTE: these take the sequence argument first, like min and max,
# and like standard math notation: \sigma (i = 1..n) fn(i)
# A lot of programing is finding the best value that satisfies some condition;
# so there are three versions of argmin/argmax, depending on what you want to
# do with ties: return the first one, return them all, or pick at random.


def argmin(seq, fn)
  #  Return an element with lowest fn(seq[i]) score; tie goes to first one.
  
  best = seq[0]
  best_score = fn.call best
  seq.each do |x|
    x_score = fn.call x
    if x_score < best_score
      best, best_score = x, x_score
    end
  end
  return best
end

def argmin_lsit(seq, fn)
  # Return a list of elements of seq[i] with the lowest fn(seq[i]) scores.
  
  best_score, best = fn.call(seq[0]), []
  seq.each do |x|
    x_score = fn.call x
    if x_score < best_score
      best, best_score = [x], [x_score]
    elsif x_score == best_score
      best << x
    end
  end
  return best
end

def argmin_random_tie(seq, fn)
  # Return an element with lowest fn(seq[i]) score; break ties at random.
  # Thus, for all s,f: argmin_random_tie(s, f) in argmin_list(s, f)
  
  best_score = fn.call seq[0]
  n = 0
  seq.each do |x|
    x_score = fn.call x
    if x_score < best_score
      best, best_score = x, x_score
      n = 1
    elsif x_score == best_score
      n += 1
      if rand(n) == 0
        best = x
      end
    end
  end
  return best
end

def argmax(seq, fn)
  # Return an element with highest fn(seq[i]) score; tie goes to first one.
  
  return argmin(seq, lamda{|x| - fn.call(x)})
end

def argmax_list(seq, fn)
  # Return a list of elements of seq[i] with the highest fn(seq[i]) scores.
  
  return argmin_list(seq, lambda{|x| - fn.call(x)})
end

def argmax_random_tie(seq, fn)
  # Return an element with highest fn(seq[i]) score; break ties at random.
  
  return argmin_random_tie(seq, lambda{ |x| -fn.call(x)})
end

#______________________________________________________________________________
# Simple Data Structures: infinity, Dict, Struct
                
$infinity = 1.0e300

=begin
### problem ####
  memoized doesnt work, but dont understund the python memoized_fn.cache
=end

def memoize(fn, slot=nil)
  # Memoize fn: make it remember the computed value for any argument list.
  # If slot is specified, store result in that slot of first argument.
  # If slot is false, store results in a dictionary.
  
  unless slot.nil?
    def memoized_fn(obj, *args)
      if obj.respond_to? slot
        return object.instance_variable_get slot
      else
        val = fn.call(obj, *args)
        obj.instance_variable_set slot, val
        return val
      end
    end
  else
    def memoized_fn(*args)
      if not memoized_fn.cache.has_key?(args)
        memoized_fn.cache[args] = fn.call(args)
      end
      return memoized_fn.cache[args]
    end
    memoized_fn.cache = {}
  end
  return memoized_fn
end








#______________________________________________________________________________
# Queues: Stack, FIFOQueue, PriorityQueue

class A_Queue 
  # Queue is an abstract class/interface. There are three types:
  #     Stack(): A Last In First Out Queue.
  #     FIFOQueue(): A First In First Out Queue.
  #     PriorityQueue(lt): Queue where items are sorted by lt, (default <).
  # Each type supports the following methods and functions:
  #     q.append(item)  -- add an item to the queue
  #     q.extend(items) -- equivalent to: for item in items: q.append(item)
  #     q.pop()         -- return the top item from the queue
  #     len(q)          -- number of items in q (also q.__len())
  # Note that isinstance(Stack(), Queue) is false, because we implement stacks
  # as lists.  If Python ever gets interfaces, Queue will be an interface.
  
  def initialize
  end
  
  def extend(items)
    items.each {|item| self.push item}
  end
end

def stack
  #Return an empty list, suitable as a Last-In-First-Out Queue.
  return []
end

class FIFOQueue < A_Queue
  # A First-In-First-Out Queue
  def initialize
    @A = []
    @start = 0
  end
  
  def <<(item)
    @A.push item
  end
  def push  
    self.<< item
  end
  def append(item)
    self.<< item
  end
  
  def length
    @A.length - @start
  end
  
  def extend(items)
    @A.concat items
  end
  
  def pop
    e = @A[@start]
    
    @start += 1

    if @start > 5 && @start > @A.length/2
      @A = @A[@start .. @A.length - 1] || @A
      @start = 0
    end
    return e
  end
   
  def empty?
    @A.length == @start
  end
  
  def concat(items)
    @A.concat items
  end
  
end

class PriorityQueue < A_Queue
  # A queue in which the minimum (or maximum) element (as determined by f and
  # order) is returned first. If order is min, the item with minimum f(x) is
  # returned first; if order is max, then it is the item with maximum f(x).

  def initialize(order=:min, f=lambda{ |x| x})
    @A=[]
    @order=order
    @f=f
  end

=begin  
  def <<(item)
    bisect.insort(@A, [@f(item), item])
  end
=end #<<<--- Maybe change to:
  def <<(item)
    @A << [@f.call(item), item]
  end
  
  def append(item)
    self.<< item
  end
  
  def length
    @A.length
  end
  
  def pop
    if @order == :min
      return @A.delete_at(0)[1]
    else
      return @A.pop[1]
    end
  end
  
  def empty?
    @A.empty?
  end
  
  def concat(items)
    items.each do |item|
      self.<< item
    end
  end
  
  def to_s
    puts @A
  end
end


####### for Ruby ########

def uniform_rand(min, max)
  # this is for do like pyton random.uniform(min, max) 
  rand * (max-min) + min
end