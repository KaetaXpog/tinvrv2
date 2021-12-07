import sys, os

class GenASM:
    def __init__(self):
        self.asm=""
    def setReg(self,regnum,value):
        self.asm+="addi ${}, $0, {}\n".format(regnum,value)
    def writeToFile(self,fname):
        with open(fname,'w') as f:
            f.write(self.asm)
    
if __name__=='__main__':
    os.chdir(os.path.dirname(sys.argv[0]))
    ga=GenASM()
    [ga.setReg(i,0) for i in range(1,32)]
    ga.writeToFile('ri.s')