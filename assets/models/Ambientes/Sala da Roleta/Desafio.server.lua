local room=script.Parent
local players=game:GetService("Players")
local heartbeat=game:GetService("RunService").Heartbeat
local rng=Random.new()
local arena=room.Arena
local labels={"Quadrado","Triângulo","Estrela","Círculo","Olho","Espiral"}
local colors={Color3.fromRGB(249,119,92),Color3.fromRGB(99,158,255),Color3.fromRGB(255,214,95),Color3.fromRGB(115,226,159),Color3.fromRGB(230,132,222),Color3.fromRGB(245,155,91)}
local function localFrame(x,y,z) return room:GetPivot()*CFrame.new(x,y,z) end
local function position(char)
 local root=char and char:FindFirstChild("HumanoidRootPart")
 local hum=char and char:FindFirstChildOfClass("Humanoid")
 if root and hum and hum.Health>0 then return room:GetPivot():PointToObjectSpace(root.Position),hum end
end
local function move(char,x,y,z,north)
 local target=localFrame(x,y,z)
 char:PivotTo(north and target or target*CFrame.Angles(0,math.pi,0))
 local root=char:FindFirstChild("HumanoidRootPart")
 if root then root.AssemblyLinearVelocity=Vector3.zero end
end
local function gate(name,open)
 local m=arena[name]
 m:PivotTo(localFrame(0,52+(open and 9.3 or 0),27))
 m.Colisor.CanCollide=not open
end
local plates=arena.Placas:GetChildren()
local function tilt(tile,k)
 local hinge=room:GetPivot()*tile:GetAttribute("Dobradica")
 tile:PivotTo(hinge*CFrame.Angles(-1.51*k,0,0))
end
local function animate(duration,fn)
 local start=os.clock()
 repeat
  local t=math.min((os.clock()-start)/duration,1)
  fn(t)
  if t==1 then break end
  heartbeat:Wait()
 until not room.Parent
end
local dial=arena.Roleta
local angle=0
local function spinAt(a)
 dial:PivotTo(localFrame(0,52,-25)*CFrame.Angles(0,0,a))
end
local indicator=room.Luzes.Ponteiro.PointLight
local wash=room.Luzes.Leitura.PointLight
local display=arena.Painel.Mostrador.Texto
local function sound(name)
 local id=tostring(room:GetAttribute(name.."Id") or ""):match("%d+")
 if not id or id=="0" then return end
 local s=arena.Painel[name]
 s.SoundId="rbxassetid://"..id
 s:Play()
end
local lens=room.Visual:WaitForChild("Ponteiro__Marfim")
local coating=lens:FindFirstChildWhichIsA("SurfaceAppearance")
local function tint(color)
 indicator.Color=color
 if coating then coating.Color=color else lens.Color=color end
end
local function bridge(open)
 local model=arena.Passarela
 model:PivotTo(localFrame(0,52,27)*CFrame.Angles(open and 0 or -math.pi/2,0,0))
 model.Colisor.CanCollide=open
end
local function setPhase(s)
 room:SetAttribute("Estado",s)
end
local active=false
local solved=false
local function round()
 setPhase("Em jogo")
 local deadline=os.clock()+40
 local last=-1
 for r=1,4 do
  local pick=rng:NextInteger(0,5)
  if pick==last then pick=(pick+rng:NextInteger(1,5))%6 end
  last=pick
  local from=angle
  local sector=pick+6*rng:NextInteger(0,1)
  local target=2*math.pi+(sector*math.pi/6-from)%(2*math.pi)+from
  display.Text="◆   "..r.." / 4   ◆"
  tint(Color3.fromRGB(239,202,139))
  sound("Roleta")
  animate(2.3,function(t)
   local a=from+(target-from)*(1-(1-t)^2)
   spinAt(a)
   tint(colors[math.floor(a/(math.pi/6)+.5)%6+1])
  end)
  angle=sector*math.pi/6
  spinAt(angle)
  room:SetAttribute("Simbolo",labels[pick+1])
  display.Text=labels[pick+1]
  tint(colors[pick+1])
  wash.Color=Color3.fromRGB(238,217,189):Lerp(colors[pick+1],.62)
  task.wait(4.3)
  local wrong={}
  for _,tile in ipairs(plates) do
   if tile:GetAttribute("Simbolo")~=pick then
    table.insert(wrong,tile)
    tile.Colisor.CanCollide=false
   end
  end
  sound("Alcapao")
  animate(.43,function(t) for _,tile in ipairs(wrong) do tilt(tile,t*t) end end)
  task.wait(1.55)
  animate(.60,function(t) for _,tile in ipairs(wrong) do tilt(tile,1-t) end end)
  for _,tile in ipairs(wrong) do tile.Colisor.CanCollide=true end
  task.wait(math.max(.02,deadline-(4-r)*10-os.clock()))
 end
 local survivor=false
 for _,p in ipairs(players:GetPlayers()) do
  local v=position(p.Character)
  if v and math.abs(v.X)<18.5 and math.abs(v.Z)<22.5 and v.Y>=51 and v.Y<82 then survivor=true end
 end
 solved=survivor
 bridge(solved)
 gate("PortaoN",solved)
 wash.Color=solved and Color3.fromRGB(152,225,173) or Color3.fromRGB(239,187,128)
 display.Text=solved and "PASSAGEM ABERTA" or "◆"
 setPhase(solved and "Concluido" or "Aguardando")
 active=false
end
bridge(false)
gate("PortaoN",false)

setPhase("Aguardando")
local cooldown={}
players.PlayerRemoving:Connect(function(p) cooldown[p]=nil end)
while room:IsDescendantOf(workspace) do
 local waiting={}
 for _,p in ipairs(players:GetPlayers()) do
  local c=p.Character
  local v,h=position(c)
  if v and math.abs(v.X)<26.6 and math.abs(v.Z)<27 and v.Y<7.6 and v.Y> -8 then
   h.Health=0
  elseif v and (cooldown[p] or 0)<os.clock() then
   if math.abs(v.X)<5.9 and v.Y>0 and v.Y<9 and v.Z>27.4 and v.Z<30.4 then
    if solved then move(c,0,3.8,-32,true);cooldown[p]=os.clock()+1
    elseif not active then table.insert(waiting,p) end
   elseif solved and math.abs(v.X)<3.25 and v.Y>51 and v.Y<61 and v.Z>27.35 and v.Z<31.35 then
    move(c,0,3.8,-32,true);cooldown[p]=os.clock()+1
   elseif solved and math.abs(v.X)<5.9 and v.Y>0 and v.Y<9 and v.Z< -27.4 and v.Z> -30.4 then
    move(c,0,3.8,32,false);cooldown[p]=os.clock()+1
   end
  end
 end
 if #waiting>0 and not active then
  active=true
  -- Small assembly interval lets nearby teammates enter together.
  setPhase("Reunindo")
  task.delay(2,function()
   local count=0
   for _,p in ipairs(players:GetPlayers()) do
    local v=position(p.Character)
    if v and math.abs(v.X)<6 and v.Z>27 and v.Z<33 and v.Y>0 and v.Y<10 then
     move(p.Character,-16+(count%8)*4.3,55.6,16.6-(math.floor(count/8)%9)*3.8,true)
     count+=1
    end
   end
   if count>0 then round() else active=false;setPhase("Aguardando") end
  end)
 end
 task.wait(.08)
end


