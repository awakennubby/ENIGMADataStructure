
module SiteNetwork

using Distributed

using Random

filename = "repo.jl"
filepath = joinpath(@__DIR__,filename)

@everywhere include(filepath)

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
end

mutable struct LinkStruct <: Link
#The link contains two numbers
	#nodea - number of the from node
	NodeA::Union{Int,Node}
	#nodeb - number of the to node
	NodeB::Union{Int,Node}
	#where S-S = 1, S-I = 2, S-S = 3
	#We can rid object if we pass NodeA and NodeB to do so, depends if we're doing this on IDs or not
	#DetermineState(object,NodeA,NodeB)
	state::Int
end

#does link needs a state function??
	#how to get random link of a certain state??

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
#=nodeArr is filled with IDs of object.Items, so when we create links
we link using the IDs but call CRepo functions to retrieve the object.Items
=#
function setNodes(x::Int)
	nodeArr = []
	for i=1:x
		newNode = NodeStruct(0)
		push!(nodeArr, newNode) #initalizes nodeArr with firstStubs = 0
	end
	return nodeArr
end

function RandLinkState(state::Int, linkArr::Array)
	LinkIDArr = rand(1:1:length(linkArr)[1], 1)
	LinkID = LinkIDArr[1]
	while linkArr[LinkID].state != state
		LinkIDArr = rand(1:1:size(linkArr,1)[1], 1)
		LinkID = LinkIDArr[1]
	end
	return LinkIDArr[1]
end

end
