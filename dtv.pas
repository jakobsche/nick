unit DTV;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ComCtrls;

type
  
  { TDetailledTreeView }

  TDetailledTreeView = class(TCustomTreeView)
  private
    FListView: TCustomListView;
    procedure SetListView(AValue: TCustomListView);
  protected
    procedure DoSelectionChanged; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation);
      override;
    procedure UpdateListView; virtual;
  public

  published
    property ListView: TCustomListView read FListView write SetListView;
    property OnSelectionChanged;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Nick''s components',[TDetailledTreeView]);
end;

{ TDetailledTreeView }

procedure TDetailledTreeView.SetListView(AValue: TCustomListView);
begin
  if FListView = AValue then Exit;
  if FListView <> nil then FListView.RemoveFreeNotification(Self);
  FListView := AValue;
  if AValue <> nil then AValue.FreeNotification(Self);
end;

procedure TDetailledTreeView.DoSelectionChanged;
begin
  inherited DoSelectionChanged;
  if Assigned(ListView) then UpdateListView
end;

procedure TDetailledTreeView.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  case Operation of
    opRemove:
      if AComponent <> nil then
        if AComponent = FListView then begin
          ListView := nil
        end;
  end;
end;

procedure TDetailledTreeView.UpdateListView;
begin
{ This is called only, if ListView <> nil, to fill the ListView with Items,
  being determined by the selected Tree Node. Override this in a descendent or
  use the OnSelectionChanged event in the Object Inspector}
end;

end.
