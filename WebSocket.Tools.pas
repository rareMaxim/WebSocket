unit WebSocket.Tools;

interface

type
  TwsTools = class
  public
    class function BytesToStrings(ABytes: TArray<Byte>): TArray<string>; static;
    class function BytesToString(ABytes: TArray<Byte>): string; static;
    class procedure PrintBytes(ABytes: TArray<Byte>);
    class procedure Log(const AMsg: string);
  end;

implementation

uses
  System.SysUtils;

{ TwsTools }

class function TwsTools.BytesToString(ABytes: TArray<Byte>): string;
var
  lStrArr: TArray<string>;
begin
  lStrArr := BytesToStrings(ABytes);
  Result := string.Join(', ', lStrArr);
end;

class function TwsTools.BytesToStrings(ABytes: TArray<Byte>): TArray<string>;
var
  I: Integer;
begin
  SetLength(Result, Length(ABytes));
  for I := Low(ABytes) to High(ABytes) do
    Result[I] := ABytes[I].ToString;
end;

class procedure TwsTools.PrintBytes(ABytes: TArray<Byte>);
var
  lRes: string;
  lStrArr: TArray<string>;
begin
  lStrArr := BytesToStrings(ABytes);
  lRes := string.Join(', ', lStrArr);
  Log(lRes);
end;

class procedure TwsTools.Log(const AMsg: string);
begin
  Writeln(TimeToStr(now) + ' ' + AMsg);
end;

end.
