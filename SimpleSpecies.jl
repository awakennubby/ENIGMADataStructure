using Distributed
using Plots

filename = "repo.jl"
filepath1 = joinpath(@__DIR__,filename1)
@everywhere include(filepath1)

filename2 = "SimpleSpeciesClass.jl"
filepath2 = joinpath(@__DIR__,filename2)
@everywhere include(filepath2)

function InitializeRG(n::Int, k::Int, net::SiteNetwork.Network)
    net.N = n #number of nodes
    net.K = k #number of links
    net.nodeArr = SiteNetwork.setNodes(net.N)#Set the size of node array to N
    net.stubArr = SiteNetwork.setStubs(2*net.K) #Set the size of stub array  to 2K
    net.linkArr = SiteNetwork.setLinks(net.K) #Set the size of link array to K
    #Set first to 0 on all nodes
    #^ this is done in the node class
    for i=1:net.K #This is the for look where we place all the links randomly
        #These are the nodes that we link
        a::Int = 0
        b::Int = 0
        #Make sure that we are trying to make a sensible link we will define linkable below.
        while linkable(a,b,net) == false
            randA = rand(1:1:net.N, 1)
            a = randA[1]
            randB = rand(1:1:net.N, 1)
            b = randB[1]
        end
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
end

function linkable(a,b, net::SiteNetwork.Network)
    if a == 0 || b == 0 || a == b
        return false
    end
    if linked(a,b, net) == false
        return true
    end
end

function linked(a,b, net::SiteNetwork.Network)
    nstub = net.nodeArr[a].first
    while nstub != 0
        nlink = net.stubArr[nstub].link #The number of the link that the stub is holding
		if net.linkArr[nlink].NodeA == b #Check if the target node is at end a of the link
	        return true
	    end
	    if net.linkArr[nlink].NodeB == b #Same for the other end of the link
	        return true
	    end
		nstub = net.stubArr[nstub].next #Go to the next stub
    end
end

function Initialize(n::Int, k::Int, object::repo.CRepository)
    N::Int = n #number of nodes
    K::Int = k #number of links
    #will make net after, prob some global or maybe inherit from another program
	nodeArray::Array = []
	stubArray::Array = []
	linkArray::Array = []
    global net = SiteNetwork.NetworkStruct(0,0, 0, nodeArray, stubArray, linkArray)
    InitializeRG(n, k, net) #Initialize a random graph of the right size
    InfectN(object, net, 100) #infect 100 Nodes, we are going to make a function for that below
end

function Simulation(Time_tx, object::repo.CRepository,net::SiteNetwork.Network)
	#Simulate till Time_tx
	plotly()
	x = []
	y = []
    while net.t<Time_tx && isInfected(object) == true
        Step(object,net, x, y)
    end
	scatter(x,y)
	plot(x,y,title="Simple Species Model", label="z = 10, p = 1, r = 2")
	xlabel!("X Axis is Time")
	yaxis!("Y axis are nodes infected")
	gui()
end

function Step(object::repo.CRepository,net::SiteNetwork.Network, x::Array, y::Array)

	p = 1
	r = 2
    nInfected = repo.NumberOfItemsClass(object,2)#net.N #Init the infected and active link count by asking the repository for the count #net.N = 1000
	nActiveLinks = SiteNetwork.SusInfectedOnly(net.linkArr)
    #nActiveLinks = net.K #nAct = 5000
	#p = 1
    pInfected = nActiveLinks * p #total infection rate is number of active links times infection
	 #rate per link p,pInfected = 5000
	#r = 2
	pRecovery = nInfected * r #total recovery rate is number of infected times per-capita
	#recovery rate,pRecovery = 2000
    delta = pInfected/(pRecovery + pInfected) #probability that next event is an infection event
	#delta should be 5000/(5000+2000), .71
    RandomA = rand(Float32, 1) #We make two uniform random number in the interval [0,1)
    RandomB = rand(Float32, 1)

    tau = -(log(1.0-RandomA[1]))/(pInfected + pRecovery) #this formula is the time that passes,
    #before the next event happens

    net.t+=tau #advances the time
    if RandomB[1] < delta
        InfectionEvent(object,net) # function will be written below
    else
        RecoveryEvent(object,net) # function will be written below
    end
	push!(x, net.t)
	push!(y, repo.NumberOfItemsClass(object, 2))
end

function RecoveryEvent(object::repo.CRepository,net::SiteNetwork.Network)
    n = repo.RandomIDClass(object, 2)# n = Random infected node from repository
    Recover(n,object,net)
end
function InfectionEvent(object::repo.CRepository, net::SiteNetwork.Network)
I = SiteNetwork.RandLinkState(2,net.linkArr)

nodeAID = net.linkArr[I].NodeA

nodeBID = net.linkArr[I].NodeB


if isInfectedNode(object,nodeAID) == true
	Infect(nodeBID,object,net)
else
	Infect(nodeAID,object,net)
end
end

function isInfected(object::repo.CRepository)
    if repo.NumberOfItemsClass(object, 2) != 0 #there is still stuff infected
        return true
    else
        return false #n = idItem
    end
    #just ask repn if the node is in the infected state
end

function isInfectedNode(object::repo.CRepository,NodeID::Int)
	if repo.Class_idItem(object, NodeID) == 2
		return true
	else
		return false
	end
end

function Infect(n::Int,object::repo.CRepository,net::SiteNetwork.Network)
	repo.ChangeClassID(object,n,2)
 	nStub = net.nodeArr[n].first
	#println("nStub:",nStub)
	while nStub !=0
		stubAlt = net.stubArr[nStub]
		nLink = net.linkArr[stubAlt.link]
		state = nLink.state
		if state == 1
			nLink.state = 2
			net.linkArr[stubAlt.link].state = nLink.state
		else
			nLink.state = 3
			net.linkArr[stubAlt.link].state = nLink.state
		end
		nStub = net.stubArr[nStub].next
	end
end

function Recover(n::Int,object::repo.CRepository,net::SiteNetwork.Network)
    repo.ChangeClassID(object, n, 1)
	nStub = net.nodeArr[n].first
	while nStub != 0
		stubAlt = net.stubArr[nStub]
		nLink = net.linkArr[stubAlt.link]
		state = nLink.state
		if nLink.state == 2
			nLink.state = 1
			net.linkArr[stubAlt.link].state = nLink.state
		else
			nLink.state = 2
			net.linkArr[stubAlt.link].state = nLink.state
		end
		nStub = net.stubArr[nStub].next
	end
end

function InfectN(object::repo.CRepository, net::SiteNetwork.Network, N::Int)
    for i=0:N
        # n=random susceptible node from repn
        n = repo.RandomIDClass(object, 1)
        Infect(n, object, net)
    end
end

MasterRepository = repo.ConstructorNClasses(C=2, N = 1000)
repo.Allocate(MasterRepository)
#Create a repository for N agents also initializing them in state S.
for i = 1:1000
	#add each new object to Repo
	repo.Add(MasterRepository, repo.ConstructorNClasses(C=i), 1)
end

Initialize(1000, 5000, MasterRepository)
Simulation(3, MasterRepository,net)
println("Final number infected: ", repo.NumberOfItemsClass(MasterRepository, 2))
