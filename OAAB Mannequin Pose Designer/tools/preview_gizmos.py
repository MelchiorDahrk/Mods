"""Render the author's movement/rotation shapes directly from their NIF."""
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from nif_geometry import ROOT, shapes

def sub(a,b): return tuple(x-y for x,y in zip(a,b))
def dot(a,b): return sum(x*y for x,y in zip(a,b))
def cross(a,b): return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def unit(a): return tuple(x/math.sqrt(dot(a,a)) for x in a)

factor=2
canvas=Image.new('RGB',(960*factor,480*factor),'#30353c')
right=unit((-1,1,0)); eye=unit((1,1,.7)); up=unit(cross(eye,right))
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',24*factor)
small=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',14*factor)
draw=ImageDraw.Draw(canvas)
draw.text((32*factor,18*factor),'Authored mannequin gizmo',font=font,fill='#eef0f4')
draw.text((32*factor,54*factor),'Authored geometry with rotation mask (offline preview)',font=small,fill='#aab2bd')
entries=shapes()
pixels=np.array(canvas)
height,width=pixels.shape[:2]

def raster(points,color,depth):
    """Depth-test triangles; the transparent sphere writes only depth."""
    a,b,c=np.array(points)
    lo=np.maximum(np.floor(np.minimum(np.minimum(a,b),c)[:2]).astype(int),(0,0))
    hi=np.minimum(np.ceil(np.maximum(np.maximum(a,b),c)[:2]).astype(int),(width-1,height-1))
    if np.any(lo>hi): return
    denominator=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1])
    if abs(denominator)<1e-8: return
    x,y=np.meshgrid(np.arange(lo[0],hi[0]+1)+.5,np.arange(lo[1],hi[1]+1)+.5)
    u=((b[1]-c[1])*(x-c[0])+(c[0]-b[0])*(y-c[1]))/denominator
    v=((c[1]-a[1])*(x-c[0])+(a[0]-c[0])*(y-c[1]))/denominator
    w=1-u-v
    z=u*a[2]+v*b[2]+w*c[2]
    target=depth[lo[1]:hi[1]+1,lo[0]:hi[0]+1]
    visible=(u>=0)&(v>=0)&(w>=0)&(z>=target)
    target[visible]=z[visible]
    if color is not None:
        pixels[lo[1]:hi[1]+1,lo[0]:hi[0]+1][visible]=color

for mode,origin in (('move',(240,300)),('rotate',(715,265))):
    faces=[]; masks=[]; markers=[]
    depth=np.full((height,width),-np.inf)
    for shape,data,materials in entries:
        masking=shape['name']=='sphere'
        marker=shape['name']=='node'
        if masking and mode!='rotate': continue
        if not masking and not marker and shape['name'].endswith('_move') != (mode=='move'): continue
        transform=shape['world']
        rotation=transform['rotation']; scale=transform['scale']; translation=transform['translation']
        def world(p):
            return tuple(translation[i]+scale*sum(rotation[3*i+j]*p[j] for j in range(3)) for i in range(3))
        vertices=[world(p) for p in data['vertices']]
        rgb=materials[0]['diffuse']
        for indices in data['triangles']:
            points=[vertices[i] for i in indices]
            normal=cross(sub(points[1],points[0]),sub(points[2],points[0]))
            if dot(normal,eye)<=1e-10: continue
            screen=[((origin[0]+dot(p,right)*4.2)*factor,(origin[1]-dot(p,up)*4.2)*factor,dot(p,eye)) for p in points]
            color=tuple(round(c*255) for c in rgb)
            (masks if masking else markers if marker else faces).append((screen,color))
    for points,_ in masks: raster(points,None,depth)
    for points,color in faces: raster(points,color,depth)
    # Bone markers render independently over the gizmo's transparent depth mask.
    marker_depth=np.full((height,width),-np.inf)
    for points,color in markers: raster(points,color,marker_depth)

canvas=Image.fromarray(pixels)
draw=ImageDraw.Draw(canvas)
draw.text((165*factor,433*factor),'G: Movement',font=font,fill='#eef0f4')
draw.text((640*factor,433*factor),'R: Rotation',font=font,fill='#eef0f4')
destination=ROOT/'docs/gizmos-preview.png'
canvas.resize((960,480),Image.Resampling.LANCZOS).save(destination)
print(destination)
