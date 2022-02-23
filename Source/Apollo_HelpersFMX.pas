unit Apollo_HelpersFMX;

interface

uses
  FMX.Controls,
  FMX.Edit,
  FMX.Forms,
  FMX.ImgList,
  FMX.Objects,
  FMX.StdCtrls,
  FMX.TabControl,
  FMX.TreeView,
  System.Classes;

type
  TCreateFrameProc<T: TFrame> = reference to function: T;

  TFormHelper = class helper for TForm
    function ShowFrameAsNew<T: TFrame>(aParent: TPanel; aFrame: T;
      aCreateFrameProc: TCreateFrameProc<T>): T; overload;
    function ShowFrameAsNew<T: TFrame>(aParent: TTabControl; aFrame: T;
      aCreateFrameProc: TCreateFrameProc<T>; aDirection: TTabTransitionDirection = TTabTransitionDirection.Normal): T; overload;
    procedure ShowFrame(aParent: TPanel; aFrame: TFrame); overload;
    procedure ShowFrame(aParent: TTabControl; aFrame: TFrame;
      aDirection: TTabTransitionDirection = TTabTransitionDirection.Normal); overload;
  end;

  TTreeViewItemHelper = class helper for TTreeViewItem
    procedure RemoveAllNodes;
  end;

  TValidValueFunc = reference to function(const aValue: Variant; out aErrMsg: string): Boolean;
  TValidPassedProc = reference to procedure(const aValue: Variant);

  TEditHelper = class helper for TEdit
    procedure Validate(aValidFunc: TValidValueFunc; aValidPassedProc: TValidPassedProc);
  end;

  TFMXTools = record
    class function ShowFrameAsNew<T: TFrame>(aParent: TPanel; aFrame: T;
      aCreateFrameProc: TCreateFrameProc<T>): T; overload; static;
    class function ShowFrameAsNew<T: TFrame>(aParent: TTabControl; aFrame: T;
      aCreateFrameProc: TCreateFrameProc<T>; aDirection: TTabTransitionDirection): T; overload; static;
    class procedure HideAllFrames(aParent: TPanel); static;
    class procedure ShowFrame(aParent: TPanel; aFrame: TFrame); overload; static;
    class procedure ShowFrame(aParent: TTabControl; aFrame: TFrame;
      aDirection: TTabTransitionDirection); overload; static;
    class procedure ShowHintForControl(const aMsg: string; aControl: TControl); static;
  end;

  IEditExtensionHelper = interface
  ['{A70503BE-0E64-4045-9985-C458886C89B7}']
    procedure ApplyToLabel(aLabel: TLabel; aEditClick: TNotifyEvent);
  end;

  function MakeEditExtension(aImageList: TImageList; const aImageIndex: Integer): IEditExtensionHelper;

implementation

