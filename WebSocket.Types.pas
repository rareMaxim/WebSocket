unit WebSocket.Types;

interface

uses
  WebSocket.Types.Frame,

  System.SysUtils;

type


  TwsFrame = class(WebSocket.Types.Frame.TwsFrame);
  TWebSocketError = class(Exception);

implementation

end.
