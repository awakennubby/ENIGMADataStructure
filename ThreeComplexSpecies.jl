speciesName = "ComplexSpeciesClass.jl"
speciesPath = joinpath(@__DIR__,speciesName)
include(speciesPath)

repoFile = "repo.jl"
repoPath = joinpath(@__DIR__,repoFile)
include(repoPath)


using Plots
using GraphRecipes
using LightGraphs
using Random

##############CorrectDistance##############################
#given two nodes, check is the distance between them is less than d
function correctDistance(d, nodeA,nodeB)
	A1 = nodeA.x
	B1 = nodeA.y
	A2 = nodeB.x
	B2 = nodeB.y
	A = A1 - A2
	A = ^(A,2)
	B = B1 - B2
	B = ^(B,2)
	C = ^((A+B), .5)
	if C < d
		return true
	else
		return false
	end
end

#return the array of linkPairs
function LinkPairs(net::SiteNetwork.Network)
    linkPairs = []
    d = .1
    for i=1:length(net.nodeArr)
        for j=i:length(net.nodeArr)
            if correctDistance(d, net.nodeArr[i], net.nodeArr[j]) == true
                pair = [i, j]
                push!(linkPairs, pair)
            end
        end
    end
    return linkPairs
end

#################initializeRG##################
function InitializeRG(n::Int, k::Int, net::SiteNetwork.Network)
	net.N = n #number of nodes
	net.K = k #number of links
	net.nodeArr = SiteNetwork.setNodes(net, net.N)#Set the size of node array to N
	#a list of pairs of IDs of linked nodes
	linkPairs = LinkPairs(net)
	#a list of pairs of only the x coords of the linked nodes
	linkX = []
	#a list of pairs of only the y coords of the linked nodes
	linkY = []
	net.K = size(linkPairs)[1]
	net.stubArr = SiteNetwork.setStubs(2*net.K) #Set the size of stub array  to 2K
	net.linkArr = SiteNetwork.setLinks(net.K) #Set the size of link array to K
	#net.linkRepo = SiteNetwork.setLinkRepo(states, net.K) #set the number of states
	#Set first to 0 on all nodes
	#^ this is done in the node class
	#graph = SimpleGraph(net.K)
	for i=1:net.K #This is the for look where we place all the links randomly
		#These are the nodes that we link
		a::Int = linkPairs[i][1]
		b::Int = linkPairs[i][2]

		temp = []
		#push the two x coords in
		push!(temp, net.nodeArr[a].x)
		push!(temp, net.nodeArr[b].x)
		#push the temp into linkX
		push!(linkX, temp)
		#clear the temp
		temp = []
		#same with the y coord
		push!(temp, net.nodeArr[a].y)
		push!(temp, net.nodeArr[b].y)
		push!(linkY, temp)

		#add_edge!(graph, a, b)
	#Make sure that we are trying to make a sensible link we will define linkable below.
		#Now the link knows that what it is supposed to link to, but we have to tell the node as well.
		net.linkArr[i].NodeA = a
		net.linkArr[i].NodeB = b
		#Nodes are connected to links by stubs.  we are using stub 1,2, for link 1; stub 3,4 for link 2 etc.
		stuba = 2*i - 1
		stubb = 2*i
		#now the stub knows which node it is supposed to be on
		net.stubArr[stuba].node = a
		#now the stub knows what link it is holding
		net.stubArr[stuba].link = i
		#These two commands insert the stub into the nodes sub list
		net.stubArr[stuba].next = net.nodeArr[a].first
		net.nodeArr[a].first = stuba
		#do the same for the other stub
		net.stubArr[stubb].link = i
		net.stubArr[stubb].next = net.nodeArr[b].first
		net.nodeArr[b].first = stubb
	end

	plotly()
	x = net.xCoord
	y = net.yCoord
	scatter(x,y, title="The Network", marker = true)
	plot(linkX, linkY, label = "", shape = :circle, markersize = 2)
	xlabel!("X axis")
	yaxis!("Y axis")
	plotly()
	gui()

	println(net.K)
end

##################Initialize###########################
function Initialize(n::Int, k::Int, object::repo.CRepository)
	N::Int = n #number of nodes
	K::Int = k #number of links
	nodeArray::Array = []
	stubArray::Array = []
	linkArray::Array = []
	xCoord::Array = []
	yCoord::Array = []
	x = 10
	y = 10
	#3 diff states
	#linkRepo = repo.ConstructorNClasses(C=2, N=1)
	global net = SiteNetwork.NetworkStruct(0,0, 0, nodeArray, stubArray, linkArray, xCoord, yCoord)
	InitializeRG(n, k, net) #Initialize a random graph of the right size
	#ColonizeN(object, net, 100) #infect 100 Nodes, we are going to make a function for that below
	#colonize 10 nodes to c1
	ColonizeN(20, 3, object, net) #node of class 3 = c1
	#colonize 10 nodes to c2
	ColonizeN(20, 4, object, net) #nodes of class 4 = c2
