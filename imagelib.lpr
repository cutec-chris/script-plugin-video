library imagelib;

{$mode objfpc}{$H+}

uses
  Classes,sysutils,general_nogui,FPimage,FPCanvas,FPImgCanv
  {$IFDEF WINDOWS}
  ,Windows
  {$ENDIF}
  ;

var
  BaseImage : TFPMemoryImage;
  Image : TFPMemoryImage;
  MaskImage : TFPMemoryImage;

type
  THLSColor = record
    h,l,s : word;
  end;

procedure CopyToWorkArea(x,y,width,height : Integer);
begin
  if not Assigned(Image) then exit;
  Image.Width:=Width;
  Image.Height:=Height;
  Image.Assign(BaseImage);// CopyPixels(BaseImage);
end;
procedure ScaleImage(NewWidth : Integer;NewHeight : Integer);
var
  DestIntfImage: TFPMemoryImage;
  DestCanvas: TFPImageCanvas;
begin
  if not Assigned(Image) then exit;
  if (Image.Height = 0)
  or (Image.Width = 0) then exit;
  DestIntfImage := TFPMemoryImage.Create(NewWidth, NewHeight);
  //DestIntfImage.DataDescription := GetDescriptionFromDevice(0);
  DestCanvas := TFPImageCanvas.Create(DestIntfImage);
  DestIntfImage.Width:=NewWidth;
  DestIntfImage.Height:=NewHeight;
  //DestCanvas.Interpolation := TFPSharpInterpolation.Create;
  DestCanvas.StretchDraw(0, 0, NewWidth, NewHeight, Image);
  Image.Free;
  Image := DestIntfImage;
  DestCanvas.Free;
end;
function ImageWidth : Integer;
begin
  result := 0;
  if Assigned(BaseImage) then
    Result := BaseImage.Width;
end;
function ImageHeight : Integer;
begin
  result := 0;
  if Assigned(BaseImage) then
    Result := BaseImage.Height;
end;
procedure SetPixel(x,y : Integer; r,g,b : word);
var
  aColor : TFPColor;
begin
  if not Assigned(Image) then exit;
  aColor.red:=r;
  aColor.green:=g;
  aColor.blue:=b;
  Image.Colors[x,y] := aColor;
end;
procedure SetPixelHLS(x,y : Integer; h,l,s : word);
begin
  if not Assigned(Image) then exit;
  //Image.Colors[x,y] := TColorToFPColor(HLStoColor(round(h/255),round(l/255),round(s/255)));
end;
function GetPixel(x,y : Integer) : TFPColor;
begin
  if not Assigned(Image) then exit;
  Result := Image.Colors[x,y];
end;
function GetPixelHLS(x,y : Integer) : THLSColor;
var
  h: Byte;
  l: Byte;
  s: Byte;
begin
  if not Assigned(Image) then exit;
  ColorToHLS(FPColorToTColor(Image.Colors[x,y]),h,l,s);
  Result.h := h*255;
  Result.l := l*255;
  Result.s := s*255;
end;
procedure RefreshImage;
var
  aMaskHandle: HBitmap;
  aHandle: HBitmap;
begin
  if not Assigned(FBitmap) then
    begin
      FBitmap := TBitmap.Create;
    end;
  if not Assigned(Image) then exit;
  if (Image.Height = 0)
  or (Image.Width = 0) then exit;
  (FBitmap.Canvas as TFPCustomCanvas).StretchDraw(0,0,FBitmap.Width,FBitmap.Height,Image);
  if Assigned(Onrefresh) then
    OnRefresh(nil);
end;
function LoadImage(aFile : string) : Boolean;
begin
  result := False;
  if Assigned(BaseImage) then BaseImage.Free;
  try
    BaseImage := TLazIntfImage.Create(0,0);
    BaseImage.DataDescription := GetDescriptionFromDevice(0);
    BaseImage.LoadFromFile(aFile);
    result := True;
  except
  end;
  if not Assigned(Image) then
    begin
      Image := TLazIntfImage.Create(0,0);
      Image.DataDescription := GetDescriptionFromDevice(0);
      RefreshImage;
    end;
  if not Assigned(FBaseBitmap) then FBaseBitmap := TBitmap.Create;
  FBaseBitmap.Height := BaseImage.Height;
  FBaseBitmap.Width := BaseImage.Width;
  (FBaseBitmap.Canvas as TFPCustomCanvas).StretchDraw(0,0,BaseImage.Width,BaseImage.Height,BaseImage);
  if Assigned(OnBaserefresh) then
    OnBaseRefresh(nil);
