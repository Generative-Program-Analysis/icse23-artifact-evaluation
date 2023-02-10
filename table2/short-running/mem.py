import csv, re
import glob, os
import pandas as pd
#import matplotlib.pyplot as plt
#from matplotlib.backends.backend_pdf import PdfPages

path = os.getcwd()
#print(path)
os.chdir(path+"/klee")
file_reg = re.compile("klee-(.*)-0_raw\.log")
klee_mem_data = []
for file in glob.glob("klee-*-0_raw.log"):

    obj = re.match(file_reg, file)
    program= obj.group(1)

    #print (program)
    mem_file = open("klee-"+program+"-0_raw.log", mode='r')
    r_lines = reversed(mem_file.readlines())

    for line in r_lines:
      #print (line)
      temp_obj = re.search("Maximum\s+resident\s+set\s+size\s+\(kbytes\):\s+(\d+)", line.strip())
      if temp_obj:
        lastline = line
        #print ("found")
        break

    log_obj = re.search("Maximum\s+resident\s+set\s+size\s+\(kbytes\):\s+(\d+)", lastline.strip())
    klee_mem_data.append([program, log_obj.group(1)])

klee_df = pd.DataFrame(klee_mem_data,columns=['Program', 'Mem Usage'])
klee_df = klee_df.astype({'Program': str, 'Mem Usage':float})
klee_df['Mem Usage'] = (klee_df['Mem Usage'] / 1000000).apply(lambda x: round(x, 2))
#print (klee_df)

os.chdir(path)


os.chdir(path+"/gs")
file_reg = re.compile("gs-(.*)-0_raw\.log")
gs_mem_data = []
for file in glob.glob("gs-*-0_raw.log"):

    obj = re.match(file_reg, file)
    program= obj.group(1)

    #print (program)
    mem_file = open("gs-"+program+"-0_raw.log", mode='r')
    r_lines = reversed(mem_file.readlines())

    for line in r_lines:
      #print (line)
      temp_obj = re.search("Maximum\s+resident\s+set\s+size\s+\(kbytes\):\s+(\d+)", line.strip())
      if temp_obj:
        lastline = line
        #print ("found")
        break

    log_obj = re.search("Maximum\s+resident\s+set\s+size\s+\(kbytes\):\s+(\d+)", lastline.strip())
    gs_mem_data.append([program, log_obj.group(1)])

gs_df = pd.DataFrame(gs_mem_data,columns=['Program', 'Mem Usage'])
gs_df = gs_df.astype({'Program': str, 'Mem Usage':float})
gs_df['Mem Usage'] = (gs_df['Mem Usage'] / 1048576).apply(lambda x: round(x, 2))
#print (gs_df)

klee_df = klee_df.set_index("Program")
klee_df = klee_df.rename(columns={'Mem Usage' : 'Klee Mem Usage (GB)'})
gs_df = gs_df.set_index("Program")
gs_df = gs_df.rename(columns={'Mem Usage' : 'GenSym Mem Usage (GB)'})
mem_table = pd.concat([klee_df, gs_df], axis=1, sort=True)
print (mem_table)
print ("\nklee max memory: "+str(mem_table['Klee Mem Usage (GB)'].max()))
print ("\ngensym max memory: "+str(mem_table['GenSym Mem Usage (GB)'].max()))
os.chdir(path)