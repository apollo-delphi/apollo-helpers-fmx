unit Apollo_HelpersFMX;

interface

uses
  FMX.ImgList,
  FMX.Objects,
  FMX.StdCtrls,
  FMX.TreeView,
  System.Classes;

type
  TTreeViewItemHelper = class helper for TTreeViewItem
    procedure RemoveAllNodes;
  end;

  IEditExtensionHelper = interface
  ['{A70503BE-0E64-4045-9985-C458886C89B7}']
    procedure ApplyToLabel(aLabel: TLabel; aEditClick: TNotifyEvent);
  end;

  function MakeEditExtension(aImageList: TImageList; const aImageIndex: Integer): IEditExtensionHelper;

implementation

uses
  FMX.Controls,
  FMX.Graphics,
  FMX.Layouts,
  FMX.ListBox,
  FMX.Types,
  System.Rtti,
  System.SysUtils,
  System.UITypes;

type
  TEditExtensionHelper = class(TInterfacedObject, IEditExtensionHelper)
  private
    FEditClick: TNotifyEvent;
    FImageIndex: Integer;
    FImageList: TImageList;
    function GetEditExtensionButton(Sender: TObject): TSpeedButton;
    function GetControl(Sender: TObject): TStyledControl;
    procedure ApplyEditExtensionStyle(Sender: TObject);
    procedure ApplyToLabel(aLabel: TLabel; aEditClick: TNotifyEvent);
    procedure EditExtensionButtonClick(Sender: TObject);
    procedure EditExtensionButtonMouseEnter(Sender: TObject);
    procedure EditExtensionButtonMouseLeave(Sender: TObject);
    procedure EditExtensionWrapperMouseEnter(Sender: TObject);
    procedure EditExtensionWrapperMouseLeave(Sender: TObject);
    constructor Create(aImageList: TImageList; const aImageIndex: Integer);
  end;

function MakeEditExtension(aImageList: TImageList; const aImageIndex: Integer): IEditExtensionHelper;
begin
  Result := TEditExtensionHelper.Create(aImageList, aImageIndex);
end;

{ TTreeViewItemHelper }

procedure TTreeViewItemHelper.RemoveAllNodes;
var
  i: Integer;
begin
  for i := Count - 1 downto 0 do
    RemoveObject(Items[i]);
end;

{ TEditExtensionHelper }

procedure TEditExtensionHelper.ApplyEditExtensionStyle(Sender: TObject);
var
  Control: TStyledControl;
begin
  Control := GetControl(Sender);

  Control.StylesData['background.OnMouseEnter'] := TValue.From<TNotifyEvent>(EditExtensionWrapperMouseEnter);
  Control.StylesData['background.OnMouseLeave'] := TValue.From<TNotifyEvent>(EditExtensionWrapperMouseLeave);

  Control.StylesData['editbutton.OnMouseEnter'] := TValue.From<TNotifyEvent>(EditExtensionButtonMouseEnter);
  Control.StylesData['editbutton.OnMouseLeave'] := TValue.From<TNotifyEvent>(EditExtensionButtonMouseLeave);
  Control.StylesData['editbutton.OnClick'] := TValue.From<TNotifyEvent>(EditExtensionButtonClick);

  GetEditExtensionButton(Sender).Images := FImageList;
  GetEditExtensionButton(Sender).ImageIndex := FImageIndex;
end;

constructor TEditExtensionHelper.Create(aImageList: TImageList; const aImageIndex: Integer);
begin
  FImageList := aImageList;
  FImageIndex := aImageIndex;
end;

procedure TEditExtensionHelper.EditExtensionButtonClick(Sender: TObject);
begin
  if Assigned(FEditClick) then
    FEditClick(GetControl(Sender));
end;

procedure TEditExtensionHelper.EditExtensionButtonMouseEnter(Sender: TObject);
begin
  GetEditExtensionButton(Sender).Visible := True;
  GetControl(Sender).StylesData['background.Fill.Color'] := TAlphaColors.Lightgray;
end;

procedure TEditExtensionHelper.EditExtensionButtonMouseLeave(Sender: TObject);
begin
  GetEditExtensionButton(Sender).Visible := False;
  GetControl(Sender).StylesData['background.Fill.Color'] := TAlphaColors.Null;
end;

procedure TEditExtensionHelper.EditExtensionWrapperMouseEnter(Sender: TObject);
begin
  GetEditExtensionButton(Sender).Visible := True;
end;

procedure TEditExtensionHelper.EditExtensionWrapperMouseLeave(Sender: TObject);
begin
  GetEditExtensionButton(Sender).Visible := False;
end;

function TEditExtensionHelper.GetControl(Sender: TObject): TStyledControl;
begin
  if Sender is TSpeedButton then
    Exit(TFmxObject(Sender).Parent.Parent.Parent.Parent as TStyledControl)
  else
  if Sender is TRectangle then
    Exit(TFmxObject(Sender).Parent.Parent as TStyledControl)
  else
    Exit(Sender as TStyledControl);
end;

function TEditExtensionHelper.GetEditExtensionButton(Sender: TObject): TSpeedButton;
var
  StyleObject: TFmxObject;
begin
  StyleObject := GetControl(Sender).FindStyleResource('editbutton');
  if (StyleObject <> nil) and (StyleObject is TSpeedButton) then
    Result := TSpeedButton(StyleObject)
  else
    Result := nil;
end;

procedure TEditExtensionHelper.ApplyToLabel(aLabel: TLabel; aEditClick: TNotifyEvent);
begin
  FEditClick := aEditClick;

  aLabel.HitTest := False;
  aLabel.OnApplyStyleLookup := ApplyEditExtensionStyle;
  aLabel.StyleLookup := 'labelEditExt';
end;

end.
