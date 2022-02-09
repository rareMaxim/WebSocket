unit WebSocket;

interface

{ /$DEFINE LOG }

uses
  WebSocket.Types,
  System.Net.Socket,
  System.Net.URLClient,
  System.Types,
  System.SysUtils, WebSocket.Types.Frame, ms301.LogMessage;

type
  TWebSocket = class
  private
    FUri: TURI;
    FSecuredKey: string;
    FSocket: TSocket;
    FOnOpenCallback: TProc;
    FOnTextCallback: TProc<string>;
    FOnErrorCallback: TProc<TWebSocketError>;
    FOnLogCallback: TProc<TLogMessage>;
  protected
    procedure DoLog(ALogMessage: TLogMessage); overload;
    procedure DoLog(const ATag, AMessage: string); overload;
    procedure DoLog(const ATag, AFormatMessage: string; const Args: array of const); overload;
{$REGION 'Connect'}
    procedure DoOnTcpNativeConnected(const ASyncResult: IAsyncResult);
    procedure DoOnOpenCallback;
{$ENDREGION}
{$REGION 'Handshake'}
    procedure SendHandshake;
    procedure EndSendHandshake(const ASyncResult: IAsyncResult);
    procedure DoOnTcpNativeEndSendHandshakeData(const ASyncResult: IAsyncResult);
    procedure DoOnTcpNativeEndReceiveSendHandshake(const ASyncResult: IAsyncResult);
    procedure DoCheckHeaderAnswer(const AHeaderFromServer: string);
{$ENDREGION}
{$REGION 'Reading frames'}
    procedure DoOnTcpNativeBeginReceiveFrameData;
    procedure DoOnTcpNativeEndReceiveFrameData(const ASyncResult: IAsyncResult);
    procedure DoOnTextCallback(AMsg: string);
    procedure DoOnFrame(AFrame: TwsFrame);
{$ENDREGION}
    procedure DoOnError(AError: TWebSocketError);
    procedure SendFrame(const iData: TBytes; const iCode: TwsOpCode);
    procedure DoOnTcpNativeEndSendData(const ASyncResult: IAsyncResult);
    procedure SendOpCode(const iCode: TwsOpCode); overload;
    procedure SendOpCode(const iCode: TwsOpCode; const iParam: Word); overload;
    procedure SendOpCode(const iCode: TwsOpCode; const iBin: TBytes); overload;

    procedure SendTextFrame(const iStr: string; const iCode: TwsOpCode);
    procedure SendText(const iText: string);
  public
    procedure Send(const AText: string); overload;
    procedure Send(const AData: TBytes); overload;
    procedure SendPing;
    procedure Connect;
    procedure Close;
    constructor Create(const AUrl: string);
    destructor Destroy; override;
    property OnOpenCallback: TProc read FOnOpenCallback write FOnOpenCallback;
    property OnTextCallback: TProc<string> read FOnTextCallback write FOnTextCallback;
    property OnErrorCallback: TProc<TWebSocketError> read FOnErrorCallback write FOnErrorCallback;
    property OnLogCallback: TProc<TLogMessage> read FOnLogCallback write FOnLogCallback;
  end;

implementation

uses
  WebSocket.Tools,
  System.Classes;
{ TWebSocket }

procedure TWebSocket.Close;
begin

end;

procedure TWebSocket.Connect;
begin
  DoLog('network', 'BeginConnect (%s, %d)', [FUri.Host, FUri.Port]);
  FSocket.BeginConnect(DoOnTcpNativeConnected, FUri.Host, '', '', FUri.Port);
end;

constructor TWebSocket.Create(const AUrl: string);
begin
  DoLog('event', 'TWebSocket.Create (%s)', [AUrl]);
  FSocket := TSocket.Create(TSocketType.TCP, TEncoding.UTF8);
  FUri := TURI.Create(AUrl);
end;

destructor TWebSocket.Destroy;
begin
  FSocket.Close;
  FSocket.Free;
  DoLog('event', 'TWebSocket.Destroy');
  inherited;
end;

procedure TWebSocket.DoCheckHeaderAnswer(const AHeaderFromServer: string);
var
  lHeaders: TStringList;
