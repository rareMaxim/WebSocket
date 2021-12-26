unit WebSocket;

interface

uses
  System.Net.Socket,
  System.Net.URLClient,
  System.Types;

type
  TWebSocket = class
  private
    FUri: TURI;
    FSecuredKey: string;
    FSocket: TSocket;
  protected
    procedure EndSendHandshake(const ASyncResult: IAsyncResult);
    procedure DoOnTcpNativeConnected(const ASyncResult: IAsyncResult);
    procedure DoOnTcpNativeEndSendHandshakeData(const ASyncResult: IAsyncResult);
    procedure DoOnTcpNativeEndReceiveSendHandshake(const ASyncResult: IAsyncResult);
    procedure DoOnTcpNativeBeginReceiveFrameData;
    procedure DoOnTcpNativeEndReceiveFrameData(const ASyncResult: IAsyncResult);
  public
    procedure SendHandshake;
    procedure Connect;
    constructor Create(const AUrl: string);
    destructor Destroy; override;
  end;

implementation

uses
  WebSocket.Tools,
  WebSocket.Types.Frame,
  System.SysUtils,
  System.Classes;
{ TWebSocket }

procedure TWebSocket.Connect;
begin
  FSocket.BeginConnect(DoOnTcpNativeConnected, FUri.Host, '', '', FUri.Port);

end;

constructor TWebSocket.Create(const AUrl: string);
begin
  FSocket := TSocket.Create(TSocketType.TCP, TEncoding.UTF8);
  FUri := TURI.Create(AUrl);
end;

destructor TWebSocket.Destroy;
begin
  FSocket.Free;
  inherited;
end;

procedure TWebSocket.DoOnTcpNativeEndReceiveFrameData(const ASyncResult: IAsyncResult);
var
  lResult: TBytes;
  lFrame: TwsFrame;
begin
  TwsTools.Log('procedure TWebSocket.DoOnTcpNativeEndReceiveFrameData(const ASyncResult: IAsyncResult);');
  Writeln(FSocket.Handle);
  lResult := FSocket.EndReceiveBytes(ASyncResult);
  lFrame := TwsFrame.Create(lResult);
  try
    TwsTools.Log(TwsFrame.Print(lFrame));
    DoOnTcpNativeBeginReceiveFrameData;
  finally
    lFrame.Free;
  end;
end;

procedure TWebSocket.DoOnTcpNativeEndReceiveSendHandshake(const ASyncResult: IAsyncResult);
var
  lResult: TBytes;
  lStr: string;
  lHeaders: TStringList;
begin
  TwsTools.Log('procedure TWebSocket.DoOnTcpNativeEndReceiveSendHandshake(const ASyncResult: IAsyncResult);');
  Writeln(FSocket.Handle);
  lResult := FSocket.EndReceiveBytes(ASyncResult);
  lStr := TEncoding.UTF8.GetString(lResult);

  lHeaders := TStringList.Create();
  try
    lHeaders.Text := lStr;
    Writeln(lHeaders.Text);
  finally
    lHeaders.Free;
  end;
  DoOnTcpNativeBeginReceiveFrameData;
end;

procedure TWebSocket.DoOnTcpNativeEndSendHandshakeData(const ASyncResult: IAsyncResult);
begin
  TwsTools.Log('procedure TWebSocket.DoOnTcpNativeEndSendHandshakeData(const ASyncResult: IAsyncResult);');
  Writeln(FSocket.Handle);
  FSocket.EndSend(ASyncResult);
  TwsTools.Log('EndSend');
  Writeln(FSocket.Handle);
  FSocket.BeginReceive(DoOnTcpNativeEndReceiveSendHandshake, []);
end;

procedure TWebSocket.DoOnTcpNativeBeginReceiveFrameData;
begin
  FSocket.BeginReceive(DoOnTcpNativeEndReceiveFrameData, [])
end;

procedure TWebSocket.DoOnTcpNativeConnected(const ASyncResult: IAsyncResult);
begin

  TwsTools.Log('procedure TWebSocket.DoOnTcpNativeConnected(const ASyncResult: IAsyncResult);');
  Writeln(FSocket.Handle);
  SendHandshake;
end;

procedure TWebSocket.EndSendHandshake(const ASyncResult: IAsyncResult);
var
  lResp: string;
begin
  TwsTools.Log('procedure TWebSocket.EndSendHandshake(const ASyncResult: IAsyncResult);');
  Writeln(FSocket.Handle);
  lResp := FSocket.EndReceiveString(ASyncResult);
end;

procedure TWebSocket.SendHandshake;
var
  str: string;
begin

  TwsTools.Log('procedure TWebSocket.SendHandshake;');

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

end.
