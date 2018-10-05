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

unit PresEdit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, DBObjPas,
  ExtCtrls;

type

  { TPresentationPage }

  TPresentationPage = class(TDataRecord)
  private
    FDelay: Integer;
    FPicture: TPicture;
    function GetPicture: TPicture;
  public
    destructor Destroy; override;
  published
    property Delay: Integer read FDelay write FDelay;
    property Picture: TPicture read GetPicture write FPicture;
  end;

  TPresentationEditor = class;

  { TPresentation }

  TPresentation = class(TDataTable) {streamable container for a presentation}
  private
    FDelay: Integer;
    FEditor: TPresentationEditor;
    FTitle: string;
    function GetPages(I: Integer): TPresentationPage;
    procedure Loaded; override;
  public
    constructor Create(AnOwner: TComponent); override;
    procedure AddPage(FileName: string);
    procedure Clear;
    procedure Delete(AnIndex: Integer);
    function IsEmpty: Boolean;
    procedure LoadFromFile(FileName: string);
    procedure SaveToFile(FileName: string);
    property Editor: TPresentationEditor read FEditor write FEditor;
    property Pages[I: Integer]: TPresentationPage read GetPages;
  published
    property Delay: Integer read FDelay write FDelay; {used for pages without
      their own value}
    property Title: string read FTitle write FTitle;
  end;

  { TMiniPageView }

  TMiniPageView = class(TCustomControl)
  private
    FEditor: TPresentationEditor;
    FPageIndex: Integer;
    FPage: TPresentationPage;
    FBitmap: TBitmap;
    procedure Move(Destination: TMiniPageView);
    procedure SetPage(AValue: TPresentationPage);
    property Bitmap: TBitmap read FBitmap write FBitmap;
    property Editor: TPresentationEditor read FEditor;
  protected
    procedure DragOver(Source: TObject; X,Y: Integer; State: TDragState;
                       var Accept: Boolean); override;
    procedure MouseDown(Button: TMouseButton; Shift:TShiftState; X,Y:Integer); override;
    procedure Paint; override;
    procedure SetParent(NewParent: TWinControl); override;
  public
    constructor Create(AnOwner: TComponent); override;
    destructor Destroy; override;
    procedure DragDrop(Source: TObject; X,Y: Integer); override;
    procedure SetFocus; override;
    procedure View;
    property Page: TPresentationPage read FPage write SetPage;
    property PageIndex: Integer read FPageIndex write FPageIndex;
  end;

type
  
  { TPresentationEditor }

  TPresentationEditor = class(TScrollBox)
  private
    FItemIndex: Integer;
    FMiniPageViewList: TList;
    FPresentation: TPresentation;
    FImage: TImage;
    function GetMiniPageView(i: Integer): TMiniPageView;
    function GetMiniPageViewCount: Integer;
    function GetMiniPageViewList: TList;
    function GetMiniPageViews(i: Integer): TMiniPageView;
    function GetPresentation: TPresentation;
    procedure ResizeMiniPageViews;
    procedure SetItemIndex(Value: Integer);
    procedure UpdateMiniPageViews;
    property MiniPageViewList: TList read GetMiniPageViewList;
  protected

  public
    constructor Create(AnOwner: TComponent); override;
    destructor Destroy; override;
    procedure AddPage(FileName: string);
    procedure Delete(AnIndex: Integer);
    property ItemIndex: Integer read FItemIndex write SetItemIndex;
    property MiniPageViewCount: Integer read GetMiniPageViewCount;
    property MiniPageViews[i: Integer]: TMiniPageView read GetMiniPageView;
    property Presentation: TPresentation read GetPresentation;
  published
    property Image: TImage read FImage Write FImage;
  end;

procedure Register;

implementation

uses Streaming2;

procedure Register;
begin
  RegisterComponents('Nick''s Components',[TPresentationEditor]);
end;

{ TMiniPageView }

procedure TMiniPageView.Move(Destination: TMiniPageView);
begin
  Editor.Presentation.Move(Self.Page, Destination.Page);
  Editor.UpdateMiniPageViews;
end;

procedure TMiniPageView.SetPage(AValue: TPresentationPage);
var
  Rel: Extended;
