unit SSDPFind;


interface


uses
  IdUDPServer, IdGlobal, IdStack, IdSocketHandle, System.Classes, System.SysUtils,
  System.Generics.Collections;


const
  FIND_INTERVAL = 1000;


type TSSDPFindIP = class
  private
    FAddress: string;
    FActive: Boolean;
    FIPv6: Boolean;
  public
    constructor Create(AAddress: string; AIPv6: Boolean);
    //
    property Address: string  read FAddress;
    property Active : Boolean read FActive write FActive;
    property IPv6   : Boolean read FIPv6   write FIPv6;
end;


type TSSDPFindIPs = class(TObjectList<TSSDPFindIP>);


type TOnSSDPFind         = procedure(Sender: TObject; Address: string) of Object;
type TOnSSDPFindProc     = reference to procedure(Address: string);
type TOnSSDPFindFinished = procedure(Sender: TObject; Addresses: TStrings) of Object;


type TSSDPFind = class(TObject)
  private
    FResult        : TStrings;
    FUdp           : TIdUDPServer;
    FIPAddresses   : TSSDPFindIPs;
    FOnFind        : TOnSSDPFind;
    FSearchUSN     : string;
    FPort          : Word;
    FResultProc    : TOnSSDPFindProc;
    FOnFindFinished: TOnSSDPFindFinished;
  protected
    procedure FillIPList;
    procedure _OnUDPRead(AThread: TIdUDPListenerThread; const AData: TIdBytes; ABinding: TIdSocketHandle);
    procedure DoOnUdpRead(ReadedLocation: string);
  public
    constructor Create(APort: Word = 0);
    destructor  Destroy; override;
    procedure Find(ResultProc: TOnSSDPFindProc = nil);
    //
    property SearchUSN  : string       read FSearchUSN   write FSearchUSN;
    property Port       : Word         read FPort        write FPort;
    property IPAddresses: TSSDPFindIPs read FIPAddresses;
    //
    property OnFind        : TOnSSDPFind         read FOnFind         write FOnFind;
    property OnFindFinished: TOnSSDPFindFinished read FOnFindFinished write FOnFindFinished;
end;


implementation


{ TSSDPFindIP }


constructor TSSDPFindIP.Create(AAddress: string; AIPv6: Boolean);
begin
  FAddress := AAddress;
  FActive  := False;
  FIPv6    := AIPv6;
end;


{ TSSDPFind }


constructor TSSDPFind.Create(APort: Word);
begin
  FUdp         := TIdUDPServer.Create(nil);
  FIPAddresses := TSSDPFindIPs.Create(True);
  FResult      := TStringList.Create;

  FUdp.BroadcastEnabled := True;
  FUdp.OnUDPRead        := _OnUDPRead;
  FPort                 := APort;
  FSearchUSN            := 'ssdp:all';

  FillIPList;
end;


destructor TSSDPFind.Destroy;
begin
  if FUdp.Active then
    FUdp.Active := False;
  FUdp.DisposeOf;
  FResult.DisposeOf;
  inherited;
end;


procedure TSSDPFind.DoOnUdpRead(ReadedLocation: string);
begin
  if Assigned(FResultProc) then
    FResultProc(ReadedLocation) else
  if Assigned(FOnFind) then
    FOnFind(Self, ReadedLocation);
end;


procedure TSSDPFind.FillIPList;
var
  LList: TIdStackLocalAddressList;
  i: Integer;
begin
  FIPAddresses.Clear;
  LList := TIdStackLocalAddressList.Create;
  try
    GStack.GetLocalAddressList(LList);
    for i := 0 to LList.Count - 1 do
      FIPAddresses.Add(
        TSSDPFindIP.Create(
          LList[i].IPAddress,
          (LList[i].IPVersion = TIdIPVersion.Id_IPv6)
        )
      );
  finally
    LList.DisposeOf;
  end;
end;


procedure TSSDPFind.Find(ResultProc: TOnSSDPFindProc);
var
  sh: TIdSocketHandle;
  i: Integer;
begin
  if FUdp.Active then
    Exit;

  inherited;
  FResultProc := ResultProc;

  FUdp.Bindings.ClearAndResetID;
  for i := 0 to FIPAddresses.Count - 1 do
    if FIPAddresses[i].Active then
    begin
      sh      := FUdp.Bindings.Add;
      sh.IP   := FIPAddresses[i].Address;
      sh.Port := 0;
      if FIPAddresses[i].IPv6 then
        sh.IPVersion := TIdIPVersion.Id_IPv6
      else
        sh.IPVersion := TIdIPVersion.Id_IPv4;
    end;

  FResult.Clear;

  FUdp.Send('239.255.255.250', FPort,
    'M-SEARCH * HTTP/1.1'#13#10 +
    'HOST: 239.255.255.250:' + IntToStr(FPort) + #13#10 +
    'MAN: "ssdp:discover"'#13#10 +
    'MX: 1'#13#10 +
    'ST: ' + FSearchUSN + #13#10#13#10
  );

  TThread.CreateAnonymousThread(procedure
  begin
    Sleep(FIND_INTERVAL);
    TThread.Synchronize(nil, procedure
    begin
      FUdp.Active := False;
      if Assigned(FOnFindFinished) then
        FOnFindFinished(Self, FResult);
    end);
  end).Start;
end;


procedure TSSDPFind._OnUDPRead(AThread: TIdUDPListenerThread;
  const AData: TIdBytes; ABinding: TIdSocketHandle);
const
  S_LOCATION = 'LOCATION: ';
var
  s: string;
  i: Integer;
  sl: TStringList;
begin
  sl := TStringList.Create;
  try
    sl.Text := BytesToString(AData, IndyTextEncoding_UTF8);
    for i := 0 to sl.Count - 1 do
    begin
      s := sl[i];
      if Pos(S_LOCATION, s) = Low(string) then
      begin
        Delete(s, Low(string), Length(S_LOCATION));
        FResult.Append(s);
        DoOnUdpRead(s);
      end;
    end;
  finally
    sl.Free;
  end;
end;


end.
