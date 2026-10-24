-- Drawn in Aseprite, using only opaque colors sampled from the scene's tree.
local root=app.params.root
local reference=Image{fromFile=root..'/Resources/Levels/Tree_redraw.png'}
local pc=app.pixelColor
local counts={}
for it in reference:pixels() do local c=it();if pc.rgbaA(c)==255 then counts[c]=(counts[c] or 0)+1 end end
local function sample(r,g,b)
 local best,dist=nil,math.huge
 for c,n in pairs(counts) do if n>=8 then
  local d=(pc.rgbaR(c)-r)^2+(pc.rgbaG(c)-g)^2+(pc.rgbaB(c)-b)^2
  if d<dist then best,dist=c,d end
 end end
 return best
end
local C={ink=sample(18,31,33),deep=sample(23,45,44),leaf=sample(29,59,55),mid=sample(41,76,65),light=sample(62,91,65),moss=sample(72,100,65),bark=sample(72,57,47),barkLight=sample(103,77,54),barkShade=sample(46,40,36)}
local W,H=256,320
local s=Sprite(W,H,ColorMode.RGB)
local im
local function pixel(x,y,c) x=math.floor(x);y=math.floor(y);if x>=0 and x<W and y>=0 and y<H then im:putPixel(x,y,c) end end
local function poly(p,c)
 local min,max=H,0;for _,v in ipairs(p) do min=math.min(min,v[2]);max=math.max(max,v[2]) end
 for y=math.floor(min),math.ceil(max) do local xs={}
  for i=1,#p do local a,b=p[i],p[i%#p+1];if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then xs[#xs+1]=a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2]) end end
  table.sort(xs);for i=1,#xs-1,2 do for x=math.ceil(xs[i]),math.floor(xs[i+1]) do pixel(x,y,c) end end
 end
end
local function line(x,y,a,b,c,t)
 local steps=math.max(math.abs(a-x),math.abs(b-y));t=t or 1
 for i=0,steps do local f=steps==0 and 0 or i/steps;for u=0,t-1 do for v=0,t-1 do pixel(x+(a-x)*f+u,y+(b-y)*f+v,c) end end end
end
local function shape(cx,cy,rx,ry,seed,c)
 local p={};for i=0,31 do local a=i*math.pi/16;local f=1+.065*math.sin(i*2.1+seed)+.035*math.sin(i*.9+seed*3)
  p[#p+1]={math.floor(cx+math.cos(a)*rx*f),math.floor(cy+math.sin(a)*ry*f)} end
 poly(p,c)
end
local function layer(name,first)
 local l=first and s.layers[1] or s:newLayer();l.name=name;im=Image(W,H,ColorMode.RGB);return l
end
local function finish(l) s:newCel(l,1,im,Point(0,0)) end
local l=layer('01 Trunk and spreading roots',true)
poly({{70,305},{89,289},{102,267},{105,212},{97,167},{72,144},{61,115},{70,111},{88,136},{112,146},{117,105},{130,96},{137,143},{159,127},{177,99},{186,102},{174,139},{145,168},{141,211},{144,267},{156,289},{181,305},{151,302},{131,289},{121,288},{102,303}},C.ink)
poly({{82,299},{102,274},{110,215},{105,166},{82,144},{73,123},{91,143},{119,155},{123,112},{129,107},{132,153},{162,133},{176,113},{168,139},{137,166},{133,216},{138,272},{151,291},{164,299},{144,293},{126,276},{111,294}},C.bark)
poly({{94,293},{107,263},{115,209},{113,165},{119,158},{122,209},{117,265},{108,288}},C.barkLight)
poly({{126,171},{130,218},{127,268},{139,292},{133,266},{135,217},{137,169},{157,146}},C.barkShade)
line(108,184,112,212,C.barkShade,2);line(113,214,108,248,C.barkShade,2)
line(130,278,145,297,C.barkLight,2);line(116,275,107,296,C.barkLight,2)
finish(l)
l=layer('02 Leaf canopy')
-- An asymmetrical connected crown, with a few large masses instead of repeated leaf symbols.
local clusters={{48,156,33,27,1},{78,122,38,34,2},{55,108,29,30,3},{85,78,38,34,4},{116,50,35,31,5},{149,56,35,32,6},{173,88,37,32,7},{202,113,30,29,8},{205,148,35,30,9},{173,158,35,30,10},{139,136,41,34,11},{111,104,45,35,12},{87,167,34,26,13},{124,175,31,24,14}}
for _,v in ipairs(clusters) do shape(v[1],v[2],v[3]+3,v[4]+3,v[5],C.ink) end
for _,v in ipairs(clusters) do shape(v[1],v[2],v[3],v[4],v[5],C.deep) end
for _,v in ipairs(clusters) do
 local x,y,rx,ry,k=table.unpack(v)
 shape(x-3,y-5,rx*.88,ry*.74,k+.3,C.leaf)
 shape(x-7,y-10,rx*.66,ry*.49,k+.8,C.mid)
 -- Broken angular highlights retain the source art's restricted shading.
 if k%3~=0 then
  poly({{x-rx*.48,y-ry*.46},{x-rx*.18,y-ry*.63},{x+rx*.03,y-ry*.55},{x-rx*.13,y-ry*.29},{x-rx*.5,y-ry*.19}},C.light)
 end
 if k%4==0 then line(x+3,y-ry*.41,x+9,y-ry*.49,C.moss,2) end
end
-- Smaller scallops interrupt broad edges without adding new colors.
shape(28,143,11,9,2,C.leaf);shape(224,134,10,10,4,C.leaf)
finish(l)
l=layer('03 Grass at roots')
for _,v in ipairs({{79,303},{94,307},{157,306},{175,304}}) do
 local x,y=v[1],v[2]
 poly({{x-7,y},{x-11,y-12},{x-3,y-5},{x-2,y-19},{x+2,y-7},{x+9,y-12},{x+5,y}},C.deep)
 line(x-5,y-2,x-8,y-10,C.mid);line(x,y-2,x-1,y-14,C.light);line(x+3,y-1,x+7,y-9,C.mid)
end
finish(l)
local out=root..'/Resources/Second_prompt/background_assets/Aseprite_Redraws/starting_tree_v1'
s:saveAs(out..'.aseprite')
s:saveCopyAs(out..'.png')
local colors={};local rendered=Image(s)
for it in rendered:pixels() do local c=it();if pc.rgbaA(c)>0 then assert(counts[c],'Unexpected color');colors[c]=true end end
local n=0;for _ in pairs(colors) do n=n+1 end
print('Saved 256x320 tree, 3 layers, '..n..' colors, all sampled from Tree_redraw.png')
