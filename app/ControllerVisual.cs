using System;
using System.Collections.Generic;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Shapes;
namespace StadiaStudio {
 public sealed class ControllerVisual:UserControl {
  // One shared layout model: photos constrain relative spacing, the patent constrains outline proportions.
  // Coordinates are a visual estimate, not a calibrated physical reconstruction.
  const double LayoutCenterX=277.5,ButtonRowY=114,StickRowY=190;
  const double OuterOffset=153,FunctionOffset=40,PillOffset=64,StickOffset=86;
  const double FaceDiameter=36,FaceRadius=38,FunctionDiameter=22,PillWidth=30,PillHeight=18;
  readonly Canvas drawing=new Canvas{Width=555,Height=395};
  readonly Dictionary<int,Border> zones=new Dictionary<int,Border>();
  readonly Dictionary<int,Path> sculpted=new Dictionary<int,Path>();
  readonly Dictionary<int,TextBlock> labels=new Dictionary<int,TextBlock>();
  readonly Dictionary<int,Path> directionMarks=new Dictionary<int,Path>();
  readonly Dictionary<int,Path> directionEdges=new Dictionary<int,Path>();
  readonly Dictionary<int,Canvas> functionIcons=new Dictionary<int,Canvas>();
  readonly Dictionary<int,Path> faceGlyphs=new Dictionary<int,Path>();
  readonly TranslateTransform left=new TranslateTransform(),right=new TranslateTransform();
  readonly Brush idle=Ui.Brush("#303B40"),outline=Ui.Brush("#657279"),accent=Ui.Brush("#CAF57A");
  int selected=-1;bool[] pressed=new bool[19];readonly SolidColorBrush[] triggerInk={new SolidColorBrush(),new SolidColorBrush()};public event Action<int> Selected;
  public ControllerVisual() {
   // Cross-check the actual product photographs with FIG.3 instead of copying either image coordinates.
   // Symmetric pairs share a centerline, row and size; neutral stick rings remain concentric.
   // Only L1/R1 are shown on the controller; L2/R2 already have dedicated live panels below it.
   SculptedZone(4,"M78,38 C82,19 105,9 140,8 C151,8 158,15 162,28 L154,31 C150,22 142,18 130,18 C105,18 90,25 84,40 Z",117,20,"");
   SculptedZone(5,"M393,28 C397,15 404,8 415,8 C450,9 473,19 477,38 L471,40 C465,25 450,18 425,18 C413,18 405,22 401,31 Z",438,20,"");
   // Patent front-plan contour, not the foreshortened product photograph.
   ShapePath("M277.5,12 L162,12 C110,12 83,26 66,58 C49,91 37,146 25,202 C14,253 5,300 5,321 C5,353 17,372 41,380 C64,388 85,384 99,370 C111,358 117,335 125,311 C134,284 143,267 159,260 C165,258 171,257 177,257 L378,257 C384,257 390,258 396,260 C412,267 421,284 430,311 C438,335 444,358 456,370 C470,384 491,388 514,380 C538,372 550,353 550,321 C550,300 541,253 530,202 C518,146 506,91 489,58 C472,26 445,12 393,12 Z");
   BringLabelToFront(4);BringLabelToFront(5);
   // Stadia's D-pad uses fully radiused arm ends and concave transitions, not a rounded rectangle cross.
   // Exact bilateral and vertical symmetry: center=(110,113), bounds x=63..157 and y=66..160.
   ShapePath("M110,66 C102.3,66 96,72.3 96,80 L96,95 C96,97.2 94.2,99 92,99 L77,99 C69.3,99 63,105.3 63,113 C63,120.7 69.3,127 77,127 L92,127 C94.2,127 96,128.8 96,131 L96,146 C96,153.7 102.3,160 110,160 C117.7,160 124,153.7 124,146 L124,131 C124,128.8 125.8,127 128,127 L143,127 C150.7,127 157,120.7 157,113 C157,105.3 150.7,99 143,99 L128,99 C125.8,99 124,97.2 124,95 L124,80 C124,72.3 117.7,66 110,66 Z");PlaceDpadLast();
   // One canonical arm, rotated about the cross center, drives both hit/fill and selection.
   // Split each concave cubic at t=.5: neighboring arms meet on exact 45-degree seams.
   DpadDirection(13,0);DpadDirection(14,180);DpadDirection(15,270);DpadDirection(16,90);
   // Four ABXY centers form a regular diamond, mirrored from the D-pad group center.
   CircleZone(0,LayoutCenterX+OuterOffset,ButtonRowY+FaceRadius,FaceDiameter,"A");
   CircleZone(1,LayoutCenterX+OuterOffset+FaceRadius,ButtonRowY,FaceDiameter,"B");
   CircleZone(2,LayoutCenterX+OuterOffset-FaceRadius,ButtonRowY,FaceDiameter,"X");
   CircleZone(3,LayoutCenterX+OuterOffset,ButtonRowY-FaceRadius,FaceDiameter,"Y");
   FunctionAt(6,LayoutCenterX-PillOffset,ButtonRowY-40,PillWidth,PillHeight,false,"options");
   FunctionAt(7,LayoutCenterX+PillOffset,ButtonRowY-40,PillWidth,PillHeight,false,"menu");
   FunctionAt(11,LayoutCenterX+FunctionOffset,ButtonRowY,FunctionDiameter,FunctionDiameter,true,"capture");
   FunctionAt(12,LayoutCenterX-FunctionOffset,ButtonRowY,FunctionDiameter,FunctionDiameter,true,"assistant");
   StadiaZone(10,LayoutCenterX-20,StickRowY-20);
   Stick(8,LayoutCenterX-StickOffset,StickRowY,left);Stick(9,LayoutCenterX+StickOffset,StickRowY,right);
   Content=new Viewbox{Child=drawing,Stretch=Stretch.Uniform};
  }
  void ShapePath(string data){Geometry geometry=Geometry.Parse(data);geometry.Freeze();drawing.Children.Add(new Path{Data=geometry,Fill=Ui.Brush("#222C31"),Stroke=outline,StrokeThickness=2,StrokeLineJoin=PenLineJoin.Round,IsHitTestVisible=false});}
  void ContourPath(string data){Geometry geometry=Geometry.Parse(data);geometry.Freeze();drawing.Children.Add(new Path{Data=geometry,Fill=Brushes.Transparent,Stroke=Ui.Brush("#4D5A60"),StrokeThickness=1,Opacity=.8,IsHitTestVisible=false});}
  void PlaceDpadLast(){TransformGroup t=new TransformGroup();t.Children.Add(new ScaleTransform(92.0/94,92.0/94,110,113));t.Children.Add(new TranslateTransform(LayoutCenterX-OuterOffset-110,ButtonRowY-113));drawing.Children[drawing.Children.Count-1].RenderTransform=t;}
  const string DpadTopFillEdge="M94.825,97.825 C95.55,97.1 96,96.1 96,95 L96,80 C96,72.3 102.3,66 110,66 C117.7,66 124,72.3 124,80 L124,95 C124,96.1 124.45,97.1 125.175,97.825";
  void DpadDirection(int id,double angle){
   SculptedZone(id,DpadTopFillEdge+" L110,113 Z",0,0,null);PlaceDpadLast();
   RotateDpadGeometry(sculpted[id],angle);
   // Selection follows the whole directional region: rounded arm plus two center-point diagonals.
   DirectionEdge(id,DpadTopFillEdge+" L110,113 Z");RotateDpadGeometry(directionEdges[id],angle);
  }
  static void RotateDpadGeometry(Path path,double angle){Geometry geometry=path.Data.Clone();geometry.Transform=new RotateTransform(angle,110,113);geometry.Freeze();path.Data=geometry;}
  void DirectionEdge(int id,string data){Geometry geometry=Geometry.Parse(data);geometry.Freeze();Path edge=new Path{Data=geometry,Fill=null,Stroke=Brushes.Transparent,StrokeThickness=2,StrokeStartLineCap=PenLineCap.Round,StrokeEndLineCap=PenLineCap.Round,StrokeLineJoin=PenLineJoin.Round,IsHitTestVisible=false,Tag="DpadSelectionEdge"};drawing.Children.Add(edge);PlaceDpadLast();directionEdges[id]=edge;}
  void SculptedZone(int id,string data,double x,double y,string label){Geometry geometry=Geometry.Parse(data);geometry.Freeze();Path shape=new Path{Data=geometry,Fill=label==null?Brushes.Transparent:idle,Stroke=label==null?Brushes.Transparent:outline,StrokeThickness=1.5,StrokeLineJoin=PenLineJoin.Round,ToolTip=Destination.Physical[id],Cursor=System.Windows.Input.Cursors.Hand};shape.MouseLeftButtonDown+=(s,e)=>{Select(id);if(Selected!=null)Selected(id);e.Handled=true;};System.Windows.Automation.AutomationProperties.SetName(shape,Destination.Physical[id]);drawing.Children.Add(shape);sculpted[id]=shape;if(label!=null){TextBlock text=new TextBlock{Text=label,FontSize=13,FontWeight=FontWeights.SemiBold,Foreground=Ui.Text,Width=40,TextAlignment=TextAlignment.Center,IsHitTestVisible=false};Canvas.SetLeft(text,x-20);Canvas.SetTop(text,y-9);drawing.Children.Add(text);labels[id]=text;}}
  void DirectionMark(int id,string data){Path mark=new Path{Data=Geometry.Parse(data),Stroke=outline,StrokeThickness=2,StrokeStartLineCap=PenLineCap.Round,StrokeEndLineCap=PenLineCap.Round,StrokeLineJoin=PenLineJoin.Round,IsHitTestVisible=false};drawing.Children.Add(mark);directionMarks[id]=mark;}
  void ShoulderHighlight(string data){drawing.Children.Add(new Path{Data=Geometry.Parse(data),Stroke=Ui.Brush("#849097"),Opacity=.55,StrokeThickness=1,StrokeStartLineCap=PenLineCap.Round,StrokeEndLineCap=PenLineCap.Round,IsHitTestVisible=false});}
  void BringLabelToFront(int id){TextBlock label=labels[id];drawing.Children.Remove(label);drawing.Children.Add(label);}
  void Stick(int id,double x,double y,TranslateTransform movement){
   Ellipse socket=new Ellipse{Width=82,Height=82,Fill=Ui.Brush("#151D21"),Stroke=outline,StrokeThickness=1.5,IsHitTestVisible=false};Canvas.SetLeft(socket,x-41);Canvas.SetTop(socket,y-41);drawing.Children.Add(socket);
   // Neutral orthographic position: socket, thumb cap and concave ring are concentric.
   Zone(id,x-33,y-33,66,66,true,"");zones[id].RenderTransform=movement;
   Ellipse inner=new Ellipse{Width=44,Height=44,Stroke=Ui.Brush("#4D5A60"),StrokeThickness=1,IsHitTestVisible=false,RenderTransform=movement};Canvas.SetLeft(inner,x-22);Canvas.SetTop(inner,y-22);drawing.Children.Add(inner);
  }
  void CircleZone(int id,double centerX,double centerY,double diameter,string label){
   Zone(id,centerX-diameter/2,centerY-diameter/2,diameter,diameter,true,label);
   // Center actual glyph ink, not the font's ascent/descent line box.
   FormattedText text=new FormattedText(label,System.Globalization.CultureInfo.InvariantCulture,FlowDirection.LeftToRight,new Typeface(new FontFamily("Segoe UI"),FontStyles.Normal,FontWeights.SemiBold,FontStretches.Normal),14,Ui.Text,1.0);
   Geometry ink=text.BuildGeometry(new Point(0,0));Rect bounds=ink.Bounds;
   ink.Transform=new TranslateTransform(-bounds.X,-bounds.Y);ink.Freeze();
   Path glyph=new Path{Data=ink,Fill=Ui.Text,Width=bounds.Width,Height=bounds.Height,Stretch=Stretch.None,HorizontalAlignment=HorizontalAlignment.Center,VerticalAlignment=VerticalAlignment.Center,IsHitTestVisible=false};
   zones[id].Child=glyph;faceGlyphs[id]=glyph;
  }
  void FunctionAt(int id,double centerX,double centerY,double width,double height,bool circle,string kind){FunctionZone(id,centerX-width/2,centerY-height/2,width,height,circle,kind);}
  void Zone(int id,double x,double y,double width,double height,bool circle,string label){Border z=new Border{Width=width,Height=height,CornerRadius=new CornerRadius(circle?width/2:6),Background=idle,BorderBrush=outline,BorderThickness=new Thickness(1.5),ToolTip=Destination.Physical[id],Cursor=System.Windows.Input.Cursors.Hand,Child=new TextBlock{Text=label,Foreground=Ui.Text,FontSize=height<25?10:14,FontWeight=FontWeights.SemiBold,HorizontalAlignment=HorizontalAlignment.Center,VerticalAlignment=VerticalAlignment.Center,IsHitTestVisible=false}};z.MouseLeftButtonDown+=(s,e)=>{Select(id);if(Selected!=null)Selected(id);e.Handled=true;};System.Windows.Automation.AutomationProperties.SetName(z,Destination.Physical[id]);Canvas.SetLeft(z,x);Canvas.SetTop(z,y);drawing.Children.Add(z);zones[id]=z;}
  void FunctionZone(int id,double x,double y,double width,double height,bool circle,string kind){
   Canvas icon=new Canvas{Width=24,Height=24,Tag=kind,IsHitTestVisible=false};Brush ink=Ui.Text;
   if(kind=="options")for(int i=0;i<3;i++){Ellipse dot=new Ellipse{Width=3.2,Height=3.2,Fill=ink};Canvas.SetLeft(dot,4.4+i*6.5);Canvas.SetTop(dot,10.4);icon.Children.Add(dot);}
   else if(kind=="menu")icon.Children.Add(IconStroke("M5,7 L19,7 M5,12 L19,12 M5,17 L19,17",ink,1.8));
   else if(kind=="capture"){icon.Children.Add(IconStroke("M9,5 L5,5 L5,9 M15,5 L19,5 L19,9 M19,15 L19,19 L15,19 M9,19 L5,19 L5,15",ink,1.7));}
   else {AddDot(icon,3.5,3.5,8,ink);AddDot(icon,16,4,2.5,ink);AddDot(icon,15,11,4.5,ink);AddDot(icon,11,18,3,ink);}
   Border z=new Border{Width=width,Height=height,CornerRadius=new CornerRadius(circle?width/2:height/2),Background=idle,BorderBrush=outline,BorderThickness=new Thickness(1.5),ToolTip=Destination.Physical[id],Cursor=System.Windows.Input.Cursors.Hand,Child=new Viewbox{Width=circle?16:21,Height=circle?16:16,Stretch=Stretch.Uniform,Child=icon,IsHitTestVisible=false}};
   z.MouseLeftButtonDown+=(s,e)=>{Select(id);if(Selected!=null)Selected(id);e.Handled=true;};System.Windows.Automation.AutomationProperties.SetName(z,Destination.Physical[id]);Canvas.SetLeft(z,x);Canvas.SetTop(z,y);drawing.Children.Add(z);zones[id]=z;functionIcons[id]=icon;
  }
  static Path IconStroke(string data,Brush ink,double width){return new Path{Data=Geometry.Parse(data),Stroke=ink,StrokeThickness=width,StrokeStartLineCap=PenLineCap.Round,StrokeEndLineCap=PenLineCap.Round,StrokeLineJoin=PenLineJoin.Round};}
  static void AddDot(Canvas canvas,double x,double y,double size,Brush ink){Ellipse dot=new Ellipse{Width=size,Height=size,Fill=ink};Canvas.SetLeft(dot,x);Canvas.SetTop(dot,y);canvas.Children.Add(dot);}
  static void RecolorIcon(Canvas icon,Brush ink){foreach(UIElement item in icon.Children){Shape shape=item as Shape;if(shape==null)continue;if(shape.Fill!=null)shape.Fill=ink;if(shape.Stroke!=null)shape.Stroke=ink;}}
  void StadiaZone(int id,double x,double y){
   Canvas mark=new Canvas{Width=120,Height=80,IsHitTestVisible=false};
   // Exact path geometry from Google's official 120x80 Stadia logo mark SVG; only the fill is changed to white.
   const string officialStadiaPath="M1.00857143,23.3413856 C0.362857143,23.8032807 0.00285714286,24.5360402 0,25.2901838 L0,25.2901838 L0,25.3201215 C0.00285714286,25.6380308 0.0685714286,25.9602169 0.204285714,26.2667213 L0.204285714,26.2667213 L11.69,52.2882388 C12.1985714,53.441551 13.5114286,54.0060895 14.7014286,53.5841112 L14.7014286,53.5841112 C22.2214286,50.9025535 48.2628571,42.4187946 65.1157143,46.9949777 L65.1157143,46.9949777 C65.1157143,46.9949777 48.21,47.9729409 32.9228571,59.96083 L32.9228571,59.96083 C32.0614286,60.6379911 31.7742857,61.8155385 32.2157143,62.8163113 L32.2157143,62.8163113 C33.4571429,65.6204709 35.9485714,71.2573021 37.3585714,74.4435231 L37.3585714,74.4435231 L39.3385714,79.0881351 C39.81,80.1901256 41.3157143,80.3227066 41.98,79.3247851 L41.98,79.3247851 C45.5471429,73.9531159 51.5614286,71.2701325 57.3385714,68.927868 L57.3385714,68.927868 C63.2571429,66.5300051 69.4328571,64.7408743 75.7328571,63.6759494 L75.7328571,63.6759494 C82.4457143,62.54117 89.3,62.2375168 96.0842857,62.8376953 L96.0842857,62.8376953 C97.2142857,62.9374875 98.2628571,62.2446448 98.6,61.1640383 L98.6,61.1640383 L103.788571,44.5814332 C104.094286,43.6006188 103.742857,42.528566 102.908571,41.9255362 L102.908571,41.9255362 C97.1228571,37.7342657 74.2042857,23.6564437 33.9014286,29.3118077 L33.9014286,29.3118077 C33.9014286,29.3118077 68.2928571,9.55581202 111.954286,31.2577547 L111.954286,31.2577547 C113.277143,31.916383 114.874286,31.2249659 115.315714,29.8193221 L115.315714,29.8193221 L119.89,15.1954944 C119.961429,14.9688237 119.995714,14.7393017 120,14.512631 L120,14.512631 L120,14.4427765 C119.987143,13.6102248 119.541429,12.8204411 118.784286,12.3913349 L118.784286,12.3913349 C113.304286,9.29065 94.7514286,2.79222317e-07 69.23,2.79222317e-07 L69.23,2.79222317e-07 C49.6685714,-0.00142532301 26.0157143,5.45578001 1.00857143,23.3413856";
   mark.Children.Add(new Path{Data=Geometry.Parse(officialStadiaPath),Fill=Brushes.White,IsHitTestVisible=false});
   Border z=new Border{Width=40,Height=40,CornerRadius=new CornerRadius(20),Background=idle,BorderBrush=outline,BorderThickness=new Thickness(1.5),ToolTip=Destination.Physical[id],Cursor=System.Windows.Input.Cursors.Hand,Child=new Viewbox{Width=23,Height=17,Stretch=Stretch.Uniform,Child=mark,IsHitTestVisible=false}};
   z.MouseLeftButtonDown+=(s,e)=>{Select(id);if(Selected!=null)Selected(id);e.Handled=true;};System.Windows.Automation.AutomationProperties.SetName(z,Destination.Physical[id]);Canvas.SetLeft(z,x);Canvas.SetTop(z,y);drawing.Children.Add(z);zones[id]=z;
  }
  public void Select(int id){selected=id;Refresh();}
  void Refresh(){foreach(var p in zones){p.Value.BorderBrush=p.Key==selected?accent:outline;p.Value.Background=pressed[p.Key]?accent:idle;TextBlock text=p.Value.Child as TextBlock;if(text!=null)text.Foreground=pressed[p.Key]?Ui.Inset:Ui.Text;if(faceGlyphs.ContainsKey(p.Key))faceGlyphs[p.Key].Fill=pressed[p.Key]?Ui.Inset:Ui.Text;if(functionIcons.ContainsKey(p.Key))RecolorIcon(functionIcons[p.Key],pressed[p.Key]?Ui.Inset:Ui.Text);}foreach(var p in sculpted){bool direction=p.Key>=13&&p.Key<=16;p.Value.Fill=pressed[p.Key]?accent:direction?Brushes.Transparent:idle;p.Value.Stroke=direction?Brushes.Transparent:p.Key==selected?accent:outline;if(direction)directionEdges[p.Key].Stroke=p.Key==selected?accent:Brushes.Transparent;if(labels.ContainsKey(p.Key))labels[p.Key].Foreground=pressed[p.Key]?Ui.Inset:Ui.Text;if(directionMarks.ContainsKey(p.Key))directionMarks[p.Key].Stroke=pressed[p.Key]?Ui.Inset:outline;}}
  public void Update(PadStatus status){bool[] current=status==null?new bool[19]:status.Buttons;bool changed=false;for(int i=0;i<19;i++)if(current[i]!=pressed[i]){changed=true;break;}if(changed){pressed=current;Refresh();}Move(left,status,4);Move(right,status,6);}
  static void Move(TranslateTransform transform,PadStatus status,int offset){transform.X=status==null?0:Math.Max(-1,(status.Raw[offset]-128)/127.0)*13;transform.Y=status==null?0:Math.Max(-1,(status.Raw[offset+1]-128)/127.0)*13;}
  public void VerifyMotion(){PadStatus input=new PadStatus{HasInput=true};input.Raw[1]=1;input.Raw[2]=64;input.Raw[3]=68;input.Raw[4]=255;input.Raw[5]=0;input.Raw[6]=0;input.Raw[7]=255;Update(input);if(left.X!=13||left.Y!=-13||right.X!=-13||right.Y!=13||zones[0].Background!=accent||sculpted[4].Fill!=accent||sculpted[13].Fill!=accent||sculpted[16].Fill!=accent)throw new Exception("Controller motion, shoulder or diagonal D-pad feedback failed.");if(sculpted.ContainsKey(17)||sculpted.ContainsKey(18)||labels.ContainsKey(17)||labels.ContainsKey(18))throw new Exception("L2/R2 must not be duplicated in the controller drawing.");if(functionIcons.Count!=4||!new[]{6,7,11,12}.All(id=>functionIcons.ContainsKey(id)&&functionIcons[id].Children.Count>0))throw new Exception("Vector function icons missing.");Select(14);if(sculpted[14].Stroke!=Brushes.Transparent||directionEdges[14].Stroke!=accent)throw new Exception("D-pad selection failed.");Viewbox logo=zones[10].Child as Viewbox;Canvas logoCanvas=logo==null?null:logo.Child as Canvas;if(logoCanvas==null||logoCanvas.Width!=120||logoCanvas.Height!=80||logoCanvas.Children.Count!=1||logoCanvas.Children.Cast<Path>().Any(p=>p.Fill!=Brushes.White))throw new Exception("Official white vector Stadia logo missing.");Update(null);if(left.X!=0||left.Y!=0||right.X!=0||right.Y!=0||zones[0].Background!=idle||sculpted[4].Fill!=idle||sculpted[13].Fill!=Brushes.Transparent)throw new Exception("Controller did not reset after disconnect.");}
 }
}

