library video;

{$mode objfpc}{$H+}

uses
  Classes,sysutils,general_nogui,FPimage,FPCanvas,FPImgCanv,math,ucapture,
  IntfGraphics,lazcanvas,Graphics,GraphUtil,vfw,Clipbrd
  {$IFDEF WINDOWS}
  ,Windows
  {$ENDIF}
  ;

var
  BaseImage : TLazIntfImage;
  Image : TLazIntfImage;
  MaskImage : TLazIntfImage;
  FBaseBitmap : Graphics.TBitmap;
  FBitmap : Graphics.TBitmap;

type
  THLSColor = record
    h,l,s : word;
  end;

procedure CopyToWorkArea(x,y,width,height : Integer);stdcall;
begin
  if not Assigned(Image) then exit;
  Image.Width:=Width;
  Image.Height:=Height;
  Image.CopyPixels(BaseImage);
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
  Result := Image.Colors[x,y];
end;
function GetPixelHLS(x,y : Integer) : THLSColor;stdcall;
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
procedure RefreshImage;stdcall;
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
      RefreshImage;
    end;
  if not Assigned(FBaseBitmap) then FBaseBitmap := Graphics.TBitmap.Create;
  FBaseBitmap.Height := BaseImage.Height;
  FBaseBitmap.Width := BaseImage.Width;
  (FBaseBitmap.Canvas as TFPCustomCanvas).StretchDraw(0,0,BaseImage.Width,BaseImage.Height,BaseImage);
end;
function SaveImage(aFile : PChar) : Boolean;stdcall;
begin
  result := False;
  try
    BaseImage.SaveToFile(aFile);
    result := True;
  except
  end;
end;
function DoMaskImage(aPercent : Integer) : Boolean;stdcall;
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
function SetMaskImage: Boolean;stdcall;
begin
  if Assigned(MaskImage) then MaskImage.Free;
  MaskImage := TLazIntfImage.CreateCompatible(BaseImage,BaseImage.Width,BaseImage.Height);
  MaskImage.CopyPixels(BaseImage);
end;

procedure CapGrabFrame(Destination: Graphics.TBitmap);stdcall; // Get one live frame
var
  Stream : TFileStream;
  H: THandle;
  Bmp : Graphics.TBitmap;
begin
  capGrabFrameNoStop(FCapHandle);        // Copy the current frame to a buffer
  capEditCopy(FCapHandle);               // Copy from buffer to the clipboard
end;

function CaptureImage(dev: PChar): Boolean;stdcall;
var
  aPicture: TPicture;
begin
  CapGrabFrame(nil);
  Result := False;
  if Assigned(BaseImage) then BaseImage.Free;
  try
    BaseImage := TLazIntfImage.Create(0,0);
    //BaseImage.DataDescription := GetDescriptionFromDevice(GetDC(0));
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

procedure CapDestroy;stdcall;             // Destroy capture window
begin
  if FCreated then
  begin
    //DestroyWindow(FCapHandle);
    FCreated := False;
  end;
end;

procedure CapDisconnect;stdcall;          // Disconnect driver
begin
  if FConnected then
  begin
    capDriverDisconnect(FCapHandle);
    FConnected := False;
  end;
end;

function DeinitCapture: Boolean;stdcall;
begin
  if FCreated then
    begin
      CapDisconnect;
      CapDestroy;
    end;
end;

procedure CapCreate;stdcall;              // Create capture window
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

procedure CapConnect;stdcall;             // Connect/Reconnect window + driver
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

function InitCapture: Boolean;stdcall;
begin
  if not FCreated then
    begin
      CapCreate;
      CapConnect;
    end;
end;

function ScriptUnitDefinition : PChar;stdcall;
begin
  Result := 'unit video;'
       +#10+'interface'
       +#10+'type'
       +#10+'  TFPColor = record red : word;green : word;blue : word;alpha : word; end;'
       +#10+'  THLSColor = record h : word;l : word;s : word;end;'
       +#10+''
       +#10+'  function CompareColors(Color1, Color2: TFPColor): integer;external ''CompareColors@%dllpath% stdcall'';'
       +#10+'  function CalculateGray (From : TFPColor) : word;external ''CalculateGray@%dllpath% stdcall'';'
       +#10+'  procedure CopyToWorkArea(x,y,width,height : Integer);external ''CopyToWorkArea@%dllpath% stdcall'';'
       +#10+'  function CaptureImage(dev : PChar) : Boolean;external ''CaptureImage@%dllpath% stdcall'';'
       +#10+'  function InitCapture : Boolean;external ''InitCapture@%dllpath% stdcall'';'
       +#10+'  procedure ScaleImage(NewWidth : Integer;NewHeight : Integer);external ''ScaleImage@%dllpath% stdcall'';'
       +#10+'  function ImageWidth : Integer;external ''ImageWidth@%dllpath% stdcall'';'
       +#10+'  function ImageHeight : Integer;external ''ImageHeight@%dllpath% stdcall'';'
       +#10+'  procedure SetPixel(x,y : Integer; r,g,b : word);external ''SetPixel@%dllpath% stdcall'';'
       +#10+'  procedure SetPixelHLS(x,y : Integer; h,l,s : byte);external ''SetPixelHLS@%dllpath% stdcall'';'
       +#10+'  function GetPixel(x,y : Integer) : TFPColor;external ''GetPixel@%dllpath% stdcall'';'
       +#10+'  function GetPixelHLS(x,y : Integer) : THLSColor;external ''GetPixelHLS@%dllpath% stdcall'';'
       +#10+'  function LoadImage(aImage : PChar) : Boolean;external ''LoadImage@%dllpath% stdcall'';'
       +#10+'  function SaveImage(aImage : PChar) : Boolean;external ''SaveImage@%dllpath% stdcall'';'
       +#10+'  procedure RefreshImage;external ''RefreshImage@%dllpath% stdcall'';'
       +#10+'implementation'
       +#10+'end.'
            ;
end;

procedure ScriptCleanup;stdcall;
begin
  DeinitCapture;
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
  SaveImage,
  RefreshImage,

  ScriptUnitDefinition,
  ScriptCleanup;

end.
