-- Original geometric drawing executed in Aseprite; no image generation model.
local root=app.params.root
local pc=app.pixelColor
local counts={}
for _,path in ipairs({'Resources/Second_prompt/background_assets/Aseprite_Redraws/waterfall_cliff_redraw.png','Resources/Levels/Grass_redraw.png'}) do
 local source=Image{fromFile=root..'/'..path}
 for it in source:pixels() do local c=it();if pc.rgbaA(c)==255 then counts[c]=(counts[c] or 0)+1 end end
end
local function sample(r,g,b)
 local best,dist=nil,math.huge
 for c,n in pairs(counts) do if n>15 then local d=(pc.rgbaR(c)-r)^2+(pc.rgbaG(c)-g)^2+(pc.rgbaB(c)-b)^2;if d<dist then best,dist=c,d end end end
 return best
end
local C={ink=sample(27,35,40),shadow=sample(45,55,65),stone=sample(64,76,88),light=sample(83,96,108),moss=sample(29,58,48),leaf=sample(51,77,55)}
local W,H=1024,900
local s=Sprite(W,H,ColorMode.RGB)
local im
local function pixel(x,y,c) x=math.floor(x);y=math.floor(y);if x>=0 and x<W and y>=0 and y<H then im:putPixel(x,y,c) end end
local function line(x,y,a,b,c,t)
 local n=math.max(math.abs(a-x),math.abs(b-y));t=t or 4
 for i=0,n do local f=n==0 and 0 or i/n;for u=0,t-1 do for v=0,t-1 do pixel(x+(a-x)*f+u,y+(b-y)*f+v,c) end end end
end
local function poly(p,c)
 local lo,hi=H,0;for _,v in ipairs(p) do lo=math.min(lo,v[2]);hi=math.max(hi,v[2]) end
 for y=math.floor(lo),math.ceil(hi) do local xs={}
  for i=1,#p do local a,b=p[i],p[i%#p+1];if(a[2]<=y and b[2]>y)or(b[2]<=y and a[2]>y)then xs[#xs+1]=a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2])end end
  table.sort(xs);for i=1,#xs-1,2 do for x=math.ceil(xs[i]),math.floor(xs[i+1])do pixel(x,y,c)end end
 end
end
local function layer(name,first)
 local l=first and s.layers[1]or s:newLayer();l.name=name;im=Image(W,H,ColorMode.RGB);return l
end
local function finish(l)s:newCel(l,1,im,Point(0,0))end
local l=layer('01 Continuous rock silhouette',true)
poly({{12,72},{41,40},{114,54},{173,88},{245,100},{309,135},{397,161},{473,194},{537,210},{613,247},{691,279},{768,298},{843,338},{918,366},{984,395},{1011,435},{1000,715},{966,785},{912,807},{856,766},{785,759},{741,726},{660,719},{612,674},{539,657},{481,612},{415,605},{359,566},{291,550},{238,499},{172,488},{131,451},{63,432},{29,381}},C.ink)
finish(l)
l=layer('02 Individual stone faces')
local function rock(x,y,w,h,variant)
 -- Each face is placed explicitly; uneven corners keep the arrangement legible.
 local p={{x+15,y},{x+w*.67,y+5},{x+w-4,y+29},{x+w,y+h*.66},{x+w*.72,y+h-7},{x+23,y+h},{x,y+h*.59},{x+4,y+25}}
 poly(p,variant%3==0 and C.shadow or C.stone)
 poly({p[1],p[2],p[3],{x+w*.66,y+51},{x+14,y+35}},C.light)
 poly({{x+w-4,y+29},p[4],p[5],{x+w*.61,y+h*.59}},C.shadow)
 for i=1,#p do local a,b=p[i],p[i%#p+1];line(a[1],a[2],b[1],b[2],C.ink,5)end
end
rock(13,78,137,163,1);rock(153,106,144,157,2);rock(302,158,161,177,3)
rock(469,220,153,170,4);rock(627,276,159,178,5);rock(790,336,201,175,6)
rock(38,246,158,163,4);rock(201,273,170,177,2);rock(376,345,153,178,1)
rock(534,398,188,191,5);rock(726,463,141,175,3);rock(871,520,125,183,2)
rock(140,416,127,65,3);rock(273,458,140,81,2);rock(418,531,126,68,4)
rock(550,598,142,83,1);rock(698,649,143,72,5);rock(846,710,120,67,2)
-- Sparse cracks follow individual rocks, rather than a repeated texture.
line(225,150,216,179,C.ink,3);line(216,179,232,197,C.ink,3)
line(428,406,414,428,C.ink,3);line(414,428,421,444,C.ink,3)
line(918,573,902,596,C.ink,3)
finish(l)
l=layer('03 Moss rim and sparse grass')
local top={{15,68},{45,40},{111,55},{175,88},{244,102},{310,134},{395,163},{472,193},{539,213},{614,248},{690,280},{768,299},{844,338},{919,367},{981,396},{1005,430}}
local rim={};for _,p in ipairs(top)do rim[#rim+1]=p end
for i=#top,1,-1 do local p=top[i];rim[#rim+1]={p[1],p[2]+18+(i%3)*3}end
poly(rim,C.moss)
for _,p in ipairs({{83,49},{270,113},{565,228},{822,330},{956,385}})do
 local x,y=p[1],p[2]
 poly({{x-15,y+10},{x-23,y-18},{x-8,y-8},{x-7,y-36},{x+2,y-13},{x+14,y-25},{x+8,y+8}},C.ink)
 poly({{x-12,y+8},{x-16,y-10},{x-4,y-2},{x-4,y-24},{x+2,y-3},{x+9,y-15},{x+5,y+8}},C.leaf)
end
poly({{184,294},{214,292},{238,311},{222,329},{198,326},{177,312}},C.moss)
poly({{601,433},{633,430},{649,449},{631,464},{610,453}},C.moss)
finish(l)
local out=root..'/Resources/Second_prompt/background_assets/Aseprite_Redraws/river_embankment_v1'
s:saveAs(out..'.aseprite');s:saveCopyAs(out..'.png')
local used={};for it in Image(s):pixels()do local c=it();if pc.rgbaA(c)>0 then assert(counts[c]);used[c]=true end end
local n=0;for _ in pairs(used)do n=n+1 end
print('Embankment drawn in Aseprite: '..n..' existing colors, 3 editable layers')
