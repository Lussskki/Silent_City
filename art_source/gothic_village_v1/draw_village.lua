-- Original pixel artwork drawn with Aseprite; existing game assets remain untouched.
local root = app.params.out
local W,H = 1024,384
local s = Sprite(W,H,ColorMode.RGB)
local pc = app.pixelColor
local function rgb(h) return pc.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16)) end
local C={}
for k,v in pairs({ink='20272b',edge='30383b',stone='454e50',light='59615f',shade='383f44',roof='414c42',tile='53604d',moss='59664d',wood='403b38',plank='585047',iron='29363a',teal='397475',glow='659a90',far='596970',far2='65747a',window='313e46'}) do C[k]=rgb(v) end
local im
local layers={}
local function layer(name)
  local l
  if #layers==0 then l=s.layers[1] else l=s:newLayer() end
  l.name=name; im=Image(W,H,ColorMode.RGB); table.insert(layers,l)
  return l
end
local function finish(l) s:newCel(l,1,im,Point(0,0)) end
local function dot(x,y,c) x=math.floor(x);y=math.floor(y);if x>=0 and x<W and y>=0 and y<H then im:putPixel(x,y,c) end end
local function rect(x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do dot(xx,yy,c) end end end
local function line(x,y,a,b,c,t)
 local n=math.max(math.abs(a-x),math.abs(b-y));t=t or 1
 for i=0,n do local f=n==0 and 0 or i/n;rect(math.floor(x+(a-x)*f),math.floor(y+(b-y)*f),t,t,c) end
end
local function poly(p,c)
 local lo,hi=H,0
 for _,v in ipairs(p) do lo=math.min(lo,v[2]);hi=math.max(hi,v[2]) end
 for y=math.floor(lo),math.ceil(hi) do
  local xs={}
  for i=1,#p do local a,b=p[i],p[i%#p+1];if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then xs[#xs+1]=a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2]) end end
  table.sort(xs);for i=1,#xs-1,2 do for x=math.ceil(xs[i]),math.floor(xs[i+1]) do dot(x,y,c) end end
 end
end
local function outline(p,c,t) for i=1,#p do local a,b=p[i],p[i%#p+1];line(a[1],a[2],b[1],b[2],c,t or 2) end end
local function masonry(x,y,w,h,base,scale)
 rect(x,y,w,h,base);scale=scale or 1
 local bw,bh=18*scale,10*scale
 for yy=y,y+h-2,bh do
  line(x,yy,x+w-1,yy,C.shade)
  local off=(math.floor((yy-y)/bh)%2)*math.floor(bw/2)
  for xx=x-off,x+w-2,bw do
   if xx>=x then line(xx,yy,xx,math.min(yy+bh,y+h-1),C.shade) end
   local a=math.max(xx+2,x+1);local b=math.min(xx+bw-3,x+w-2)
   if a<b then line(a,yy+2,b,yy+2,C.light) end
  end
 end
end
local function tree(x,y,h,c,t)
 line(x,y,x-5,y-h*.55,c,t);line(x-5,y-h*.55,x+3,y-h,c,t-1)
 line(x-3,y-h*.42,x-23,y-h*.72,c,t-1);line(x-23,y-h*.72,x-29,y-h*.92,c,2)
 line(x-19,y-h*.68,x-37,y-h*.77,c,2)
 line(x,y-h*.63,x+22,y-h*.82,c,t-1);line(x+22,y-h*.82,x+28,y-h*.97,c,2)
 line(x+12,y-h*.74,x+30,y-h*.73,c,2)
end
local l=layer('01 Distant village - slow parallax')
for i=0,17 do
 local x=i*62-12;local h=40+(i*31)%61;local y=286
 rect(x,y-h,66,h,C.far2);poly({{x-7,y-h+1},{x+23,y-h-26},{x+70,y-h+1}},C.far2)
 if i%4==0 then rect(x+23,y-h-47,18,53,C.far2);poly({{x+19,y-h-46},{x+31,y-h-78},{x+45,y-h-46}},C.far2) end
end
for i=0,13 do
 local x=i*83-15;local h=50+(i*19)%51
 rect(x,303-h,67,h,C.far);poly({{x-6,303-h},{x+30,267-h},{x+73,303-h}},C.far)
 for k=0,2 do rect(x+13+k*17,315-h,4,10,C.far2) end
 if i%3==1 then tree(x+70,303,72,C.far,3) end
end
finish(l)
local function window(x,y,w,h,lit)
 local p={{x,y+h},{x,y+8},{x+w/2,y},{x+w,y+8},{x+w,y+h}}
 poly(p,C.ink);outline(p,C.ink,2)
 local q={{x+3,y+h-3},{x+3,y+9},{x+w/2,y+4},{x+w-3,y+9},{x+w-3,y+h-3}}
 poly(q,lit and C.teal or C.window)
 line(x+w/2,y+4,x+w/2,y+h,C.ink,2);line(x+2,y+h*.55,x+w-2,y+h*.55,C.ink,2)
 if lit then line(x+5,y+11,x+5,y+h-6,C.glow) end
 rect(x-3,y+h, w+7,4,C.edge)
end
local function roof(x,y,w,rise)
 local p={{x-12,y+6},{x+w*.47,y-rise},{x+w+13,y+5},{x+w+9,y+13},{x-13,y+14}}
 poly(p,C.roof);outline(p,C.ink,3)
 for yy=y-rise+10,y+6,9 do
  local t=(yy-(y-rise))/(rise+6);local left=x+w*.47-(w*.47+12)*t;local right=x+w*.47+(w*.53+13)*t
  line(left,yy,right,yy+1,C.ink,2)
  for xx=math.ceil(left+4),right-4,12 do
   local shift=(math.floor(yy/9)%2)*5
   if xx+shift<right-2 then line(xx+shift,yy-6,xx+shift-2,yy,C.tile,2) end
  end
 end
 line(x-12,y+7,x+w*.47,y-rise,C.tile,2)
end
local function house(x,base,w,h,rise,variant)
 local top=base-h
 masonry(x,top,w,h,C.stone)
 poly({{x+w-27,top+4},{x+w,top+12},{x+w,base},{x+w-27,base}},C.shade)
 poly({{x,top},{x+w*.47,top-rise+7},{x+w,top}},C.stone)
 local cx=x+w-32
 masonry(cx,top-rise-17,16,rise+28,C.shade)
 rect(cx-3,top-rise-20,23,6,C.ink);rect(cx-1,top-rise-19,18,2,C.light)
 roof(x,top,w,rise)
 rect(x-2,top+15,5,h-15,C.ink);rect(x+w-3,top+15,5,h-15,C.ink)
 rect(x+3,top+17,w-7,5,C.wood);rect(x+3,base-6,w-4,6,C.edge)
 window(x+math.floor(w*.47)-10,top-rise+24,20,29,true)
 local dx=x+math.floor(w*.55)-13
 rect(dx-4,base-53,33,53,C.ink);rect(dx,base-49,25,47,C.wood)
 for k=0,3 do line(dx+3+k*6,base-47,dx+3+k*6,base-5,C.plank) end
 rect(dx+17,base-26,4,5,C.ink);dot(dx+18,base-25,C.light)
 rect(dx-6,base-4,38,5,C.light);rect(dx-9,base+1,44,4,C.edge)
 window(x+14,top+32,19,26,false)
 if variant%2==0 then
  line(x+11,top+40,x+37,top+56,C.ink,6);line(x+12,top+40,x+36,top+55,C.plank,3)
  line(x+12,top+56,x+34,top+38,C.ink,5);line(x+13,top+56,x+34,top+39,C.wood,3)
 else window(x+w-29,top+37,15,23,false) end
 -- Cracks and ivy grow in clusters rather than uniform noise.
 for k=1,4 do local a=x+7+(k*29+variant*9)%(w-17);local b=top+27+(k*23)%(h-34)
  line(a,b,a-3,b+5,C.edge);line(a-3,b+5,a+1,b+9,C.edge)
 end
 for k=0,11 do local yy=top+20+k*6;local xx=x+5+math.floor(math.sin(k*1.7)*3)
  if yy<base then rect(xx,yy,4,5,C.roof);rect(xx-3,yy+2,4,3,C.moss) end
 end
end
l=layer('02 Houses - middle parallax')
tree(242,327,124,C.edge,6);tree(779,327,136,C.edge,6)
house(24,326,123,100,58,0)
house(304,326,145,124,72,1)
house(550,326,115,94,63,2)
house(847,326,137,125,70,3)
-- Low outbuildings join the village without making a solid visual wall.
masonry(153,283,51,43,C.shade);roof(153,283,51,22)
masonry(683,288,57,38,C.shade);roof(683,288,57,20)
finish(l)
l=layer('03 Near walls and ironwork - fast parallax')
local function pillar(x,y)
 masonry(x,y-50,18,50,C.stone);rect(x-3,y-53,24,6,C.ink);rect(x-2,y-53,22,3,C.light)
 rect(x-2,y-3,23,4,C.ink)
end
local function fence(x,y,w)
 line(x,y-17,x+w,y-17,C.iron,3);line(x,y-34,x+w,y-34,C.iron,3)
 for xx=x+5,x+w-4,11 do line(xx,y-43,xx,y,C.iron,3);poly({{xx-3,y-42},{xx+1,y-49},{xx+5,y-42}},C.iron);line(xx+1,y-40,xx+1,y-4,C.stone) end
end
local function wall(x,y,w)
 masonry(x,y-27,w,27,C.shade);rect(x,y-31,w,5,C.ink);line(x+1,y-30,x+w-2,y-30,C.light,2)
end
wall(0,356,91);fence(107,356,117);pillar(91,356);pillar(226,356)
wall(244,356,91);wall(468,356,68);pillar(450,356);fence(552,356,151);pillar(534,356);pillar(704,356)
wall(723,356,74);wall(944,356,80);pillar(927,356)
-- Walk-through arch with genuine transparent opening.
local ax=348;local ay=356
masonry(ax,ay-66,19,66,C.stone);masonry(ax+68,ay-66,19,66,C.stone)
for yy=ay-98,ay-56 do for xx=ax,ax+87 do
 local dx=(xx-(ax+43.5))/44;local dy=(yy-(ay-56))/43
 local outer=dx*dx+dy*dy
 local ix=(xx-(ax+43.5))/25;local iy=(yy-(ay-56))/26
 if outer<=1 and ix*ix+iy*iy>=1 then dot(xx,yy,C.stone) end
end end
for a=185,355,22 do local t=math.rad(a);line(ax+44+math.cos(t)*27,ay-56+math.sin(t)*27,ax+44+math.cos(t)*42,ay-56+math.sin(t)*42,C.ink,2) end
line(ax+18,ay-59,ax+18,ay,C.ink,2);line(ax+67,ay-59,ax+67,ay,C.ink,2)
tree(819,356,102,C.ink,5)
-- Hanging lantern, framed and separated from the architectural silhouette.
line(870,277,870,296,C.iron,2);rect(864,296,15,21,C.ink);rect(867,300,9,12,C.teal);line(871,299,871,313,C.iron,2);rect(863,295,17,3,C.stone)
finish(l)
-- Neutral backdrop is an optional editor aid, hidden in the saved source.
local backdrop=s:newLayer();backdrop.name='Preview backdrop - hide for export';backdrop.stackIndex=1
local bg=Image(W,H,ColorMode.RGB);bg:clear(rgb('4d555a'));s:newCel(backdrop,1,bg,Point(0,0))
s:saveCopyAs(root..'/village_preview.png')
backdrop.isVisible=false
s:saveAs(root..'/gothic_village_v1.aseprite')
for _,l in ipairs(layers) do
 for _,other in ipairs(layers) do other.isVisible=other==l end
 s:saveCopyAs(root..'/'..l.name:sub(1,2)..'_layer.png')
end
for _,l in ipairs(layers) do l.isVisible=true end
print('Created layered village artwork: '..root)
