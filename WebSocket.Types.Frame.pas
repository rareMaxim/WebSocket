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

  TwsFinhelper = record helper for TwsFin
    function ToString: string;
  end;

  TwsRsvhelper = record helper for TwsRsv
    function ToString: string;
  end;

  TwsOpcodehelper = record helper for TwsOpcode
    function ToString: string;
  end;

  TwsFrame = class
  private
    FFin: TwsFin;
    FRsv1: TwsRsv;
    FRsv2: TwsRsv;
    FRsv3: TwsRsv;
    FOpcode: TwsOpcode;
    FMasked: Boolean;
    FPayloadLength: Integer;
    FMaskingKey: TBytes;
    FPayload: TBytes;
    FFrameSize: Integer;
  protected
    FIsValidFrame: Boolean;
    class function DecodeFrame(const iData: TBytes; var AFrame: TwsFrame): Boolean;

  public
    class function Print(AFrame: TwsFrame): string;
    class function EncodeFrame(const iData: TBytes; const iCode: TwsOpcode; const iMask: Boolean): TBytes;
    constructor Create(ARawBytes: TBytes); overload; virtual;
    function ToText(const AForge: Boolean = True): string;
    property Fin: TwsFin read FFin write FFin;
    property Rsv1: TwsRsv read FRsv1 write FRsv1;
    property Rsv2: TwsRsv read FRsv2 write FRsv2;
    property Rsv3: TwsRsv read FRsv3 write FRsv3;
    property Opcode: TwsOpcode read FOpcode write FOpcode;
    property Masked: Boolean read FMasked write FMasked;
    property PayloadLength: Integer read FPayloadLength write FPayloadLength;
    property MaskingKey: TBytes read FMaskingKey write FMaskingKey;
    property Payload: TBytes read FPayload write FPayload;
    function IsValid: Boolean;
  end;

implementation

uses
  System.Rtti,
  WebSocket.Tools;

{ TwsFrameBase }

constructor TwsFrame.Create(ARawBytes: TBytes);
begin
  FIsValidFrame := DecodeFrame(ARawBytes, self);
end;

class function TwsFrame.DecodeFrame(const iData: TBytes; var AFrame: TwsFrame): Boolean;
var
  Index: UInt32;
  MaskingKey: UInt32;
  MaskingKyeArray: array [0 .. 3] of Byte absolute MaskingKey;
  i: UInt32;
begin
  Result := False;
  AFrame.PayloadLength := 0;

  var
  DataLen := Length(iData);
  if DataLen < 2 then
    Exit;

  // FIN & OpCode
  AFrame.Fin := TwsFin((iData[0] and $80) shr 7 > 0);
  AFrame.Opcode := TwsOpcode(iData[0] and $0F);

  // Mask
  var
  Mask := (iData[1] and $80) shr 7 > 0;
  var
    PayloadLenRaw: Int64Rec;
  var
  Len := iData[1] and $7F;
  var
    Size: UInt32 := 2;

  UInt64(PayloadLenRaw) := 0;

  Index := 2;

  if Len < $7E then
    AFrame.PayloadLength := Len
  else
  begin
    var
      PayloadLenCount: UInt32;

    if Len = $7E then
      PayloadLenCount := 2
    else
      PayloadLenCount := 8;

    var
    DataIndex := Index + PayloadLenCount - 1;

    for i := 0 to PayloadLenCount - 1 do
      PayloadLenRaw.Bytes[i] := iData[DataIndex - i];

    AFrame.PayloadLength := UInt64(PayloadLenRaw);

    Inc(Index, PayloadLenCount);
    Inc(Size, PayloadLenCount);
  end;

  AFrame.FFrameSize := Integer(Size + UInt32(Ord(Mask) * 4) + AFrame.PayloadLength);

  if DataLen < AFrame.FFrameSize then
    Exit(AFrame.Opcode in [TwsOpcode.Close, TwsOpcode.Ping, TwsOpcode.Pong]);

  // Masking Key
  MaskingKey := 0;
  if Mask then
  begin
    Move(iData[Index], MaskingKey, SizeOf(MaskingKey));
    Inc(Index, SizeOf(MaskingKey));
  end;

  // Payload Data
  if AFrame.PayloadLength > 0 then // 10.3 Rio's bug. PayloadLen = 0 でも for に入る
  begin
    SetLength(AFrame.FPayload, AFrame.PayloadLength);
    for i := 0 to AFrame.PayloadLength - 1 do
      AFrame.Payload[i] := iData[Index + i] xor MaskingKyeArray[i mod 4];
  end;
  Result := True;
