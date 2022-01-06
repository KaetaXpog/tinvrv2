from typing import List
import chain
import argparse

from tb.chain import times

def hexFormat(i:int,length:int)->str:
    res=hex(i)
    if(len(res)-2<length):
        res=res[:2]+(length-len(res)+2)*'0'+res[2:]
    return res

class GenRAMData:
    def __init__(self):
        pass
    def gendata(self)->List:
        res=[]
        for i in range(1024):
            res.append(hexFormat(i%256,2))
        return res
    def organizeData(self,data)->str:
        res=""
        slot=[]
        for i in data:
            slot.append(i[2:])
            if(len(slot)==16):
                slot.reverse()
                print(slot)
                res=res+"".join(slot)+'\n'
                slot=[]
        return res
    def writeToFile(self,data,fname):
        with open(fname,'w') as f:
            f.write(data)
    def do(self,fname):
        self.writeToFile(self.organizeData(self.gendata()),fname)

def organizeDataFrom32bTo128b(ifname,ofname):
    lines=[]
    with open(ifname) as ifile:
        lines=ifile.readlines()
    lines=chain.Chain(lines).filter(
        lambda x:x!="").map(
            str.strip).pad(
                chain.times
if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('-g','--gen_cache',help='gen cache hex file')
    parser.add_argument('-r','--reorder',help='reorganize code to 128bits')
    args=parser.parse_args()
    if args.gen_chche:
        GenRAMData().do('../build/cram.hex')
    if args.reorder:

