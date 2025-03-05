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

    procedure InOrder(const Node: TRedBlackNode<K, V>);

    procedure RotateLeft(Node: TRedBlackNode<K, V>);
    procedure RotateRight(Node: TRedBlackNode<K, V>);
    procedure FixInsert(Node: TRedBlackNode<K, V>);
    procedure FreeNodes(Node: TRedBlackNode<K, V>);

    procedure DoDumpProc(const Node: TRedBlackNode<K, V>);
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
  LTemp: TRedBlackNode<K, V>;
begin
  LTemp := Node.Right;
  Node.Right := LTemp.Left;
  if LTemp.Left <> nil then
    LTemp.Left.FParent := Node;
  LTemp.FParent := Node.Parent;
  if Node.Parent = nil then
    FRoot := LTemp else
  if Node = Node.Parent.Left then
    Node.Parent.Left := LTemp else
    Node.Parent.Right := LTemp;
  LTemp.Left := Node;
  Node.FParent := LTemp;
end;

procedure TRedBlackTree<K, V>.RotateRight(Node: TRedBlackNode<K, V>);
var
  LTemp: TRedBlackNode<K, V>;
begin
  LTemp := Node.Left;
  Node.Left := LTemp.Right;
  if LTemp.Right <> nil then
    LTemp.Right.FParent := Node;
  LTemp.FParent := Node.Parent;
  if Node.Parent = nil then
    FRoot := LTemp else
  if Node = Node.Parent.Right then
    Node.Parent.Right := LTemp else
    Node.Parent.Left := LTemp;
  LTemp.Right := Node;
  Node.FParent := LTemp;
end;

procedure TRedBlackTree<K, V>.FixInsert(Node: TRedBlackNode<K, V>);
var
  LUncle: TRedBlackNode<K, V>;
begin
  while (Node.Parent <> nil) and (Node.Parent.Colour = crRed) do
    begin
      if Node.Parent = Node.Parent.Parent.Left then
        begin
          LUncle := Node.Parent.Parent.Right;
          if (LUncle <> nil) and (LUncle.Colour = crRed) then
            begin
              Node.Parent.Colour := crBlack;
              LUncle.Colour := crBlack;
              Node.Parent.Parent.Colour := crRed;
              Node := Node.Parent.Parent;
            end else
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
        end else
        begin
          LUncle := Node.Parent.Parent.Left;
          if (LUncle <> nil) and (LUncle.Colour = crRed) then
            begin
              Node.Parent.Colour := crBlack;
              LUncle.Colour := crBlack;
              Node.Parent.Parent.Colour := crRed;
              Node := Node.Parent.Parent;
            end else
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

procedure TRedBlackTree<K, V>.InOrder(const Node: TRedBlackNode<K, V>);
begin
  if Node = nil then
    Exit;
  InOrder(Node.Left);
  DoDumpProc(Node);
  InOrder(Node.Right);
end;

procedure TRedBlackTree<K, V>.DoDumpProc(const Node: TRedBlackNode<K, V>);
begin
  if Assigned(FDumpProc) then
    FDumpProc(Node);
end;

procedure TRedBlackTree<K, V>.Dump;
begin
  InOrder(FRoot);
end;

end.
