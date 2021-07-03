unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, FMX.Layouts,
  FMX.ListBox, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Controls, FMX.Types,
  FMX.Objects, FMX.Forms, FMX.DialogService, SSDPFind;



const
  USN = 'urn:schemas-upnp-org:RacTool:control:1';

type
  TfrmMain = class(TForm)
    btnFind: TSpeedButton;
    cbInterfaces: TComboBox;
    rectMain: TRectangle;
    lstResult: TListBox;
    procedure btnFindClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbInterfacesChange(Sender: TObject);
  private
    { Private declarations }
    FFind: TSSDPFind;
    procedure _OnFind(Sender: TObject; Address: string);
    procedure _OnFindFinished(Sender: TObject; List: TStrings);
    procedure EnableControls(AEnable: Boolean);
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

procedure TfrmMain.btnFindClick(Sender: TObject);
begin
  if cbInterfaces.ItemIndex >= 0 then
  begin
    lstResult.Clear;
    EnableControls(False);

    // Find with method 1:
//    FFind.Find;

    // or method 2:
    FFind.Find(procedure(Address: string) begin
      lstResult.Items.Append(Format('Method 2 -> Found "%s"', [Address]));
    end);

  end else
    TDialogService.MessageDialog('You have to select network interface first', TMsgDlgType.mtWarning, [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0, nil);
end;

procedure TfrmMain.cbInterfacesChange(Sender: TObject);
var
  i: Integer;
begin
  // Disable all interfaces
  for i := 0 to FFind.IPAddresses.Count - 1 do
    FFind.IPAddresses[i].Active := False;
  // Enable selected interface
  FFind.IPAddresses[cbInterfaces.ItemIndex].Active := True;
end;

procedure TfrmMain.EnableControls(AEnable: Boolean);
begin
  cbInterfaces.Enabled := AEnable;
  btnFind.Enabled      := AEnable;
  lstResult.Enabled    := AEnable;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  // Create component
  FFind := TSSDPFind.Create(1900);
  // of course you cas set up port later:
  // FFind := TSSDPFind.Create;
  // FFind.Port := 1900;

  // Set URN to find. Comment it to search all SSDP.
  FFind.SearchUSN := USN;

  // Necessary with method 1 only. With method 2, you can skip it.
  FFind.OnFind         := _OnFind;
  FFind.OnFindFinished := _OnFindFinished;

  // Fill combobox with IP addresses
  for i := 0 to FFind.IPAddresses.Count - 1 do
    cbInterfaces.Items.Append(FFind.IPAddresses[i].Address);
  cbInterfaces.ItemIndex := -1;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FFind.DisposeOf;
end;

procedure TfrmMain._OnFind(Sender: TObject; Address: string);
begin
  lstResult.Items.Append(Format('Method 1 -> Found "%s"', [Address]));
end;

procedure TfrmMain._OnFindFinished(Sender: TObject; List: TStrings);
var
  suffix: string;
begin
  if List.Count <> 1 then
    suffix := 'es';
  lstResult.Items.Append(Format('Done. Found %d address%s', [List.Count, suffix]));
  EnableControls(True);
end;

end.
