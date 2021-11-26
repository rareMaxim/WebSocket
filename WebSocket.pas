unit WebSocket;

interface

uses
  System.Net.HttpClient,
  System.Net.URLClient;

type
  TWebSocket = class
  private
    FUri: TURI;
  public
    constructor Create(const AUrl: string);
  end;

implementation

{ TWebSocket }

constructor TWebSocket.Create(const AUrl: string);
begin
  FUri := TURI.Create(AUrl);
end;

end.
