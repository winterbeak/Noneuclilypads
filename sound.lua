local sound = {}

MAX_CONCURRENT = 3


function sound.load(path, volume, isStatic)
  local source
  
  if isStatic then
    source = love.audio.newSource("sounds/" .. path, "static")
  else
    source = love.audio.newSource("sounds/" .. path, "stream")
  end
  
  source:setVolume(volume)
  
  return source
end


sound.SoundEffect = {}

function sound.SoundEffect:new(path, volume)
  local newObj = {
    volume = volume,
    sources = {sound.load(path, volume, true)},
  }
  
  self.__index = self
  return setmetatable(newObj, self)
end


function sound.SoundEffect:newSource()
  table.insert(self.sources, self.sources[1]:clone())
end


--- Plays the sound effect.
-- If pitch is left as nil, this randomly picks a pitch between 0.9 and 1.1.
function sound.SoundEffect:play(pitch)
  pitch = pitch or 1 + (math.random() * 0.2 - 0.1)
  
  local foundSource
  
  for i = 1, #self.sources do
    if not self.sources[i]:isPlaying() then
      self.sources[i]:setPitch(pitch)
      self.sources[i]:play()
      foundSource = true
      break
    end
  end
  
  if not foundSource then
    if #self.sources < MAX_CONCURRENT then
      self:newSource()
      self.sources[#self.sources]:setPitch(pitch)
      self.sources[#self.sources]:play()
    end
  end
  
end


function sound.SoundEffect:stop()
  for i = 1, #self.sources do
    self.sources[i]:stop()
  end
end


sound.SoundSet = {}

--- Paths must be of the form pathStart .. soundCount .. pathEnd
function sound.SoundSet:new(pathStart, soundCount, pathEnd, volume)
  local path
  local newObj = {
    soundEffects = {}
  }
  
  for i = 1, soundCount do
    path = pathStart .. i .. pathEnd
    newObj.soundEffects[i] = sound.SoundEffect:new(path, volume)
  end
  
  self.__index = self
  return setmetatable(newObj, self)
end


function sound.SoundSet:playRandom(pitch)
  local effectNum = math.random(1, #self.soundEffects)
  self.soundEffects[effectNum]:play(pitch)
end


function sound.SoundSet:playID(num, pitch)
  self.soundEffects[num]:play(pitch)
end


function sound.SoundSet:stop()
  for i = 1, #self.soundEffects do
    self.soundEffects[i]:stop()
  end
end


sound.FadableSound = {}

function sound.FadableSound:new(path, maxVolume, looping)
  local newObj = {
    source = sound.load(path, 1, false),
    
    maxVolume = maxVolume,
    volume = maxVolume,
    targetVolume = maxVolume,
    
    fadingUp = false,
    fadingDown = false,
  }
  
  if looping then
    newObj.source:setLooping(true)
  end
  
  newObj.source:setVolume(maxVolume)
  
  self.__index = self
  return setmetatable(newObj, self)
end


function sound.FadableSound:fadeTo(volume)
  self.fadingUp = false
  self.fadingDown = false
  
  if self.volume < volume then
    self.fadingUp = true
  elseif self.volume > volume then
    self.fadingDown = true
  end
  
  self.targetVolume = volume
end


function sound.FadableSound:setVolume(volume)
  if volume > self.maxVolume then
    volume = self.maxVolume
  end
  
  self.volume = volume
  self.source:setVolume(volume)
end


function sound.FadableSound:update()
  
  if self.fadingUp then
    self.volume = self.volume + 0.02
    
    if self.volume > self.targetVolume then
      self.volume = self.targetVolume
      self.fadingUp = false
    end
    
    if self.volume > self.maxVolume then
      self.volume = self.maxVolume
      self.fadingUp = false
    end
    
    self.source:setVolume(self.volume)
    
  elseif self.fadingDown then
    self.volume = self.volume - 0.02
    
    if self.volume < self.targetVolume then
      self.volume = self.targetVolume
      self.fadingDown = false
    end
    
    self.source:setVolume(self.volume)
    
  end
  
end


function sound.FadableSound:play()
  self.source:play()
end


return sound