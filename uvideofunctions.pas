unit uvideofunctions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,FPimage,FPCanvas,FPImgCanv,math,
  IntfGraphics,lazcanvas,Graphics,GraphUtil,LCLType
  {$IFDEF WINDOWS}
  ,ucapture_win
  {$ENDIF}
  ;

type
  THLSColor = record
    h,l,s : word;
  end;

  procedure CopyToWorkArea(x,y,width,height : Integer);{$IFDEF LIBRARY}stdcall;{$ENDIF}
  procedure ScaleImage(NewWidth : Integer;NewHeight : Integer);{$IFDEF LIBRARY}stdcall;{$ENDIF}
  function ImageWidth : Integer;{$IFDEF LIBRARY}stdcall;{$ENDIF}
  function ImageHeight : Integer;{$IFDEF LIBRARY}stdcall;{$ENDIF}
  procedure SetPixel(x,y : Integer; r,g,b : word);{$IFDEF LIBRARY}stdcall;{$ENDIF}
  procedure SetPixelHLS(x,y : Integer; h,l,s : word);{$IFDEF LIBRARY}stdcall;{$ENDIF}
  function GetPixel(x,y : Integer) : TFPColor;{$IFDEF LIBRARY}stdcall;{$ENDIF}
  function GetPixelHLS(x,y : Integer) : THLSColor;{$IFDEF LIBRARY}stdcall;{$ENDIF}
  procedure RefreshImage;{$IFDEF LIBRARY}stdcall;{$ENDIF}
  function LoadImage(aFile : PChar) : Boolean;{$IFDEF LIBRARY}stdcall;{$ENDIF}
  function SaveImage(aFile : PChar) : Boolean;{$IFDEF LIBRARY}stdcall;{$ENDIF}

  var
    BaseImage : TLazIntfImage;
    Image : TLazIntfImage;

implementation

procedure CopyToWorkArea(x,y,width,height : Integer);{$IFDEF LIBRARY}stdcall;{$ENDIF}
begin
  if not Assigned(Image) then exit;
  Image.Width:=Width;
  Image.Height:=Height;
  Image.CopyPixels(BaseImage);
end;
procedure ScaleImage(NewWidth : Integer;NewHeight : Integer);{$IFDEF LIBRARY}stdcall;{$ENDIF}
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
function ImageWidth : Integer;{$IFDEF LIBRARY}stdcall;{$ENDIF}
begin
  result := 0;
  if Assigned(BaseImage) then
    Result := BaseImage.Width;
end;
function ImageHeight : Integer;{$IFDEF LIBRARY}stdcall;{$ENDIF}
begin
  result := 0;
  if Assigned(BaseImage) then
    Result := BaseImage.Height;
end;
procedure SetPixel(x,y : Integer; r,g,b : word);{$IFDEF LIBRARY}stdcall;{$ENDIF}
var
  aColor : TFPColor;
begin
  if not Assigned(Image) then exit;
  aColor.red:=r;
  aColor.green:=g;
  aColor.blue:=b;
  Image.Colors[x,y] := aColor;
end;
procedure SetPixelHLS(x,y : Integer; h,l,s : word);{$IFDEF LIBRARY}stdcall;{$ENDIF}
begin
  if not Assigned(Image) then exit;
  Image.Colors[x,y] := TColorToFPColor(HLStoColor(round(h/255),round(l/255),round(s/255)));
end;
function GetPixel(x,y : Integer) : TFPColor;{$IFDEF LIBRARY}stdcall;{$ENDIF}
begin
  if not Assigned(Image) then exit;
  Result := Image.Colors[x,y];
end;
function GetPixelHLS(x,y : Integer) : THLSColor;{$IFDEF LIBRARY}stdcall;{$ENDIF}
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
procedure RefreshImage;{$IFDEF LIBRARY}stdcall;{$ENDIF}
var
  aMaskHandle: HBitmap;
  aHandle: HBitmap;
begin
  if not Assigned(Image) then
    begin
      Image := TLazIntfImage.Create(0,0);
      Image.DataDescription := GetDescriptionFromDevice(0);
    end;
  Image.CopyPixels(BaseImage);
end;
function LoadImage(aFile : PChar) : Boolean;{$IFDEF LIBRARY}stdcall;{$ENDIF}
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
  RefreshImage;
end;
function SaveImage(aFile : PChar) : Boolean;{$IFDEF LIBRARY}stdcall;{$ENDIF}
begin
  result := False;
  try
    BaseImage.SaveToFile(aFile);
    result := True;
  except
  end;
end;

end.

