import csv, re
import glob, os
import pandas as pd
#import matplotlib.pyplot as plt
#from matplotlib.backends.backend_pdf import PdfPages

path = os.getcwd()
#print(path)
os.chdir(path+"/klee")
file_reg = re.compile("klee-(.*)\.csv")
data = []
for file in glob.glob("klee-*.csv"):
    obj = re.match(file_reg, file)
    program= obj.group(1)

    # get coverage
    gcov_file = open(program+"_gcov.log", mode='r')
    gcov_line = 0
    gcov_name = program
    if program == "base32" or program == "base64":
      gcov_name = "basenc"
    lines = gcov_file.readlines()
    for line in lines:
      gcov_obj = re.search("File\s+'.*{0}.c'".format(gcov_name), line.strip())
      if gcov_obj:
        break
      gcov_line += 1
    gcov_data = lines[gcov_line+1]
    gcov_obj = re.search("Lines\s+executed:([+-]?[0-9]+\.[0-9]+)%\s+of\s+(\d+)", gcov_data.strip())
    gcov_cov_percentage = gcov_obj.group(1)

    #print(gcov_file)
    for dir in glob.glob("klee-"+program+"-*"):
        dir_obj = re.match("klee-"+program+"-(\d+)$", dir)
        if (dir_obj):
            num = dir_obj.group(1)
            info_file = open(dir+"/info", mode='r')
            content = info_file.read()
            completed_path_obj = re.search("KLEE:\s+done:\s+completed\s+paths\s+=\s+(\d+)", content)
            partial_path_obj = re.search("KLEE:\s+done:\s+partially\s+completed\s+paths\s+=\s+(\d+)", content)
            test_num_obj = re.search("KLEE:\s+done:\s+generated\s+tests\s+=\s+(\d+)", content)
            completed_path_num = completed_path_obj.group(1)
            partial_path_num = partial_path_obj.group(1)
            test_num = test_num_obj.group(1)
            data.append([program, gcov_cov_percentage, num, completed_path_num, partial_path_num, test_num])
df = pd.DataFrame(data,columns=['Program', 'LineCov', 'Run', 'CompletePath' ,'PartialPath', 'TestNum'])
df = df.astype({'Program': str, 'LineCov':float, 'Run': int, 'CompletePath': int ,'PartialPath' : int, 'TestNum' : int})
dict = {}
for x, y in df.groupby("Program"):
    dict[x] = y.reset_index(level=[0]).sort_values('Run').drop(['index','Run'], axis = 1)
programs=list(dict.keys())
#print(programs)

#print(os.getcwd())
os.chdir(path+"/klee")
for prog in programs:
    df = pd.read_csv("klee-"+prog+".csv")
    #df = df.convert_dtypes(False, True, False, False, False)
    df = df.drop(['Instructions', 'FullBranches', 'PartialBranches', 'NumBranches', 'NumStates',
                  'MallocUsage', 'NumQueries', 'NumQueryConstructs', 'CoveredInstructions',
                  'UncoveredInstructions', 'QueryCexCacheMisses', 'QueryCexCacheHits', 'ArrayHashTime'], axis=1)
    df = df / 1000000.0
    df['ExeTime'] = df['WallTime'] - df['SolverTime']
    dict[prog] = pd.concat([dict[prog], df], axis=1)
    #print(dict[prog])
os.chdir(path)

os.chdir(path+"/gs")
gs_dict = {}
for prog in programs:
    gs_data = []

    # get coverage
    gcov_file = open(prog+"_gcov.log", mode='r')
    gcov_line = 0
    gcov_name = prog
    if prog == "base32" or prog == "base64":
      gcov_name = "basenc"
    lines = gcov_file.readlines()
    for line in lines:
      gcov_obj = re.search("File\s+'.*{0}.c'".format(gcov_name), line.strip())
      if gcov_obj:
        break
      gcov_line += 1
    gcov_data = lines[gcov_line+1]
    gcov_obj = re.search("Lines\s+executed:([+-]?[0-9]+\.[0-9]+)%\s+of\s+(\d+)", gcov_data.strip())
    gcov_cov_percentage = gcov_obj.group(1)

    for dir in glob.glob("gs-"+prog+"-*"):
        dir_obj = re.match("gs-"+prog+"-(\d+)_raw.log$", dir)
        if (dir_obj):
            num = dir_obj.group(1)
            info_file = open(dir, mode='r', encoding='utf-8', errors='ignore')

            r_lines = reversed(info_file.readlines())

            for line in r_lines:
              temp_obj = re.search("\[([^s]+)s/([^s]+)s/([^s]+)s/([^s]+)s\] #blocks: (\d+)/(\d+); #br: (\d+)/(\d+)/(\d+); #paths: (\d+); .+; #queries: (\d+)/(\d+) \((\d+)\)", line.strip())
              if temp_obj:
                lastline = line
                break

            log_obj = re.search("\[([^s]+)s/([^s]+)s/([^s]+)s/([^s]+)s\] #blocks: (\d+)/(\d+); #br: (\d+)/(\d+)/(\d+); #paths: (\d+); .+; #queries: (\d+)/(\d+) \((\d+)\)", lastline.strip())
            gs_data.append([prog, gcov_cov_percentage, num, log_obj.group(10), log_obj.group(12), log_obj.group(1), log_obj.group(2), log_obj.group(4)])

    df = pd.DataFrame(gs_data,columns=['Program', 'LineCov', 'Run', 'Path' ,'TestNum', 'QueryTime',  'SolverTime', 'WallTime'])
    #df = df.convert_dtypes(False, True, False, False, False)
    df = df.astype({'Program': str, 'LineCov':float, 'Run': int, 'Path': int ,'TestNum' : int, 'QueryTime' : float, 'SolverTime' : float, 'WallTime' : float})
    df['ExeTime'] = df['WallTime'] - df['SolverTime']
    gs_dict[prog] = df.sort_values('Run').drop(['Run'], axis = 1)
    #print(gs_dict[prog])
