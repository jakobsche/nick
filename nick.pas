{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit nick;

{$warn 5023 off : no warning about unused units}
interface

uses
  PathView, PresEdit, DTV, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('PathView', @PathView.Register);
  RegisterUnit('PresEdit', @PresEdit.Register);
  RegisterUnit('DTV', @DTV.Register);
end;

initialization
  RegisterPackage('nick', @Register);
end.
