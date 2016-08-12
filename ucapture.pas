unit ucapture;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, process,IntfGraphics;

function CaptureImage(dev: PChar;Width : Integer = 640;Height : Integer = 480): Boolean;{$IFDEF LIBRARY}stdcall;{$ENDIF}
function InitCapture(dev : PChar;Width,Height : Integer): Boolean;{$IFDEF LIBRARY}stdcall;{$ENDIF}
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
  InitCapture(dev,Width,Height);
  if not Assigned(CapProcess) then exit;
  if not CapProcess.Active then exit;
  DeleteFile(GetTempDir+'capture.png');
  DeleteFile('frame.bmp');
  for i := 0 to 100 do
    begin
      if FileExists(GetTempDir+'capture.png') then break;
      if FileExists('frame.bmp') then break;
      sleep(30);
    end;
  if not FileExists(GetTempDir+'capture.png') then
    if not FileExists('frame.bmp') then
      exit;
  aFS := nil;
  while aFS = nil do
    begin
      try
        if FileExists(GetTempDir+'capture.png') then
          aFS := TFileStream.Create(GetTempDir+'capture.png',fmShareDenyRead)
        else if FileExists('frame.bmp') then
          aFS := TFileStream.Create('frame.bmp',fmShareDenyRead);
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
  if not Assigned(Image) then
    begin
      Image := TLazIntfImage.Create(0,0);
      Image.DataDescription := GetDescriptionFromDevice(0);
    end;
  if FileExists(GetTempDir+'capture.png') then
    begin
      BaseImage.LoadFromFile(GetTempDir+'capture.png');
      Image.DataDescription:=BaseImage.DataDescription;
      Image.CopyPixels(BaseImage);
      Result:=True;
    end
  else if FileExists('frame.bmp') then
    begin
      BaseImage.LoadFromFile('frame.bmp');
      Image.DataDescription:=BaseImage.DataDescription;
      Image.CopyPixels(BaseImage);
      Result:=True;
    end;
end;

function InitCapture(dev: PChar; Width, Height: Integer): Boolean;
var
  i: Integer;
begin
  if (not Assigned(CapProcess)) or (not CapProcess.Active) or (Width<>FWidth) or (FHeight<>Height) then
    begin
      if Assigned(CapProcess) then CapProcess.Terminate(0);
      FreeAndNil(CapProcess);
      FWidth:=Width;
      FHeight:=Height;
      CapProcess := TProcess.Create(nil);
      CapProcess.Options:=[poNoConsole];
      {$IFDEF WINDOWS}
      if Width>640 then
        CapProcess.CommandLine:='dscapture /width '+IntToStr(Width)+' /height '+IntToStr(Height)+' /period 100 /frames 60 /bmp'
      else
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

