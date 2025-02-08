unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, fphttpclient,
  fpjson;

type

  { TForm1 }

  TForm1 = class(TForm)
    BtnGetFile: TButton;
    BtnUploadFile: TButton;
    MemoResponse: TMemo;
    OpenDialog: TOpenDialog;
    BtnSendRequest: TButton;
    EdtUrl: TEdit;
    EdtAutorisation: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    procedure BtnGetFileClick(Sender: TObject);
    procedure BtnUploadFileClick(Sender: TObject);
  private
    function SendGetRequest(FileName,_url,Auth: string): string;
    function SendPostRequest(FileName,_url,Auth: string): string;
    function URLEncode(const Str: string): string;
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

//const
  //API_URL = 'http://192.168.1.123:9001/stream/';
  //AUTH_TOKEN = 'Bearer 123456789';

procedure TForm1.BtnGetFileClick(Sender: TObject);
var
  FileName: string;
begin
  FileName := InputBox('Nom Fichier', 'Enter Nom Fichier:', '');
  if FileName <> '' then
    MemoResponse.Lines.Text := SendGetRequest(FileName,EdtUrl.Text,EdtAutorisation.Text);
end;

procedure TForm1.BtnUploadFileClick(Sender: TObject);
begin
  if OpenDialog.Execute then
  begin
    MemoResponse.Lines.Add('Chargement: ' + OpenDialog.FileName);
    MemoResponse.Lines.Text := SendPostRequest(OpenDialog.FileName,EdtUrl.text,EdtAutorisation.Text);
  end;
end;

function TForm1.SendGetRequest(FileName,_url,Auth: string): string;
var
  HttpClient: TFPHTTPClient;
  Stream: TMemoryStream;
  SavePath: string;
  AUTH_TOKEN:string;
  URL: string;
begin
  //URL := 'http://192.168.1.123:9001/stream/'+ ExtractFileName(FileName);
  //URL := 'http://'+_url+ ExtractFileName(FileName);
   URL := 'http://'+_url+ URLEncode(ExtractFileName(FileName));
  AUTH_TOKEN:= 'Bearer '+Auth;
  HttpClient := TFPHTTPClient.Create(nil);

  HttpClient.AddHeader('Authorization', AUTH_TOKEN);
  HttpClient.AddHeader('Content-Type', 'application/octet-stream');
  Stream := TMemoryStream.Create;

  // Dossier où le fichier sera enregistré
  SavePath := GetCurrentDir+'/image/'+ExtractFileName(FileName);
      ShowMessage(SavePath);
  try
    // Effectuer la requête GET et récupérer le flux de données
    HttpClient.Get(URL, Stream);

    // Sauvegarder le flux dans le dossier spécifié
    Stream.SaveToFile(SavePath);
  //  showmessage('Image téléchargée et enregistrée dans : '+ SavePath);
   result:=  SavePath;
  except
    on E: Exception do
      ShowMessage('Error: '+E.Message);
  end;

  Stream.Free;
  HttpClient.Free;
end;

function TForm1.SendPostRequest(FileName,_url,Auth: string): string;
var
  Client: TFPHTTPClient;
  FileStream: TFileStream;
  Response: TStringStream;
  ResponseCode: Integer;
  URL:string;
  AUTH_TOKEN : string;
begin
  URL := 'http://'+_url+ URLEncode(ExtractFileName(FileName));
  //encodedStr := TIdURI.Encode(rawStr);
  AUTH_TOKEN:= 'Bearer '+Auth;
  Client := TFPHTTPClient.Create(nil);
  FileStream := TFileStream.Create(FileName, fmOpenRead);
  Response := TStringStream.Create('');
  try
    Client.AddHeader('Authorization', AUTH_TOKEN);
    Client.AddHeader('Content-Type', 'application/octet-stream');
    try
      Client.RequestBody := FileStream;
      Client.Post(URL , Response);
      ResponseCode := Client.ResponseStatusCode;
      if ResponseCode = 201 then
        Result := 'File uploaded successfully : '+FileName
      else
        Result := 'Upload failed. HTTP Code: ' + IntToStr(ResponseCode) + ' - ' + Response.DataString;
    except
      on E: Exception do
        Result := 'Error: ' + E.Message;
    end;
  finally
    FileStream.Free;
    Response.Free;
    Client.Free;
  end;
end;



function TForm1.URLEncode(const Str: string): string;
var
  i: Integer;
  c: Char;
begin
  Result := '';
  for i := 1 to Length(Str) do
  begin
    c := Str[i];
    // Encodage des caractères non-alphanumériques
    if c in ['A'..'Z', 'a'..'z', '0'..'9', '-', '_', '.', '~'] then
      Result := Result + c
    else
      Result := Result + '%' + IntToHex(Ord(c), 2);
  end;
end;



end.


