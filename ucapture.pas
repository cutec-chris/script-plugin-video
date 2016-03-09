unit ucapture;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uvisualscripting, vfw, ExtCtrls, Windows,Graphics,ClipBrd,
  IntfGraphics,FPimage,FPCanvas;

function Init : Boolean;
function Deinit : Boolean;
function SelectSource : Boolean;
function SelectFormat : Boolean;
function SelectQuality : Boolean;
function CaptureImage(dev : string) : Boolean;

type
  {$IFDEF FPC}
    TMWndProc = Windows.WNDPROC;
  {$ELSE}
    TMWndProc = Pointer;
  {$ENDIF}
var
  pCapture : TPanel;
  OldProc: TMWndProc;
implementation
var
  FCapHandle:  THandle;             // Capture window handle
  FCreated:    Boolean = False;             // Window created
  FConnected:  Boolean;             // Driver connected
  FDriverCaps: TCapDriverCaps;      // Driver capabilities
  FLiveVideo:  Boolean;             // Live Video enabled

function MsgProc(Handle: HWnd; Msg: UInt; WParam: Windows.WParam;
    LParam: Windows.LParam): LResult; stdcall;
begin
  {
  if Msg = WM_TSRECORD then
    CapRecord
  else if Msg = WM_TSSTOP then
    CapStop
  else
  }
    Result := Windows.CallWindowProc(OldProc, Handle, Msg, WParam, LParam);
end;

procedure Hook;
begin
//  OldProc := TMWndProc(Windows.GetWindowLong(Handle, GWL_WNDPROC));
//  Windows.SetWindowLong(Handle, GWL_WNDPROC, LongInt(@MsgProc));
end;

procedure Unhook;
begin
//  if Assigned(OldProc) then
//    Windows.SetWindowLong(Handle, GWL_WNDPROC, LongInt(OldProc));
  OldProc := nil;
end;

procedure CapDestroy;             // Destroy capture window
begin
  if FCreated then
  begin
    //DestroyWindow(FCapHandle);
    FCreated := False;
  end;
end;

procedure CapCreate;              // Create capture window
begin
  CapDestroy; // Destroy if necessary
  with pCapture do
    FCapHandle := capCreateCaptureWindow('Video Window',
      WS_CHILDWINDOW {or WS_VISIBLE} or WS_CLIPCHILDREN or WS_CLIPSIBLINGS
      //or WS_OVERLAPPED or WS_SIZEBOX
      , 5, 5, Width-10, Height-10, Handle, 0);

  if FCapHandle <> 0 then
    FCreated := True
  else
  begin
    FCreated := False;
  end;
end;

procedure CapDisconnect;          // Disconnect driver
begin
  if FConnected then
  begin
    capDriverDisconnect(FCapHandle);
    FConnected := False;
  end;
end;

procedure CapConnect;             // Connect/Reconnect window + driver
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

procedure CapGrabFrame(Destination: Graphics.TBitmap); // Get one live frame
var
  Stream : TFileStream;
  H: THandle;
  Bmp : Graphics.TBitmap;
begin
  capGrabFrameNoStop(FCapHandle);        // Copy the current frame to a buffer
  capEditCopy(FCapHandle);               // Copy from buffer to the clipboard
end;

function Init: Boolean;
begin
  if not FCreated then
    begin
      CapCreate;
      CapConnect;
    end;
end;

function Deinit: Boolean;
begin
  if FCreated then
    begin
      CapDisconnect;
      CapDestroy;
    end;
end;

function SelectSource: Boolean;
begin
  capDlgVideoSource(FCapHandle);
end;

function SelectFormat: Boolean;
begin
  capDlgVideoFormat(FCapHandle);
end;

function SelectQuality: Boolean;
begin
  capDlgVideoCompression(FCapHandle);
end;

function CaptureImage(dev: string): Boolean;
var
  aPicture: TPicture;
begin
  CapGrabFrame(nil);
  Result := False;
  if Assigned(BaseImage) then BaseImage.Free;
  try
    BaseImage := TLazIntfImage.Create(0,0);
    BaseImage.DataDescription := GetDescriptionFromDevice(0);
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
  if not Assigned(FBaseBitmap) then FBaseBitmap := TBitmap.Create;
  FBaseBitmap.Height := BaseImage.Height;
  FBaseBitmap.Width := BaseImage.Width;
  (FBaseBitmap.Canvas as TFPCustomCanvas).StretchDraw(0,0,BaseImage.Width,BaseImage.Height,BaseImage);
  if Assigned(OnBaserefresh) then
    OnBaseRefresh(nil);
end;

finalization
  DeInit;

end.
