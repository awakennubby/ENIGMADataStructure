#include("C:/Users/slephc/Desktop/Julia 1.4.2/repo.jl")
module repo

using Pkg
Pkg.add("Parameters")
using Parameters


abstract type CRepository end
export CopyConstructor, ConstructorNClasses, ConstructorNClassesNItems, everything

#Copy Constructor
@with_kw mutable struct CopyConstructor <: CRepository
	#The initialization
	#R is the CRepository object take in
	R::CRepository
	itemcopy::Bool
	#C and N are initialized to R's C and N
	C = R.C
	N = R.N
	#All other values are init to 0/default
	nStored::Int = 0
	count::Array{Int} = R.count
	offset::Array{Int} = R.offset
	items::Array{Any} = R.items
	nums::Array{Int} = R.nums
	ids::Array{Int} = R.ids

end

#We want to use mutable types because we want to be able to modify instances
@with_kw mutable struct ConstructorNClasses <: CRepository
	#The initialization
	#C will equal in the input
	C::Int						#number of classes
	#all other values initialized to 0/default
	N::Int = 0					#current max number of items
	nStored::Int = 0			#total number of items stored
	count::Array{Int} = [1]		#number of items per class;
	offset::Array{Int} = [1]	#start index of a class
	items::Array{Any} =[1]		#array of item pointers
	nums::Array{Int} = [1]		#number of an item according to id
	ids::Array{Int} = [1]		#id of an item according to number

end


#We want to use mutable types because we want to be able to modify instances
@with_kw mutable struct ConstructorNClassesNItems <: CRepository
	#C will equal input
	C::Int
	#N will equal input
	N::Int
	#all other values init to 0 or default
	nStored::Int = 0
	count::Array{Int} = [1]
	offset::Array{Int} = [1]
	items::Array{Any} =[1]
	nums::Array{Int} = [1]
	ids::Array{Int} = [1]

end


#/////////////////////////// A D D I N G    I T E M S///////////////////

function Add(object::CRepository, pItem) where T #add item to class 1
	return Add(object, pItem, 1)
end

function Add(object::CRepository, pItem::T, nClass::Int) where T
	@assert nClass <= object.C		#basic storage at the end
	@assert nClass >= 1
	curnum::Int = object.offset[object.C]
	if curnum>=object.N
		if Enlarge(object) == false
			error("Repository Error")
		#DO THIS LATER
		end
	end
	#REP_UID uid=ids[curnum];
	uid::Int = object.ids[curnum]
	#items[uid]=pItem;				// Store Item
	object.items[uid] = pItem
	#ClassDecrease(curnum,nClass);   // Move into right class
	#println("curnum ", curnum, " nClass ", nClass)
	ClassDecrease(object, curnum, nClass)
	#nStored++;
	object.nStored += 1
	#return uid;
	println(object.offset)
	return uid
end

#////////////////// I D  F U N C T I O N /////////////////////////////////////
function IDAdr(object::CRepository, adr::Int) #///ID of an address
	return object.ids[adr]
end

function ID(object::CRepository, cls::Int, adr::Int)
	return object.ids[object.offset[cls]+adr-1]
end

#///////////////// N U M B E R  O F  I T E M S ///////////////////////////////////
function NumberOfItems(object::CRepository) #////////// GET NUMBER OF ALL ITEMS /////////
	return object.nStored #REP_ADDRESS
end

#REP_ADDRESS CRepository<T>::NumberOfItems(const REP_CLASS nClass) const//////////////////////
function NumberOfItemsClass(object::CRepository, nClass::Int) # /// NUMBER OF ITEMS OF CLASS ///////////////
	@assert(nClass>=1)
	@assert(nClass<object.C)
	return object.count[nClass]#REP_ADDRESS
end

#/////////////// R E M O V I N G  I T E M S ///////////////////////////////////////

function RemoveNum(object::CRepository,nNum::Int)
	@assert(nNum>=1)
	@assert(nNum<1)
	pItem::Ptr{T} = object.items[object.ids[nNum]]
	object.items[object.ids[nNum]] = 1
	ClassIncrease(nNum,object.C)
	object.nStored -= 1
	return pItem #REP_ADDRESS
end

function RemoveID(object::CRepository,idItem::Int) #// REMOVE AN ITEM ////////////////
	@assert(idItem >=1 && idItem<N)
	return Remove(object.num[idItem]) #REP_UID
end

function Remove(object::CRepository,nClass::Int,nNum::Int) #REP_CLASS nClass, REP_ADDRESS nNum
	@assert(nClass<object.C && nClass>=1)
	@assert(nNum>=1 && nNum<object.count[nClass])
	num = nNum + object.offset[nClass] #REP_ADDRESS num=nNum+offset[nClass];
	return Remove(num)
end

function RemoveAll()
	while(NumberOfItems())
		Remove(1) #REP_ADDRESS
	end
end
#////////////////// C L A S S  F U N C T I O N S ///////////////////////////////////

