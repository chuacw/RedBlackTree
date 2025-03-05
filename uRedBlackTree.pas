unit uRedBlackTree;

interface

uses
  System.Generics.Defaults;

type
  TNodeColour = (crRed, crBlack);

  TRedBlackNode<K, V> = class
  protected
    FKey: K;
    FValue: V;
    FColour: TNodeColour;
    Left, Right, FParent: TRedBlackNode<K, V>;
  public
    constructor Create(const AKey: K; const AValue: V; AColor: TNodeColour);
    destructor Destroy; override;
    property Colour: TNodeColour read FColour write FColour;
    property Key: K read FKey;
    property Value: V read FValue;
    property Parent: TRedBlackNode<K, V> read FParent;
  end;

  TDumpProc<K, V> = reference to procedure(const ANode: TRedBlackNode<K, V>);

  TRedBlackTree<K, V> = class
  protected
    FDumpProc: TDumpProc<K, V>;
    FRoot: TRedBlackNode<K, V>;
    Comparer: IComparer<K>;

    procedure InOrder(const ANode: TRedBlackNode<K, V>);

    procedure RotateLeft(ANode: TRedBlackNode<K, V>);
    procedure RotateRight(ANode: TRedBlackNode<K, V>);
    procedure FixInsert(ANode: TRedBlackNode<K, V>);
    procedure FreeNodes(ANode: TRedBlackNode<K, V>);

    procedure DoDumpProc(const ANode: TRedBlackNode<K, V>);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(AKey: K; AValue: V);
    procedure Dump;
    property DumpProc: TDumpProc<K, V> write FDumpProc;
  end;

implementation

uses
  System.SysUtils;

constructor TRedBlackNode<K, V>.Create(const AKey: K; const AValue: V; AColor: TNodeColour);
begin
  FKey := AKey;
  FValue := AValue;
  Colour := AColor;
end;

destructor TRedBlackNode<K, V>.Destroy;
type
  PObject = ^TObject;
var
  LKey, LValue: PObject;
begin
  case GetTypeKind(Key) of
    tkClass:
      begin
        LKey := @Key;
        FreeAndNil(LKey^);
      end;
  else
    FKey := Default(K);
  end;
  case GetTypeKind(Value) of
    tkClass:
      begin
        LValue := @Value;
        FreeAndNil(LValue^);
      end;
  else
    FValue := Default(V);
  end;
  inherited;
end;

constructor TRedBlackTree<K, V>.Create;
begin
  FRoot := nil;
  Comparer := TComparer<K>.Default;
end;

destructor TRedBlackTree<K, V>.Destroy;
begin
  FreeNodes(FRoot);
  inherited;
end;

procedure TRedBlackTree<K, V>.FreeNodes(ANode: TRedBlackNode<K, V>);
begin
  if ANode = nil then
    Exit;
  FreeNodes(ANode.Left);
  FreeNodes(ANode.Right);
  ANode.Free;
end;

procedure TRedBlackTree<K, V>.RotateLeft(ANode: TRedBlackNode<K, V>);
var
  LTemp: TRedBlackNode<K, V>;
begin
  LTemp := ANode.Right;
  ANode.Right := LTemp.Left;
  if LTemp.Left <> nil then
    LTemp.Left.FParent := ANode;
  LTemp.FParent := ANode.Parent;
  if ANode.Parent = nil then
    FRoot := LTemp else
  if ANode = ANode.Parent.Left then
    ANode.Parent.Left := LTemp else
    ANode.Parent.Right := LTemp;
  LTemp.Left := ANode;
  ANode.FParent := LTemp;
end;

procedure TRedBlackTree<K, V>.RotateRight(ANode: TRedBlackNode<K, V>);
var
  LTemp: TRedBlackNode<K, V>;
begin
  LTemp := ANode.Left;
  ANode.Left := LTemp.Right;
  if LTemp.Right <> nil then
    LTemp.Right.FParent := ANode;
  LTemp.FParent := ANode.Parent;
  if ANode.Parent = nil then
    FRoot := LTemp else
  if ANode = ANode.Parent.Right then
    ANode.Parent.Right := LTemp else
    ANode.Parent.Left := LTemp;
  LTemp.Right := ANode;
  ANode.FParent := LTemp;
end;

procedure TRedBlackTree<K, V>.FixInsert(ANode: TRedBlackNode<K, V>);
var
  LUncle: TRedBlackNode<K, V>;
begin
  while (ANode.Parent <> nil) and (ANode.Parent.Colour = crRed) do
    begin
      if ANode.Parent = ANode.Parent.Parent.Left then
        begin
          LUncle := ANode.Parent.Parent.Right;
          if (LUncle <> nil) and (LUncle.Colour = crRed) then
            begin
              ANode.Parent.Colour := crBlack;
              LUncle.Colour := crBlack;
              ANode.Parent.Parent.Colour := crRed;
              ANode := ANode.Parent.Parent;
            end else
            begin
              if ANode = ANode.Parent.Right then
                begin
                  ANode := ANode.Parent;
                  RotateLeft(ANode);
                end;
              ANode.Parent.Colour := crBlack;
              ANode.Parent.Parent.Colour := crRed;
              RotateRight(ANode.Parent.Parent);
            end;
        end else
        begin
          LUncle := ANode.Parent.Parent.Left;
          if (LUncle <> nil) and (LUncle.Colour = crRed) then
            begin
              ANode.Parent.Colour := crBlack;
              LUncle.Colour := crBlack;
              ANode.Parent.Parent.Colour := crRed;
              ANode := ANode.Parent.Parent;
            end else
            begin
              if ANode = ANode.Parent.Left then
                begin
                  ANode := ANode.Parent;
                  RotateRight(ANode);
                end;
              ANode.Parent.Colour := crBlack;
              ANode.Parent.Parent.Colour := crRed;
              RotateLeft(ANode.Parent.Parent);
            end;
        end;
    end;
  FRoot.Colour := crBlack;
end;

procedure TRedBlackTree<K, V>.Add(AKey: K; AValue: V);
var
  LNode, LParent, LNewNode: TRedBlackNode<K, V>;
begin
  LNode := FRoot;
  LParent := nil;
  while LNode <> nil do
  begin
    LParent := LNode;
    if Comparer.Compare(AKey, LNode.Key) < 0 then
      LNode := LNode.Left else
      LNode := LNode.Right;
  end;
  LNewNode := TRedBlackNode<K, V>.Create(AKey, AValue, crRed);
  LNewNode.FParent := LParent;
  if LParent = nil then
    FRoot := LNewNode else
  if Comparer.Compare(AKey, LParent.Key) < 0 then
    LParent.Left := LNewNode else
    LParent.Right := LNewNode;
  FixInsert(LNewNode);
end;

procedure TRedBlackTree<K, V>.InOrder(const ANode: TRedBlackNode<K, V>);
begin
  if ANode = nil then
    Exit;
  InOrder(ANode.Left);
  DoDumpProc(ANode);
  InOrder(ANode.Right);
end;

procedure TRedBlackTree<K, V>.DoDumpProc(const ANode: TRedBlackNode<K, V>);
begin
  if Assigned(FDumpProc) then
    FDumpProc(ANode);
end;

procedure TRedBlackTree<K, V>.Dump;
begin
  InOrder(FRoot);
end;

end.
