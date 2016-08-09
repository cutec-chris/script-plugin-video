unit uvideofunctions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,FPimage,FPCanvas,FPImgCanv,math,ucapture,
  IntfGraphics,lazcanvas,Graphics,GraphUtil
  {$IFDEF WINDOWS}
  ,Windows,vfw,Clipbrd
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
  function CaptureImage(dev: PChar): Boolean;{$IFDEF LIBRARY}stdcall;{$ENDIF}
  function DeinitCapture: Boolean;{$IFDEF LIBRARY}stdcall;{$ENDIF}

implementation

var
  BaseImage : TLazIntfImage;
  Image : TLazIntfImage;
  MaskImage : TLazIntfImage;
  FBaseBitmap : Graphics.TBitmap;
  FBitmap : Graphics.TBitmap;

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
  if not Assigned(FBitmap) then
    begin
      FBitmap := Graphics.TBitmap.Create;
    end;
  if not Assigned(Image) then exit;
  if (Image.Height = 0)
  or (Image.Width = 0) then exit;
  (FBitmap.Canvas as TFPCustomCanvas).StretchDraw(0,0,FBitmap.Width,FBitmap.Height,Image);
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
      RefreshImage;
    end;
  if not Assigned(FBaseBitmap) then FBaseBitmap := Graphics.TBitmap.Create;
  FBaseBitmap.Height := BaseImage.Height;
  FBaseBitmap.Width := BaseImage.Width;
  (FBaseBitmap.Canvas as TFPCustomCanvas).StretchDraw(0,0,BaseImage.Width,BaseImage.Height,BaseImage);
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
procedure CapGrabFrame(Destination: Graphics.TBitmap);{$IFDEF LIBRARY}stdcall;{$ENDIF} // Get one live frame
var
  Stream : TFileStream;
  H: THandle;
  Bmp : Graphics.TBitmap;
begin
  capGrabFrameNoStop(FCapHandle);        // Copy the current frame to a buffer
  capEditCopy(FCapHandle);               // Copy from buffer to the clipboard
end;
function CaptureImage(dev: PChar): Boolean;{$IFDEF LIBRARY}stdcall;{$ENDIF}
var
  aPicture: TPicture;
begin
  CapGrabFrame(nil);
  Result := False;
  if Assigned(BaseImage) then BaseImage.Free;
  try
    BaseImage := TLazIntfImage.Create(0,0);
    BaseImage.DataDescription := GetDescriptionFromDevice(GetDC(0));
  except
  end;
  if Clipboard.HasPictureFormat then // Load the frame/image from clipboard
    begin
      result := True;
      aPicture := TPicture.Create;
      aPicture.Assign(Clipboard);
      BaseImage.LoadFromBitmap(aPicture.Bitmap.handle,aPicture.Bitmap.MaskHandle);
      aPicture.Free;
    end;
  if not Assigned(Image) then
    begin
      Image := TLazIntfImage.Create(0,0);
      Image.DataDescription := GetDescriptionFromDevice(0);
    end;
  RefreshImage;
if not Assigned(FBaseBitmap) then FBaseBitmap := Graphics.TBitmap.Create;
  FBaseBitmap.Height := BaseImage.Height;
  FBaseBitmap.Width := BaseImage.Width;
  (FBaseBitmap.Canvas as TFPCustomCanvas).StretchDraw(0,0,BaseImage.Width,BaseImage.Height,BaseImage);
end;
procedure CapDestroy;{$IFDEF LIBRARY}stdcall;{$ENDIF}             // Destroy capture window
begin
  if FCreated then
  begin
    //DestroyWindow(FCapHandle);
    FCreated := False;
  end;
end;
procedure CapDisconnect;{$IFDEF LIBRARY}stdcall;{$ENDIF}          // Disconnect driver
begin
  if FConnected then
  begin
    capDriverDisconnect(FCapHandle);
    FConnected := False;
  end;
end;
function DeinitCapture: Boolean;{$IFDEF LIBRARY}stdcall;{$ENDIF}
begin
  if FCreated then
    begin
      CapDisconnect;
      CapDestroy;
    end;
end;
procedure CapCreate;{$IFDEF LIBRARY}stdcall;{$ENDIF}              // Create capture window
begin
  CapDestroy; // Destroy if necessary
  FCapHandle := capCreateCaptureWindow('Video Window',
    WS_CHILDWINDOW {or WS_VISIBLE} or WS_CLIPCHILDREN or WS_CLIPSIBLINGS
    //or WS_OVERLAPPED or WS_SIZEBOX
    , 5, 5, 0, 0, 0, 0);

  if FCapHandle <> 0 then
    FCreated := True
  else
  begin
    FCreated := False;
  end;
end;
procedure CapConnect;{$IFDEF LIBRARY}stdcall;{$ENDIF}             // Connect/Reconnect window + driver
begin
  if FCreated then
  begin
    CapDisconnect;                           // Disconnect if necessary
    if capDriverConnect(FCapHandle, 0) then  // Connect the Capture Driver
    begin
      FConnected := True;
      capDriverGetCaps(FCapHandle, @FDriverCaps, SizeOf(TCapDriverCaps));
    end
    else
    begin
      FConnected := False;
    end;
  end;
end;
function InitCapture: Boolean;{$IFDEF LIBRARY}stdcall;{$ENDIF}
begin
  if not FCreated then
    begin
      CapCreate;
      CapConnect;
    end;
end;


end.