end;
function DoMaskImage(aPercent : Integer) : Boolean;
var
  x: Integer;
  y: Integer;
  aColor : TFPColor;
begin
  Result := False;
  aColor.alpha:=0;
  aColor.red:=65535;
  aColor.green:=65535;
  aColor.blue:=65535;
  if Assigned(MaskImage) then
    for x := 0 to BaseImage.Width-1 do
      for y := 0 to BaseImage.Height-1 do
        begin
          if CompareColors(BaseImage.Colors[x,y],MaskImage.Colors[x,y]) >= aPercent then
            begin
              BaseImage.Colors[x,y] := aColor;
            end;
        end;
end;
function SetMaskImage: Boolean;
begin
  if Assigned(MaskImage) then MaskImage.Free;
  MaskImage := TLazIntfImage.CreateCompatible(BaseImage,BaseImage.Width,BaseImage.Height);
  MaskImage.CopyPixels(BaseImage);
end;

function ScriptUnitDefinition : PChar;stdcall;
begin
  Result := 'unit ImageLib;'
       +#10+'interface'
       +#10+'type'
       +#10+'  TParityType = (NoneParity, OddParity, EvenParity);'
       +#10+'  TFPColor = record red,green,blue,alpha : word; end;'
       +#10+'  THLSColor = record h,l,s : word; end;'
       +#10+'  function CompareColors(Color1, Color2: TFPColor): integer;external ''CompareColors@%dllpath% stdcall'';'''
       +#10+'  function CalculateGray (From : TFPColor) : word;external ''CalculateGray@%dllpath% stdcall'';'''
       +#10+'  procedure CopyToWorkArea(x,y,width,height : Integer);external ''CopyToWorkArea@%dllpath% stdcall'';'''
       +#10+'  function CaptureImage(dev : string) : Boolean;external ''CaptureImage@%dllpath% stdcall'';'''
       +#10+'  function InitCapture : Boolean;external ''InitCapture@%dllpath% stdcall'';'''
       +#10+'  function SetMaskImage: Boolean;external ''SetMaskImage@%dllpath% stdcall'';'''
       +#10+'  function MaskImage(aPercent : Integer) : Boolean;external ''MaskImage@%dllpath% stdcall'';'''
       +#10+'  procedure ScaleImage(NewWidth : Integer;NewHeight : Integer);external ''ScaleImage@%dllpath% stdcall'';'''
       +#10+'  function ImageWidth : Integer;external ''ImageWidth@%dllpath% stdcall'';'''
       +#10+'  function ImageHeight : Integer;external ''ImageHeight@%dllpath% stdcall'';'''
       +#10+'  procedure SetPixel(x,y : Integer; r,g,b : word);external ''SetPixel@%dllpath% stdcall'';'''
       +#10+'  procedure SetPixelHLS(x,y : Integer; h,l,s : byte);external ''SetPixelHLS@%dllpath% stdcall'';'''
       +#10+'  function GetPixel(x,y : Integer) : TFPColor;external ''GetPixel@%dllpath% stdcall'';'''
       +#10+'  function GetPixelHLS(x,y : Integer) : THLSColor;external ''GetPixelHLS@%dllpath% stdcall'';'''
       +#10+'  function LoadImage(aImage : string) : Boolean;external ''LoadImage@%dllpath% stdcall'';'''
       +#10+'  procedure RefreshImage;external ''RefreshImage@%dllpath% stdcall'';'''
            ;
end;

procedure ScriptCleanup;stdcall;
begin

end;

exports
  CompareColors,
  CalculateGray,
  CopyToWorkArea,
  CaptureImage,
  InitCapture,
  SetMaskImage,
  MaskImage,
  ScaleImage,
  ImageWidth,
  ImageHeight,
  SetPixel,
  SetPixelHLS,
  GetPixel,
  GetPixelHLS,
  LoadImage,
  RefreshImage,

  ScriptUnitDefinition,
  ScriptCleanup;

end.
