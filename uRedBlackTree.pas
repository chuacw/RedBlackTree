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

    procedure InOrder(Node: TRedBlackNode<K, V>);

    procedure RotateLeft(Node: TRedBlackNode<K, V>);
    procedure RotateRight(Node: TRedBlackNode<K, V>);
    procedure FixInsert(Node: TRedBlackNode<K, V>);
    procedure FreeNodes(Node: TRedBlackNode<K, V>);

    procedure DoDumpProc(Node: TRedBlackNode<K, V>);
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

procedure TRedBlackTree<K, V>.FreeNodes(Node: TRedBlackNode<K, V>);
begin
  if Node = nil then
    Exit;
  FreeNodes(Node.Left);
  FreeNodes(Node.Right);
  Node.Free;
end;

procedure TRedBlackTree<K, V>.RotateLeft(Node: TRedBlackNode<K, V>);
var
  Temp: TRedBlackNode<K, V>;
begin
  Temp := Node.Right;
  Node.Right := Temp.Left;
  if Temp.Left <> nil then
    Temp.Left.FParent := Node;
  Temp.FParent := Node.Parent;
  if Node.Parent = nil then
    FRoot := Temp
  else if Node = Node.Parent.Left then
    Node.Parent.Left := Temp
  else
    Node.Parent.Right := Temp;
  Temp.Left := Node;
  Node.FParent := Temp;
end;

procedure TRedBlackTree<K, V>.RotateRight(Node: TRedBlackNode<K, V>);
var
  Temp: TRedBlackNode<K, V>;
begin
  Temp := Node.Left;
  Node.Left := Temp.Right;
  if Temp.Right <> nil then
    Temp.Right.FParent := Node;
  Temp.FParent := Node.Parent;
  if Node.Parent = nil then
    FRoot := Temp
  else if Node = Node.Parent.Right then
    Node.Parent.Right := Temp
  else
    Node.Parent.Left := Temp;
  Temp.Right := Node;
  Node.FParent := Temp;
end;

procedure TRedBlackTree<K, V>.FixInsert(Node: TRedBlackNode<K, V>);
var
  Uncle: TRedBlackNode<K, V>;
begin
  while (Node.Parent <> nil) and (Node.Parent.Colour = crRed) do
  begin
    if Node.Parent = Node.Parent.Parent.Left then
    begin
      Uncle := Node.Parent.Parent.Right;
      if (Uncle <> nil) and (Uncle.Colour = crRed) then
      begin
        Node.Parent.Colour := crBlack;
        Uncle.Colour := crBlack;
        Node.Parent.Parent.Colour := crRed;
        Node := Node.Parent.Parent;
      end
      else
      begin
        if Node = Node.Parent.Right then
        begin
          Node := Node.Parent;
          RotateLeft(Node);
        end;
        Node.Parent.Colour := crBlack;
        Node.Parent.Parent.Colour := crRed;
        RotateRight(Node.Parent.Parent);
      end;
    end
    else
    begin
      Uncle := Node.Parent.Parent.Left;
      if (Uncle <> nil) and (Uncle.Colour = crRed) then
      begin
        Node.Parent.Colour := crBlack;
        Uncle.Colour := crBlack;
        Node.Parent.Parent.Colour := crRed;
        Node := Node.Parent.Parent;
      end
      else
      begin
        if Node = Node.Parent.Left then
        begin
          Node := Node.Parent;
          RotateRight(Node);
        end;
        Node.Parent.Colour := crBlack;
        Node.Parent.Parent.Colour := crRed;
        RotateLeft(Node.Parent.Parent);
      end;
    end;
  end;
  FRoot.Colour := crBlack;
end;

procedure TRedBlackTree<K, V>.Add(AKey: K; AValue: V);
var
  Node, Parent, NewNode: TRedBlackNode<K, V>;
begin
  Node := FRoot;
  Parent := nil;
  while Node <> nil do
  begin
    Parent := Node;
    if Comparer.Compare(AKey, Node.Key) < 0 then
      Node := Node.Left
    else
      Node := Node.Right;
  end;
  NewNode := TRedBlackNode<K, V>.Create(AKey, AValue, crRed);
  NewNode.FParent := Parent;
  if Parent = nil then
    FRoot := NewNode
  else if Comparer.Compare(AKey, Parent.Key) < 0 then
    Parent.Left := NewNode
  else
    Parent.Right := NewNode;
  FixInsert(NewNode);
end;

procedure TRedBlackTree<K, V>.InOrder(Node: TRedBlackNode<K, V>);
begin
  if Node = nil then
    Exit;
  InOrder(Node.Left);
  DoDumpProc(Node);
  InOrder(Node.Right);
end;

procedure TRedBlackTree<K, V>.DoDumpProc(Node: TRedBlackNode<K, V>);
begin
  if Assigned(FDumpProc) then
    FDumpProc(Node);
end;

procedure TRedBlackTree<K, V>.Dump;
begin
  InOrder(FRoot);
end;

end.