end;

class function TwsFrame.EncodeFrame(const iData: TBytes; const iCode: TwsOpcode; const iMask: Boolean): TBytes;
var
  Index: Integer;
  MaskingKey: UInt32;
  MaskingKyeArray: array [0 .. 3] of Byte absolute MaskingKey;
  i: Integer;

  procedure SetBuff(const iValue: Byte);
  begin
    Result[Index] := iValue;
    Inc(Index);
  end;

begin
  // CalcBuffSize
  var
    Len: UInt64 := UInt64(Length(iData));
  var
    ExPayloadLen: UInt32 := 0;
  var
    MaskLenValue: UInt32;
  var
    PayloadLen: Int64Rec;

  if Len < 126 then
    MaskLenValue := Len
  else
  begin
    if Len < $10000 then
    begin
      ExPayloadLen := 2;
      MaskLenValue := 126;
      PayloadLen.Lo := Len
    end
    else
    begin
      ExPayloadLen := 8;
      MaskLenValue := 127;
      PayloadLen := Int64Rec(Len);
    end;
  end;

  SetLength(Result, 1 + 1 + ExPayloadLen + UInt32(Ord(iMask) * 4) + Len);
  Index := 0;

  // 0 Byte
  // Final Flag. String Length を 32bit で考えているので 1 Frame で収まる
  var
  Fin := 1;
  SetBuff(Fin shl 7 + Ord(iCode));

  // 1 Byte
  SetBuff(MaskLenValue + UInt32(Ord(iMask) shl 7));

  // 2 ～ 10 Byte
  // Payload Length
  for i := ExPayloadLen - 1 downto 0 do
    SetBuff(PayloadLen.Bytes[i]);

  // Masking Key
  MaskingKey := Random(Int32($FFFFFFFF));

  Move(MaskingKey, Result[Index], SizeOf(MaskingKey));
  Inc(Index, SizeOf(MaskingKey));

  // Payload Data
  for i := 0 to Len - 1 do // 10.3.1 のバグで i をインライン定義するとエラー
    SetBuff(Ord(iData[i]) xor MaskingKyeArray[i mod 4]);
end;

function TwsFrame.IsValid: Boolean;
begin
  Result := FIsValidFrame;
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
    '            Masking Key: %s' + sLineBreak + //
    '           Payload Data: %s';
var
  lFin: string;
  lRsv1, lRsv2, lRsv3: string;
  lOpCode: string;
begin;
  lFin := AFrame.Fin.ToString;
  lRsv1 := AFrame.FRsv1.ToString;
  lRsv2 := AFrame.FRsv2.ToString;
  lRsv3 := AFrame.FRsv3.ToString;
  lOpCode := AFrame.FOpcode.ToString;
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

function TwsFrame.ToText(const AForge: Boolean = True): string;
begin
  Result := '';
  try
    Result := TEncoding.UTF8.GetString(FPayload);
  except
    on E: Exception do
      Result := '';
  end;
  if Result.IsEmpty and AForge then
    try
      Result := TEncoding.ANSI.GetString(FPayload);
    except
      on E: Exception do
        Result := '';
    end;
end;

{ TwsOpcodehelper }

function TwsOpcodehelper.ToString: string;
begin
  Result := TRttiEnumerationType.GetName<TwsOpcode>(self);
end;

{ TwsRsvhelper }

function TwsRsvhelper.ToString: string;
begin
  Result := TRttiEnumerationType.GetName<TwsRsv>(self);
end;

{ TwsFinhelper }

function TwsFinhelper.ToString: string;
begin
  Result := TRttiEnumerationType.GetName<TwsFin>(self);
end;

end.