end

###################Simulation########################
function Simulation(Time_tx::Float64, object::repo.CRepository,net::SiteNetwork.Network)
	#Simulate till Time_tx
	plotly()
	x = []
	xy = []
	by = []
	c1y = []
	c2y = []
	y = [xy, by, c1y, c2y]
    while (net.t < Time_tx) == true
        Step(object,net, x, y)
    end
	scatter(x,y)
	labels = ["x", "B", "C1", "C2"]
	plot(x,y,title="Simple Species Model", label=labels)
	xlabel!("X Axis is Time")
	yaxis!("Y axis are nodes infected")
	gui()
end

###################Step#####################
function Step(object::repo.CRepository,net::SiteNetwork.Network, x::Array, y::Array)

	BCol_rate = .5
	#C1 spreading rate > C2 spreading rate
	C1Col_rate = .1
	C2Col_rate = .1
	#basala extinction rate,relatively high
	BExt_rate = .1
	C1Ext_rate = .1 #C1 extinction rate < C2 Extinction rate
	C2Ext_rate = .1
    nColonized = object.nStored - repo.NumberOfItemsClass(object,1)#net.N #get the number of empty patches and subtract from total

	nActiveLinks = SiteNetwork.SusInfectedOnly(net.linkArr)
    #nActiveLinks = net.K #nAct = 5000
	#p = 1
    pColonized = (BCol_rate + C1Col_rate+C2Col_rate)* nActiveLinks #nActiveLinks * p #total infection rate is number of active links times infection
	 #rate per link p,pInfected = 5000
	#r = 2
	pExtinct = nColonized * (BExt_rate + C1Ext_rate + C2Ext_rate) #total recovery rate is number of infected times per-capita
	#recovery rate,pRecovery = 2000
    delta = pColonized/(pExtinct + pColonized) #probability that next event is an infection event
	#delta should be 5000/(5000+2000), .71
    RandomA = rand(Float32, 1) #We make two uniform random number in the interval [0,1)
    RandomB = rand(Float32, 1)
    tau = -(log(1.0-RandomA[1]))/(pColonized + pExtinct) #this formula is the time that passes,
    #before the next event happens

    net.t+=tau #advances the time
    if RandomB[1] < delta
		#now decide what TYPE of colonization event

		pBasal = BCol_rate*(SiteNetwork.numLinks(1, net.linkArr))
		pC1 = C1Col_rate*(SiteNetwork.numLinks(2, net.linkArr))
		pC2 = C2Col_rate*(SiteNetwork.numLinks(3, net.linkArr))

		probBasal = pBasal/(pBasal+pC1+pC2)
		probC1 = pC1/(pBasal+pC1+pC2)
		probC2 = pC2/(pBasal+pC1+pC2)

		RandomA = rand(Float64, 1)

		if RandomA[1] < probBasal #type 1 spread (basal)
			ColonizationEvent(1, object,net) # function will be written below
		elseif RandomA[1] < probC1+probBasal #type 2 spread (c1)
			ColonizationEvent(2, object,net) # function will be written below
		else #type 3 spread (c2)
			ColonizationEvent(3, object,net) # function will be written below
		end

    else
		someNode = repo.RandomID(object)

		pBasal = BExt_rate*(repo.NumberOfItemsClass(object, 2))
		pC1 = C1Ext_rate*(repo.NumberOfItemsClass(object, 3))
		pC2 = C2Ext_rate*(repo.NumberOfItemsClass(object, 4))

		probBasal = pBasal/(pBasal+pC1+pC2)
		probC1 = pC1/(pBasal+pC1+pC2)
		probC2 = pC2/(pBasal+pC1+pC2)

		RandomA = rand(Float64, 1)
		randType = 0
		if RandomA[1] < probBasal #type 1 extinct (basal)
			someNode = repo.RandomID(object)
			while repo.Class_idItem(object, someNode) == 1
				someNode = repo.RandomID(object)
			end
			randType = 1
		elseif RandomA[1] < probBasal+probC1 && repo.NumberOfItemsClass(object,3) != 0  #type 2 extinct (c2)
			#type 2 C1 extinction, get a C1 node
			someNode = repo.RandomIDClass(object, 3)
			randType = 2
		elseif repo.NumberOfItemsClass(object,4) != 0  #type 3 extinct (c2)
			#type 3 C2 extinction, get a C2 node
			someNode = repo.RandomIDClass(object, 4)
			randType = 3
		end
        ExtinctionEvent(someNode,randType,object,net) # function will be written below
    end
	push!(x, net.t)
	for i=1:4
		push!(y[i], repo.NumberOfItemsClass(object, i))
	end
end


##################Exticntion#############################
#ExtinctionEvent
function ExtinctionEvent(n::Int, ExtinctType::Int, object::repo.CRepository,net::SiteNetwork.Network)
	#We choose the random node Step
	#N = Random node in the appropriate state depending on the nature of the extinction event
	#Extinct(n) #We then change nodeB to X and update the link state
	#Change C1->P and C2->P 2 = P,3 = C1, 4 = C2
	Extinction(n, ExtinctType,object,net)
