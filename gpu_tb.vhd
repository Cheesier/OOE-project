-- TestBench Template 

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY gpu_tb IS
END gpu_tb;

ARCHITECTURE behavior OF gpu_tb IS 

  -- Component Declaration
  COMPONENT gpu
    PORT(
      clk,rst : IN std_logic;
      vgaRed, vgaGreen: out  STD_LOGIC_VECTOR (2 downto 0);
      vgaBlue : out  STD_LOGIC_VECTOR (2 downto 1);
      Hsync,Vsync : out  STD_LOGIC
      );
  END COMPONENT;

  SIGNAL clk : std_logic := '0';
  SIGNAL rst : std_logic := '0';
  signal vgaRed : std_logic_vector(2 downto 0);
  signal vgaGreen : std_logic_vector(2 downto 0);
  signal vgaBlue : std_logic_vector(1 downto 0);
  signal Hsync,Vsync : STD_LOGIC;
  SIGNAL tb_running : boolean := true;
BEGIN

  -- Component Instantiation
  uut: gpu PORT MAP(
    clk => clk,
    rst => rst,
    vgaRed => vgaRed,
    vgaGreen => vgaGreen,
    vgaBlue => vgaBlue,
    Hsync => Hsync, 
    Vsync => Vsync);


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
    -- Aktivera reset ett litet tag.
    rst <= '1';
    wait for 500 ns;

    wait until rising_edge(clk);        -- se till att reset släpps synkront
                                        -- med klockan
    rst <= '0';
    report "Reset released" severity note;
    wait for 1 us;
    
    
    for i in 0 to 60000000 loop         -- Vänta ett antal klockcykler
      wait until rising_edge(clk);
    end loop;  -- i
    
    tb_running <= false;                -- Stanna klockan (vilket medför att inga
                                        -- nya event genereras vilket stannar
                                        -- simuleringen).
    wait;
  end process;
      
END;
