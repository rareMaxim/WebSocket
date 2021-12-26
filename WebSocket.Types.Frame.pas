unit WebSocket.Types.Frame;

interface

uses
  System.SysUtils;

type
  TwsFrame = class
  private
    FFin: Boolean;
    FRsv1: Boolean;
    FRsv2: Boolean;
    FRsv3: Boolean;
    FOpcode: Byte;
    FMasked: Boolean;
    FPayloadLength: Integer;
    FMaskingKey: TBytes;
  protected
    class procedure FillFrameByHeader(ARawBytes: TBytes; var AOutFrame: TwsFrame);
  public
    class function Print(AFrame: TwsFrame): string;
    constructor Create(ARawBytes: TBytes); virtual;
    property Fin: Boolean read FFin write FFin;
    property Rsv1: Boolean read FRsv1 write FRsv1;
    property Rsv2: Boolean read FRsv2 write FRsv2;
    property Rsv3: Boolean read FRsv3 write FRsv3;
    property Opcode: Byte read FOpcode write FOpcode;
    property Masked: Boolean read FMasked write FMasked;
    property PayloadLength: Integer read FPayloadLength write FPayloadLength;
    property MaskingKey: TBytes read FMaskingKey write FMaskingKey;
  end;

implementation

uses
  WebSocket.Tools;

{ TwsFrameBase }

constructor TwsFrame.Create(ARawBytes: TBytes);
begin
  TwsFrame.FillFrameByHeader(ARawBytes, Self);
end;

class procedure TwsFrame.FillFrameByHeader(ARawBytes: TBytes; var AOutFrame: TwsFrame);
var
  lByteCount: Integer;
begin
  Write('TwsFrame.Parse: ');
  TwsTools.PrintBytes(ARawBytes);
  AOutFrame.Fin := (ARawBytes[0] and $80) <> 0;
  AOutFrame.Rsv1 := (ARawBytes[0] and $40) <> 0;
  AOutFrame.Rsv2 := (ARawBytes[0] and $20) <> 0;
  AOutFrame.Rsv3 := (ARawBytes[0] and $10) <> 0;
  AOutFrame.Opcode := (ARawBytes[0] and $0F);
  AOutFrame.Masked := (ARawBytes[1] and $80) <> 0;
  AOutFrame.PayloadLength := ($7F and ARawBytes[1]);
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
    AOutFrame.PayloadLength := AOutFrame.PayloadLength or (ARawBytes[1] and $FF) shl (8 * lByteCount);
  end;
  // TODO: add control frame payload length validation here
  if AOutFrame.Masked then
  begin
    // Masking Key
    SetLength(AOutFrame.FMaskingKey, 4);
    AOutFrame.FMaskingKey := copy(ARawBytes, 2, 4);
  end;

end;

class function TwsFrame.Print(AFrame: TwsFrame): string;
const
  OUT_FORMAT = sLineBreak + //
    '                    FIN: %s' + sLineBreak + //
    '                   RSV1: %s' + sLineBreak + //
    '                   RSV2: %s' + sLineBreak + //
    '                   RSV3: %s' + sLineBreak + //
    '                 Opcode: %d' + sLineBreak + //
    '                   MASK: %s' + sLineBreak + //
    '         Payload Length: %d' + sLineBreak + //
    'Extended Payload Length: %s' + sLineBreak + //
    '            Masking Key: %s ' + sLineBreak + //
    '           Payload Data: %s';
begin

  Result := string.Format(OUT_FORMAT, [ //
    AFrame.Fin.ToString(TUseBoolStrs.True), // FIN
    AFrame.Rsv1.ToString(TUseBoolStrs.True), // RSV1
    AFrame.Rsv2.ToString(TUseBoolStrs.True), // RSV2
    AFrame.Rsv3.ToString(TUseBoolStrs.True), // RSV3
    AFrame.Opcode, // Opcode
    AFrame.Masked.ToString(TUseBoolStrs.True), // MASK
    AFrame.PayloadLength, // Payload Length
    'WIP', // Extended Payload Length
    TwsTools.BytesToString(AFrame.MaskingKey), // Masking Key
    'WIP' // Payload Data
    ]);
end;

end.