begin
  if FPage=AValue then Exit;
  FPage:=AValue;
  if FPage.Picture <> nil then begin
    if FBitmap = nil then FBitmap := TBitmap.Create;
    if FPage.Picture.Width > FPage.Picture.Height then Rel := Width / FPage.Picture.Width
    else Rel := Height / FPage.Picture.Height;
    FBitmap.Width := Round(FPage.Picture.Width * Rel);
    FBitmap.Height := Round(FPage.Picture.Height * Rel);
    FBitmap.Canvas.StretchDraw(Rect(0, 0, FBitmap.Width, FBitmap.Height), FPage.Picture.Graphic);
  end;
end;

procedure TMiniPageView.DragDrop(Source: TObject; X, Y: Integer);
begin
  inherited DragDrop(Source, X, Y);
  if Source <> Self then begin
    (Source as TMiniPageView).Move(Self);
    SetFocus
  end;
end;

procedure TMiniPageView.DragOver(Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
  inherited DragOver(Source, X, Y, State, Accept);
  Accept := True
end;

procedure TMiniPageView.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  View;
  if (Shift = []) and (Button = mbLeft) then BeginDrag(True)
end;

procedure TMiniPageView.SetFocus;
begin
  inherited SetFocus;
  View
end;

procedure TMiniPageView.View;
begin
  if Editor <> nil then begin
    Editor.FItemIndex := PageIndex;
    if Editor.Image <> nil then
      if Page <> nil then
        if Page.Picture <> nil then
          Editor.Image.Picture := Page.Picture;
    Editor.ScrollInView(Self)
  end;
end;

procedure TMiniPageView.Paint;
var
  X, Y: Integer;
begin
  inherited Paint;
  if Focused then Canvas.Brush.Color := clRed
  else Canvas.Brush.Color := clGray;
  Canvas.FillRect(ClientRect);
  if Page <> nil then
    if Page.Picture <> nil then begin
      X := (Width - Bitmap.Width) div 2;
      Y := (Height - Bitmap.Height) div 2;
      Canvas.Draw(X, Y, Bitmap);
    end;
end;

procedure TMiniPageView.SetParent(NewParent: TWinControl);
begin
  inherited SetParent(NewParent);
  if Parent is TPresentationEditor then TWinControl(FEditor) := Parent;
end;

constructor TMiniPageView.Create(AnOwner: TComponent);
begin
  inherited Create(AnOwner);
  DragMode := dmAutomatic;
end;

destructor TMiniPageView.Destroy;
begin
  FBitmap.Free;
  inherited Destroy;
end;

{ TPresentationPage }

function TPresentationPage.GetPicture: TPicture;
begin
  if not Assigned(FPicture) then FPicture := TPicture.Create;
  Result := FPicture;
end;

destructor TPresentationPage.Destroy;
begin
  FPicture.Free;
  inherited Destroy;
end;

{ TPresentation }

function TPresentation.GetPages(I: Integer): TPresentationPage;
begin
  TDataRecord(Result) := Items[I]
end;

procedure TPresentation.Loaded;
begin
  inherited Loaded;
  if Editor <> nil then Editor.UpdateMiniPageViews;
end;

constructor TPresentation.Create(AnOwner: TComponent);
begin
  inherited Create(AnOwner);
  Delay := 18000;
  Title := 'Beispiel für Presenta Viewer'
end;

procedure TPresentation.AddPage(FileName: string);
var
  Page: TPresentationPage;
begin
  TDataRecord(Page) := NewItem(TPresentationPage);
  Page.Picture.LoadFromFile(FileName);
end;

procedure TPresentation.Clear;
var
  i: Integer;
begin
  for i := ItemCount - 1 downto 0 do Pages[i].Free;
  ItemList.Clear;
end;

procedure TPresentation.Delete(AnIndex: Integer);
var
  ToDelete: TPresentationPage;
begin
  ToDelete := Pages[AnIndex];
  ToDelete.Free
end;

function TPresentation.IsEmpty: Boolean;
begin
  Result := ItemCount = 0
end;

procedure TPresentation.LoadFromFile(FileName: string);
begin
  ReadBinaryFromFile(FileName, TComponent(Self));
  if Editor <> nil then Editor.UpdateMiniPageViews;
end;

procedure TPresentation.SaveToFile(FileName: string);
begin
  WriteBinaryToFile(FileName, Self)
end;

{ TPresentationEditor }

procedure TPresentationEditor.UpdateMiniPageViews;
var
  i, j: Integer;
  MPV: TMiniPageView;
begin
  if MiniPageViewCount <= Presentation.ItemCount then begin
    for i := 0 to MiniPageViewCount  - 1 do begin
      MiniPageViews[i].Page := Presentation.Pages[i];
      if i = ItemIndex then MiniPageViews[i].SetFocus;
    end;
    for j := MiniPageViewCount to Presentation.ItemCount - 1 do begin
      MPV := TMiniPageView.Create(Self);
      MPV.Parent := Self;
      MPV.PageIndex := j;
      MPV.Top := 0;
      MPV.Height := ClientHeight;
      MPV.Width := ClientHeight;
      MPV.Left := (MPV.Width + 8) * j;
      MiniPageViewList.Add(MPV);
      MPV.Page := Presentation.Pages[j];
      if j = ItemIndex then MiniPageViews[j].SetFocus;
    end;
  end
  else begin
    for i := 0 to Presentation.ItemCount - 1 do begin
      MiniPageViews[i].Page := Presentation.Pages[i];
      if ItemIndex = -1 then ItemIndex := i;
    end;
    for j := Presentation.ItemCount to MiniPageViewCount - 1 do begin
      if j = ItemIndex then ItemIndex := j - 1;
      MPV := MiniPageViews[j];
      MiniPageViewList.Delete(j);
      MPV.Free
    end;
  end;
  ResizeMiniPageViews;
  for i := 0 to MiniPageViewCount - 1 do MiniPageViews[i].Paint
end;

function TPresentationEditor.GetMiniPageViewCount: Integer;
begin
  if Assigned(FMiniPageViewList) then Result := FMiniPageViewList.Count
  else Result := 0
end;

function TPresentationEditor.GetMiniPageViewList: TList;
begin
  if not Assigned(FMiniPageViewList) then FMiniPageViewList := TList.Create;
  Result := FMiniPageViewList
end;

function TPresentationEditor.GetMiniPageViews(i: Integer): TMiniPageView;
begin
  Pointer(Result) := MiniPageViewList[i]
end;

function TPresentationEditor.GetMiniPageView(i: Integer): TMiniPageView;
begin
  Pointer(Result) := MiniPageViewList[i]
end;

{function TPresentationEditor.GetMiniPageViewCount: Integer;
begin
  if Assigned(FMiniPageViewList) then Result := FMiniPageViewList.Count
  else Result := 0
end;}

{function TPresentationEditor.GetMiniPageViewList: TList;
begin
  if not Assigned(FMiniPageViewList) then FMiniPageViewList := TList.Create
  Result := FMiniPageViewList
end;}

{function TPresentationEditor.GetMiniPageViews(i: Integer): TMiniPageView;
begin
  Pointer(Result) := MiniPageViewList[i]
end;}

function TPresentationEditor.GetPresentation: TPresentation;
begin
  if not Assigned(FPresentation) then begin
    FPresentation := TPresentation.Create(Self);
    FPresentation.Editor := Self;
  end;
  Result := FPresentation
end;

procedure TPresentationEditor.ResizeMiniPageViews;
begin

end;

procedure TPresentationEditor.SetItemIndex(Value: Integer);
begin
  if FItemIndex = Value then Exit;
  if Value < MiniPageViewCount then begin
    FItemIndex := Value;
    if Value > -1 then MiniPageViews[Value].SetFocus;
    if Image <> nil then Image.Picture := MiniPageViews[Value].Page.Picture;
  end;
end;

{procedure TPresentationEditor.UpdateMiniPageViews;
begin

end;}

{procedure TPresentationEditor.ResizeMiniPageViews;
var
  i: Integer;
begin
  for i := 0 to MiniPageViewCount - 1 do begin
    MiniPageViews[i].Height := ClientHeight;
    MiniPageViews[i].Width := MiniPageViews[i].Height;
    MiniPageViews[i].Top := 0;
    MiniPageViews[i].Left := (MiniPageViews[i].Width + 8) * i
  end;
end;}

constructor TPresentationEditor.Create(AnOwner: TComponent);
begin
  inherited Create(AnOwner);
  if not (csDesigning in ComponentState) then Color := clBlack;
end;

destructor TPresentationEditor.Destroy;
begin
  FMiniPageViewList.Free;
  inherited Destroy;
end;

procedure TPresentationEditor.AddPage(FileName: string);
begin
  Presentation.AddPage(FileName);
  {if not (csUpdating in ComponentState) then} UpdateMiniPageViews;
end;

procedure TPresentationEditor.Delete(AnIndex: Integer);
begin
  Presentation.Delete(AnIndex);
  UpdateMiniPageViews;
end;

end.
