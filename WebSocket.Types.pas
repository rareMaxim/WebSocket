unit WebSocket.Types;

interface

uses
  WebSocket.Types.Frame,
  WebSocket.Types.Message,
  System.SysUtils;

type
  TwsMessage = class(WebSocket.Types.Message.TwsMessage);
  TwsFrame = class(WebSocket.Types.Frame.TwsFrame);
  TWebSocketError = class(Exception);

implementation

end.
