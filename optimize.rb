# ruby 187 on Windows XP
# ruby 274  on Windows 10

# Builds  the minimal fsa with final transitions representing a lexicographically sorted list of strings and further reduces its sise by storing some states inside others. The method is applied to the Scrabble dictionary TWL06.  

words=IO.readlines("TWL06.txt") 
f= File.open("dict.fsa", 'wb')

class Node
	attr_accessor :edges, :idx
def initialize
	@edges=[]
end

end# Node

class Fsa
	
def initialize
	@previous_wd=""
	@root= Node.new
	@stack=[@root]
	@register={}
	# Necessary for ruby 187:
	@a=[] # Keeps the nodes in their registration order.
end

def register_or_replace(limit=0)
1.upto(@stack.length) do |x|
if limit == (@stack.length - x)    then
break
else		
child=@stack[-x]
parent=@stack[-(x+1)]
if @register.has_key?(child.edges) then	
parent.edges[-1][1]=@register[child.edges]
else
@a<< child# 
@register[child.edges]=child
end #if @register
end#if limit
end#upto
@stack=@stack.slice(0 .. limit)
end #register_or_replace

def insert(word)
# cpl is the length of the longest common prefix.
cpl=0
(0 ... word.length).each{ |i|
word[i]==@previous_wd[i] ? cpl +=1 :  break
}
suffix=word[cpl .. -1]
register_or_replace(cpl)
node=@stack[-1]
suffix.each_byte{|byte| 
next_node = Node.new
node.edges<<[byte, next_node]
@stack<<next_node
node=next_node
}
@stack[-2].edges[-1] << true # Marks transition as final
@previous_wd=word
end#insert

def insert_last_word
register_or_replace
@register[@root.edges]=@root
@a<< @root #
end

def node_count
@register.length
end

def edge_count
count=0
@register.values.each{|node|
count += node.edges.length
}
return count
end

def to_a
@a.reverse
end
end#Fsa

## Build the automaton
fsa=Fsa.new
words.each{|word| fsa.insert(word.strip)}
fsa.insert_last_word

## The automaton as an array of nodes

ar1= fsa.to_a  #puts the nodes in topological order
ar1.each_with_index{ |node, x|  node.idx=x }
ar1.each do |node|
node.edges.each do |edge|
edge[2]= edge[2] ? 1 : 0 # end of word mark
edge[1]= edge[1].idx
end#node.edges.each
end#ar1.each
ar1.map!{|node| node.edges}

# The new representation "ar1" allows the use of array indexes as pointers to reference the nodes. The nodes themselves are arrays of edges.
  
# A catalogue of edges:
# h[edge]contains (references to) nodes having edge as a member.
h =Hash.new { |hash, n| hash[n] = [] } 
ar1.each_with_index do |node, x| 
node.each do |edge|
h[edge] << x 
end#each
end#each_with_index


## A catalogue of nodes and  their proper supersets:
supernodes=Hash.new { |hash, key| hash[key] = [] }

ar1.each_with_index do |node, x| 
node.each do |edge|
 supernodes[x] << h[edge]
end#each
supernodes[x].flatten!

fq=Hash.new(0)
supernodes[x].each do |y|
	fq[y] += 1
end#each
# Not superset? delete:
supernodes[x].delete_if { |y| fq[y] < node.length }
# Superset not proper? delete:
supernodes[x].delete_if{|y| y == x}# delete x

supernodes[x].sort!{|n, m| ar1[n].length <=> ar1[m].length}
supernodes[x].uniq!
end#each_with_index

# Ignore nodes lacking supernodes: 
supernodes.delete_if { |key, value| value.empty? } 

# Nodes are potentially embeddable in their supernodes. The ordering defined on those nodes is meant to yield a better compression, in the end. Nodes having a single supernode come first and when two nodes are competing for the same supernode, the node with more edges is preferred.

candidates=supernodes.keys
candidates.sort! do |n, m| 
if supernodes[n].length == supernodes[m].length then
ar1[m].length <=> ar1[n].length # reversed order
else supernodes[n].length <=> supernodes[m].length
end#if
end#sort!

# Matching candidates 
chosen=Hash.new
matches=Hash.new
candidates.each do |k|
a=supernodes[k]
v=nil
a.each_index do |i|
v=a[i] unless chosen[a[i]]	
break if v
end#each_index
if v then
matches[k]=v
chosen[v]=true
end#if
end#candidates.each

 chains=[]
heads=matches.keys - matches.values
heads.each do |m|
	chain=[m]
	x=matches[m]
while x do
	chain << x
	x=matches[x]
end#while
chains <<  chain 
end.each

data=Hash.new
chains.each do |z|
	j=z[-1]
	a=ar1[j]
z.each_with_index do |m, i|
	break if  i== z.length - 1
	x=matches[m] # x is nil if m==z[-1]
	a1=ar1[m]
	a2=ar1[x]
	ar1[x]=(a2 - a1)+a1  # reorder the edges in a2
	data[m]=[j, a.length - a1.length]
end#each2	
end#each

## Preparing the ground for the final representation as an array of edges.
# Some nodes are to be removed from "ar1" while preserving the order of the others. However the positions(indexes)of the preserved nodes will change. The hash "nw1" links the  positions of the nodes to their future positions in the new array. 

nw1=Hash.new
n=0
ar1.each_index do |x|
	next if matches[x]
	nw1[x]=n
	n += 1
end#each_index


# The hash "nw2" establishes a correspondence between the indexes of nodes in an array of nodes and their future indexes in the array of edges.

nw2=[]
n=0
ar1.each_with_index do |node, x|
	next if matches[x]
	nw2 << n
	n += node.length
end#each_index

# For embeddable nodes. Form the address of their future residence.

data.keys.each do |m|
j=data[m][0] 
data[m] = nw2[nw1[j]] + data[m][1] 
end	

## Representation of the optimized graph.

# Remove  embeddable nodes
ar2=[]
 ar1.each_with_index do |node, x|
next if  matches[x]
ar2 << node
end#ar1.each

# Update indexes. Redirect targets
 ar2.each_with_index do |node, x|
node.each do |edge|
m=edge[1]
if  matches[m] then
edge[1]=	data[m]
else
edge[1]=nw2[nw1[m]] 
end#if
edge[2] +=2 if edge==node[-1]#  Mark end of node
end#node.each
end#ar2.each

ar2.flatten!(1) # now ar2 is an array of edges

# Pack edges as 32 bit integers.
ar2.each do |label, target, flags|
target<<=2    # make room for flags
target|=flags   # insert flags
f.print	label.chr, ((target>>16)&0xff).chr,  ((target>>8)&0xff).chr, (target&0xff).chr  
end#each