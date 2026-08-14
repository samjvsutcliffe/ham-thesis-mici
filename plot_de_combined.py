import matplotlib.pyplot as plt
import pandas as pd
import json
import os,re
import numpy as np

#chalk_dir ="./"
chalk_dir = "/nobackup/rmvn14/thesis/mici/"
output_regex = re.compile("output-.*$")
#output_regex = re.compile("output-.*1.0$")
#output_regex = re.compile("output-.*-500.0.*$")
output_list = list(filter(output_regex.match,os.listdir(chalk_dir)))
output_list.sort()
with open(chalk_dir+output_list[0]+"/settings.json") as f:
    json_settings = json.load(f)
    thresh_energy = json_settings["CRITERIA-ENERGY"]
    thresh_oobf = json_settings["CRITERIA-OOBF"]
    tau = 1#json_settings["DELAY-TIME"]
#thresh_oobf = 1e-3
#tau = 1
fig,ax = plt.subplots()
ax_damage = ax.twinx()
#ax.set_ylim(0,thresh_energy*thresh_hist*2)
#ax.axhline(thresh_energy*(thresh_hist),c="green",ls="--")
#ax.axhline(thresh_energy/(thresh_hist),c="red",ls="--")
#ax.set_ylim(0,thresh_energy*thresh_hist*2)
ax.axhline(thresh_oobf,c="green",ls="--")

print(tau)
key_lines = []
key_labels = []
for i,out in enumerate(output_list):
    output_dir = chalk_dir + "./{}/".format(out)
    if os.path.isfile(output_dir+"timesteps.csv"):
        ms = out#out.split("_")[-1]
        df = pd.read_csv(output_dir+"timesteps.csv")
        time = df["time"].values/ (24 * 60 * 60)
        oobf = df["oobf"].values
        energy = df["energy"].values
        damage = df["damage"].values
        first = True
        first_time = -2
        #collapse = (energy > thresh_energy) | (oobf > thresh_oobf)
        #for i in range(len(df)-1):
        #    if collapse[i] != collapse[i+1] and first:
        #        ##Transition found
        #        first = False
        #        x = time[i+1]
        #        first_time=i+1
        #        ax_damage.scatter(time[i+1],damage[i+1],marker="x",c="black")
        l = ax_damage.plot(time,damage,label="s = {}".format(ms))
        key_lines.append(l[0])
        key_labels.append("s = {}".format(ms))
        colour = l[0].get_color()
        l = ax_damage.plot(time,damage,label="s = {}".format(ms),ls="--",color=colour,marker="x")
        #lss = ax.plot(time,oobf,label="s = {}".format(ms),ls="--",c=colour)
        quasi_point = None
        #for i in range(len(df)-1):
        #    if df["step-type"].iloc[i] == "COLLAPSE":
        #        if quasi_point == None:
        #            quasi_point = time[i]
        #    else:
        #        if quasi_point:
        #            plt.axvspan(quasi_point,time[i],alpha=0.25,color=colour)
        #            quasi_point = None
        #if quasi_point:
        #    plt.axvspan(quasi_point,time[i],alpha=0.25,color=colour)
ax_damage.set_ylabel("Mass-Damage (Kg)")
ax.set_xlabel("Time (days)")
ax.set_ylabel("Residual")
ax_damage.set_ylim(bottom=0,top=None)
print(key_lines)
ax_damage.legend(key_lines,key_labels)
ax.set_yscale("log")
plt.show()
