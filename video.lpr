library video;

{$mode objfpc}{$H+}

uses
  Interfaces,Forms,
  Classes,sysutils,general_nogui,uvideofunctions
  {$ifdef WINDOWS}
  ,ucapture_win
  {$ENDIF}
  ;

function ScriptUnitDefinition : PChar;stdcall;
begin
  Result := 'unit video;'
       +#10+'interface'
       +#10+'type'
       +#10+'  TFPColor = record red : word;green : word;blue : word;alpha : word; end;'
       +#10+'  THLSColor = record h : word;l : word;s : word;end;'
       +#10+''
//       +#10+'  function CompareColors(Color1, Color2: TFPColor): integer;external ''CompareColors@%dllpath% stdcall'';'
//       +#10+'  function CalculateGray (From : TFPColor) : word;external ''CalculateGray@%dllpath% stdcall'';'
       +#10+'  procedure CopyToWorkArea(x,y,width,height : Integer);external ''CopyToWorkArea@%dllpath% stdcall'';'
       +#10+'  function CaptureImage(dev : PChar) : Boolean;external ''CaptureImage@%dllpath% stdcall'';'
//       +#10+'  function InitCapture : Boolean;external ''InitCapture@%dllpath% stdcall'';'
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
end;

exports
//  CompareColors,
//  CalculateGray,
  CopyToWorkArea,
  CaptureImage,
//  InitCapture,
//  SetMaskImage,
//  MaskImage,
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

initialization
  Application.Initialize;
end.
