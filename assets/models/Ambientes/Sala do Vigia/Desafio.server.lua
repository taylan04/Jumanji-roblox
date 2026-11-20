local room=script.Parent
local players=game:GetService("Players")
local run=game:GetService("RunService")
local rng=Random.new()
local arena=room.Mecanismo
local statue,gate=arena.Vigia,arena.Entrada
local closedStatue=room:GetPivot():ToObjectSpace(statue:GetPivot())
local gateRest=CFrame.new(0,0,27)
local map=arena.Painel.Mapa
local sectors={}
for row=0,3 do
 for col=0,3 do
  local id=4*row+col+1
  local key=row..""..col
  local spikes=arena.Agulhas["Setor"..key]
  sectors[id]={p=spikes,rest=room:GetPivot():ToObjectSpace(spikes.CFrame),cell=map["Zona"..key]}
 end
end
local alive={}
local completed=false
local active=false
local teal=Color3.fromRGB(97,210,187)
local amber=Color3.fromRGB(224,133,94)
local idle=Color3.fromRGB(52,65,62)
local function cellAt(p)
 local row=math.clamp(math.floor((p.Z+26)/13),0,3)
 local col=math.clamp(math.floor((p.X+26)/13),0,3)
 return 4*row+col+1
end
local function location(char)
 local root=char and char:FindFirstChild("HumanoidRootPart")
 local h=char and char:FindFirstChildOfClass("Humanoid")
 if root and h and h.Health>0 then return room:GetPivot():PointToObjectSpace(root.Position),h end
end
local function inside(p)
 return p and math.abs(p.X)<26.65 and math.abs(p.Z)<26.55 and p.Y>-.4 and p.Y<36.5
end
local function roster(danger,tip)
 local count=0
 for player,char in pairs(alive) do
  local p,h=location(char)
  if player.Character~=char or not inside(p) then alive[player]=nil
  elseif danger and not danger[cellAt(p)] and p.Y<tip+3.3 then
   h.Health=0
   alive[player]=nil
  else count+=1 end
 end
 return count
end
local function animation(duration,update)
 local start=os.clock()
 repeat
  local t=math.min(1,(os.clock()-start)/duration)
  update(t)
  if t==1 then return end
  run.Heartbeat:Wait()
 until not room.Parent
end
local function gateHeight(height)
 gate:PivotTo(room:GetPivot()*CFrame.new(0,height,0)*gateRest)
end
local function pick(last)
 -- One refuge per quadrant. Its position changes independently on every wave.
 local safe={}
 for quadrant=0,3 do
  local row=2*math.floor(quadrant/2)
  local col=2*(quadrant%2)
  local choices={}
  for dr=0,1 do for dc=0,1 do
   local id=1+4*(row+dr)+col+dc
   if not last[id] then table.insert(choices,id) end
  end end
  safe[choices[rng:NextInteger(1,#choices)]]=true
 end
 return safe
end
local function board(safe,title)
 map.Leitura.Text=title
 for id,s in ipairs(sectors) do
  local code=string.char(65+math.floor((id-1)/4))..(1+(id-1)%4)
  s.cell.Text=code..(safe and (safe[id] and "  ○" or "  ×") or "")
  s.cell.BackgroundColor3=safe and (safe[id] and teal or amber) or idle
  s.cell.TextColor3=safe and Color3.fromRGB(26,24,22) or Color3.fromRGB(199,186,146)
 end
end
local fixtures={}
for _,p in ipairs(room.Luzes:GetChildren()) do
 local light=p:FindFirstChildOfClass("PointLight")
 if light and p.Name~="Mapa" then table.insert(fixtures,{light=light,base=light.Brightness}) end
end
local dust=arena.Poeira:GetDescendants()
local function shake(seconds)
 room:SetAttribute("TremorDuracao",seconds)
 room:SetAttribute("TremorInicio",workspace:GetServerTimeNow())
 for _,e in ipairs(dust) do
  if e:IsA("ParticleEmitter") then e.Enabled=true;e:Emit(3) end
 end
end
local function flicker(elapsed)
 for i,f in ipairs(fixtures) do
  local dip=math.max(0,math.sin(elapsed*9.4+i*1.3))^6
  f.light.Brightness=f.base*(1-.68*dip)
 end
end
local function calm()
 room:SetAttribute("TremorInicio",nil)
 for _,e in ipairs(dust) do if e:IsA("ParticleEmitter") then e.Enabled=false end end
 for _,f in ipairs(fixtures) do f.light.Brightness=f.base end
end
local function spikes(safe,height)
 local base=room:GetPivot()*CFrame.new(0,height,0)
 for i,s in ipairs(sectors) do
  if not safe[i] then s.p.CFrame=base*s.rest end
 end
end
local function openExit()
 room:SetAttribute("Estado","Abrindo passagem")
 board(nil,"O VIGIA CEDE PASSAGEM")
 shake(5.4)
 animation(5.4,function(t)
  local distance=11.0*(t^3*(10-15*t+6*t*t))
  statue:PivotTo(room:GetPivot()*CFrame.new(distance,0,0)*closedStatue)
  flicker(t*5.4)
 end)
 calm()
 completed=true
 room:SetAttribute("Estado","Concluido")
 board(nil,"PASSAGEM LIBERADA")
 arena.Saida.Luz.Enabled=true
end
local function challenge()
 -- Activation waits while friends cross the threshold. Never close the entrance on a player.
 room:SetAttribute("Estado","Reunindo")
 board(nil,"ENTREM NA SALA")
 task.wait(2.5)
 for _,player in ipairs(players:GetPlayers()) do
  local char=player.Character
  local p=location(char)
  if inside(p) then alive[player]=char end
 end
 if roster()>0 then
  gateHeight(0)
  room:SetAttribute("Estado","Em jogo")
  local last={}
  for wave=1,4 do
   local safe=pick(last)
   last=safe
   board(safe,"RODADA "..wave.." / 4")
   local warning=5.8
   shake(warning)
   animation(warning,function(t) flicker(t*warning) end)
   calm()
   if roster()==0 then break end
   animation(.43,function(t)
    local height=6.49*(1-(1-t)^2)
    spikes(safe,height)
    if height>.45 then roster(safe,height-.06) end
   end)
   animation(1.45,function() roster(safe,6.43) end)
   animation(.90,function(t)
    local height=6.49*(1-t*t*(3-2*t))
    spikes(safe,height)
    if height>.45 then roster(safe,height-.06) end
   end)
   if roster()==0 then break end
   task.wait(.70)
  end
  if roster()>0 then openExit() end
 end
 gateHeight(10.1)
 table.clear(alive)
 if not completed then board(nil,"ENTRE PARA INICIAR");room:SetAttribute("Estado","Aguardando") end
 active=false
end
gateHeight(10.1)
board(nil,"ENTRE PARA INICIAR")
room:SetAttribute("Estado","Aguardando")
while room:IsDescendantOf(workspace) and not completed do
 if not active then
  for _,player in ipairs(players:GetPlayers()) do
   local p=location(player.Character)
   if inside(p) and p.Z<24.8 then
    active=true
    task.spawn(challenge)
    break
   end
  end
 end
 task.wait(.12)
end

