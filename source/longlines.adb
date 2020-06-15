with Ada.Characters.Latin_1;
with Ada.Strings.Functions;
		Line : in String;
		Width : in Positive)
	is
		Last : Natural := Line'First - 1;
		while Last < Line'Last loop
				I : constant Positive := Last + 1;
				Item : Wide_Wide_Character;
				Ada.Characters.Conversions.Get (Line (I .. Line'Last), Last, Item);
		Line : in String;
			Ada.Text_IO.Put (Line (Line'First .. Over_Index - 1));
			Ada.Text_IO.Put (Line (Over_Index .. Line'Last));
		Message : in String;
		Ada.Text_IO.Put (Message);
	package Unbounded_Strings renames Ada.Strings.Unbounded_Strings;
		Line : Unbounded_Strings.Unbounded_String;
		Unbounded_Strings.Reserve_Capacity (Line, Width + 1);
			Unbounded_Strings.Set_Length (Line, 0);
					Item : Character;
					Ada.Text_IO.Look_Ahead (File, Item, End_Of_Line);
					Unbounded_Strings.Append (Line, (1 => Item));
				Line_Ref : String
					renames Unbounded_Strings.Constant_Reference (Line);
	package Functions renames Ada.Strings.Functions;
		type Git_File_Mode is mod 8#1000000#;
		Default_Mode : constant Git_File_Mode := 8#100644#;
		Symbolic_Link : constant Git_File_Mode := 8#020000#;
		function Value (Image : String) return Git_File_Mode is
		begin
			return Git_File_Mode'Value ("8#" & Image & "#");
		exception
			when Constraint_Error =>
				return Default_Mode;
		end Value;
		procedure Process_New_File_Mode (
			Line : in String;
			Mode : out Git_File_Mode)
		is
			pragma Assert (
				Line'Length >= 14
				and then Line (Line'First .. Line'First + 13) = "new file mode ");
			P : Positive := Line'First + 14;
			First : constant Positive := P;
		begin
			while P <= Line'Last and then Line (P) in '0' .. '7' loop
				P := P + 1;
			end loop;
			Mode := Value (Line (First .. P - 1));
		end Process_New_File_Mode;
		procedure Process_Index (
			Line : in String;
			Mode : in out Git_File_Mode)
		is
			pragma Assert (
				Line'Length >= 6
				and then Line (Line'First .. Line'First + 5) = "index ");
			P : Positive := Line'First + 6;
		begin
			declare
				Index : Natural;
			begin
				Index :=
					Functions.Index_Element_Forward (Line (P .. Line'Last), ' ');
				if Index = 0 then
					P := Line'Last + 1;
				else
					P := Index + 1;
				end if;
			end;
			if P <= Line'Last then
				declare
					First : constant Positive := P;
				begin
					while P <= Line'Last and then Line (P) in '0' .. '7' loop
						P := P + 1;
					end loop;
					Mode := Value (Line (First .. P - 1));
				end;
			end if;
		end Process_Index;
			Line : in String;
					Functions.Index_Element_Forward (
						Ada.Characters.Latin_1.HT);
				S_First : Positive := Line_First;
				S_Last : Natural := Line_Last;
					Hierarchical_File_Names.Relative_Name (Line (S_First .. S_Last),
						Line (S_First .. S_Last));
			Line : in String;
						Functions.Index_Element_Forward (Line (P .. Line'Last), ' ');
							Line_Number := Integer'Value (Line (First .. P - 1));
		procedure Get_Line (Line : in out Unbounded_Strings.Unbounded_String) is
			Item : Character;
				Ada.Text_IO.Look_Ahead (File, Item, End_Of_Line);
				Unbounded_Strings.Append (Line, (1 => Item));
		Mode : Git_File_Mode := Default_Mode;
		Line : Unbounded_Strings.Unbounded_String;
		Unbounded_Strings.Reserve_Capacity (Line, Width + 1);
				Item : Character;
				Ada.Text_IO.Look_Ahead (File, Item, End_Of_Line);
							Unbounded_Strings.Set_Length (Line, 0);
							Unbounded_Strings.Append (Line, (1 => Item));
								Line_Ref : String
									renames Unbounded_Strings.Constant_Reference (Line);
									if (Mode and Symbolic_Link) = 0 then
										declare
											Name_Ref : String
												renames Unbounded_Strings
														.Constant_Reference (
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
									end if;
							Unbounded_Strings.Set_Length (Line, 0);
							Unbounded_Strings.Append (Line, (1 => Item));
								Line_Ref : String
									renames Unbounded_Strings.Constant_Reference (Line);
						when 'd' =>
							Unbounded_Strings.Set_Length (Line, 0);
							Unbounded_Strings.Append (Line, (1 => Item));
							Get_Line (Line);
							declare
								Line_Ref : String
									renames Unbounded_Strings.Constant_Reference (Line);
							begin
								if Line_Ref'Length >= 5
									and then Line_Ref (
											Line_Ref'First .. Line_Ref'First + 4) =
										"diff "
								then
									Unbounded_Strings.Set_Length (Name, 0);
									Mode := Default_Mode;
									Line_Number := 1;
								end if;
							end;
							Added := False;
						when 'i' =>
							Unbounded_Strings.Set_Length (Line, 0);
							Unbounded_Strings.Append (Line, (1 => Item));
							Get_Line (Line);
							declare
								Line_Ref : String
									renames Unbounded_Strings.Constant_Reference (Line);
							begin
								if Line_Ref'Length >= 6
									and then Line_Ref (
											Line_Ref'First .. Line_Ref'First + 5) =
										"index "
								then
									Process_Index (Line_Ref, Mode);
								end if;
							end;
							Added := False;
						when 'n' =>
							Unbounded_Strings.Set_Length (Line, 0);
							Unbounded_Strings.Append (Line, (1 => Item));
							Get_Line (Line);
							declare
								Line_Ref : String
									renames Unbounded_Strings.Constant_Reference (Line);
							begin
								if Line_Ref'Length >= 14
									and then Line_Ref (
											Line_Ref'First .. Line_Ref'First + 13) =
										"new file mode "
								then
									Process_New_File_Mode (Line_Ref, Mode);
								end if;
							end;
							Added := False;
							if Final_New_Line
								and then Added
								and then (Mode and Symbolic_Link) = 0
							then
								Unbounded_Strings.Set_Length (Line, 0);
									Line_Ref : String
										renames Unbounded_Strings.Constant_Reference (