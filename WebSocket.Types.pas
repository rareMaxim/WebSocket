unit WebSocket.Types;

interface

uses
  WebSocket.Types.Frame,
  WebSocket.Types.Message;

type
  TwsMessage = class(WebSocket.Types.Message.TwsMessage);
  TwsFrame = class(WebSocket.Types.Frame.TwsFrame);

implementation

end.