end

function Extinction(n::Int,ExtinctType::Int,object::repo.CRepository,net::SiteNetwork.Network)
	#n is the node, where X=1,P=2,C1=3,C2 = 4
	if ExtinctType == 1 	#extinction type 1 = basal extinction
		repo.ChangeClassID(object,n,1) #beomes an empty patch
	elseif ExtinctType == 2 #extinction type 2 = C1 extinction
		repo.ChangeClassID(object,n,2) #becomes a basal patch
	else #extinction type 3 = c2 extinction
		repo.ChangeClassID(object,n,1) #becoems a basal patch
	end
	nStub = net.nodeArr[n].first
	while nStub != 0
		linkID = net.stubArr[nStub].link #The number of the link that the stub is holding
		net.linkArr[linkID].state = update_link(linkID, object, net)
		nStub = net.stubArr[nStub].next
	end
end


########################Colonization#################################

#ColonizeEvent
#takes in a colonization type (Basal spread = 1, c1 spread = 2, or c2 spread = 3)
function ColonizationEvent(ColType::Int, object::repo.CRepository,net::SiteNetwork.Network)
	#Note that state 1 = spread 1, state 2 = spread 2, state 3 = spread 3
	link = SiteNetwork.RandLinkState(ColType,net.linkArr) #get a random linkstate to fit C1,C2,B
	Colonize(link, object, net)
end

#isColonize

#Colonize
#takes in a link to colonize from A to B
#updates NodeB and then calls update_link to update the link
function Colonize(linkID::Int, object::repo.CRepository,net::SiteNetwork.Network)
	#first change nodeB to be of the same class of nodeA
	link = net.linkArr[linkID]
	nodeAID = link.NodeA
	nodeBID = link.NodeB
	newClass = repo.Class_idItem(object, nodeAID)
	repo.ChangeClassID(object, nodeBID, newClass)
	#then, update all the links B has
	nStub = net.nodeArr[nodeBID].first
	while nStub != 0
		linkID = net.stubArr[nStub].link #The number of the link that the stub is holding
		net.linkArr[linkID].state = update_link(linkID, object, net)
		nStub = net.stubArr[nStub].next
	end
end


#ColonizeN
#takes in an N int number of nodes to colonize to type Class
#This is only used in Initialization, so all nodes are in in empty patch class
function ColonizeN(N::Int, Class::Int, object::repo.CRepository, net::SiteNetwork.Network)
    for i=0:N
        #get a random empty node from repn
        N = repo.RandomIDClass(object, 1)
		#change the state of N to the new Class
		repo.ChangeClassID(object, N, Class)
		#then, update all its links
		nStub = net.nodeArr[N].first
		#println("NOde N:", N)
		while nStub != 0
			linkID = net.stubArr[nStub].link #The number of the link that the stub is holding
			link = net.linkArr[linkID]
			#print(" link id ", linkID)
			net.linkArr[linkID].state = update_link(linkID, object, net)
			nStub = net.stubArr[nStub].next
		end
    end
end



##################################update_link###################################

#update_link
#takes in a linkID
#checks the two nodes
#returns the numerical state that the link should be in
function update_link(linkID::Int, object::repo.CRepository,net::SiteNetwork.Network)
	link = net.linkArr[linkID]
	NodeAID = link.NodeA
	NodeBID = link.NodeB
	NodeAState = repo.Class_idItem(object, NodeAID)
	NodeBState = repo.Class_idItem(object, NodeBID)
	#Basal Spread: link state 1 is a non-X nodeA connected to a X nodeB
	if NodeAState != 1 && NodeBState == 1
		#println("state 1")
		return 1
	#C1 Spread: link state 2 is a C1 nodeA connected to a B nodeB
	elseif NodeAState == 3 && NodeBState == 2
		#println("state 2")
		return 2
	#C2 Spread: link state 1 is a C2 nodeA connected to a B or a C1 nodeB
	elseif NodeAState == 4 && (NodeBState == 2 || NodeBState == 3)
		#println("state 3")
		return 3
	else
		#println("state 4")
		return 4
	end
end

MasterRepository = repo.ConstructorNClasses(C=4, N = 1000)
repo.Allocate(MasterRepository)
#Create a repository for N agents also initializing them in state S.
for i = 1:1000
	#add each new object to Repo
	repo.Add(MasterRepository, repo.ConstructorNClasses(C=i), 1)
end

Initialize(1000, 5000, MasterRepository)
Simulation(40.00, MasterRepository, net)
println("Final number empty: ", repo.NumberOfItemsClass(MasterRepository, 1))
println("Final number basal: ", repo.NumberOfItemsClass(MasterRepository, 2))
println("Final number c1: ", repo.NumberOfItemsClass(MasterRepository, 3))
println("Final number c2: ", repo.NumberOfItemsClass(MasterRepository, 4))
