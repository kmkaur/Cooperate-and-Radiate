
# Code for processing the ant data, comparing the species list against
# the list of abstracts.
#
# The code is designed to minimize the number of comparisons needed
# per abstract. In its current manifestation, the code examines each
# abstract only once, comparing it to the list of species, but only
# scanning the abstract a single time.


from numpy import unique
import pandas as pd


###############################################################


def process_abstract(s):

    # this function will take the string, process the text, split into
    # a list, then group the list elements into pairs, then return the
    # new list.
    s2 = s.translate(None, '\t&*[]\n\\%.,()+-0123456789')
    
    # lower case and split
    s3 = s2.lower().split(' ')

    # remove empty entries
    s4 = [e for e in s3 if e != '']

    n = len(s4)

    l = []

    # Here we pair up the words into pairs, so that we can compare the
    # pairs of words to the species pairs of words.  If we need to
    # look at sub-species then we will need to keep sets of three
    # words.
    # This also allows us to look at trait terms in the text, since
    # the trait terms are all one or two words.
    
    for i in range(n-1):
        l.append(s4[i] + ' ' + s4[i+1])

    l.sort()
    s4.sort()

    # return only the unique word pairs, sorted.
    return unique(s4), unique(l)


###############################################################


def process_species(filename):

# first, process the species
    df = pd.read_csv(filename)

    # Get the species, lower case them, sort them, and remove
    # duplicates.
    species0 = df['current valid name'].map(lambda x: x.lower()).sort_values().drop_duplicates()

    indices = species0.index
    species = species0.values

    return species



###############################################################


def scan_abstract(abstract, species, abstract_index, result):

    # Because the abstract word pair (AWP) list has been sorted
    # alphabetically, and the species list is alphabetical, we can
    # scan through the AWP list and the species list 'simultaneously'.
    # This is in quotes because what we actually do is march down the
    # species list while the current species is 'ahead' in the
    # alphabet of the current AWP, then check to see if the species
    # name matches the AWP.  Then we march down the AWP list until the
    # current AWP is no longer ahead of the current species, and then
    # we check again.  We carry on this way until we run out of
    # species or run out of abstract.
    
    
    # the lengths of the species list and AWP list.
    len_abstract = len(abstract)
    len_species = len(species)

    # indices for holding the scan through the species and abstract.
    sindex = 0
    aindex = 0

    # add an empty entry in the results for this abstract
    result[abstract_index] = []
    
    if (len_abstract == 0):
        print 'Abstract', abstract_index, 'is empty'
        done = True
    else:
        done = False


    while (not done):
    
        # If either of the indices have reached their limit, we're
        # done.  Go once more through the code.
        if ((sindex == (len_species - 1)) or
            (aindex == (len_abstract - 1))): done = True
        
#        print abstract_index, len_abstract, len_species, aindex, sindex
        
        # March down the species list until the current species is no
        # longer ahead of the current AWP, alphabetically.
        while ((species[sindex] < abstract[aindex]) and
               sindex != (len_species - 1)): sindex += 1
            
        # Check to see if we have a winner.  If we do, save it and
        # increment the species by one.
        if (species[sindex] == abstract[aindex]):
#            print sindex, aindex, species[sindex], abstract[aindex]
            result[abstract_index].append(species[sindex])
            if (sindex != (len_species - 1)): sindex += 1
               
#        print len_abstract, aindex, len_species, sindex, species[sindex], abstract[aindex]
                   
        # March down the AWP list until the current AWP is no longer
        # ahead of the current species, alphabetically.
        while ((species[sindex] > abstract[aindex]) and
               aindex != (len_abstract - 1)): aindex += 1
                       
        # Check to see if we have a winner.  If we do, save it and
        # increment the AWP index by one.
        if (species[sindex] == abstract[aindex]):
#            print sindex, aindex, species[sindex], abstract[aindex]
            result[abstract_index].append(species[sindex])
            if (aindex != (len_abstract - 1)): aindex += 1
                           

    # if there were no results for this abstract, remove the entry
    if (result[abstract_index] == []): del result[abstract_index]


###############################################################


def analyze_abstracts(abstractfile, speciesfile):

    # get the species
    species = process_species(speciesfile)

    # open the abstract file
    f = open(abstractfile, 'r')
    
    # dictionary to hold the answers
    result = {}
    
    trait1 = ["efn", "efns", "elaiosome", "elaiosomes", "domatia", "domatium", "myrmecodomatia", "myrmecodomatium", "myrmecophyte", "myrmecophytes", "trichilium", "trichilia", "aril", "myrmecochory", "myrmecochorous", "myrmecochore", "myrmecochores", "extrafloral"]
    trait2 = ["foliar nectaries", "foliar nectary", "root tuber", "root tubers", "food body", "food bodies", "beltian body", "beltian bodies", "mullerian body", "mullerian bodies", "pearl body", "pearl bodies", "leaf pouch", "leaf pouches", "swollen thorn", "swollen thorns", "seed dispersal", "seed dispersing"]
    

    # index of the abstract being examined.
    abstract_index = 0

    # read the next line of the abstracts
    nextline = f.readline()

        
    # while the variable 'nextline' is non-empty, loop.
    while (nextline):

        # get the abstract.
        s = f.readline()
        
        #if s.strip():
            
        # clean it up
        abstract1, abstract2 = process_abstract(s)

        # do the scan.
        if (len(abstract2) != 0):
            
            scan_abstract(abstract2, species, abstract_index, result)
            
            for trait in trait1:
                if ((trait in abstract1) and
                    (abstract_index in result)):
                    if trait not in result:
                        result[trait] ={}
                    
                    result[trait][abstract_index]=result[abstract_index][:]
            
            
            for trait in trait2:
                if ((trait in abstract2) and
                    (abstract_index in result)):
                    if trait not in result:
                        result[trait] ={}
                    
                    result[trait][abstract_index]=result[abstract_index][:]
    
            # read the empty line.
            dummy = f.readline()

        # read the next line
        nextline = f.readline()

        # increment to the next abstract.
        abstract_index += 1


    # because it's good form.
    f.close()


    return result


