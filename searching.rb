# ruby187 on Windows Xp
# ruby274 on Windows 10

# Searches the optimized minimal fsa of the Scrabble dictionary. Returns "true" if "word" is recognized and "false" otherwise.

word="ZYMOLOGIES"

f=File.open("TWL06.fsa", "rb")
str=f.read
@fsa=str.unpack("N*") 

@fsa.map! do |x|
[(x>>24)&0xff, (x>>2)&0x3fffff, x&3]
end

def node(j)	
result=[]
while j < @fsa.length do
 result << @fsa[j]
 break if @fsa[j][2]>1
 j+=1
end#while
return result
end#def

n=0
word.each_byte.with_index do |byte, x|
edge=node(n).assoc(byte)
if edge then
puts edge[2]&1==1 if  x==word.length - 1 
n=edge[1] 
else
puts false
end#if
end#each_byte

