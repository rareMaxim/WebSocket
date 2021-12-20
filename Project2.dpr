program Project2;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  WebSocket in 'WebSocket.pas',
  WebSocket.Types.Frame in 'WebSocket.Types.Frame.pas',
  WebSocket.Tools in 'WebSocket.Tools.pas';

procedure test;
var
  lSocket: TWebSocket;
begin
  lSocket := TWebSocket.Create('ws://vnc.interpay.com.ua:22004/');
  try
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
