using Distributed
using Plots

filename = "repo.jl"
filepath = joinpath(@__DIR__,filename)

@everywhere include(filepath)


#Initialize()
#Set time t=0
#time = 0
#Create N agents and set their internal state to S AKA class 0
#make Master Repository
MasterRepository = repo.ConstructorNClasses(C=2, N = 1000)
repo.Allocate(MasterRepository)
#Create a repository for N agents also initializing them in state S.
for i = 1:1000
	#add each new object to Repo
	repo.Add(MasterRepository, repo.ConstructorNClasses(C=i), 1)
end

function Initialize()
	#start with 20 infected nodes
	for i = 1:20
		Infect()
	end
end

function Infect()
	#Define x= id of random agent in class S from the repository.
	x = repo.RandomIDClass(MasterRepository, 1)
	#Change the internal state of agent x to I.
	repo.ChangeClassID(MasterRepository, x, 2)
	#Change class of x in the repository to I.
end

function Recover()
	# Define x=id of random agent in class I from the repository.
	x = repo.RandomIDClass(MasterRepository,2)
	# Change the internal state of agent x to S.
	repo.ChangeClassID(MasterRepository,x,1)
	#Change class of x in the repository to S.
end

function Model()
	Initialize()
	p = 1
	r = 100
	plotly()
	x = []
	y = []
	time::Float64 = 0
	#x = 1:10; y=rand(10);
	for i=1:2500 #TO END DO
		#Get n_i from repository
		nInfected = repo.NumberOfItemsClass(MasterRepository, 2)
			#so get the rate of recovery from the repository
		#Get n_s from repository
		nSuspectible = repo.NumberOfItemsClass(MasterRepository, 1)
			#rate of susceptibles
   		#Calulate rInf = p*nI*nS
		rateInfected = p*nInfected*nSuspectible
			#this is the total rate at which infection events
   		#Calculate rRec = r*nI
		rateRecovered = r*nInfected #I set r = .5
			#The total rate at which agents recover is then r*nI
			#r is the rate of recovery
			#nl is rate of recovery from the repository
   		#Calculate rTot=rInf+rRec
		TotalRate = rateInfected+rateRecovered
			#total rate = the total rate of infection events plus the rate of recovery
   		#Calculate q=rRec/(rInf+rRec)
		q = rateRecovered/(TotalRate)
   		#Generate a random number u  between 0 and 1
		u = rand(Float32, 1)
   		#If u<q Recover() ELSE Infect()
		if u[1] < q
			Recover()
		else
			Infect()
		end
   		#Let t=t+exp(-rTot)
		time += (exp(-1/TotalRate))
		push!(x, time)
		push!(y, repo.NumberOfItemsClass(MasterRepository, 2))
	end
	println("number infected: ", repo.NumberOfItemsClass(MasterRepository, 2))
	scatter(x,y)
	plot(x,y,title="Simple Infection Model", label="p = 1, r = 100")
	xlabel!("X Axis is Time")
	yaxis!("Y axis is people infected")
	gui()
end

Model()
