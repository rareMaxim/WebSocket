unit WebSocket.Types.Frame;

interface

type
  TwsFrameFin = (More = $0, Final = $1);

  TwsFrameBase = class
  private
    FFin: TwsFrameFin;

  public
    property Fin: TwsFrameFin read FFin write FFin;
  end;

implementation

end.
