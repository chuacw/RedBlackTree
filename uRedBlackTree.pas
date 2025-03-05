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
    FLeft, FRight, FParent: TRedBlackNode<K, V>;
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
    FComparer: IComparer<K>;

    procedure InOrder(const ANode: TRedBlackNode<K, V>);

    procedure RotateLeft(ANode: TRedBlackNode<K, V>);
    procedure RotateRight(ANode: TRedBlackNode<K, V>);
    procedure FixInsert(ANode: TRedBlackNode<K, V>);
    procedure FreeNodes(var VNode: TRedBlackNode<K, V>);

    procedure DoDumpProc(const ANode: TRedBlackNode<K, V>);
    procedure RemoveNode(Node: TRedBlackNode<K, V>);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AKey: K; const AValue: V);
    function FindNode(const AKey: K): TRedBlackNode<K, V>;
    procedure Remove(const AKey: K);
    
    procedure Dump(const ADumpProc: TDumpProc<K, V> = nil);
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
  FComparer := TComparer<K>.Default;
end;

destructor TRedBlackTree<K, V>.Destroy;
begin
  FreeNodes(FRoot);
  inherited;
end;

procedure TRedBlackTree<K, V>.FreeNodes(var VNode: TRedBlackNode<K, V>);
begin
  if VNode = nil then
    Exit;
  FreeNodes(VNode.FLeft);
  FreeNodes(VNode.FRight);
  FreeAndNil(VNode);
end;

procedure TRedBlackTree<K, V>.RotateLeft(ANode: TRedBlackNode<K, V>);
var
  LTemp: TRedBlackNode<K, V>;
begin
  LTemp := ANode.FRight;
  ANode.FRight := LTemp.FLeft;
  if LTemp.FLeft <> nil then
    LTemp.FLeft.FParent := ANode;
  LTemp.FParent := ANode.Parent;
  if ANode.Parent = nil then
    FRoot := LTemp else
  if ANode = ANode.Parent.FLeft then
    ANode.Parent.FLeft := LTemp else
    ANode.Parent.FRight := LTemp;
  LTemp.FLeft := ANode;
  ANode.FParent := LTemp;
end;

procedure TRedBlackTree<K, V>.RotateRight(ANode: TRedBlackNode<K, V>);
var
  LTemp: TRedBlackNode<K, V>;
begin
  LTemp := ANode.FLeft;
  ANode.FLeft := LTemp.FRight;
  if LTemp.FRight <> nil then
    LTemp.FRight.FParent := ANode;
  LTemp.FParent := ANode.Parent;
  if ANode.Parent = nil then
    FRoot := LTemp else
  if ANode = ANode.Parent.FRight then
    ANode.Parent.FRight := LTemp else
    ANode.Parent.FLeft := LTemp;
  LTemp.FRight := ANode;
  ANode.FParent := LTemp;
end;

procedure TRedBlackTree<K, V>.FixInsert(ANode: TRedBlackNode<K, V>);
var
  LUncle: TRedBlackNode<K, V>;
begin
  while (ANode.Parent <> nil) and (ANode.Parent.Colour = crRed) do
    begin
      if ANode.Parent = ANode.Parent.Parent.FLeft then
        begin
          LUncle := ANode.Parent.Parent.FRight;
          if (LUncle <> nil) and (LUncle.Colour = crRed) then
            begin
              ANode.Parent.Colour := crBlack;
              LUncle.Colour := crBlack;
              ANode.Parent.Parent.Colour := crRed;
              ANode := ANode.Parent.Parent;
            end else
            begin
              if ANode = ANode.Parent.FRight then
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
          LUncle := ANode.Parent.Parent.FLeft;
          if (LUncle <> nil) and (LUncle.Colour = crRed) then
            begin
              ANode.Parent.Colour := crBlack;
              LUncle.Colour := crBlack;
              ANode.Parent.Parent.Colour := crRed;
              ANode := ANode.Parent.Parent;
            end else
            begin
              if ANode = ANode.Parent.FLeft then
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

