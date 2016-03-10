unit ucapture;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, vfw, Windows,Graphics,ClipBrd,
  IntfGraphics,FPimage,FPCanvas;

function SelectSource : Boolean;
function SelectFormat : Boolean;
function SelectQuality : Boolean;

type
  {$IFDEF FPC}
    TMWndProc = Windows.WNDPROC;
  {$ELSE}
    TMWndProc = Pointer;
  {$ENDIF}
var
  OldProc: TMWndProc;
  FCapHandle:  THandle;             // Capture window handle
  FCreated:    Boolean = False;             // Window created
  FConnected:  Boolean;             // Driver connected
  FDriverCaps: TCapDriverCaps;      // Driver capabilities
  FLiveVideo:  Boolean;             // Live Video enabled
implementation

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

end.
