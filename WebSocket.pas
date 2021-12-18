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
    procedure DoOnTcpNativeConnected(const ASyncResult: IAsyncResult);
    procedure DoOnTcpNativeSend(const ASyncResult: IAsyncResult);
    procedure EndSendHandshake(const ASyncResult: IAsyncResult);
  public
    procedure SendHandshake;
    procedure Connect;
    constructor Create(const AUrl: string);
    destructor Destroy; override;
    class procedure Log(const AMsg: string);
  end;

implementation

uses

  System.SysUtils;
{ TWebSocket }

procedure TWebSocket.Connect;
begin
  FSocket.BeginConnect(DoOnTcpNativeConnected, FUri.Host, '', '', FUri.Port);
  SendHandshake;
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

procedure TWebSocket.DoOnTcpNativeConnected(const ASyncResult: IAsyncResult);
begin
  Log('TWebSocket.DoOnTcpNativeConnected');
end;

procedure TWebSocket.DoOnTcpNativeSend(const ASyncResult: IAsyncResult);
begin
  Log('TWebSocket.DoOnTcpNativeSend');
end;

procedure TWebSocket.EndSendHandshake(const ASyncResult: IAsyncResult);
var
  lResp: string;
begin
  lResp := FSocket.EndReceiveString(ASyncResult);
  Log('procedure TWebSocket.EndSendHandshake(const ASyncResult: IAsyncResult);');
end;

class procedure TWebSocket.Log(const AMsg: string);
begin
  Writeln(TimeToStr(now) + ' ' + AMsg);
end;

procedure TWebSocket.SendHandshake;
var
  str: string;
  key: string;
begin

  Log('procedure TWebSocket.SendHandshake;');

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
  FSocket.BeginSend(str + sLineBreak,
    procedure(const ABeginSendSyncResult: IAsyncResult)
    var
      lResp: Integer;
    begin
      lResp := FSocket.EndSend(ABeginSendSyncResult);
      FSocket.BeginReceive(
        procedure(const ABeginReceiveSyncResult: IAsyncResult)
        var
          lResp: string;
        begin
          lResp := FSocket.EndReceiveString(ABeginReceiveSyncResult);
          Log('procedure TWebSocket.EndSendHandshake(const ASyncResult: IAsyncResult);');
        end);
    end);

end;

end.
