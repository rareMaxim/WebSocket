unit WebSocket.Types.Frame;

interface

(*
  0                   1                   2                   3
  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
  +-+-+-+-+-------+-+-------------+-------------------------------+
  |F|R|R|R| opcode|M| Payload len |    Extended payload length    |
  |I|S|S|S|  (4)  |A|     (7)     |             (16/64)           |
  |N|V|V|V|       |S|             |   (if payload len==126/127)   |
  | |1|2|3|       |K|             |                               |
  +-+-+-+-+-------+-+-------------+ - - - - - - - - - - - - - - - +
  |     Extended payload length continued, if payload len == 127  |
  + - - - - - - - - - - - - - - - +-------------------------------+
  |                               |Masking-key, if MASK set to 1  |
  +-------------------------------+-------------------------------+
  | Masking-key (continued)       |          Payload Data         |
  +-------------------------------- - - - - - - - - - - - - - - - +
  :                     Payload Data continued ...                :
  + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +
  |                     Payload Data continued ...                |
  +---------------------------------------------------------------+

*)
uses
  System.Classes,
  System.SysUtils;

type
{$SCOPEDENUMS ON}
  TwsFin = (More = $0, Final = $1);
  TwsRsv = (Off = $0, On = $1);
  TwsOpcode = (Cont = $0, Text = $1, Binary = $2, Z3, Z4, Z5, Z6, Z7, Close = $8, Ping = $9, Pong = $A);
{$SCOPEDENUMS  OFF}

  TwsFrame = class
  private
    FByteStream: TBytesStream;
    FFin: TwsFin;
    FRsv1: TwsRsv;
    FRsv2: TwsRsv;
    FRsv3: TwsRsv;
    FOpcode: TwsOpcode;
    FMasked: Boolean;
    FPayloadLength: Integer;
    FMaskingKey: TBytes;
    FPayload: TBytes;
  protected

    class procedure FillFrameByHeader(AByteStream: TBytesStream; var AOutFrame: TwsFrame);

  public
    class function Print(AFrame: TwsFrame): string;
    constructor Create; overload; virtual;
    constructor Create(ARawBytes: TBytes); overload; virtual;
    constructor CreatePongFrame;
    property Fin: TwsFin read FFin write FFin;
    property Rsv1: TwsRsv read FRsv1 write FRsv1;
    property Rsv2: TwsRsv read FRsv2 write FRsv2;
    property Rsv3: TwsRsv read FRsv3 write FRsv3;
    property Opcode: TwsOpcode read FOpcode write FOpcode;
    property Masked: Boolean read FMasked write FMasked;
    property PayloadLength: Integer read FPayloadLength write FPayloadLength;
    property MaskingKey: TBytes read FMaskingKey write FMaskingKey;
    property Payload: TBytes read FPayload write FPayload;
  end;

implementation

uses
  System.Rtti,
  WebSocket.Tools;

{ TwsFrameBase }

constructor TwsFrame.Create(ARawBytes: TBytes);
begin
  Write('TwsFrame.Parse: ');
  TwsTools.PrintBytes(ARawBytes);
  FByteStream := TBytesStream.Create(ARawBytes);
  TwsFrame.FillFrameByHeader(FByteStream, Self);
end;

constructor TwsFrame.Create;
begin
  FFin := TwsFin.Final;
end;

constructor TwsFrame.CreatePongFrame;
begin

end;

class procedure TwsFrame.FillFrameByHeader(AByteStream: TBytesStream; var AOutFrame: TwsFrame);
var
  lByte: Byte;
  lByteCount: Integer;
begin
  AByteStream.ReadData(lByte);
  if (lByte and $80) <> 0 then
    AOutFrame.Fin := TwsFin.Final
  else
    AOutFrame.Fin := TwsFin.More;
  if (lByte and $40) <> 0 then
    AOutFrame.Rsv1 := TwsRsv.On
  else
    AOutFrame.Rsv1 := TwsRsv.Off;
  if (lByte and $20) <> 0 then
    AOutFrame.Rsv2 := TwsRsv.On
  else
    AOutFrame.Rsv1 := TwsRsv.Off;
  if (lByte and $10) <> 0 then
    AOutFrame.Rsv3 := TwsRsv.On
  else
    AOutFrame.Rsv1 := TwsRsv.Off;
  AOutFrame.Opcode := TwsOpcode(lByte and $0F);
  AByteStream.ReadData(lByte);
  AOutFrame.Masked := (lByte and $80) <> 0;
  AOutFrame.PayloadLength := ($7F and lByte);
  lByteCount := 0;
  if AOutFrame.PayloadLength = $7F then
  begin
    // 8 byte extended payload length
    lByteCount := 8;
  end
  else if AOutFrame.PayloadLength = $7E then
  begin
    // 2 bytes extended payload length
    lByteCount := 2;
  end;
  // Decode Payload Length
  Dec(lByteCount);
  while (lByteCount > 0) do
  begin
    Dec(lByteCount);
    AOutFrame.PayloadLength := AOutFrame.PayloadLength or (lByte and $FF) shl (8 * lByteCount);
  end;
  // TODO: add control frame payload length validation here
  if AOutFrame.Masked then
  begin
    // Masking Key
    SetLength(AOutFrame.FMaskingKey, 4);
    AByteStream.ReadData(AOutFrame.FMaskingKey, 4);
  end;
  SetLength(AOutFrame.FPayload, AOutFrame.FPayloadLength);
  AByteStream.ReadData(AOutFrame.FPayload, AOutFrame.FPayloadLength);
end;

class function TwsFrame.Print(AFrame: TwsFrame): string;
const
  OUT_FORMAT = sLineBreak + //
    '                    FIN: %s' + sLineBreak + //
    '                   RSV1: %s' + sLineBreak + //
    '                   RSV2: %s' + sLineBreak + //
    '                   RSV3: %s' + sLineBreak + //
    '                 Opcode: %s' + sLineBreak + //
    '                   MASK: %s' + sLineBreak + //
    '         Payload Length: %d' + sLineBreak + //
    'Extended Payload Length: %s' + sLineBreak + //
    '            Masking Key: %s ' + sLineBreak + //
    '           Payload Data: %s';
var
  lFin: string;
  lRsv1, lRsv2, lRsv3: string;
  lOpCode: string;
begin;
  lFin := TRttiEnumerationType.GetName<TwsFin>(AFrame.Fin);
  lRsv1 := TRttiEnumerationType.GetName<TwsRsv>(AFrame.FRsv1);
  lRsv2 := TRttiEnumerationType.GetName<TwsRsv>(AFrame.FRsv2);
  lRsv3 := TRttiEnumerationType.GetName<TwsRsv>(AFrame.FRsv3);
  lOpCode := TRttiEnumerationType.GetName<TwsOpcode>(AFrame.FOpcode);
  Result := string.Format(OUT_FORMAT, [ //
    lFin, // FIN
    lRsv1, // RSV1
    lRsv2, // RSV2
    lRsv3, // RSV3
    lOpCode, // Opcode
    AFrame.Masked.ToString(TUseBoolStrs.True), // MASK
    AFrame.PayloadLength, // Payload Length
    'WIP', // Extended Payload Length
    TwsTools.BytesToString(AFrame.MaskingKey), // Masking Key
    TwsTools.BytesToString(AFrame.FPayload) // Payload Data
    ]);
end;

end.
