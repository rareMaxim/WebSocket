program WSDemo;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  WebSocket in 'WebSocket.pas',
  WebSocket.Types.Frame in 'WebSocket.Types.Frame.pas',
  WebSocket.Tools in 'WebSocket.Tools.pas',
  WebSocket.Types in 'WebSocket.Types.pas',
  ms301.LogMessage in 'ms301.LogMessage.pas',
  System.Console in 'DelphiConsole\Console\System.Console.pas';

procedure test;
var
  lSocket: TWebSocket;
begin
  lSocket := TWebSocket.Create('ws://vnc.interpay.com.ua:22004');
  try
    lSocket.OnErrorCallback := procedure(AError: TWebSocketError)
      begin
        Console.ForegroundColor := TConsoleColor.Red;
        try
          Console.WriteLine(AError.ToString);
        finally
          Console.ResetColor;
        end;
      end;
    lSocket.OnLogCallback := procedure(ALog: TLogMessage)
      begin
        Console.ForegroundColor := TConsoleColor.Yellow;
        try
          Console.WriteLine(ALog.ToString);
        finally
          Console.ResetColor;
        end;

      end;
    lSocket.OnOpenCallback := procedure
      var
        LCmd: string;
      begin
        Console.WriteLine('Соединение установлено.');
        LCmd := 'show_equery';
        lSocket.Send('<?xml version="1.0" encoding="UTF-8"?>' + sLineBreak + '<request_type><row request_type="' + LCmd
          + '" terminalid="T110102"/></request_type>');
      end;
    lSocket.OnTextCallback := procedure(AMsg: string)
      begin
        Console.WriteLine(AMsg);
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
