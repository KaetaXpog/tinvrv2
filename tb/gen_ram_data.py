from typing import List


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

if __name__=='__main__':
    GenRAMData().do('../build/cram.hex')