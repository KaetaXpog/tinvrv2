import chain
import argparse
from chain import Chain

def hexFormat(i:int,length:int)->str:
    res=hex(i)
    if(len(res)-2<length):
        res=res[:2]+(length-len(res)+2)*'0'+res[2:]
    return res

class GenRAMData:
    def __init__(self):
        pass
    def gendata(self)->list:
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
    print(len(lines))
    lines=chain.Chain(lines).filter(lambda x:x!=""
        ).map(str.strip).pad(chain.times(len,4),'0'*32
        ).divide(4).map(chain.Chain.reverse)
    lines=chain.Chain(lines).map(
        lambda xs: "".join(xs)+"\n").reduce(
            lambda xs: "".join(xs))
    with open(ofname,'w') as ofile:
        ofile.write(lines.unpack())
if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('-g','--gen_cache',
        action='store_true',help='gen cache hex file')
    parser.add_argument('-r','--reorder',
        action='store_true',help='reorganize code to 128bits')
    parser.add_argument('--ifname',help='input file name')
    parser.add_argument('-o','--ofname',help='output file name')
    args=parser.parse_args()
    if args.gen_cache:
        GenRAMData().do('../build/cram.hex')
    if args.reorder:
        assert args.ifname!=None and args.ofname!=None
        # organizeDataFrom32bTo128b("./build/code.bin",
        #     "./build/code.128b"
        # )
        organizeDataFrom32bTo128b(
            args.ifname,
            args.ofname
        )
