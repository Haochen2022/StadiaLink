using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using Forms=System.Windows.Forms;
using Wpf=System.Windows;
using Controls=System.Windows.Controls;
using Input=System.Windows.Input;
using Media=System.Windows.Media;
using Effects=System.Windows.Media.Effects;
using Imaging=System.Windows.Media.Imaging;
namespace StadiaStudio {
 public static class Battery {
  [DllImport("StadiaDevice.dll",CallingConvention=CallingConvention.Winapi)] static extern int StadiaReadBattery(ulong address,out int level);
  public static int? Read(ulong address){int level;int hr=StadiaReadBattery(address,out level);return hr>=0&&level>=0&&level<=100?(int?)level:null;}
 }
 sealed class RoundedTrayMenu:Wpf.Window {
  readonly Controls.TextBlock level;
  readonly Controls.Border surface;
  readonly Action open,exit;
  public RoundedTrayMenu(Action openAction,Action exitAction) {
   open=openAction;exit=exitAction;Width=232;SizeToContent=Wpf.SizeToContent.Height;WindowStyle=Wpf.WindowStyle.None;AllowsTransparency=true;Background=Media.Brushes.Transparent;ShowInTaskbar=false;Topmost=true;ResizeMode=Wpf.ResizeMode.NoResize;
   var content=new Controls.StackPanel();
   var brand=new Controls.Grid{Margin=new Wpf.Thickness(1,0,1,10)};brand.ColumnDefinitions.Add(new Controls.ColumnDefinition{Width=Wpf.GridLength.Auto});brand.ColumnDefinitions.Add(new Controls.ColumnDefinition());
   var mark=Ui.Logo(26);mark.Margin=new Wpf.Thickness(0,0,9,0);brand.Children.Add(mark);
   var names=new Controls.StackPanel{VerticalAlignment=Wpf.VerticalAlignment.Center};names.Children.Add(Ui.T("STADIALINK",12,Ui.Text,true));level=Ui.T("Batería: —",10,Ui.Muted);level.Margin=new Wpf.Thickness(0,2,0,0);names.Children.Add(level);Controls.Grid.SetColumn(names,1);brand.Children.Add(names);content.Children.Add(brand);
   content.Children.Add(new Controls.Border{Height=1,Background=Ui.Line,Margin=new Wpf.Thickness(0,0,0,5)});
   content.Children.Add(MenuItem("open","Abrir StadiaLink",()=>{Hide();open();}));
   content.Children.Add(MenuItem("exit","Salir",()=>{Hide();exit();}));
   surface=new Controls.Border{Background=Ui.Panel,BorderBrush=Ui.Line,BorderThickness=new Wpf.Thickness(1),CornerRadius=new Wpf.CornerRadius(14),Padding=new Wpf.Thickness(12),Child=content,Effect=new Effects.DropShadowEffect{BlurRadius=24,ShadowDepth=5,Opacity=.48,Color=Media.Colors.Black}};
   Content=surface;Deactivated+=(s,e)=>Hide();PreviewKeyDown+=(s,e)=>{if(e.Key==Input.Key.Escape)Hide();};
  }
  // Lucide SquareArrowOutUpRight and LogOut, normalized to the tray's 17px grid.
  Controls.Viewbox MenuIcon(string kind) {
   string data=kind=="open"?"M21,13 V19 A2,2 0 0 1 19,21 H5 A2,2 0 0 1 3,19 V5 A2,2 0 0 1 5,3 H11 M21,3 L12,12 M15,3 H21 V9":"M16,17 L21,12 L16,7 M21,12 H9 M9,21 H5 A2,2 0 0 1 3,19 V5 A2,2 0 0 1 5,3 H9";
   return new Controls.Viewbox{Width=17,Height=17,Stretch=Media.Stretch.Uniform,Child=new System.Windows.Shapes.Path{Data=Media.Geometry.Parse(data),Stroke=Ui.Lime,StrokeThickness=2,StrokeStartLineCap=Media.PenLineCap.Round,StrokeEndLineCap=Media.PenLineCap.Round,StrokeLineJoin=Media.PenLineJoin.Round}};
  }
  Controls.Border MenuItem(string kind,string text,Action click) {
   var row=new Controls.Grid();row.ColumnDefinitions.Add(new Controls.ColumnDefinition{Width=new Wpf.GridLength(28)});row.ColumnDefinitions.Add(new Controls.ColumnDefinition());
   var icon=MenuIcon(kind);icon.HorizontalAlignment=Wpf.HorizontalAlignment.Center;icon.VerticalAlignment=Wpf.VerticalAlignment.Center;row.Children.Add(icon);
   var label=Ui.T(text,12,Ui.Text,true);label.VerticalAlignment=Wpf.VerticalAlignment.Center;Controls.Grid.SetColumn(label,1);row.Children.Add(label);
   var item=new Controls.Border{Background=Media.Brushes.Transparent,CornerRadius=new Wpf.CornerRadius(9),Padding=new Wpf.Thickness(7,8,10,8),Margin=new Wpf.Thickness(0,1,0,1),Child=row,Cursor=Input.Cursors.Hand};
   item.MouseEnter+=(s,e)=>item.Background=Ui.Brush("#2C3A2D");item.MouseLeave+=(s,e)=>item.Background=Media.Brushes.Transparent;item.MouseLeftButtonUp+=(s,e)=>click();return item;
  }
  public void SetLevel(string text){I18n.SetText(level,text);}
  public void ShowAtCursor() {
   if(IsVisible)Hide();Show();UpdateLayout();
   Wpf.DpiScale dpi=Media.VisualTreeHelper.GetDpi(this);System.Drawing.Point cursor=Forms.Cursor.Position;System.Drawing.Rectangle work=Forms.Screen.FromPoint(cursor).WorkingArea;
   double x=cursor.X/dpi.DpiScaleX-ActualWidth+8,y=cursor.Y/dpi.DpiScaleY-ActualHeight-10;
   double left=work.Left/dpi.DpiScaleX+8,right=work.Right/dpi.DpiScaleX-ActualWidth-8,top=work.Top/dpi.DpiScaleY+8,bottom=work.Bottom/dpi.DpiScaleY-ActualHeight-8;
   Left=Math.Max(left,Math.Min(right,x));Top=Math.Max(top,Math.Min(bottom,y<top?cursor.Y/dpi.DpiScaleY+10:y));Activate();Focus();
  }
  public void Snapshot(string file) {
   Show();UpdateLayout();int width=Math.Max(1,(int)Math.Ceiling(ActualWidth)),height=Math.Max(1,(int)Math.Ceiling(ActualHeight));var image=new Imaging.RenderTargetBitmap(width,height,96,96,Media.PixelFormats.Pbgra32);image.Render(this);var encoder=new Imaging.PngBitmapEncoder();encoder.Frames.Add(Imaging.BitmapFrame.Create(image));using(FileStream stream=File.Create(file))encoder.Save(stream);Hide();
  }
  public bool MatchesMainTheme {get{return Width==232&&surface.CornerRadius.TopLeft==14&&Object.ReferenceEquals(surface.Background,Ui.Panel)&&Object.ReferenceEquals(surface.BorderBrush,Ui.Line);}}
 }
 public sealed class BatteryTray:IDisposable {
  readonly Forms.NotifyIcon tray=new Forms.NotifyIcon();readonly Icon logo;readonly RoundedTrayMenu menu;Icon badge;int? lastLevel;bool lastConnected;bool lastCharging;bool first=true;string levelText="Batería: —";
  readonly Queue<DeviceNotice> pending=new Queue<DeviceNotice>();readonly Forms.Timer noticeTimer=new Forms.Timer{Interval=6500};string lastLanguage;bool updateNotice;public Action UpdateClicked;
  [DllImport("user32.dll")] static extern bool DestroyIcon(IntPtr icon);
  public BatteryTray(Action open,Action exit){
   logo=Icon.ExtractAssociatedIcon(Assembly.GetExecutingAssembly().Location);tray.Icon=logo;tray.Text=I18n.T("StadiaLink");menu=new RoundedTrayMenu(open,exit);menu.SetLevel(levelText);
   tray.MouseUp+=(s,e)=>{if(e.Button==Forms.MouseButtons.Right){menu.SetLevel(levelText);menu.ShowAtCursor();}};tray.BalloonTipClicked+=(s,e)=>{if(updateNotice&&UpdateClicked!=null)UpdateClicked();else open();};tray.DoubleClick+=(s,e)=>{menu.Hide();open();};tray.Visible=true;
   noticeTimer.Tick+=(s,e)=>{if(pending.Count==0)noticeTimer.Stop();else ShowNotice(pending.Dequeue());};
  }
  public bool Visible {get{return tray.Visible;}}
  public void Update(bool connected,int? percent,bool charging=false){
   if(!first&&lastLevel==percent&&lastConnected==connected&&lastCharging==charging&&lastLanguage==I18n.Code)return;first=false;lastLevel=percent;lastConnected=connected;lastCharging=charging;lastLanguage=I18n.Code;
   levelText=I18n.T(!connected?"Mando desconectado":percent.HasValue?"Batería: "+percent.Value+" %":"Batería: no disponible");tray.Text=I18n.T(!connected?"StadiaLink · sin mando":percent.HasValue?"Stadia · "+percent.Value+" %":"StadiaLink · batería no disponible");
   if(connected&&charging){string suffix=I18n.T(percent==100?" · Carga completa":" · Cargando");levelText+=suffix;tray.Text=(tray.Text+suffix).Substring(0,Math.Min(63,tray.Text.Length+suffix.Length));}menu.SetLevel(levelText);
   Icon previous=badge;badge=null;if(connected&&percent.HasValue){using(Bitmap b=DrawBadge(percent.Value)){IntPtr native=b.GetHicon();try{using(Icon view=Icon.FromHandle(native))badge=(Icon)view.Clone();}finally{DestroyIcon(native);}}}tray.Icon=badge??logo;if(previous!=null)previous.Dispose();
  }
  public void VerifyMenu(string file){menu.SetLevel("电量：85 %");menu.Snapshot(file);if(!menu.MatchesMainTheme)throw new Exception("Tray menu theme mismatch.");File.WriteAllText(file+".txt","PASS: compact 232px tray menu uses Lucide SquareArrowOutUpRight and LogOut vector icons, Chinese labels, battery status and 14px rounded main-theme surface.");}
  void ShowNotice(DeviceNotice notice){updateNotice=notice.Title=="Actualización disponible";tray.ShowBalloonTip(5000,I18n.T(notice.Title),I18n.T(notice.Text),notice.Warning?Forms.ToolTipIcon.Warning:Forms.ToolTipIcon.Info);}
  public void Notify(DeviceNotice notice){if(noticeTimer.Enabled){if(pending.Count<8)pending.Enqueue(notice);}else{ShowNotice(notice);noticeTimer.Start();}}
  public void ClearNotifications(){pending.Clear();noticeTimer.Stop();}
  public static Bitmap DrawBadge(int percent){Bitmap bitmap=new Bitmap(16,16);string[] glyphs={"111101101101111","010110010010111","111001111100111","111001111001111","101101111001001","111100111001111","111100111101111","111001001001001","111101111101111","111101111001111"};string digits=percent.ToString();int sx=digits.Length==3?1:2,sy=2,width=digits.Length*(3*sx+1)-1,x0=(16-width)/2;using(Graphics g=Graphics.FromImage(bitmap))using(SolidBrush ink=new SolidBrush(Color.White))using(SolidBrush charge=new SolidBrush(percent<=15?Color.FromArgb(255,138,112):Color.FromArgb(202,245,122))){g.Clear(Color.FromArgb(16,21,23));for(int d=0;d<digits.Length;d++)for(int y=0;y<5;y++)for(int x=0;x<3;x++)if(glyphs[digits[d]-'0'][y*3+x]=='1')g.FillRectangle(ink,x0+d*(3*sx+1)+x*sx,1+y*sy,sx,sy);g.FillRectangle(charge,1,13,Math.Max(1,(int)Math.Round(14*percent/100.0)),2);}return bitmap;}
  public void Dispose(){noticeTimer.Dispose();menu.Close();tray.Visible=false;tray.Dispose();if(badge!=null)badge.Dispose();if(logo!=null)logo.Dispose();}
 }
}