os.chdir(path)

for prog in programs:
    new_df = dict[prog].drop(['CexCacheTime', 'ForkTime', 'ResolveTime'], axis=1)
    new_df['Path'] = new_df['CompletePath'] + new_df['PartialPath']
    new_df = new_df.astype({'Program': str, 'Path': int, 'LineCov':float, 'TestNum' : int, 'QueryTime' : float, 'SolverTime' : float, 'WallTime' : float})
    new_df = new_df.drop(['CompletePath', 'PartialPath'], axis=1)
    new_df = new_df[['Program', 'Path', 'LineCov',  'QueryTime',  'SolverTime',  'ExeTime', 'WallTime']]
    new_df['LineCov'] = new_df['LineCov'].apply(lambda x: round(x, 2))
    new_df['QueryTime'] = new_df['QueryTime'].apply(lambda x: round(x, 2))
    new_df['SolverTime'] = new_df['SolverTime'].apply(lambda x: round(x, 2))
    new_df['WallTime'] = new_df['WallTime'].apply(lambda x: round(x, 2))
    new_df['ExeTime'] = new_df['ExeTime'].apply(lambda x: round(x, 2))
    if (prog == programs[0]) :
        klee_table = new_df
    else :
        klee_table = pd.concat([klee_table, new_df], axis=0, ignore_index=True)

for prog in programs:
    new_df = gs_dict[prog]
    new_df = new_df.astype({'Program': str, 'Path': int, 'LineCov':float, 'TestNum' : int, 'QueryTime' : float, 'SolverTime' : float, 'WallTime' : float})
    new_df = new_df[['Program', 'Path', 'LineCov',  'QueryTime',  'SolverTime',  'ExeTime', 'WallTime']]
    new_df['LineCov'] = new_df['LineCov'].apply(lambda x: round(x, 2))
    new_df['QueryTime'] = new_df['QueryTime'].apply(lambda x: round(x, 2))
    new_df['SolverTime'] = new_df['SolverTime'].apply(lambda x: round(x, 2))
    new_df['WallTime'] = new_df['WallTime'].apply(lambda x: round(x, 2))
    new_df['ExeTime'] = new_df['ExeTime'].apply(lambda x: round(x, 2))
    if (prog == programs[0]) :
        gs_table = new_df
    else :
        gs_table = pd.concat([gs_table, new_df], axis=0, ignore_index=True)
#print("\n####klee\n")
klee_table=klee_table.set_index("Program")
klee_table = klee_table.rename(columns={'Path': 'klee-Path', 'LineCov': 'klee-LineCov', 'QueryTime': 'klee-QueryTime', 'SolverTime': 'klee-SolverTime', 'ExeTime': 'klee-ExeTime', 'WallTime': 'klee-WallTime'})
#print(klee_table)
klee_table.to_csv('klee_table.csv')
#print("\n####gs\n")
gs_table=gs_table.set_index("Program")
#print(gs_table)
gs_table = gs_table.rename(columns={'Path': 'gensym-Path', 'LineCov': 'gensym-LineCov', 'QueryTime': 'gensym-QueryTime', 'SolverTime': 'gensym-SolverTime', 'ExeTime': 'gensym-ExeTime', 'WallTime': 'gensym-WallTime'})
gs_table.to_csv('gs_table.csv')

total_table = pd.concat([klee_table, gs_table], axis=1)
total_table['Exec Speedup'] = (total_table['klee-ExeTime'] / total_table['gensym-ExeTime']).apply(lambda x: round(x, 2))
total_table['Whole Speedup'] = (total_table['klee-WallTime'] / total_table['gensym-WallTime']).apply(lambda x: round(x, 2))

total_table['klee-LineCov'] = total_table['klee-LineCov'].astype(str)
total_table['klee-LineCov'] = total_table['klee-LineCov'] + '%'
total_table['gensym-LineCov'] = total_table['gensym-LineCov'].astype(str)
total_table['gensym-LineCov'] = total_table['gensym-LineCov'] + '%'

total_table['Exec Speedup'] = total_table['Exec Speedup'].astype(str)
total_table['Exec Speedup'] = total_table['Exec Speedup'] + 'x'
total_table['Whole Speedup'] = total_table['Whole Speedup'].astype(str)
total_table['Whole Speedup'] = total_table['Whole Speedup'] + 'x'

print(total_table)
total_table.to_csv("short-running.csv")