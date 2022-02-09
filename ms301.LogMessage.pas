unit ms301.LogMessage;

interface

type
  TLogMessage = record
  private
    FMessage: string;
    FTag: string;
    FTime: TDateTime;
    FMessageFormat: string;
    FTimeFormat: string;
  public
    class function Create(const ATag, AMessage: string): TLogMessage; static;
    function FormattedTime: string;
    function ToString: string;
    property Tag: string read FTag write FTag;
    property Message: string read FMessage write FMessage;
    property Time: TDateTime read FTime write FTime;
    property MessageFormat: string read FMessageFormat write FMessageFormat;
    property TimeFormat: string read FTimeFormat write FTimeFormat;

  end;

implementation

uses
  System.SysUtils;

class function TLogMessage.Create(const ATag, AMessage: string): TLogMessage;
begin
  Result.FTimeFormat := 'yyyy/mm/dd hh:nn:ss:zz';
  Result.FMessageFormat := '$Time [$Tag] $Message';
  Result.FMessage := AMessage;
  Result.FTag := ATag;
  Result.FTime := Now;
end;

function TLogMessage.FormattedTime: string;
begin
  Result := FormatDateTime(FTimeFormat, FTime);
end;

function TLogMessage.ToString: string;

begin
  Result := FMessageFormat.Replace('$Time', FormattedTime).Replace('$Tag', FTag).Replace('$Message', FMessage);
end;

end.