procedure TRedBlackTree<K, V>.Add(const AKey: K; const AValue: V);
var
  LNode, LParent, LNewNode: TRedBlackNode<K, V>;
  LComparer: IComparer<K>;
  LCmpResult: NativeInt;
begin
    
  LNode := FRoot;
  LParent := nil;
  LComparer := FComparer;
  while LNode <> nil do
  begin
    LParent := LNode;
    LCmpResult := LComparer.Compare(AKey, LNode.Key);
    case LCmpResult of
      -1: begin
        LNode := LNode.FLeft;
      end;
      0: begin
        LNode.FValue := AValue;
        Exit; // No need to rebalance
      end;
      1: begin
        LNode := LNode.FRight;
      end;
    end;
//    if LComparer.Compare(AKey, LNode.Key) < 0 then
//      LNode := LNode.FLeft else
//      LNode := LNode.FRight;
  end;
  LNewNode := TRedBlackNode<K, V>.Create(AKey, AValue, crRed);
  LNewNode.FParent := LParent;
  if LParent = nil then
    FRoot := LNewNode else
  if LComparer.Compare(AKey, LParent.Key) < 0 then
    LParent.FLeft := LNewNode else
    LParent.FRight := LNewNode;

  FixInsert(LNewNode);
end;

procedure TRedBlackTree<K, V>.InOrder(const ANode: TRedBlackNode<K, V>);
begin
  if ANode = nil then
    Exit;
  InOrder(ANode.FLeft);
  DoDumpProc(ANode);
  InOrder(ANode.FRight);
end;

procedure TRedBlackTree<K, V>.DoDumpProc(const ANode: TRedBlackNode<K, V>);
begin
  if Assigned(FDumpProc) then
    FDumpProc(ANode);
end;

procedure TRedBlackTree<K, V>.Dump(const ADumpProc: TDumpProc<K, V> = nil);
var
  LSavedDumpProc: TDumpProc<K, V>;
begin
  LSavedDumpProc := nil;
  if Assigned(ADumpProc) then
    begin
      LSavedDumpProc := FDumpProc;
      FDumpProc := ADumpProc;
    end;
  InOrder(FRoot);
  if Assigned(LSavedDumpProc) then
    begin
      FDumpProc := LSavedDumpProc;
    end;
end;

procedure TRedBlackTree<K, V>.RemoveNode(Node: TRedBlackNode<K, V>);
var
  Temp, Child: TRedBlackNode<K, V>;
begin
  if (Node.FLeft = nil) or (Node.FRight = nil) then
    Temp := Node else
  begin
    Temp := Node.FRight;
    while Temp.FLeft <> nil do
      Temp := Temp.FLeft;
  end;
  if Temp.FLeft <> nil then
    Child := Temp.FLeft else
    Child := Temp.FRight;
  if Child <> nil then
    Child.FParent := Temp.Parent;
  if Temp.Parent = nil then
    FRoot := Child else 
  if Temp = Temp.Parent.FLeft then
    Temp.Parent.FLeft := Child else
    Temp.Parent.FRight := Child;
  if Temp <> Node then
  begin
    Node.FKey := Temp.Key;
    Node.FValue := Temp.Value;
  end;
  Temp.Free;
end;

function TRedBlackTree<K, V>.FindNode(const AKey: K): TRedBlackNode<K, V>;
var
  LComparer: IComparer<K>;
begin
  Result := FRoot;
  LComparer := FComparer;
  while (Result <> nil) and (LComparer.Compare(AKey, Result.Key) <> 0) do
  begin
    if LComparer.Compare(AKey, Result.Key) < 0 then
      Result := Result.FLeft else
      Result := Result.FRight;
  end;
end;

procedure TRedBlackTree<K, V>.Remove(const AKey: K);
var
  Node: TRedBlackNode<K, V>;
begin
  Node := FindNode(AKey);
  if Node <> nil then
    RemoveNode(Node);
end;

end.
