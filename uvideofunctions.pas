unit uvideofunctions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,FPimage,FPCanvas,FPImgCanv,math,
  IntfGraphics,lazcanvas,Graphics,GraphUtil,LCLType,ucapture
  ;

type
  THLSColor = record
    h,l,s : word;
  end;

  procedure CopyToWorkArea(x,y,width,height : Integer);stdcall;
  procedure ScaleImage(NewWidth : Integer;NewHeight : Integer);stdcall;
  function ImageWidth : Integer;stdcall;
  function ImageHeight : Integer;stdcall;
  procedure SetPixel(x,y : Integer; r,g,b : word);stdcall;
  procedure SetPixelHLS(x,y : Integer; h,l,s : word);stdcall;
  function GetPixel(x,y : Integer) : TFPColor;stdcall;
  function GetPixelHLS(x,y : Integer) : THLSColor;stdcall;
  procedure RefreshImage;stdcall;
  function LoadImage(aFile : PChar) : Boolean;stdcall;
  function SaveImage(aFile : PChar) : Boolean;stdcall;
  function ReloadWorkImage(aFile : PChar) : Boolean;stdcall;
  function SaveWorkImage(aFile : PChar) : Boolean;stdcall;

  var
    BaseImage : TLazIntfImage;
    Image : TLazIntfImage;

implementation

procedure CopyToWorkArea(x,y,width,height : Integer);stdcall;
begin
  if not Assigned(Image) then exit;
  Image.Width:=Width;
  Image.Height:=Height;
  Image.CopyPixels(BaseImage,x,y);
end;
procedure ScaleImage(NewWidth : Integer;NewHeight : Integer);stdcall;
var
  DestIntfImage: TLazIntfImage;
  DestCanvas: TLazCanvas;
begin
  if not Assigned(Image) then exit;
  if (Image.Height = 0)
  or (Image.Width = 0) then exit;
  DestIntfImage := TLazIntfImage.Create(NewWidth, NewHeight);
  DestIntfImage.DataDescription := GetDescriptionFromDevice(0);
  DestCanvas := TLazCanvas.Create(DestIntfImage);
  DestIntfImage.Width:=NewWidth;
  DestIntfImage.Height:=NewHeight;
  DestCanvas.Interpolation := TFPSharpInterpolation.Create;
  DestCanvas.StretchDraw(0, 0, NewWidth, NewHeight, Image);
  Image.Free;
  Image := DestIntfImage;
  DestCanvas.Free;
end;
function ImageWidth : Integer;stdcall;
begin
  result := 0;
  if Assigned(BaseImage) then
    Result := BaseImage.Width;
end;
function ImageHeight : Integer;stdcall;
begin
  result := 0;
  if Assigned(BaseImage) then
    Result := BaseImage.Height;
end;
procedure SetPixel(x,y : Integer; r,g,b : word);stdcall;
var
  aColor : TFPColor;
begin
  if not Assigned(Image) then exit;
  aColor.red:=r;
  aColor.green:=g;
  aColor.blue:=b;
  Image.Colors[x,y] := aColor;
end;
procedure SetPixelHLS(x,y : Integer; h,l,s : word);stdcall;
begin
  if not Assigned(Image) then exit;
  Image.Colors[x,y] := TColorToFPColor(HLStoColor(round(h/255),round(l/255),round(s/255)));
end;
function GetPixel(x,y : Integer) : TFPColor;stdcall;
begin
  if not Assigned(Image) then exit;
  if x>Image.Width then exit;
  if y>Image.Height then exit;
  if x<0 then exit;
  if y<0 then exit;
  Result := Image.Colors[x,y];
end;
function GetPixelHLS(x,y : Integer) : THLSColor;stdcall;
var
  h: Byte;
  l: Byte;
  s: Byte;
begin
  if not Assigned(Image) then exit;
  if x>Image.Width then exit;
  if y>Image.Height then exit;
  if x<0 then exit;
  if y<0 then exit;
  ColorToHLS(FPColorToTColor(Image.Colors[x,y]),h,l,s);
  Result.h := h*255;
  Result.l := l*255;
  Result.s := s*255;
end;
procedure RefreshImage;stdcall;
begin
end;
function LoadImage(aFile : PChar) : Boolean;stdcall;
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
    end;
  Image.DataDescription:=BaseImage.DataDescription;
  Image.CopyPixels(BaseImage);
end;
function SaveImage(aFile : PChar) : Boolean;stdcall;
begin
  result := False;
  if BaseImage = nil then exit;
  try
    BaseImage.SaveToFile(aFile);
    result := True;
  except
  end;
end;

function ReloadWorkImage(aFile: PChar): Boolean;stdcall;
begin
  result := False;
  try
    Image.LoadFromFile(aFile);
    result := True;
  except
  end;
end;

function SaveWorkImage(aFile: PChar): Boolean;stdcall;
begin
  result := False;
  if Image = nil then exit;
  try
    Image.SaveToFile(aFile);
    result := True;
  except
  end;
end;

end.

