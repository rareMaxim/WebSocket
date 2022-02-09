unit WebSocket.Tools;

interface

uses
  System.SysUtils;

type
  TwsTools = class
  public
    class function BytesToStrings(ABytes: TArray<Byte>): TArray<string>; static;
    class function BytesToString(ABytes: TArray<Byte>): string; static;
    class function BytesToHex(const ABytes: TBytes): String;
  end;

implementation

{ TwsTools }

class function TwsTools.BytesToHex(const ABytes: TBytes): String;
begin
  var
  SB := TStringBuilder.Create;
  try
    for var B in ABytes do
    begin
      SB.Append(B.ToHexString);
      SB.Append(' ');
    end;
    Result := SB.ToString;
  finally
    SB.DisposeOf;
  end;
end;

class function TwsTools.BytesToString(ABytes: TArray<Byte>): string;
var
  lStrArr: TArray<string>;
begin
  lStrArr := BytesToStrings(ABytes);
  Result := string.Join(' ', lStrArr);
end;

class function TwsTools.BytesToStrings(ABytes: TArray<Byte>): TArray<string>;
var
  I: Integer;
begin
  SetLength(Result, Length(ABytes));
  for I := Low(ABytes) to High(ABytes) do
    Result[I] := ABytes[I].ToString;
end;

end.
