# space-optimization-of-dawgs
A method to reduce the size of a minimal directed acyclic word graph by storing some nodes inside  others. The method is applied to  the  Scrabble dictionary (TWL06).

To start, we build  the minimal  automaton with final transitions recognizing the words of the dictionary, using a method of Jan Daciuk.  The  automaton  is directed and acyclic. Viewed as a graph, it is a Dawg. Thus the names "nodes" and "edges" may be used  instead of "states" and "transitions".

##Reducing the number of edges

1)  The minimal graph is represented as an array of nodes which allows  the array indexes to be used  as pointers to the nodes. When confusion is unlikely, references to nodes are simply called nodes. This happens with most ruby hashes  mentioned hereafter.

The nodes themselves are  arrays of edges. The edges are arrays of type [label, target, flags]  where label is a character code and  target an array index  pointing to a node. For the moment, flags takes  the value 1 (if the edge is the last edge of a word) or  the value 0.

2) Let a2 be  a node (an array of edges). If a1 is a (proper) subset of  a2,   reorder the edges of a2  to place the edges of a1 in the last position (simply replace a2 by (a2-a1)+a1). This is the main step towards reducing the number of edges. Indeed, if all pointers to a1 could be redirected to its clone inside a2, we could get rid of a1. So from now on, the goal is to select  pairs of nodes (a1, a2) where a1 is  a (proper) subset of a2.

3) A  hash called "supernodes"  is defined. The keys are nodes and supernodes[a] is an array of nodes. Each node in supernodes[a] is a proper superset of a. An ordering is defined on the keys and on each value. The ordering is designed  to hopefully reduce the number of edges of the graph as much as possible.

The keys are traversed in order. If a node  has supernodes, it forms a pair with its first supernode available. A supernode is available unless  marked as already chosen to form a previous pair.The selected pairs form a new  hash called "matches".

4) If a2=matches[a1],  node  a1 can be embedded in a2. However, if  node a3 is such that a3=matches[a2], then  a3 can store a2 together with a1. Therefore, we have to build all the maximal sequences of  nodes that can be formed by connecting selected pairs. Most sequences have length 2.  The last node of  a chain of length 2  stores  a single node. If the chain is of length n>2  its last node stores  all the n-1 preceding nodes.
 
5)  At this point, some nodes have to disappear from the representation. Before they vanish, we save their personal data. The size of a node due to disappear and the index of its supernode are necessary for future use. Besides, a hash is defined to relate the indexes of the remaining nodes to their new positions in the reduced array. 

6) Now a representation of  the graph as an array of edges is required. In this representation, pointing to a node means pointing to its first edge. An other hash  is defined  to establish a link between the two ways of indexing.

The edges are still arrays of type [label, target, flags] . The element "flags" takes additionnal values marking the last edge of  nodes. The "target"  elements are updated using the hashes that were built to track the changes in the indexes. If "target" pointed to a node which is no longer there, the  hash "data" allows to form its new reference.

7) Each edge of the reduced graph is packed into a 32-bit integer:
       LLLLLLLL TTTTTTTT TTTTTTTT TTTTTTGF
where L is for Label, T is for Target, F is set to mark the last edge of a word and G is set to mark the last edge of a node.
 
##Results

Only 9203 nodes out of  54259 have at least one superset but only 8839 matches could be formed since several nodes may compete for the same superset. 

The minimal graph has 126695 edges, the reduced graph 113626 edges.

Andras Kovacs <https://github.com/AndrasKovacs/dawg-gen> states a compression of "about 113735" edges for the scrabble dictionary ( the number varies slightly across runs).

##Further reading:
Jan Daciuk, Optimization of Automata, Gdansk 2014 ISBN 978-83-7348-564-8
