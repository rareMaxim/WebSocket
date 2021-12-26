program WSDemo;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  WebSocket in 'WebSocket.pas',
  WebSocket.Types.Frame in 'WebSocket.Types.Frame.pas',
  WebSocket.Tools in 'WebSocket.Tools.pas',
  WebSocket.Types.Message in 'WebSocket.Types.Message.pas',
  WebSocket.Types in 'WebSocket.Types.pas';

procedure test;
var
  lSocket: TWebSocket;
begin
  lSocket := TWebSocket.Create('ws://ws.ifelse.io:80');
  try
    lSocket.OnOpenCallback := procedure
      begin
        Writeln('Соединение установлено.');
      end;
    lSocket.OnMessageCallback := procedure(AMsg: TwsMessage)
      begin
        if AMsg.IsText then
          Writeln(AMsg.Text);
      end;
    lSocket.Connect;
  finally
    Readln;
    lSocket.Free;
  end;
end;

begin
  try
    { TODO -oUser -cConsole Main : Insert code here }
    test;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
