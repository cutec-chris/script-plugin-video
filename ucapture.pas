unit ucapture;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, process,IntfGraphics;

function CaptureImage(dev: PChar;Width : Integer = 640;Height : Integer = 480): Boolean;{$IFDEF LIBRARY}stdcall;{$ENDIF}
function InitCapture(Width,Height : Integer): Boolean;{$IFDEF LIBRARY}stdcall;{$ENDIF}
function DeinitCapture: Boolean;{$IFDEF LIBRARY}stdcall;{$ENDIF}

implementation

uses uvideofunctions;

var
  CapProcess : TProcess;
  FWidth,FHeight : Integer;

function CaptureImage(dev: PChar; Width: Integer; Height: Integer): Boolean;
var
  i: Integer;
  aFS: TFileStream;
begin
  Result := False;
  InitCapture(Width,Height);
  DeleteFile(GetTempDir+'capture.png');
  for i := 0 to 100 do
    begin
      if FileExists(GetTempDir+'capture.png') then break;
      sleep(30);
    end;
  aFS := nil;
  while aFS = nil do
    begin
      try
        aFS := TFileStream.Create(GetTempDir+'capture.png',fmShareDenyRead);
      except
        sleep(20);
      end;
    end;
  aFS.Free;
  if not Assigned(BaseImage) then
    begin
      BaseImage := TLazIntfImage.Create(0,0);
      BaseImage.DataDescription := GetDescriptionFromDevice(0);
    end;
  if FileExists(GetTempDir+'capture.png') then
    begin
      BaseImage.LoadFromFile(GetTempDir+'capture.png');
      RefreshImage;
      Result:=True;
    end;
end;

function InitCapture(Width, Height: Integer): Boolean;
var
  i: Integer;
begin
  if (not Assigned(CapProcess)) or (Width<>FWidth) or (FHeight<>Height) then
    begin
      if Assigned(CapProcess) then CapProcess.Terminate(0);
      FreeAndNil(CapProcess);
      FWidth:=Width;
      FHeight:=Height;
      CapProcess := TProcess.Create(nil);
      CapProcess.Options:=[poNoConsole];
      {$IFDEF WINDOWS}
      CapProcess.CommandLine:='vfwcapture';
      {$ELSE}
      {$ENDIF}
      CapProcess.Execute;
    end;
end;

function DeinitCapture: Boolean;
begin
  FreeAndNIl(CapProcess);
end;

finalization
  if Assigned(CapProcess) then CapProcess.Terminate(0);
  FreeAndNIl(CapProcess);
end.