#idItem is REP_UID
function Class_idItem(object::CRepository, idItem::Int)
	#assert(idItem>=1);
	@assert idItem >= 1
	#assert(idItem<N);
	@assert idItem < N
	#REP_ADDRESS n=nums[idItem];
	n::Int = object.nums[idItem]
	#return Class(n);
	return Class_nNum(n)
end

#REP_CLASS CRepository<T>::Class(const REP_ADDRESS nNum)
#nNum is a REP_ADDRESS
function Class_nNum(object::CRepository, nNum::Int)
	#assert(nNum>=0);
	@assert nNum >= 1
	#assert(nNum<N);
	@assert nNum < object.N
	#REP_CLASS c=0;
	c::Int = 1
	#REP_ADDRESS n=nNum;
	n = nNum
	#while (n>=count[c])
	while n >= object.count[c]
		#n-=count[c];
		n -= object.count[c]
		#c++;
		c += 1
	end
	#return c;
	return c
end

#void CRepository<T>::ChangeClass(const REP_UID idItem, const REP_CLASS nNewClass)
function ChangeClassID(object::CRepository, idItem::Int, nNewClass::Int)
	#assert(idItem>=0 && idItem<N);
	@assert idItem >= 1 && IdItem < object.N
	#ChangeClass(nums[idItem],nNewClass);
	ChangeClass(object.nums[idItem], nNewClass)
end

#void CRepository<T>::ChangeClass(const REP_ADDRESS nNum,const REP_CLASS nNewClass)
function ChangeClassNum(object::CRepository, nNum::Int, nNewClass::Int)
	#assert(nNewClass>=0 && nNewClass<C);
	@assert nNewClass >= 1 && nNewClass < object.C
	#assert(nNum>=0 && nNum<=nStored);
	@assert nNum >= 1 && nNum <= object.nStored
	#REP_CLASS cls=Class(nNum);
	cls::Int = Class(nNum)
	#if (cls<nNewClass) ClassIncrease(nNum,nNewClass);
	if (cls < nNewClass)
		ClassIncrease(nNum, nNewClass)
	else
		ClassDecrease(nNum,nNewClass);
	end
end

#void CRepository<T>::ChangeClass(const REP_CLASS nClass,const REP_ADDRESS nNum, const REP_CLASS nNewClass)
function ChangeClass(object::CRepository, nClass::Int, nNum::Int, nNewClass::Int)
	#assert(nClass<C && nClass>=0);
	@assert nClass < object.C && nClass >= 1
	#assert(nNum>=0 && nNum<count[nClass]);
	@assert nNum>= 1 && nNum<object.count[nClass]
	#assert(nNewClass<C && nNewClass>=0);
	@assert nNewClass<object.C && nNewClass>=1
	#REP_ADDRESS num=offset[nClass]+nNum;
	num::Int = object.offset[nClass]+nNum;
	#ChangeClass(num,nNewClass);
	ChangeClass(object, object.num, nNewClass)
end

#/////////////////// I T E M  F U N C T I O N S //////////////////////////////////

function ItemNum(object::CRepository,nNum::Int) #const REP_ADDRESS nNum
	@assert (nNum < object.N)
	@assert (nNum >= 1)
	return object.items[object.ids[nNum]]
end

function ItemID(object::CRepository,idItem::Int) #REP_UID
	@assert(idItem>=1)
	@assert(idItem<object.N)
	return object.items[idItem]
end

function Item(object::CRepository,nClass::Int,nNum::Int) #REP_CLASS nCLASS,REP_ADDRESS nNum
	@assert(nClass>=1 && nClass<object.C) #// RETRIEVE ITEM /////////////
	@assert(nNum<object.count[nClass])
	@assert(nNum>=1)
	return object.items[object.ids[nNum+object.offset[nClass]]]
end

function RandomItem(object::CRepository)
	return object.Item(rng.IntFromTo(1,NumberOfItems()-1))
end

function RandomItem(object::CRepository,nClass::Int) #REP_CLASS nClass
	@assert(NumberOfItems(nClass))>1
	return Item(nClass,rng.IntFromTo(1,NumberOfItems(nClass)-1))
end

function RandomID()
	return ID(rng.IntFromTo(1,NumberOfItems()-1))
end

function RandomID(nClass::Int) #REP_CLASS nClass
	@assert(NumberOfItems(nClass))>1
	return ID(nClass,rng.IntFromTo(1,NumberOfItems(nClass)-1)) #REP_UID
end

#/////////////// D E L E T E  C O N T E N T S //////////////////////////////////////

#void CRepository<T>::DeleteAll() // REMOVE ALL ITEMS AND CALL DELETE FOR EVERY ITEM ////
function DeleteAll(object::CRepository)
	#while (NumberOfItems())
	while NumberOfItems(object)
		#T* x=Remove((REP_ADDRESS)1);
		x = Remove(object, 1)
	end
end

#//////////////////////  P R I V A T E  F U N C T I O N S /////////////////////////////////////////////////////////

