unit WebSocket.Types.Frame;

interface

uses
  System.SysUtils;

type

  TwsFrame = record
  private
    FFin: Boolean;
    FRsv1: Boolean;
    FRsv2: Boolean;
    FRsv3: Boolean;
    FOpcode: Byte;
    FMasked: Boolean;

  public
    property Fin: Boolean read FFin write FFin;
    property Rsv1: Boolean read FRsv1 write FRsv1;
    property Rsv2: Boolean read FRsv2 write FRsv2;
    property Rsv3: Boolean read FRsv3 write FRsv3;
    property Opcode: Byte read FOpcode write FOpcode;
    property Masked: Boolean read FMasked write FMasked;
    class function Parse(ABytes: TBytes): TwsFrame; static;

  end;

implementation

uses
  WebSocket.Tools;

{ TwsFrame }

class function TwsFrame.Parse(ABytes: TBytes): TwsFrame;
var
  lPayloadLength: Integer;
begin
  Write('TwsFrame.Parse: ');
  TwsTools.PrintBytes(ABytes);
  Result.Fin := (ABytes[0] and $80) <> 0;
  Result.Rsv1 := (ABytes[0] and $40) <> 0;
  Result.Rsv2 := (ABytes[0] and $20) <> 0;
  Result.Rsv3 := (ABytes[0] and $10) <> 0;
  Result.Opcode := (ABytes[0] and $0F);
  Result.Masked := (ABytes[1] and $80) <> 0;
  lPayloadLength := ($7F and ABytes[1]);
end;

end.
