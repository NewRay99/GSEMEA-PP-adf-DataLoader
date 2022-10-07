from read_kv import read_kv
import json

SYSTEM_STAGEDISPLAYNAME = "dev"

print("##SYSTEM_STAGEDISPLAYNAME:  " + SYSTEM_STAGEDISPLAYNAME)


kv = read_kv(SYSTEM_STAGEDISPLAYNAME, './kv.json')

for k, v in kv.items():
    #print(f"{k} == {v[0]} == {v[1]}")
    print(f"##vso[task.setvariable variable={k}]{v}")
    # print(f"##vso[task.setvariable variable={k}type]{v[0]}")
