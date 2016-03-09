library video;

{$mode objfpc}{$H+}

uses
  Classes,sysutils,general_nogui
  {$IFDEF WINDOWS}
  ,Windows
  {$ENDIF}
  ;



function ScriptDefinition : PChar;stdcall;
begin
  Result := 'unit SerialPort;'
       +#10+'interface'
       +#10+'type'
       +#10+'  TParityType = (NoneParity, OddParity, EvenParity);'
       +#10+'  function SerOpen(const DeviceName: String): LongInt;external ''SerOpen@%dllpath% stdcall'';'
       +#10+'  procedure SerClose(Handle: LongInt);external ''SerClose@%dllpath% stdcall'';'
       +#10+'  procedure SerFlush(Handle: LongInt);external ''SerFlush@%dllpath% stdcall'';'
       +#10+'  function SerRead(Handle: LongInt; Count: LongInt): string;'
       +#10+'  function SerReadTimeout(Handle: LongInt;Timeout: Integer;Count: LongInt) : string;'
       +#10+'  function SerWrite(Handle: LongInt; Data : PChar;Len : Integer): LongInt;external ''SerWrite@%dllpath% stdcall'';'
       +#10+'  procedure SerParams(Handle: LongInt; BitsPerSec: LongInt; ByteSize: Integer; Parity: TParityType; StopBits: Integer);external ''SerParams@%dllpath% stdcall'';'
       +#10+'  function SerGetCTS(Handle: LongInt) : Boolean;external ''SerGetCTS@%dllpath% stdcall'';'
       +#10+'  function SerGetDSR(Handle: LongInt) : Boolean;external ''SerGetDSR@%dllpath% stdcall'';'
       +#10+'  procedure SerSetRTS(Handle: LongInt;Value : Boolean);external ''SerSetRTS@%dllpath% stdcall'';'
       +#10+'  procedure SerSetDTR(Handle: LongInt;Value : Boolean);external ''SerSetDTR@%dllpath% stdcall'';'
       +#10+'  procedure SerRTSToggle(Handle: LongInt;Value : Boolean);external ''SerRTSToggle@%dllpath% stdcall'';'
       +#10+'  function SerPortNames: PChar;external ''SerPortNames@%dllpath% stdcall'';'

       +#10+'  function SerReadEx(Handle: LongInt; Count: LongInt): PChar;external ''SerReadEx@%dllpath% stdcall'';'
       +#10+'  function SerReadTimeoutEx(Handle: LongInt;var Data : PChar;Timeout: Integer;Count: LongInt) : Integer;external ''SerReadTimeoutEx@%dllpath% stdcall'';'
       +#10+'implementation'
       +#10+'  function SerRead(Handle: LongInt; Count: LongInt): string;'
       +#10+'  var aOut : PChar;'
       +#10+'      bOut : string;'
       +#10+'      i : Integer;'
       +#10+'  begin'
       +#10+'    Result := '''';'
       +#10+'    aOut := SerReadEx(Handle,Count);'
       +#10+'    bOut := aOut;'
       +#10+'    SetLength(Result,Count);'
       +#10+'    for i := 0 to Count-1 do'
       +#10+'      begin'
       +#10+'        Result := Result+chr(StrToInt(''$''+copy(bOut,0,2)));'
       +#10+'        bOut := copy(bOut,3,length(bOut));'
       +#10+'        if bOut='''' then break;'
       +#10+'      end;'
       +#10+'  end;'
       +#10+'  function SerReadTimeout(Handle: LongInt;Timeout: Integer;Count: LongInt) : string;'
       +#10+'  var aOut : PChar;'
       +#10+'      bOut : string;'
       +#10+'      a : Integer;'
       +#10+'  begin'
       +#10+'    Result := '''';'
       +#10+'    a := SerReadTimeoutEx(Handle,aOut,Timeout,Count);'
       +#10+'    bOut := aOut;'
       +#10+'    Result := '''''
       +#10+'    while a > 0 do'
       +#10+'      begin'
       +#10+'        Result := Result+chr(StrToInt(''$''+copy(bOut,0,2)));'
       +#10+'        bOut := copy(bOut,3,length(bOut));'
       +#10+'        if bOut='''' then break;'
       +#10+'        dec(a);'
       +#10+'      end;'
       +#10+'  end;'
       +#10+'end.'
            ;
end;

procedure ScriptCleanup;stdcall;
begin

end;

exports
  ScriptDefinition,
  ScriptCleanup;

end.
