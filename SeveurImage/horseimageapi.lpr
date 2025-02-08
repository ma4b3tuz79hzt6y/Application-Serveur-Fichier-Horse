program horseimageapi;

{$MODE DELPHI}{$H+}

uses
  {$IFDEF UNIX} cthreads, {$ENDIF}
  Horse, Horse.OctetStream, SysUtils, Classes;

const
  VALID_FILE_TYPES: array[0..5] of string = ('.png', '.jpg', '.svg','.pdf','.doc','.ppt');
  AUTH_TOKEN = 'Bearer 123456789';  // Remplacez par un vrai mécanisme de sécurité
  LOG_FILE = 'logs/api.log';

procedure LogMessage(Msg: string);
var
  LogFile: TextFile;
begin
  AssignFile(LogFile, LOG_FILE);
  if FileExists(LOG_FILE) then Append(LogFile) else Rewrite(LogFile);
  Writeln(LogFile, FormatDateTime('YYYY-MM-DD HH:NN:SS', Now) + ' - ' + Msg);
  CloseFile(LogFile);
end;

function IsAuthorized(Req: THorseRequest): Boolean;
begin
  Result := Req.Headers['Authorization'] = AUTH_TOKEN;
end;

function IsValidFileType(const FileName: string): Boolean;
var
  Ext: string;
  I: Integer;
begin
  Result := False;
  Ext := LowerCase(ExtractFileExt(FileName));
  for I := Low(VALID_FILE_TYPES) to High(VALID_FILE_TYPES) do
    if Ext = VALID_FILE_TYPES[I] then Exit(True);
end;

procedure GetStream(Req: THorseRequest; Res: THorseResponse);
var
  LStream: TFileStream;
  FilePath, FileName: string;
begin
  if not IsAuthorized(Req) then
  begin
    Res.Status(THTTPStatus.Unauthorized).Send('401 Unauthorized');
    LogMessage('Unauthorized access attempt.');
    Exit;
  end;

  FileName := Req.Params['fichier'];
  FilePath := ExtractFilePath(ExtractFilePath(ParamStr(0))) + 'ImageBarber/Images/' + FileName;

  if not IsValidFileType(FileName) then
  begin
    Res.Status(THTTPStatus.BadRequest).Send('400 Bad Request - Invalid file type');
    LogMessage('Invalid file type access: ' + FileName);
    Exit;
  end;

  if not FileExists(FilePath) then
  begin
    Res.Status(THTTPStatus.NotFound).Send('404 Not Found');
   // LogMessage('File not found: ' + FilePath);
    Exit;
  end;

  try
    LStream := TFileStream.Create(FilePath, fmOpenRead);
    Res.Send<TStream>(LStream).ContentType('application/octet-stream');
    LogMessage('File served: ' + FilePath);
  except
    on E: Exception do
    begin
      Res.Status(THTTPStatus.InternalServerError).Send('500 Internal Server Error');
     // LogMessage('Error serving file: ' + E.Message);
    end;
  end;
end;

procedure PostStream(Req: THorseRequest; Res: THorseResponse);
var
  FileName, FilePath: string;
begin
  if not IsAuthorized(Req) then
  begin
    Res.Status(THTTPStatus.Unauthorized).Send('401 Unauthorized');
    LogMessage('Unauthorized upload attempt.');
    Exit;
  end;

  FileName := Req.Params['fichier'];
  if not IsValidFileType(FileName) then
  begin
    Res.Status(THTTPStatus.BadRequest).Send('400 Bad Request - Invalid file type');
    //LogMessage('Invalid file type upload: ' + FileName);
    Exit;
  end;

  if Req.Body.IsEmpty then
  begin
    Res.Status(THTTPStatus.BadRequest).Send('400 Bad Request - No file uploaded');
   // LogMessage('Upload failed: No data received.');
    Exit;
  end;

  FilePath := ExtractFilePath(ExtractFilePath(ParamStr(0))) + 'ImageBarber/Images/' + FileName;

  try
    Req.Body<TBytesStream>.SaveToFile(FilePath);
    Res.Status(THTTPStatus.Created).Send('201 Created');
   // LogMessage('File uploaded: ' + FilePath);
    writeln('File uploaded: ' + FilePath);
    writeln('Running Server : '+Thorse.Port.ToString + 'Host : '+THorse.Host);
  except
    on E: Exception do
    begin
      Res.Status(THTTPStatus.InternalServerError).Send('500 Internal Server Error');
    //  LogMessage('Upload error: ' + E.Message);
    end;
  end;
end;

procedure running (Horse:THorse);
begin
   writeln('Running Server : '+Thorse.Port.ToString + 'Host : '+Horse.Host);
end;

begin
  //if not DirectoryExists('logs') then
   // CreateDir('logs');

  THorse.Use(OctetStream);
  THorseOctetStreamConfig.GetInstance.AcceptContentType.Add('application/octet-stream');

  THorse.Get('/stream/:fichier', GetStream);
  THorse.Post('/stream/:fichier', PostStream);

  LogMessage('API started on port 9001.');
  //THorse.Listen(9001,'192.168.1.117',@running);
  THorse.Listen(9001,@running);
end.


