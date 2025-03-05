program RedBlackDictionary;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.StrUtils,
  uRedBlackTree in 'uRedBlackTree.pas';

procedure Main;
var
  LRedBlack: TRedBlackTree<Integer, Integer>;
begin
  LRedBlack := TRedBlackTree<Integer, Integer>.Create;
  try

    LRedBlack.DumpProc := procedure(const ANode: TRedBlackNode<Integer, Integer>)
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

    LRedBlack.Add(21, 0);
    LRedBlack.Add(32, 0);
    LRedBlack.Add(76, 0);
    LRedBlack.Add(60, 0);
    LRedBlack.Add(100, 0);
    LRedBlack.Add(145, 0);
    LRedBlack.Add(110, 0);
    LRedBlack.Add(150, 0);
    LRedBlack.Add(180, 0);
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
