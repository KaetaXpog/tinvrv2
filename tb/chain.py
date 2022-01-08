import copy

class Data:
    def __init__(self,d):
        self.d=d
    def op(self,f):
        return Data(f(self.d))
    def unpack(self):
        return self.d

class Func:
    def __init__(self, f):
        self.f=f
        self.next=None
    def __call__(self, *args, **kwds):
        return self.f(*args, **kwds)
    def next(self, g):
        self.next=g
    def apply(self,d):
        if self.next==None:
            return self(d)
        else:
            return self.next(self(d))

class Chain(list,Data):
    def add(self,xs: list):
        return Chain(self+xs)
    def reverse(self):
        """TODO: replace this realization"""
        tmp=list(copy.deepcopy(self))
        tmp.reverse()
        return tmp
    def pad(self,cond,e):
        if cond(self):
            return self
        else:
            return Chain(self+[e]).pad(cond,e)
    def divide(self,blockSize):
        if len(self)==blockSize:
            return Chain([self])
        else:
            return Chain([self[:blockSize]]).add(
                Chain(self[blockSize:]).divide(blockSize)
            )
    def filter(self,cond):
        return Chain(filter(cond,self))
    def map(self,func):
        return Chain(map(func,self))
    def reduce(self,func):
        return Data(func(self))
    
def times(func,num):
    def f(xs):
        return func(xs)%num==0
    return f