{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit pscript_video_functions;

interface

uses
  uvideofunctions, ucapture, LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('pscript_video_functions', @Register);
end.
