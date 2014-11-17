LIBRARY IEEE;
LIBRARY LPM;

USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE LPM.LPM_COMPONENTS.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY LOOKUP IS
	PORT(
		IO_DATA  : INOUT  STD_LOGIC_VECTOR(15 DOWNTO 0);
		CS       : IN  STD_LOGIC;
		IO_WRITE : IN  STD_LOGIC
		);
END LOOKUP;


ARCHITECTURE a OF LOOKUP IS
  SIGNAL input : STD_LOGIC_VECTOR(11 downto 0);
  SIGNAL output : STD_LOGIC_VECTOR(15 downto 0);
  SIGNAL IO_OUT : STD_LOGIC;
  
  --starting +y rotating cw facing 90 degrees
  --RIGHT(+x) IS 0 DEGREES GOING CCW
  constant c11: std_logic_vector(11 downto 0) := "011011000000"; --"3300";
  constant c21: std_logic_vector(11 downto 0) := "011010000001"; --"3201";
  constant c31: std_logic_vector(11 downto 0) := "001001000010"; --"1102";
  constant c41: std_logic_vector(11 downto 0) := "001000000011"; --"1003";
  
  constant c12: std_logic_vector(11 downto 0) := "010011001000"; --"2310";
  constant c22: std_logic_vector(11 downto 0) := "010010001001"; --"2211";
  constant c32: std_logic_vector(11 downto 0) := "000001001010"; --"0112";
  constant c42: std_logic_vector(11 downto 0) := "000000001011"; --"0013";
  
  constant c13: std_logic_vector(11 downto 0) := "001100010000"; --"1420";
  constant c23: std_logic_vector(11 downto 0) := "001011010001"; --"1321";
  constant c33: std_logic_vector(11 downto 0) := "001010000010"; --"1202";
  constant c43: std_logic_vector(11 downto 0) := "001001000011"; --"1103";
  constant c53: std_logic_vector(11 downto 0) := "001000000100"; --"1004";
  
  constant c14: std_logic_vector(11 downto 0) := "000101011000"; --"0530";
  constant c24: std_logic_vector(11 downto 0) := "000100011001"; --"0431";
  constant c34: std_logic_vector(11 downto 0) := "000011001010"; --"0312";
  constant c44: std_logic_vector(11 downto 0) := "000010001011"; --"0213";
  constant c54: std_logic_vector(11 downto 0) := "000001001100"; --"0114";
  constant c64: std_logic_vector(11 downto 0) := "000000000101"; --"0005";
  
  
  constant C11a: std_logic_vector(7 downto 0) := "00010001";
  constant C21a: std_logic_vector(7 downto 0) := "00100001";
  constant C31a: std_logic_vector(7 downto 0) := "00110001";
  constant C41a: std_logic_vector(7 downto 0) := "01000001";
  
  constant C12a: std_logic_vector(7 downto 0) := "00010010";
  constant C22a: std_logic_vector(7 downto 0) := "00100010";
  constant C32a: std_logic_vector(7 downto 0) := "00110010";
  constant C42a: std_logic_vector(7 downto 0) := "01000010";
  
  constant C13a: std_logic_vector(7 downto 0) := "00010011";
  constant C23a: std_logic_vector(7 downto 0) := "00100011";
  constant C33a: std_logic_vector(7 downto 0) := "00110011";
  constant C43a: std_logic_vector(7 downto 0) := "01000011";
  constant C53a: std_logic_vector(7 downto 0) := "01010011";
  
  constant C14a: std_logic_vector(7 downto 0) := "00010100";
  constant C24a: std_logic_vector(7 downto 0) := "00100100";
  constant C34a: std_logic_vector(7 downto 0) := "00110100";
  constant C44a: std_logic_vector(7 downto 0) := "01000100";
  constant C54a: std_logic_vector(7 downto 0) := "01010100";
  constant C64a: std_logic_vector(7 downto 0) := "01100100";
  
  subtype elements is std_logic_vector(11 downto 0);
  type twoDArray is array (0 to 18) of elements;
  signal arr : twoDArray;
  
  subtype elements2 is std_logic_vector(7 downto 0);
  type twoDArray2 is array (0 to 18) of elements2;
  signal arr2 : twoDArray2;
  
  signal cur: std_logic_vector(11 downto 0);
  signal ang: std_logic_vector(1 downto 0);

  BEGIN

	IO_BUS: lpm_bustri
    GENERIC MAP (
      lpm_width => 16
    )
    PORT MAP (
      data     => output,
      enabledt => IO_OUT,
      tridata  => IO_DATA
    );

	IO_OUT <= (CS AND NOT(IO_WRITE));

	PROCESS(CS, IO_WRITE)
      BEGIN
        IF ((CS AND IO_WRITE) = '1') THEN
          input <= IO_DATA(11 downto 0);
        END IF;
    END PROCESS;
      
      
    arr(0) <= c11;
    arr(1) <= c21;
    arr(2) <= c31;
    arr(3) <= c41;
    
    arr(4) <= c12;
    arr(5) <= c22;
    arr(6) <= c32;
    arr(7) <= c42;
    
    arr(8) <= c13;
    arr(9) <= c23;
    arr(10) <= c33;
    arr(11) <= c43;
    arr(12) <= c53;
    
    arr(13) <= c14;
    arr(14) <= c24;
    arr(15) <= c34;
    arr(16) <= c44;
    arr(17) <= c54;
    arr(18) <= c64;
    
    arr2(0) <= C11a;
    arr2(1) <= C21a;
    arr2(2) <= C31a;
    arr2(3) <= C41a;
    
    arr2(4) <= C12a;
    arr2(5) <= C22a;
    arr2(6) <= C32a;
    arr2(7) <= C42a;
    
    arr2(8) <= C13a;
    arr2(9) <= C23a;
    arr2(10) <= C33a;
    arr2(11) <= C43a;
    arr2(12) <= C53a;
    
    arr2(13) <= C14a;
    arr2(14) <= C24a;
    arr2(15) <= C34a;
    arr2(16) <= C44a;
    arr2(17) <= C54a;
    arr2(18) <= C64a;
    
    process(CS)
	begin
	if(CS = '0') then
 L1: for i in 0 to 18 loop
		ang <= "01"; --00 = 0 degrees, 01 = 90, 10 = 180, 11 = 270
		cur <= std_logic_vector(arr(i));
		for j in 0 to 3 loop
			if input = cur then
				output <= "000000" & arr2(i) & ang; --6 bits nothing, 8 bits x,y coord, 2 bits angle
				exit L1;
			end if;
			ang <= ang + 1;
			cur <= std_logic_vector( rotate_right(unsigned(cur),3) );
		end loop;
	end loop;
	end if;
    end process;
END a;

