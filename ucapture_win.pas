unit ucapture_win;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils,Windows,IntfGraphics,GraphType;

function CaptureImage(dev: PChar): Boolean;{$IFDEF LIBRARY}stdcall;{$ENDIF}
function InitCapture: Boolean;{$IFDEF LIBRARY}stdcall;{$ENDIF}
function DeinitCapture: Boolean;{$IFDEF LIBRARY}stdcall;{$ENDIF}

implementation

uses uvideofunctions,yuvconverts;

const
  WM_CAP_START = WM_USER;
  WM_CAP_DRIVER_CONNECT       = WM_CAP_START+ 10;

  WM_CAP_SET_PREVIEW          = WM_CAP_START+ 50;
  WM_CAP_SET_OVERLAY          = WM_CAP_START+ 51;
  WM_CAP_SET_PREVIEWRATE      = WM_CAP_START+ 52;

  WM_CAP_GRAB_FRAME_NOSTOP    = WM_CAP_START+ 61;
  WM_CAP_SET_CALLBACK_FRAME   = WM_CAP_START+ 5;
  WM_CAP_GET_VIDEOFORMAT      = WM_CAP_START+ 44;
  WM_CAP_SET_VIDEOFORMAT      = WM_CAP_START+ 45;

  WM_CAP_DLG_VIDEOFORMAT      = WM_CAP_START+ 41;

type
  TVIDEOHDR= record
    lpData: Pointer; // address of video buffer
    dwBufferLength: DWord; // size, in bytes, of the Data buffer
    dwBytesUsed: DWord; // see below
    dwTimeCaptured: DWord; // see below
    dwUser: DWord; // user-specific data
    dwFlags: DWord; // see below
    dwReserved1, dwReserved2, dwReserved3: DWord; // reserved; do not use
  end;
  TVIDEOHDRPtr= ^TVideoHDR;

  DWordDim= array[1..32767] of DWord;
  PDWordDim = ^DWordDim;

  function capCreateCaptureWindow(lpszWindowName: LPCSTR;
  dwStyle: DWORD;
  x, y,
  nWidth,
  nHeight: integer;
  hwndParent: HWND;
  nID: integer): HWND; stdcall;
  external 'AVICAP32.DLL' name 'capCreateCaptureWindowA';

var
  FCapHandle: THandle;
  FCodec: TVideoCodec;
  FCaptured: Boolean;
  PICWIDTH : Integer = 640;
  PICHEIGHT : Integer = 480;

type
  TRGBTripleArray = array[0..32767] of TRGBTriple;
  PRGBTripleArray = ^TRGBTripleArray;

function FrameCallbackFunction(AHandle: hWnd; VIDEOHDR: TVideoHDRPtr): bool; stdcall;
var
  I: integer;
  aImg: TLazIntfImage;
  Row1: PDWordDim;
  ImgFormatDescription: TRawImageDescription;
  x: Integer;
  FBuf2 : array[0..(1920*1080)] of DWORD;
begin
  result:= true;
  try
    //Setlength(FBuf2,PICWIDTH*(PICHEIGHT+1)*sizeof(DWORD));
    ConvertCodecToRGB(FCodec, VideoHDR^.lpData, @FBuf2, PICWIDTH, PICHEIGHT);
    ImgFormatDescription.Init_BPP32_B8G8R8_BIO_TTB(PICWIDTH,PICHEIGHT);
    BaseImage.DataDescription := ImgFormatDescription;

    for I:= 1 to PICHEIGHT do
      begin
        Row1 := BaseImage.GetDataLineStart(PICHEIGHT-I);
        for x := PICWIDTH-1 downto 0 do
          Row1^[x] := FBuf2[(I*PICWIDTH)+x];
      end;
    SendMessage(FCapHandle, WM_CAP_SET_CALLBACK_FRAME, 0, 0);
    FCaptured:= True;
  except
  end;
end;

function CaptureImage(dev: PChar): Boolean;
var
  i: Integer;
begin
  InitCapture;
  if not Assigned(BaseImage) then
    begin
      BaseImage := TLazIntfImage.Create(0,0);
      BaseImage.DataDescription := GetDescriptionFromDevice(GetDC(0));
    end;
  FCaptured := False;
  SendMessage(FCapHandle, WM_CAP_SET_CALLBACK_FRAME, 0, integer(@FrameCallbackFunction));
  SendMessage(FCapHandle, WM_CAP_GRAB_FRAME_NOSTOP, 1, 0); // ist hintergrundlauff盲hig
  for i := 0 to 300 do
    begin
      if FCaptured then break;
      sleep(10);
    end;
  if FCaptured then
    RefreshImage;
end;

function InitCapture: Boolean;
var  BitmapInfo: TBitmapInfo;
begin
  if FCapHandle = 0 then
    begin
      FCapHandle:= capCreateCaptureWindow('Video', WS_CHILD {or WS_VISIBLE}, 0, 0, PICWIDTH, PICHEIGHT, GetDesktopWindow, 1);
      SendMessage(FCapHandle, WM_CAP_DRIVER_CONNECT, 0, 0);
      SendMessage(FCapHandle, WM_CAP_SET_PREVIEWRATE, 15, 0);
      sendMessage(FCapHandle, WM_CAP_SET_OVERLAY, 1, 0);
      SendMessage(FCapHandle, WM_CAP_SET_PREVIEW, 1, 0);

      SendMessage(FCapHandle, WM_CAP_DLG_VIDEOFORMAT,1,0);     // -this was commented out

      FillChar(BitmapInfo, SizeOf(BitmapInfo), 0);
      SendMessage(FCapHandle, WM_CAP_GET_VIDEOFORMAT, SizeOf(BitmapInfo), Integer(@BitmapInfo));
      PICWIDTH:=BitmapInfo.bmiHeader.biWidth;
      PICHEIGHT:=BitmapInfo.bmiHeader.biHeight;
      FCodec:= BICompressionToVideoCodec(bitmapinfo.bmiHeader.biCompression);
    end;
end;

function DeinitCapture: Boolean;
begin

end;


end.

