# ruby187 on Windows Xp
# ruby274 on Windows 10

# Extracts all words recognized by the optimized minimal fsa of the Scrabble dictionary. The words are not in alphabetical order. Sorts the words. Prints them. Checks the sorted list for equality with the official list.
 

f=File.open("TWL06.fsa", "rb")
str=f.read
@fsa=str.unpack("N*") 


def node(j)	
result=[]
while j < @fsa.length do
 result << @fsa[j]
 break if @fsa[j]&2==2
 j+=1
end#while
return result
end#def

@candidate=[]
@replacements=[]

def dfs(j, i)
	 node(j).each do |edge|
        @candidate[i]=(edge>>24) .chr
        if edge%2==1 then
	@candidate.slice!(i+1 .. -1)
        @replacements<<@candidate.join
        end#if
         k=(edge&0xffffff)>>2
         dfs(k, i+1) 
	 end#each
 end#dfs

dfs(0, 0) 
a1=File.readlines("TWL06.txt")
a1.map!{|wd| wd.strip}
a2=@replacements 
a2.sort!
g=File.open("words.txt", "w")
g.puts a2
puts a1==a2