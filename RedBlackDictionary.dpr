program RedBlackDictionary;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.StrUtils,
  uRedBlackTree in 'uRedBlackTree.pas';

procedure Main;
var
  LRedBlack: TRedBlackTree<Integer, IInterface>;
begin
  LRedBlack := TRedBlackTree<Integer, IInterface>.Create;
  try

    LRedBlack.DumpProc := procedure(const ANode: TRedBlackNode<Integer, IInterface>)
      begin
        var Indent := 2;
        var LParent: string := '';
        if ANode.Parent = nil then
          LParent := 'root' else
          LParent := Format('(Key: %d, Parent: %p)', [ANode.Parent.Key, Pointer(ANode.Parent)]);
        var LSelf := Format('%p', [Pointer(ANode)]);
        WriteLn(StringOfChar(' ', Indent), ANode.Key, ' (', IfThen(ANode.Colour = crRed, 'Red', 'Black'), '), (Self: ', LSelf, '), ', LParent);
      end
    ;

    var LValue: IInterface := TInterfacedObject.Create as IInterface;

    LRedBlack.Add(21, LValue);
    LRedBlack.Add(32, LValue);
    LRedBlack.Add(76, LValue);
    LRedBlack.Add(60, LValue);
    LRedBlack.Add(100, LValue);
    LRedBlack.Add(145, LValue);
    LRedBlack.Add(110, LValue);
    LRedBlack.Add(150, LValue);
    LRedBlack.Add(180, LValue);

    LRedBlack.Add(21, LValue);

    LRedBlack.Remove(180);

    LRedBlack.Dump(procedure(const ANode: TRedBlackNode<Integer, IInterface>)
      begin
        var Indent := 2;
        var LParent: string := '';
        if ANode.Parent = nil then
          LParent := 'root' else
          LParent := Format('(Key: %d, Parent: %p)', [ANode.Parent.Key, Pointer(ANode.Parent)]);
        var LSelf := Format('%p', [Pointer(ANode)]);
        WriteLn('Dump parameter');
        WriteLn(StringOfChar(' ', Indent), ANode.Key, ' (', IfThen(ANode.Colour = crRed, 'Red', 'Black'), '), (Self: ', LSelf, '), ', LParent);
      end
    );
    LRedBlack.Dump;
  finally
    LRedBlack.Free;
  end;
end;

begin
  try
    Main;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