begin
  lHeaders := TStringList.Create();
  try
    { TODO -oOwner -cGeneral : Проверка ответа от сервера }
    DoOnOpenCallback;
    lHeaders.Text := AHeaderFromServer;
{$IFDEF LOG}
    Writeln(lHeaders.Text);
{$ENDIF}
  finally
    lHeaders.Free;
  end;
end;

procedure TWebSocket.DoLog(const ATag, AMessage: string);
var
  lLog: TLogMessage;
begin
  lLog := TLogMessage.Create(ATag, AMessage);
  DoLog(lLog);
end;

procedure TWebSocket.DoLog(ALogMessage: TLogMessage);
begin
  if Assigned(OnLogCallback) then
    OnLogCallback(ALogMessage);
end;

procedure TWebSocket.DoOnTcpNativeEndReceiveFrameData(const ASyncResult: IAsyncResult);
var
  lResult: TBytes;
  lFrame: TwsFrame;
begin
  DoLog('network', 'DoOnTcpNativeEndReceiveFrameData (FSocket.Handle = %d)', [FSocket.Handle]);
  lResult := FSocket.EndReceiveBytes(ASyncResult);
  lFrame := TwsFrame.Create(lResult);
  try
    DoOnFrame(lFrame);
    DoOnTcpNativeBeginReceiveFrameData;
  finally
    lFrame.Free;
  end;
end;

procedure TWebSocket.DoOnTcpNativeEndReceiveSendHandshake(const ASyncResult: IAsyncResult);
var
  lResult: TBytes;
  lStr: string;
begin
  DoLog('network', 'DoOnTcpNativeEndReceiveSendHandshake (FSocket.Handle = %d)', [FSocket.Handle]);
  lResult := FSocket.EndReceiveBytes(ASyncResult);
  lStr := TEncoding.Default.GetString(lResult);
  DoCheckHeaderAnswer(lStr);
  DoOnTcpNativeBeginReceiveFrameData;
end;

procedure TWebSocket.DoOnTcpNativeEndSendData(const ASyncResult: IAsyncResult);
begin
  FSocket.EndSend(ASyncResult);
end;

procedure TWebSocket.DoOnTcpNativeEndSendHandshakeData(const ASyncResult: IAsyncResult);
begin
  DoLog('network', 'DoOnTcpNativeEndSendHandshakeData (FSocket.Handle = %d)', [FSocket.Handle]);
  FSocket.EndSend(ASyncResult);
  DoLog('network', 'DoOnTcpNativeEndSendHandshakeData (EndSend)');
  FSocket.BeginReceive(DoOnTcpNativeEndReceiveSendHandshake, []);
end;

procedure TWebSocket.DoOnError(AError: TWebSocketError);
begin
  if Assigned(OnErrorCallback) then
    OnErrorCallback(AError);
end;

procedure TWebSocket.DoOnFrame(AFrame: TwsFrame);

begin
  DoLog('network', 'DoOnFrame (%s)', [TwsFrame.Print(AFrame)]);
  case AFrame.Opcode of

    TwsOpCode.Text:
      DoOnTextCallback(AFrame.ToText());

    TwsOpCode.Binary:
      ;
    TwsOpCode.Cont, TwsOpCode.Z3 .. TwsOpCode.Z7, TwsOpCode.Pong:
      ;

    TwsOpCode.Close:
      ;
    TwsOpCode.Ping:
      SendOpCode(TwsOpCode.Pong);
  end;

end;

procedure TWebSocket.DoOnTextCallback(AMsg: string);
begin
  if Assigned(OnTextCallback) then
    OnTextCallback(AMsg);
end;

procedure TWebSocket.DoOnOpenCallback;
begin
  if Assigned(OnOpenCallback) then
    OnOpenCallback();
end;

procedure TWebSocket.DoOnTcpNativeBeginReceiveFrameData;
begin
  DoLog('network', 'DoOnTcpNativeBeginReceiveFrameData (FSocket.Handle = %d)', [FSocket.Handle]);
  FSocket.BeginReceive(DoOnTcpNativeEndReceiveFrameData, [])
end;

