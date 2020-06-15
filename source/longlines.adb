with Ada.Characters.Conversions;
with Ada.Command_Line.Parsing;
with Ada.Directories.Information;
with Ada.Hierarchical_File_Names;
with Ada.Integer_Text_IO;
with Ada.IO_Modes;
with Ada.Locales;
with Ada.Strings.East_Asian_Width;
with Ada.Strings.Unbounded_Strings;
with Ada.Strings.Unbounded_Wide_Wide_Strings;
with Ada.Strings.Wide_Wide_Functions;
with Ada.Text_IO.Terminal.Colors.Names;
with Ada.Wide_Wide_Characters.Latin_1;
procedure longlines is
	use type Ada.Directories.File_Kind;
	use type Ada.Locales.Country_Code;
	use type Ada.Text_IO.Terminal.Colors.Color;
	package East_Asian_Width renames Ada.Strings.East_Asian_Width;
	procedure Get_Line_Width (
		Line : in Wide_Wide_String;
		Over_Index : out Natural;
		Line_Width : out Natural;
		Tab : in Natural;
		East_Asian : in Boolean;
		Width : in Positive) is
	begin
		Over_Index := 0;
		Line_Width := 0;
		for I in Line'Range loop
			declare
				Item : Wide_Wide_Character renames Line (I);
			begin
				if Item = Ada.Wide_Wide_Characters.Latin_1.HT then
					if Tab > 0 then
						Line_Width := Line_Width + (Tab - Line_Width rem Tab);
					end if;
				elsif East_Asian_Width.Is_Full_Width (
					East_Asian_Width.Kind (Item),
					East_Asian)
				then
					Line_Width := Line_Width + 2;
				else
					Line_Width := Line_Width + 1;
				end if;
				if Line_Width > Width and then Over_Index = 0 then
					Over_Index := I;
				end if;
			end;
		end loop;
	end Get_Line_Width;
	package Terminal renames Ada.Text_IO.Terminal;
	procedure Process_Line (
		Name : in String;
		Line : in Wide_Wide_String;
		Line_Number : in Positive;
		Tab : in Natural;
		East_Asian : in Boolean;
		Width : in Positive;
		Colored : in Boolean)
	is
		Over_Index : Natural;
		Line_Width : Natural;
	begin
		Get_Line_Width (Line, Over_Index, Line_Width,
			Tab => Tab, East_Asian => East_Asian, Width => Width);
		if Line_Width > Width then
			Ada.Text_IO.Put (Name);
			Ada.Text_IO.Put (':');
			Ada.Integer_Text_IO.Put (Line_Number, Width => 1);
			Ada.Text_IO.Put (':');
			Ada.Integer_Text_IO.Put (Line_Width, Width => 1);
			Ada.Text_IO.Put (':');
			Ada.Text_IO.Overloaded_Put (Line (Line'First .. Over_Index - 1));
			if Colored then
				Terminal.Colors.Set_Color (Ada.Text_IO.Current_Output.all,
					Foreground => +Terminal.Colors.Names.Red);
			end if;
			Ada.Text_IO.Overloaded_Put (Line (Over_Index .. Line'Last));
			if Colored then
				Terminal.Colors.Reset_Color (Ada.Text_IO.Current_Output.all);
			end if;
			Ada.Text_IO.New_Line;
		end if;
	end Process_Line;
	procedure Report_Missing_Final_New_Line (
		Name : in String;
		Line_Number : in Positive;
		Message : in Wide_Wide_String;
		Colored : in Boolean) is
	begin
		Ada.Text_IO.Put (Name);
		Ada.Text_IO.Put (':');
		Ada.Integer_Text_IO.Put (Line_Number, Width => 1);
		Ada.Text_IO.Put ('\');
		if Colored then
			Terminal.Colors.Set_Color (Ada.Text_IO.Current_Output.all,
				Foreground => +Terminal.Colors.Names.Red);
		end if;
		Ada.Text_IO.Overloaded_Put (Message);
		if Colored then
			Terminal.Colors.Reset_Color (Ada.Text_IO.Current_Output.all);
		end if;
		Ada.Text_IO.New_Line;
	end Report_Missing_Final_New_Line;
	package Unbounded_Wide_Wide_Strings
		renames Ada.Strings.Unbounded_Wide_Wide_Strings;
	procedure Process_File (
		File : in Ada.Text_IO.File_Type;
		Name : in String;
		Tab : in Natural;
		East_Asian : in Boolean;
		Width : in Positive;
		Final_New_Line : in Boolean;
		Colored : in Boolean)
	is
		Line : Unbounded_Wide_Wide_Strings.Unbounded_String;
		Line_Number : Positive := 1;
		Missing_Final_New_Line : Boolean := False;
	begin
		Unbounded_Wide_Wide_Strings.Reserve_Capacity (Line, Width + 1);
		while not Ada.Text_IO.End_Of_File (File) loop
			Unbounded_Wide_Wide_Strings.Set_Length (Line, 0);
			loop
				declare
					Item : Wide_Wide_Character;
					End_Of_Line : Boolean;
				begin
					Ada.Text_IO.Overloaded_Look_Ahead (File, Item, End_Of_Line);
					if End_Of_Line and Ada.Text_IO.End_Of_File (File) then
						Missing_Final_New_Line := True;
					end if;
					Ada.Text_IO.Skip_Ahead (File);
					exit when End_Of_Line;
					Unbounded_Wide_Wide_Strings.Append (Line, (1 => Item));
				end;
			end loop;
			declare
				Line_Ref : Wide_Wide_String
					renames Unbounded_Wide_Wide_Strings.Constant_Reference (Line);
			begin
				Process_Line (Name, Line_Ref, Line_Number,
					Tab => Tab, East_Asian => East_Asian, Width => Width,
					Colored => Colored);
			end;
			exit when Missing_Final_New_Line;
			Line_Number := Line_Number + 1;
		end loop;
		if Missing_Final_New_Line and Final_New_Line then
			Report_Missing_Final_New_Line (
				Name,
				Line_Number,
				" No newline at end of file",
				Colored => Colored);
		end if;
	end Process_File;
	package Hierarchical_File_Names renames Ada.Hierarchical_File_Names;
	package Unbounded_Strings renames Ada.Strings.Unbounded_Strings;
	package Wide_Wide_Functions renames Ada.Strings.Wide_Wide_Functions;
	procedure Process_Diff (
		File : in Ada.Text_IO.File_Type;
		Strip : in Natural;
		Tab : in Natural;
		East_Asian : in Boolean;
		Width : in Positive;
		Final_New_Line : in Boolean;
		Colored : in Boolean)
	is
		procedure Process_Diff_Name (
			Line : in Wide_Wide_String;
			Name : out Unbounded_Strings.Unbounded_String)
		is
			pragma Assert (
				Line'Length >= 4
				and then Line (Line'First) = '+'
				and then Line (Line'First + 1) = '+'
				and then Line (Line'First + 2) = '+'
				and then Line (Line'First + 3) = ' ');
			Line_First : constant Positive := Line'First + 4;
			Line_Last : Natural;
		begin
			declare
				Index : Natural;
			begin
				Index :=
					Wide_Wide_Functions.Index_Element_Forward (
						Line (Line_First .. Line'Last),
						Ada.Wide_Wide_Characters.Latin_1.HT);
				if Index = 0 then
					Line_Last := Line'Last;
				else
					Line_Last := Index - 1;
				end if;
			end;
			declare
				S : String
					renames Ada.Characters.Conversions.To_String (
						Line (Line_First .. Line_Last));
				S_First : Positive := S'First;
				S_Last : Natural := S'Last;
			begin
				for I in 1 .. Strip loop
					Hierarchical_File_Names.Relative_Name (S (S_First .. S_Last),
						First => S_First, Last => S_Last);
				end loop;
				if S_First > S_Last then
					Unbounded_Strings.Set_Unbounded_String (Name, "-");
				else
					Unbounded_Strings.Set_Unbounded_String (
						Name,
						S (S_First .. S_Last));
				end if;
			end;
		end Process_Diff_Name;
		procedure Process_Diff_Hunk (
			Line : in Wide_Wide_String;
			Line_Number : in out Positive)
		is
			pragma Assert (
				Line'Length >= 3
				and then Line (Line'First) = '@'
				and then Line (Line'First + 1) = '@'
				and then Line (Line'First + 2) = ' ');
			P : Positive := Line'First + 3;
		begin
			if Line (P) = '-' then
				declare
					Index : Natural;
				begin
					Index :=
						Wide_Wide_Functions.Index_Element_Forward (
							Line (P .. Line'Last),
							Ada.Wide_Wide_Characters.Latin_1.Space);
					if Index = 0 then
						P := Line'Last + 1;
					else
						P := Index + 1;
					end if;
				end;
				if P <= Line'Last and then Line (P) = '+' then
					P := P + 1;
					declare
						First : constant Positive := P;
					begin
						while P <= Line'Last and then Line (P) in '0' .. '9' loop
							P := P + 1;
						end loop;
						begin
							Line_Number :=
								Integer'Wide_Wide_Value (Line (First .. P - 1));
						exception
							when Constraint_Error =>
								Line_Number := 1;
						end;
					end;
				end if;
			end if;
		end Process_Diff_Hunk;
		procedure Get_Line (
			Line : in out Unbounded_Wide_Wide_Strings.Unbounded_String)
		is
			Item : Wide_Wide_Character;
			End_Of_Line : Boolean;
		begin
			while not Ada.Text_IO.End_Of_File (File) loop
				Ada.Text_IO.Overloaded_Look_Ahead (
					File,
					Item,
					End_Of_Line);
				Ada.Text_IO.Skip_Ahead (File);
				exit when End_Of_Line;
				Unbounded_Wide_Wide_Strings.Append (Line, (1 => Item));
			end loop;
		end Get_Line;
		Name : Unbounded_Strings.Unbounded_String;
		Line : Unbounded_Wide_Wide_Strings.Unbounded_String;
		Line_Number : Positive := 1;
		Added : Boolean := False;
	begin
		Unbounded_Wide_Wide_Strings.Reserve_Capacity (Line, Width + 1);
		while not Ada.Text_IO.End_Of_File (File) loop
			declare
				Item : Wide_Wide_Character;
				End_Of_Line : Boolean;
			begin
				Ada.Text_IO.Overloaded_Look_Ahead (File, Item, End_Of_Line);
				Ada.Text_IO.Skip_Ahead (File);
				if not End_Of_Line then
					case Item is
						when ' ' =>
							Line_Number := Line_Number + 1;
							Ada.Text_IO.Skip_Line (File);
							Added := False;
						when '+' =>
							Unbounded_Wide_Wide_Strings.Set_Length (Line, 0);
							Unbounded_Wide_Wide_Strings.Append (Line, (1 => Item));
							Get_Line (Line);
							declare
								Line_Ref : Wide_Wide_String
									renames Unbounded_Wide_Wide_Strings
											.Constant_Reference (
										Line);
							begin
								if Line_Ref'Length >= 4
									and then Line_Ref (Line_Ref'First + 1) = '+'
									and then Line_Ref (Line_Ref'First + 2) = '+'
									and then Line_Ref (Line_Ref'First + 3) = ' '
								then
									Process_Diff_Name (Line_Ref, Name);
									Line_Number := 1;
									Added := False;
								else
									declare
										Name_Ref : String
											renames Unbounded_Strings.Constant_Reference (
												Name);
									begin
										Process_Line (
											Name_Ref,
											Line_Ref (
												Line_Ref'First + 1 .. Line_Ref'Last),
											Line_Number,
											Tab => Tab, East_Asian => East_Asian,
											Width => Width, Colored => Colored);
									end;
									Line_Number := Line_Number + 1;
									Added := True;
								end if;
							end;
						when '@' =>
							Unbounded_Wide_Wide_Strings.Set_Length (Line, 0);
							Unbounded_Wide_Wide_Strings.Append (Line, (1 => Item));
							Get_Line (Line);
							declare
								Line_Ref : Wide_Wide_String
									renames Unbounded_Wide_Wide_Strings
											.Constant_Reference (
										Line);
							begin
								if Line_Ref'Length >= 3
									and then Line_Ref (Line_Ref'First) = '@'
									and then Line_Ref (Line_Ref'First + 1) = '@'
									and then Line_Ref (Line_Ref'First + 2) = ' '
								then
									Process_Diff_Hunk (Line_Ref, Line_Number);
								end if;
							end;
							Added := False;
						when '\' =>
							if Final_New_Line and Added then
								Unbounded_Wide_Wide_Strings.Set_Length (Line, 0);
								Get_Line (Line);
								declare
									Name_Ref : String
										renames Unbounded_Strings.Constant_Reference (
											Name);
									Line_Ref : Wide_Wide_String
										renames Unbounded_Wide_Wide_Strings
												.Constant_Reference (
											Line);
								begin
									Report_Missing_Final_New_Line (
										Name_Ref,
										Line_Number - 1,
										Line_Ref,
										Colored => Colored);
								end;
							else
								Ada.Text_IO.Skip_Line (File);
							end if;
							Added := False;
						when others =>
							Ada.Text_IO.Skip_Line (File);
							Added := False;
					end case;
				end if;
			end;
		end loop;
	end Process_Diff;
	procedure Help is
		procedure P (Item : in String) renames Ada.Text_IO.Put_Line;
	begin
		Ada.Text_IO.Put ("Usage: ");
		Ada.Text_IO.Put (Ada.Command_Line.Command_Name);
		Ada.Text_IO.Put (" [options] <files>");
		Ada.Text_IO.New_Line;
		P ("Check lines longer than the specified width.");
		Ada.Text_IO.New_Line;
		P ("Options: ");
		P ("  -d --diff             Unified diff mode");
		P ("  -e --east-asian       "
			& "Count ambiguous character as 2 (default: by LANG)");
		P ("  -E --no-east-asisn    Turn off -e");
		P ("  -f --final-newline    "
			& "Check newline exists at end of file (default: on)");
		P ("  -F --no-final-newline Turn off -F");
		P ("  -h --help             Display this information");
		P ("  -L --dereference      Follow symbolic links (default: off)");
		P ("  -P --no-dereference   Turn off -L");
		P ("  -pNUM --strip=NUM     "
			& "Strip num leading directories from each path in diff");
		P ("  -tNUM --tab=NUM       Expand horizonal tab as NUM (default: 8)");
		P ("  -wNUM --width=NUM     Check lines longer than NUM (default: 79)");
	end Help;
	function CJK return Boolean is
		Country : constant Ada.Locales.Country_Code := Ada.Locales.Country;
	begin
		return Country = "ZH" or else Country = "JP" or else Country = "KO";
	end CJK;
	package Parsing renames Ada.Command_Line.Parsing;
	function Get_Value (
		Position : Parsing.Cursor;
		Min, Max : Integer)
		return Integer
	is
		Value : constant String := Parsing.Value (Position);
		Result : Integer;
	begin
		Result := Integer'Value (Value);
		if Result not in Min .. Max then
			raise Constraint_Error;
		end if;
		return Result;
	exception
		when Constraint_Error =>
			Ada.Text_IO.Set_Output (Ada.Text_IO.Standard_Error.all);
			Ada.Text_IO.Put ("Bad value: ");
			Ada.Text_IO.Put (Value);
			Ada.Text_IO.New_Line;
			return Min - 1;
	end Get_Value;
	package IO_Modes renames Ada.IO_Modes;
	Diff : Boolean := False;
	Strip : Natural := 0;
	Dereference : Boolean := False;
	Tab : Natural := 8;
	East_Asian : Boolean := CJK;
	Width : Positive := 79;
	Final_New_Line : Boolean := True;
	Colored : constant Boolean :=
		Terminal.Is_Terminal (Ada.Text_IO.Current_Output.all);
	From_Standard_Input : Boolean := True;
begin
	for I in Parsing.Iterate loop
		if Parsing.Is_Option (I, 'd', "diff") then
			Diff := True;
		elsif Parsing.Is_Option (I, 'e', "east-asian") then
			East_Asian := True;
		elsif Parsing.Is_Option (I, 'E', "no-east-asian") then
			East_Asian := False;
		elsif Parsing.Is_Option (I, 'f', "final-newline") then
			Final_New_Line := True;
		elsif Parsing.Is_Option (I, 'F', "no-final-newline") then
			Final_New_Line := False;
		elsif Parsing.Is_Option (I, 'h', "help") then
			Help;
			return;
		elsif Parsing.Is_Option (I, 'L', "dereference") then
			Dereference := True;
		elsif Parsing.Is_Option (I, 'P', "no-dereference") then
			Dereference := False;
		elsif Parsing.Is_Option (I, 'p', "strip", ':') then
			declare
				X : constant Integer := Get_Value (I, 0, 255);
			begin
				if X < 0 then
					Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
					return;
				end if;
				Strip := X;
			end;
		elsif Parsing.Is_Option (I, 't', "tab", ':') then
			declare
				X : constant Integer := Get_Value (I, 0, 8);
			begin
				if X < 0 then
					Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
					return;
				end if;
				Tab := X;
			end;
		elsif Parsing.Is_Option (I, 'w', "width", ':') then
			declare
				X : constant Integer := Get_Value (I, 1, Integer'Last);
			begin
				if X <= 0 then
					Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
					return;
				end if;
				Width := X;
			end;
		elsif Parsing.Is_Unknown_Option (I) then
			Ada.Text_IO.Set_Output (Ada.Text_IO.Standard_Error.all);
			Ada.Text_IO.Put ("Unknown option: ");
			Ada.Text_IO.Put (Parsing.Name (I));
			Ada.Text_IO.New_Line;
			Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
			return;
		else
			From_Standard_Input := False;
			declare
				Argument : constant String := Parsing.Argument (I);
				Skip : Boolean := False;
			begin
				declare
					Directory_Entry : constant
							Ada.Directories.Directory_Entry_Type :=
						Ada.Directories.Get_Entry (Argument);
				begin
					case Ada.Directories.Kind (Directory_Entry) is
						when Ada.Directories.Ordinary_File =>
							null;
						when Ada.Directories.Directory =>
							Skip := True;
						when Ada.Directories.Special_File =>
							if Ada.Directories.Information.Is_Symbolic_Link (
									Directory_Entry)
								and then not Dereference
							then
								Skip := True;
							end if;
					end case;
				end;
				if not Skip then
					declare
						File : Ada.Text_IO.File_Type;
					begin
						Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Argument,
							Shared => IO_Modes.Allow);
						if Diff then
							Process_Diff (File, Strip,
								Tab => Tab, East_Asian => East_Asian, Width => Width,
								Final_New_Line => Final_New_Line, Colored => Colored);
						else
							Process_File (File, Argument,
								Tab => Tab, East_Asian => East_Asian, Width => Width,
								Final_New_Line => Final_New_Line, Colored => Colored);
						end if;
						Ada.Text_IO.Close (File);
					end;
				end if;
			exception
				when Ada.Text_IO.Name_Error =>
					Ada.Text_IO.Set_Output (Ada.Text_IO.Standard_Error.all);
					Ada.Text_IO.Put ("Failure to open: ");
					Ada.Text_IO.Put (Argument);
					Ada.Text_IO.New_Line;
					Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
			end;
		end if;
	end loop;
	if From_Standard_Input then
		if Diff then
			Process_Diff (Ada.Text_IO.Standard_Input.all, Strip,
				Tab => Tab, East_Asian => East_Asian, Width => Width,
				Final_New_Line => Final_New_Line, Colored => Colored);
		else
			Process_File (Ada.Text_IO.Standard_Input.all, "-",
				Tab => Tab, East_Asian => East_Asian, Width => Width,
				Final_New_Line => Final_New_Line, Colored => Colored);
		end if;
	end if;
end longlines;
