unit WebSocket.Types.Message;

interface

uses
  WebSocket.Types.Frame,
  System.SysUtils;

type
  TwsMessage = class
  private
    FOpcode: TwsOpcode;
    FPayload: TBytes;
  public
    constructor Create(AFrame: TwsFrame);
    function IsBinary: Boolean;
    function IsPing: Boolean;
    function IsText: Boolean;
    function RawData: TBytes;
    function Text: string;
    property Opcode: TwsOpcode read FOpcode write FOpcode;
  end;

implementation

constructor TwsMessage.Create(AFrame: TwsFrame);
begin
  FOpcode := AFrame.Opcode;
  FPayload := AFrame.Payload;
end;

function TwsMessage.IsBinary: Boolean;
begin
  Result := FOpcode = TwsOpcode.Binary;
end;

function TwsMessage.IsPing: Boolean;
begin
  Result := FOpcode = TwsOpcode.Ping;
end;

function TwsMessage.IsText: Boolean;
begin
  Result := FOpcode = TwsOpcode.Text;
end;

function TwsMessage.RawData: TBytes;
begin
  Result := FPayload;
end;

function TwsMessage.Text: string;
begin
  Result := '';
  try
    Result := TEncoding.UTF8.GetString(FPayload);
  except
    Result := '';
  end;
end;

end.