#bool CRepository<T>::Enlarge() //////////////////// ENLARGE STORAGE /////////////////////
function Enlarge(object::CRepository)
    #REP_ADDRESS newsize=(N+1)*REPOSITORY_N_ENLARGE;
	#Typedef REPOSITORY_N_ENLARGE later
	newsize::Int = (object.N + 1)*10
	#if (newsize>REPOSITORY_N_MAX) newsize=REPOSITORY_N_MAX;
	if newsize > 1000000000
		newsize = 1000000000
	end
	#if (newsize<=N+1) return false;
	if newsize <= object.N + 1
		return false
	else
		# printf("Resizing Storage To %d\n",newsize);
		#T** itembuf=items;
		#itembuf::Array{Ptr{T}} = object.items
		#items=new T*[newsize];
		itembuf = Array{Ptr{Int}}(undef, newsize)
		@assert object.items != 1
		#memset(items,0,newsize*sizeof(T*));
		#memcpy(items,itembuf,N*sizeof(T*));
		object.items = copyto!(itembuf, object.items)
		#delete itembuf;

#Populate new items w/items and bigger size
		#REP_UID* idbuf=ids;
		idbuf = object.ids
		#ids = new REP_UID[newsize];
		@assert object.ids != 1
		#for (REP_ADDRESS i=N;i<newsize;i++) ids[i]=i;
		#memcpy(ids,idbuf,N*sizeof(REP_UID));
		b = zeros(newsize)
		copyto!(b,idbuf)
		#delete idbuf;
#Populate ids w/newIds and bigger size

		#REP_ADDRESS* numbuf=nums;
		#nums=new REP_ADDRESS[newsize];
		#assert(nums);
		@assert object.nums != 1
		numbuf = Array{Int}(undef, newsize)
		#for (REP_ADDRESS i=N;i<newsize;i++) nums[i]=i;
		#memcpy(nums,numbuf,N*sizeof(REP_ADDRESS));
		object.nums = copyto!(numbuf, object.nums)
		#delete numbuf;

		#object.count[object.C]+=newsize-object.N
		object.count[object.C] += newsize- object.N
		#object.N=newsize;
		object.N = newsize
		#return true;
		return true
	end
end



#void CRepository<T>::ClassIncrease(const REP_ADDRESS nNum,const REP_CLASS nClass)
function ClassIncrease(object::CRepository, nNum::Int, nClass::Int)
	#assert(nNum>=1 && nNum<N);
	@assert nNum >= 1 && nNum < object.N
	#assert(nClass>=1 && nClass<=C);
	@assert nClass >= 1 && nClass <= C
	#REP_CLASS cls=Class(nNum);
	cls::Int = Class(object, nNum)
	#REP_ADDRESS mynum=nNum;
	mynum::Int = nNum
	#REP_UID myid=ids[mynum];
	myid::Int = object.ids[mynum]
	#assert(cls<=nClass);
	@assert cls <= nClass
	#while (cls<nClass)						// Keep increasing
	while cls < nClass
		#First go to last pos in current group
		#REP_ADDRESS tarnum=offset[cls]+count[cls]-1;
		tarnum::Int = object.offset[cls] + object.count[cls] - 1
		#if (mynum!=tarnum)
		if nynum != tarnum
			#REP_UID idbuf=ids[tarnum];
			idbuf::Int = object.ids[tarnum]
			#ids[tarnum]=ids[mynum];
			object.ids[tarnum] = object.ids[mynum]
			#ids[mynum]=idbuf;
			object.ids[mynum] = idbuf
			#nums[myid]=tarnum;				// This is right cause we switched nums
			object.nums[myid] = tarnum
			#nums[idbuf]=mynum;
			object.nums[idbuf] = mynum
			#mynum=tarnum;
			mynum = tarnum
		end
		#count[cls]--;						// Now shift the boundary
		object.count[cls] -= 1
		#count[cls+1]++;
		object.count[cls+1] += 1
		#offset[cls+1]--;
		object.offset[cls+1] -= 1
		#cls++;
		cls += 1
	end
end


function ClassDecrease(object::CRepository,nNum::Int,nClass::Int) #REP_ADDRESS nNum,REP_CLASS nClass
	@assert(nNum>=1 && nNum<object.N)
	@assert(nClass>=1 && nClass <=object.C)
	cls::Int = Class_nNum(object, nNum) #REP_CLASS
	mynum::Int = nNum #REP_ADDRESS
	myid::Int =object.ids[mynum] #REP_UID
	@assert(cls>=nClass)
	while(cls>nClass) #//Keep decreasing
		tarnum::Int = object.offset[cls] #// First go to first pos in current group #REP_UID
		if (mynum!=tarnum)
			idbuf::Int = object.ids[tarnum] #REP_UID
			object.ids[tarnum] = object.ids[mynum]
			object.ids[mynum] = idbuf
			object.nums[myid] = tarnum
			object.nums[idbuf] = mynum
			mynum = tarnum
		end
		object.count[cls] -= 1
		object.count[cls-1] += 1
		object.offset[cls] += 1
		cls -= 1
	end
end

end
