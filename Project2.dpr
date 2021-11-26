program Project2;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  WebSocket in 'WebSocket.pas',
  WebSocket.Types.Frame in 'WebSocket.Types.Frame.pas';

procedure test;
var
  lSocket: TWebSocket;
begin
  lSocket := TWebSocket.Create('ws://javascript.info');
  try

  finally
    lSocket.Free;
  end;
end;

begin
  try
    { TODO -oUser -cConsole Main : Insert code here }
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
