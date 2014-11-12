LIBRARY IEEE;

USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;


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
  
  --starting +y cw
  constant c11: std_logic_vector(11 downto 0) := "011011000000"; --"3300";
  constant c21: std_logic_vector(11 downto 0) := "011010000001"; --"3201";
  constant c31: std_logic_vector(11 downto 0) := "001001000010"; --"1102";
  constant c41: std_logic_vector(11 downto 0) := "001000000011"; --"1003";
  
  constant c12: std_logic_vector(11 downto 0) := "010011001000"; --"2310";
  constant c22: std_logic_vector(11 downto 0) := "010010001001"; --"2211";
  constant c32: std_logic_vector(11 downto 0) := "000001001010"; --"0112";
  constant c42: std_logic_vector(11 downto 0) := "000000001011"; --"0013";
  
  constant c13: std_logic_vector(11 downto 0) := "1420";
  constant c23: std_logic_vector(11 downto 0) := "1321";
  constant c33: std_logic_vector(11 downto 0) := "1202";
  constant c43: std_logic_vector(11 downto 0) := "1103";
  constant c53: std_logic_vector(11 downto 0) := "1004";
  
  constant c14: std_logic_vector(11 downto 0) := "0530";
  constant c24: std_logic_vector(11 downto 0) := "0431";
  constant c34: std_logic_vector(11 downto 0) := "0312";
  constant c44: std_logic_vector(11 downto 0) := "0213";
  constant c54: std_logic_vector(11 downto 0) := "0114";
  constant c64: std_logic_vector(11 downto 0) := "0005";
  
  subtype elements is std_logic_vector(11 downto 0);
  type twoDArray is array (0 to 18) of elements;
  signal arr : twoDArray;
  
  signal cur: std_logic_vector(11 downto 0);

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

	PROCESS(CS)
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
    
    process
	begin
 L1: for i in 0 to 18 loop
		cur <= arr(i);
		for j in 0 to 3 loop
			if input = cur then
				
				
				--output <=  & arr(i);
				exit L1;
			end if;
			cur <= rotate_left(cur,3); --i think its element wise
    
		end loop;
	end loop;
    end process;
      
      
      

END a;

