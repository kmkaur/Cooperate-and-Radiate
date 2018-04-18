
# this script is going to pre-process the abstracts to check for
# duplicates.

from numpy import unique


###############################################################


def find_single(l):
    # This function returns the first single-character entry.  This
    # probably corresponds to the first initial of the first author,
    # indicating the end of the title.
    index = -1
    for i in range(len(l)):
        if len(l[i].strip()) == 1:
            index = i
            break

    return index


###############################################################


def get_FORMIS_title(s):

    # This function takes the input string from the FORMIS abstracts
    # and returns the title.
    
    # We need several lines of attack here.  First, if there's
    # anything in quotes, it's the title.  Let's check for that first.
    if (s.count('"') == 2):
        
        # That was easy.
        title = s.split('"')[1]
        author = s.split('"')[0]
        
    else:
    
        # First get rid of the author.  The title starts when the year
        # ends.  The year takes the form "(2015)."
        s2 = s.split(").", 1)

        # If we got an empty string, return.
        if (len(s2) == 1): return '', ''

        author = s2[0] + ")."
        s2 = s2[1]
        
        # Check to see if the word "Ph.D." is left.  If it is, it
        # represents the end of the title.
        if ("Ph.D" in s2):

            title = s2.split("Ph.D")[0].strip()
            if title[-1] == ",":
                title = title[0:-1] + '.'

        elif ("M.Sc" in s2):

            title = s2.split("M.Sc")[0].strip()
            if title[-1] == ",":
                title = title[0:-1] + '.'

        elif ("PhD" in s2):

            title = s2.split("PhD")[0].strip()
            if title[-1] == ",":
                title = title[0:-1] + '.'

        elif ("Tesi Doctoral" in s2):

            title = s2.split("Tesi Doctoral")[0].strip()
            if title[-1] == ",":
                title = title[0:-1] + '.'

        elif ("Thesis Doctoral" in s2):

            title = s2.split("Thesis Doctoral")[0].strip()
            if title[-1] == ",":
                title = title[0:-1] + '.'

        elif ("Tesis" in s2):

            title = s2.split("Tesis")[0].strip()
            if title[-1] == ",":
                title = title[0:-1] + '.'

        elif ("Dissertation" in s2):

            title = s2.split("Dissertation")[0].strip()
            if title[-1] == ",":
                title = title[0:-1] + '.'

        elif ("vol." in s2):
            
            s3 = s2.split('vol.')[0]
            title = s3.split(',')[0] + '.'
            
        elif ("Proceedings" in s2):

            title = s2.split('Proceedings')[0].strip()
            if len(title) == 0: return author, ''
            if title[-1] == ",":
                title = title[0:-1] + '.'
            
        elif ("[Resumos" in s2):
            
            title = s2.split('[Resumos')[0].strip()
            if title[-1] == ",":
                title = title[0:-1] + '.'
            
        elif ("[abstract]" in s2):

            title = s2.split('[abstract]')[0].strip()
            if title[-1] == ",":
                title = title[0:-1] + '.'
            
        elif ("In:" in s2):

            title = s2.split('In:')[0].strip()
            if title[-1] == ",":
                title = title[0:-1] + '.'
            
        else:
            
            # Now split on the periods.  The first initial of the
            # author should be the end of the title.
            s3 = s2.split('.')
            i = find_single(s3)

            if (i == -1):
                # If there is no single-character author then just
                # take the first block as the title.
                title = s3[0] + '.'
            else:
                title = ".".join(s3[0:i]) + "."

    return author, title.strip()
    
    
###############################################################


def get_springer_title(s):

    # This function takes the first line of the springer abstracts and
    # strips out the title, which is mostly trivial.

    # Remove leading whitespace.
    s2 = s.strip()

    # Remove the 'TITLE' flag.
    s3 = s2[6:]

    # If there's any HTML code in the title, remove it.
    while (s3.find("<") != -1) and (s3.find(">") != -1):
        s3 = s3[0:s3.find("<")] + s3[s3.find(">") + 1:]

    s4 = s3.replace("_", "")
    s4 = s4.replace("&gt;", ">")
    title = s4.replace("$$", "")
    
    return title.strip()
   
    
###############################################################


def clean_springer_abstract(s):

    # This function cleans the springer abstract.

    # Remove leading whitespace.
    s2 = s.strip()

    # Remove the 'ABSTRACT' flag.
    s3 = s2[9:]

    # If there's any HTML code in the abstract, remove it.
    while (s3.find("<") != -1) and (s3.find(">") != -1):
        s3 = s3[0:s3.find("<")] + ' ' + s3[s3.find(">") + 1:]

    s4 = s3.replace("_", "")
    s4 = s4.replace("&gt;", ">")
    abstract = s4.replace("$$", "")

    # Reduce the amount of whitespace which might have been introduced
    # by removing the HTML.
    while (abstract.count("  ") != 0):
        abstract = abstract.replace("  ", " ")

    return abstract.strip()


###############################################################


def write_title(title, titles, g, abstract):

    # This function writes the title and abstract to file.
    
    if title != '':
        if (title not in titles):

            titles.append(title)
            g.write(title)
            g.write('\n')
            g.write(abstract)
            g.write('\n')
            if (len(abstract.strip()) > 0):
                g.write('\n')
                
            
###############################################################


f = open('FORMIS_all_abstracts.txt', 'r')
g = open('abstracts_all.txt', 'w')

# Read the first author line of the FORMIS abstracts.
nextline = f.readline()

# This list of titles.
titles = []

# while the variable nextline is not empty.
while (nextline):

    # Get the FORMIS abstract.
    abstract = f.readline().strip()

    if abstract.startswith("*["):
        abstract = abstract[2:]
    if abstract.endswith("]"):
        abstract = abstract[:-1]
    
    # get the author and title
    author, title = get_FORMIS_title(nextline)

    # Write to file.
    write_title(title, titles, g, abstract)
    
    # Check for no abstract.
    if (len(abstract.strip()) > 0):

        # read the empty line.
        dummy = f.readline()

    # read the next author line
    nextline = f.readline()

            
print 'length of titles is', len(titles)
    
# because it's good form.
f.close()


# Now do the Springer abstracts.
f = open('springer_all_abstracts.txt', 'r')

# Get the first line.
nextline = f.readline().strip()

# while the variable nextline is not empty.
while (nextline):

    # get the abstract.
    abstract = f.readline().strip()

    # If there is no abstract, keep trying until you get one.
    while (abstract[0:8] != "ABSTRACT") and (nextline):
        nextline = abstract
        abstract = f.readline().strip()

    # Clean the abstract.
    abstract = clean_springer_abstract(abstract)

    # Get the title.
    title = get_springer_title(nextline)

    # Write to file.
    write_title(title, titles, g, abstract)

    # Read the next line.
    nextline = f.readline().strip()

    
f.close()
g.close()