procedure TWebSocket.DoOnTcpNativeConnected(const ASyncResult: IAsyncResult);
begin
  DoLog('network', 'DoOnTcpNativeConnected (FSocket.Handle = %d)', [FSocket.Handle]);
  SendHandshake;
end;

procedure TWebSocket.EndSendHandshake(const ASyncResult: IAsyncResult);
var
  lResp: string;
begin
  DoLog('network', 'EndSendHandshake (FSocket.Handle = %d)', [FSocket.Handle]);
  lResp := FSocket.EndReceiveString(ASyncResult);
end;

procedure TWebSocket.Send(const AText: string);
begin
  SendText(AText);
end;

procedure TWebSocket.Send(const AData: TBytes);
begin
  SendFrame(AData, TwsOpCode.Binary);
end;

procedure TWebSocket.SendFrame(const iData: TBytes; const iCode: TwsOpCode);
var
  lTmpFrame: TwsFrame;
begin
  if TSocketState.Connected in FSocket.State then
  begin
    var
    Bytes := TwsFrame.EncodeFrame(iData, iCode, { ! } True);
    FSocket.BeginSend(Bytes, DoOnTcpNativeEndSendData);
    lTmpFrame := TwsFrame.Create(Bytes);
    try
      if lTmpFrame.Opcode = TwsOpCode.Text then
        DoLog('SEND', 'OpCode = %s, Body = %s', [lTmpFrame.Opcode.ToString, lTmpFrame.ToText])
      else
      begin
        var
        Body := TwsTools.BytesToHex(lTmpFrame.Payload);
        DoLog('SEND', 'OpCode = %s, BodyLen = %d, Body = [%s]', [lTmpFrame.Opcode.ToString, Body.Length, Body]);
      end;
    finally
      lTmpFrame.Free;
    end;
  end;
end;

procedure TWebSocket.SendHandshake;
var
  str: string;
begin
  DoLog('network', 'SendHandshake');
  FSecuredKey := 'dGhlIHNhbXBsZSBub25jZQ==';
  Randomize;
  str := 'GET ' + FUri.ToString + ' HTTP/1.1' + sLineBreak;
  str := str + 'Host: ' + FUri.Host + sLineBreak;
  str := str + 'Upgrade: websocket' + sLineBreak;
  str := str + 'Connection: Upgrade' + sLineBreak;
  str := str + 'Sec-WebSocket-Key: ' + FSecuredKey + sLineBreak;
  str := str + 'Origin: ' + 'https://github.com/ms301/WebSocket' + sLineBreak;
  str := str + 'Sec-WebSocket-Protocol: chat, superchat' + sLineBreak;
  str := str + 'Sec-WebSocket-Version: 13' + sLineBreak;
  FSocket.BeginSend(str + sLineBreak, DoOnTcpNativeEndSendHandshakeData);
end;

procedure TWebSocket.SendOpCode(const iCode: TwsOpCode; const iBin: TBytes);
begin
  DoLog('network', 'SendOpCode (TwsOpCode = %s)', [iCode.ToString]);
  SendFrame(iBin, iCode);
end;

procedure TWebSocket.SendPing;
begin

end;

procedure TWebSocket.SendText(const iText: String);
begin
  SendTextFrame(iText, TwsOpCode.Text);
end;

procedure TWebSocket.SendTextFrame(const iStr: String; const iCode: TwsOpCode);
begin
  SendFrame(TEncoding.UTF8.GetBytes(iStr), iCode);
end;

procedure TWebSocket.SendOpCode(const iCode: TwsOpCode; const iParam: Word);
var
  Bytes: TBytes;
begin
  SetLength(Bytes, SizeOf(iParam));
  Bytes[0] := WordRec(iParam).Hi;
  Bytes[1] := WordRec(iParam).Lo;
  SendOpCode(iCode, Bytes);
end;

procedure TWebSocket.SendOpCode(const iCode: TwsOpCode);
begin
  SendOpCode(iCode, 0);
end;

procedure TWebSocket.DoLog(const ATag, AFormatMessage: string; const Args: array of const);
var
  lFormattedMsg: string;
begin
  lFormattedMsg := Format(AFormatMessage, Args);
  DoLog(ATag, lFormattedMsg);
end;

end.
