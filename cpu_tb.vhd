-- TestBench Template 

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY cpu_tb IS
END cpu_tb;

ARCHITECTURE behavior OF cpu_tb IS 

  -- Component Declaration
  COMPONENT cpu
    Port ( clk,rst,step : in  STD_LOGIC;
        seg: out  STD_LOGIC_VECTOR(7 downto 0);
        an : out  STD_LOGIC_VECTOR (3 downto 0);
        led : out STD_LOGIC_VECTOR (7 downto 0));
  END COMPONENT;

  SIGNAL clk : std_logic := '0';
  SIGNAL rst : std_logic := '0';
  SIGNAL seg : std_logic_vector(7 downto 0);
  SIGNAL an :  std_logic_vector(3 downto 0);
  SIGNAL step : std_logic := '0';
  SIGNAL tb_running : boolean := true;
BEGIN

  -- Component Instantiation
  uut: cpu PORT MAP(
    clk => clk,
    rst => rst,
    step => step,
    seg => seg,
    an => an);


  clk_gen : process
  begin
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
