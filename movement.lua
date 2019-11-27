local movement = {}


movement.Linear = {}

function movement.Linear:new(first, last, length)
  local newObj = {
    first = first,
    last = last,
    length = length,
    
    m = (last - first) / length,
    b = first,
    
    frame = 0,
  }
  
  self.__index = self
  return setmetatable(newObj, self)
end


function movement.Linear:valueAt(frame)
  return self.m * frame + self.b
end



movement.Sine = {}

function movement.Sine:newFadeIn(first, last, length)
  
  local newObj = {
    first = first,
    last = last,
    length = length,
    
    a = first - last,
    c = last,
    k = math.pi / (length * 2),
    d = -length,
    
    frame = 0,
    
  }
  
  self.__index = self
  return setmetatable(newObj, self)
end


function movement.Sine:newFadeOut(first, last, length)
  
  local newObj = {
    first = first,
    last = last,
    length = length,
    
    a = last - first,
    c = first,
    k = math.pi / (length * 2),
    d = 0,
    
    frame = 0,

  }
  
  self.__index = self
  return setmetatable(newObj, self)
end


function movement.Sine:valueAt(frame)
  return self.a * (math.sin(self.k * (frame - self.d))) + self.c
end


return movement

    