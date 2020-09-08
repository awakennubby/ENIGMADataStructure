module SiteNetwork

repoFile = "repo.jl"
repoPath = joinpath(@__DIR__,repoFile)
include(repoPath)

using Random

abstract type Node end
abstract type Link end
abstract type Stub end
abstract type Network end

export everything

mutable struct NetworkStruct <: Network
	t::Float64 #Time
	N::Int #Number of nodes
	K::Int #number of links
	nodeArr::Array{Node}
	stubArr::Array{Stub}
	linkArr::Array{Link}
	xCoord::Array{Float64}
	yCoord::Array{Float64}
end


mutable struct StubStruct <: Stub
	#node - the number of the node that it is on
	node::Union{Int,Node}
	#link - the number of the link that starts at the stub
	link::Union{Int,Link}
	#next - The next stub on the same node or zero if this is the last stub
	next::Union{Int,Stub}
end


mutable struct NodeStruct <:Node
	#The node contains only one integer
	#first - the number of the first stub (or zer o) if there are no
	first::Int
	#the x and y coordinates of that node
	x::Float64
	y::Float64
end

mutable struct LinkStruct <: Link
#The link contains two numbers
	#nodea - number of the from node
	NodeA::Union{Int,Node}
	#nodeb - number of the to node
	NodeB::Union{Int,Node}
	#check what state the link is in
	# state 1: Basal Spread where nodeA is B, C1, or C2 and nodeB is X
	# state 2: C1 Spread where nodeA is C1 and nodeB is B
	# state 3: C2 Spread where nodeA is C2 and nodeB is B OR C1
	# state 4: Everything else
	state::Int
end

#returns an array of x number of links
function setLinks(x::Int)
	linkArr = []
	for i=1:x
		#push a new link into the array
		newLink = LinkStruct(0, 0, 1)
		push!(linkArr, newLink)
	end
	return linkArr
end

#returns an array of x number of stubs
function setStubs(x::Int)
	stubArr = []
	for i=1:x
		newStub = StubStruct(0, 0, 0)
		push!(stubArr, newStub)
	end
	return stubArr
end

#returns an array of x number of nodes
function setNodes(net::Network, x::Int)
	nodeArr = []
	for i=1:x
		RandomX = rand(Float32, 1) #We make two uniform random number in the interval [0,1)
	    RandomY = rand(Float32, 1)
		push!(net.xCoord, RandomX[1])
		push!(net.yCoord, RandomY[1])
		newNode = NodeStruct(0, RandomX[1], RandomY[1])
		push!(nodeArr, newNode) #initalizes nodeArr with firstStubs = 0
	end
	return nodeArr
end

#return a link in the given state
function RandLinkState(state::Int, linkArr::Array)
	#Size/length of linkArr = 5000
	LinkIDArr = rand(1:1:length(linkArr)[1], 1)
	LinkID = LinkIDArr[1]
	count = 0
	while linkArr[LinkID].state != state && count != length(linkArr)
		LinkIDArr = rand(1:1:size(linkArr,1)[1], 1)
		LinkID = LinkIDArr[1]
		count += 1
	end
	return LinkID
end

#check for number of links not in state 4
function SusInfectedOnly(linkArr::Array)
	count = 0
	for i = 1:size(linkArr,1)[1]
		if linkArr[i].state != 4
			count += 1
		end
	end
	return count
end

#return the number of links in the given state
function numLinks(state::Int, linkArr::Array)
	count = 0
	for i = 1:size(linkArr,1)[1]
		if linkArr[i].state == state
			count += 1
		end
	end
	return count
end

#this is the end for the end of the module
end
