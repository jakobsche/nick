{

This file belongs to the package "nick" which can be installed in the Lazarus IDE.

The package "nick" is dedicated to Nick Reinders.

Copyright (C) 2016 - 2018 Andreas Jakobsche  messages@jakobsche.de

This library is free software; you can redistribute it and/or modify it
under the terms of the GNU Library General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at your
option) any later version with the following modification:

As a special exception, the copyright holders of this library give you
permission to link this library with independent modules to produce an
executable, regardless of the license terms of these independent modules,and
to copy and distribute the resulting executable under terms of your choice,
provided that you also meet, for each linked independent module, the terms
and conditions of the license of that module. An independent module is a
module which is not derived from or based on this library. If you modify
this library, you may extend this exception to your version of the library,
but you are not obligated to do so. If you do not wish to do so, delete this
exception statement from your version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License
for more details.

You should have received a copy of the GNU Library General Public License
along with this library; if not, write to the Free Software Foundation,
Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
}

unit PathView;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ComCtrls;

type

  { TPathTreeView }

  TPathTreeView = class(TTreeView)
  private
    { Private declarations }
    FPaths: TStrings;
    FPathSeparator: string;
    function FindChild(AParent: TTreeNode; AText: string): TTreeNode;
    procedure AddPath(AText: string); overload;
    procedure AddPath(AParent: TTreeNode; AText: string); overload;
    function GetPaths: TStrings;
    procedure SetPaths(AValue: TStrings);
  protected
    { Protected declarations }
  public
    { Public declarations }
    constructor Create(TheOwner: TComponent); override;
  published
    { Published declarations }
    property Paths: TStrings read GetPaths write SetPaths;
    property PathSeparator: string read FPathSeparator write FPathSeparator;
  end;

procedure Register;

implementation

uses Op;

type

  { TPathList }

  TPathList = class(TStrings)
  private
    TreeView: TPathTreeView;
  protected
    function Get(Index: Integer): string; override;
    function GetCount: Integer; override;
  public
    procedure Clear; override;
    procedure Delete(Index: Integer); override;
    procedure Insert(Index: Integer; const S: string); override;
  end;

procedure Register;
begin
  RegisterComponents('Nick''s Components',[TPathTreeView]);
end;

{ TPathList }

function TPathList.Get(Index: Integer): string;
var
  ListIndex, i: Integer;
begin
  if (Index < 0) or (Index >= Count) then raise Exception.CreateFmt(
    'TPathList.Get(%d): Der Listenindex ist ungültig.', [Index]);
  ListIndex := -1;
  Result := '';
  for i := 0 to TreeView.Items.Count - 1 do
    if not TreeView.Items[i].HasChildren then begin
      Inc(ListIndex);
      if ListIndex = Index then begin
        Result := TreeView.Items[i].GetTextPath;
        Exit
      end;
    end;
end;

function TPathList.GetCount: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to TreeView.Items.Count - 1 do
    if not TreeView.Items[i].HasChildren then Inc(Result)
end;

procedure TPathList.Clear;
begin
  TreeView.Items.Clear
end;

procedure TPathList.Delete(Index: Integer);
begin
  raise Exception.Create('"TPathList.Delete" is not implemented, yet.')
end;

procedure TPathList.Insert(Index: Integer; const S: string);
begin
  TreeView.AddPath(S)
end;

{ TPathTreeView }

function TPathTreeView.FindChild(AParent: TTreeNode; AText: string): TTreeNode;
var
  i: Integer;
begin
  Result := nil;
  if AParent <> nil then begin
    for i := 0 to AParent.Count - 1 do
      if AText = AParent.Items[i].Text then begin
        Result := AParent.Items[i];
        Exit
      end
  end
  else begin
    for i := 0 to Items.Count - 1 do
      if AText = Items[i].Text then begin
        Result := Items[i];
        Exit
      end
  end;
end;

constructor TPathTreeView.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FPathSeparator := '/'
end;

procedure TPathTreeView.AddPath(AText: string);
var
  x, y: string;
  P: TTreeNode;
begin
  if AText = '' then Exit;
  x := Parse(AText, PathSeparator, y);
  P := FindChild(nil, x);
  if P = nil then AddPath(Items.Add(nil, x), y)
  else AddPath(P, y)
end;

procedure TPathTreeView.AddPath(AParent: TTreeNode; AText: string);
var
  x, y: string;
  P: TTreeNode;
begin
  if AParent = nil then raise Exception.Create({unendliche Rekursion verhindern}
  '"AddPath(nil, AText)" funktioniert nicht. Verwende "AddPath(AText)"!');
  if AText = '' then Exit;
  x := Parse(AText, PathSeparator, y);
  P := FindChild(AParent, x);
  if P = nil then AddPath(Items.AddChild(AParent, x), y)
  else AddPath(P, y)
end;

function TPathTreeView.GetPaths: TStrings;
begin
  if not Assigned(FPaths) then begin
    FPaths := TPathList.Create;
    TPathList(FPaths).TreeView := Self
  end;
  Result := FPaths
end;

procedure TPathTreeView.SetPaths(AValue: TStrings);
begin
  if AValue <> GetPaths then GetPaths.Assign(AValue);
end;

end.
