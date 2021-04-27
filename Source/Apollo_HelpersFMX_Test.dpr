program Apollo_HelpersFMX_Test;

{$STRONGLINKTYPES ON}

{DEFINE UseVCL}
{$DEFINE UseFMX}

uses
  {$IFDEF UseVCL}
  VCL.Forms,
  DUnitX.Loggers.GUI.VCL,
  {$ENDIF}

  {$IFDEF UseFMX}
  FMX.Forms,
  DUnitX.Loggers.GUIX,
  {$ENDIF}

  System.SysUtils,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  tstApollo_HelpersFMX in 'tstApollo_HelpersFMX.pas',
  Apollo_HelpersFMX in 'Apollo_HelpersFMX.pas';

begin
  Application.Initialize;
  Application.Title := 'DUnitX';
  {$IFDEF UseFMX}
  Application.CreateForm(TGUIXTestRunner, GUIXTestRunner);
  {$ENDIF}
  {$IFDEF UseVCL}
  Application.CreateForm(TGUIVCLTestRunner, GUIVCLTestRunner);
  {$ENDIF}
  Application.Run;
end.