uses
  FMX.Graphics,
  FMX.Layouts,
  FMX.ListBox,
  FMX.Types,
  System.Math,
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

  TControlHintTimer = class(TTimer)
  private
    FControl: TControl;
    FDelay: Integer;
    FDuration: Integer;
    procedure TimerHandler(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
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

{ TFormHelper }

procedure TFormHelper.ShowFrame(aParent: TPanel; aFrame: TFrame);
begin
  TFMXTools.ShowFrame(aParent, aFrame);
end;

procedure TFormHelper.ShowFrame(aParent: TTabControl; aFrame: TFrame;
  aDirection: TTabTransitionDirection);
begin
  TFMXTools.ShowFrame(aParent, aFrame, aDirection);
end;

function TFormHelper.ShowFrameAsNew<T>(aParent: TTabControl; aFrame: T;
  aCreateFrameProc: TCreateFrameProc<T>;
  aDirection: TTabTransitionDirection): T;
begin
  Result := TFMXTools.ShowFrameAsNew<T>(aParent, aFrame, aCreateFrameProc, aDirection);
end;

function TFormHelper.ShowFrameAsNew<T>(aParent: TPanel; aFrame: T;
  aCreateFrameProc: TCreateFrameProc<T>): T;
begin
  Result := TFMXTools.ShowFrameAsNew<T>(aParent, aFrame, aCreateFrameProc);
end;

{ TFMXTools }

class procedure TFMXTools.HideAllFrames(aParent: TPanel);
var
  Frame: TFrame;
  i: Integer;
begin
  for i := 0 to aParent.ChildrenCount - 1 do
    if aParent.Controls[i].InheritsFrom(TFrame) then
    begin
      Frame := TFrame(aParent.Controls[i]);
      Frame.Visible := False;
    end;
end;

class procedure TFMXTools.ShowFrame(aParent: TPanel; aFrame: TFrame);
begin
  HideAllFrames(aParent);

  aFrame.Parent := aParent;
  aFrame.Align := TAlignLayout.Client;

  aFrame.Visible := True;
end;

class procedure TFMXTools.ShowFrame(aParent: TTabControl; aFrame: TFrame;
  aDirection: TTabTransitionDirection);
var
  i: Integer;
  Tab: TTabItem;
begin
  Tab := nil;

  for i := 0 to aParent.TabCount - 1 do
  begin
    if aParent.Tabs[i].Children[0] = aFrame then
    begin
      Tab := aParent.Tabs[i];
      Break;
    end;
  end;

  if not Assigned(Tab) then
  begin
    Tab := TTabItem.Create(aParent);
    Tab.Parent := aParent;

    aFrame.Parent := Tab;
    aFrame.Align := TAlignLayout.Client;
  end;

  aParent.SetActiveTabWithTransitionAsync(Tab, TTabTransition.Slide, aDirection, nil);
end;

class function TFMXTools.ShowFrameAsNew<T>(aParent: TTabControl; aFrame: T;
  aCreateFrameProc: TCreateFrameProc<T>;
  aDirection: TTabTransitionDirection): T;
var
  i: Integer;
  Tab: TTabItem;
begin
  if Assigned(aFrame) then
    for i := 0 to aParent.TabCount - 1 do
    begin
      if aParent.Tabs[i].Children[0] = TFrame(aFrame) then
      begin
        Tab := aParent.Tabs[i];
        Tab.Free;
        Break;
      end;
    end;

  Tab := TTabItem.Create(aParent);
  Tab.Parent := aParent;

  if Assigned(aFrame) then
    FreeAndNil(aFrame);

  Result := aCreateFrameProc;
  Result.Parent := Tab;
  Result.Align := TAlignLayout.Client;

  aParent.SetActiveTabWithTransitionAsync(Tab, TTabTransition.Slide, aDirection, nil);
end;

class procedure TFMXTools.ShowHintForControl(const aMsg: string;
  aControl: TControl);
var
  Panel: TCalloutPanel;
  Text: TText;
  Timer: TControlHintTimer;
begin
  Panel := TCalloutPanel.Create(aControl);
  Panel.Width := Min(200, aControl.Width);
  Panel.Height := 50;
  Panel.Opacity := 0.9;
  Panel.Parent := aControl.Parent;

  Text := TText.Create(Panel);
  Text.Parent := Panel;
  Text.Align := TAlignLayout.Client;
  Text.Text := aMsg;

  Panel.Position.X := aControl.Position.X + (aControl.Width / 2) - (Panel.Width / 2);
  Panel.Position.Y := aControl.BoundsRect.Bottom;

  Timer := TControlHintTimer.Create(Panel);
  Timer.FDelay := 2000;
  Timer.Enabled := True;
end;

class function TFMXTools.ShowFrameAsNew<T>(aParent: TPanel; aFrame: T;
  aCreateFrameProc: TCreateFrameProc<T>): T;
begin
  if Assigned(aFrame) then
    FreeAndNil(aFrame);

  HideAllFrames(aParent);

  Result := aCreateFrameProc;
  Result.Parent := aParent;
  Result.Align := TAlignLayout.Client;
end;

{ TEditHelper }

procedure TEditHelper.Validate(aValidFunc: TValidValueFunc;
  aValidPassedProc: TValidPassedProc);
var
  ErrMsg: string;
begin
  if aValidFunc(Text, {out}ErrMsg) then
  begin
    if Assigned(aValidPassedProc) then
      aValidPassedProc(Text);
  end
  else
  begin
    TFMXTools.ShowHintForControl(ErrMsg, Self);
    Abort;
  end;
end;

{ TControlHintTimer }

constructor TControlHintTimer.Create(AOwner: TComponent);
begin
  inherited;

  FControl := AOwner as TControl;
  FDuration := 0;
  Interval := 50;
  OnTimer := TimerHandler;
end;

procedure TControlHintTimer.TimerHandler(Sender: TObject);
var
  Opacity: Single;
begin
  FDuration := FDuration + Integer(Interval);

  if FDuration >= FDelay then
  begin
    Opacity := FControl.Opacity;
    Opacity := Opacity - 0.05;
    FControl.Opacity := Max(Opacity, 0);

    if FControl.Opacity = 0 then
      FControl.Free;
  end;
end;

end.
