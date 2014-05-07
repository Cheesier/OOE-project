-- TestBench Template 

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

--use work.my_types;

ENTITY main_tb IS
END main_tb;

ARCHITECTURE behavior OF main_tb IS 

  -- Component Declaration
  COMPONENT main
    Port ( clk,rst,step: in  STD_LOGIC;
            vgaRed, vgaGreen: out  STD_LOGIC_VECTOR (2 downto 0);
            vgaBlue : out  STD_LOGIC_VECTOR (2 downto 1);
            Hsync,Vsync : out  STD_LOGIC;
            seg : out  STD_LOGIC_VECTOR(7 downto 0);
            an : out  STD_LOGIC_VECTOR (3 downto 0);
            led : out STD_LOGIC_VECTOR (7 downto 0);
            value : in  STD_LOGIC_VECTOR (15 downto 0);
            ledval : in STD_LOGIC_VECTOR (7 downto 0);
            btn_up, btn_right, btn_down, btn_left : in STD_LOGIC);
  END COMPONENT;

  SIGNAL clk : std_logic := '0';
  SIGNAL rst : std_logic := '0';
  SIGNAL step : std_logic := '0';
  SIGNAL vgaRed : std_logic_vector(2 downto 0) := "000";
  SIGNAL vgaGreen : std_logic_vector(2 downto 0) := "000";
  SIGNAL vgaBlue : std_logic_vector(2 downto 1) := "00";
  SIGNAL Hsync : std_logic := '0';
  SIGNAL Vsync : std_logic := '0';

  SIGNAL seg : std_logic_vector(7 downto 0) := X"00";
  SIGNAL an :  std_logic_vector(3 downto 0) := X"0";
  SIGNAL led : STD_LOGIC_VECTOR (7 downto 0) := X"00";
  SIGNAL value : STD_LOGIC_VECTOR (15 downto 0) := X"0000";
  SIGNAL ledval : STD_LOGIC_VECTOR (7 downto 0) := X"00";

  SIGNAL btn_up, btn_right, btn_down, btn_left : STD_LOGIC := '0';

  SIGNAL tb_running : boolean := true;
BEGIN

  -- Component Instantiation
  uut: main PORT MAP(
    clk,rst, step, vgaRed, vgaGreen, vgaBlue, Hsync, Vsync, seg, an, led, value, ledval, btn_up, btn_right, btn_down, btn_left);


  clk_gen : process
  begin
    --rst <= '1';
    --wait for 20 ns;
    --rst <= '0';
    while tb_running loop
      clk <= '0';
      wait for 5 ns;
      clk <= '1';
      wait for 5 ns;
    end loop;
    wait;
  end process;

  

  stimuli_generator : process
    variable i : integer;
  begin

    

    wait;
  end process;
      
END;
