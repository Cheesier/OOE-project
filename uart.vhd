library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity lab is
    Port ( clk,rst, rx : in  STD_LOGIC;
           seg: out  STD_LOGIC_VECTOR(7 downto 0);
           an : out  STD_LOGIC_VECTOR (3 downto 0));
end lab;

architecture Behavioral of lab is
    component leddriver
    Port ( clk,rst : in  STD_LOGIC;
           seg : out  STD_LOGIC_VECTOR(7 downto 0);
           an : out  STD_LOGIC_VECTOR (3 downto 0);
           value : in  STD_LOGIC_VECTOR (15 downto 0));
    end component;
    signal sreg : STD_LOGIC_VECTOR(9 downto 0) := B"0_00000000_0";  -- 10 bit skiftregister
    signal tal : STD_LOGIC_VECTOR(15 downto 0) := X"0000";  
    signal rx1,rx2 : std_logic;         -- vippor p√• insignalen
    signal sp : std_logic;              -- skiftpuls
    signal lp : std_logic;         -- laddpuls
    signal pos : STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal srq : std_logic := '0';       -- sr latch q value
    signal dout : std_logic_vector(3 downto 0) := "0000";  -- decadecounters out
    signal fout : std_logic_vector(8 downto 0) := "000000000";  -- 434 counters out
    signal tq : std_logic := '1';       -- t latch value
    
begin
  -- rst √§r tryckknappen i mitten under displayen
  -- *****************************
  -- *  synkroniseringsvippor    *
  -- *****************************
  process(clk) begin
     if rising_edge(clk) then
       rx1 <= rx;
       rx2 <= rx1;
     end if;
  end process;

  
  -- *****************************
  -- *       styrenhet           *
  -- *****************************

  -- Dekadr‰knare, sr-vippa
  process(clk) begin
    if rising_edge(clk) then
      if rst = '1' or srq = '0' then
        dout <= "0000";
        lp <= '0';
        if rx1 = '0' and rx2 = '1' and rst = '0' then
          srq <= '1';
        end if;
      elsif sp = '1' then
        if dout = "1001" then
          dout <= "0000";
          lp <= '1';
          srq <= '0';
        else
          dout <= dout+1;
        end if;
      else
        lp <= '0';
      end if;
    end if;
  end process;

  -- 434 r‰knare, t-vippa, enpulasre
  process(clk) begin
    if rising_edge(clk) then
      if rst = '1' or srq = '0' then
        fout <= "000000000";
        tq <= '1';
        sp <= '0';
      elsif srq = '1' then
        if fout = "110110001" then    --433
          fout <= "000000000";
          if tq = '0' then
            tq <= '1';
            sp <= '0';
          else
            tq <= '0';
            sp <= '1';
          end if;
        else
          fout <= fout+1;
          sp <= '0';
        end if;
      end if;
    end if;
  end process;

  
  -- *****************************
  -- * 10 bit skiftregister      *
  -- *****************************
  process(clk) begin
    if rising_edge(clk) then
      if rst = '1' then
        sreg <= B"0_00000000_0";
      elsif sp = '1' then
        sreg(0) <= sreg(1);
        sreg(1) <= sreg(2);
        sreg(2) <= sreg(3);
        sreg(3) <= sreg(4);
        sreg(4) <= sreg(5);
        sreg(5) <= sreg(6);
        sreg(6) <= sreg(7);
        sreg(7) <= sreg(8);
        sreg(8) <= sreg(9);
        sreg(9) <= rx2;
      end if;
    end if;
  end process;

  -- *****************************
  -- * 2  bit register           *
  -- *****************************
  process(clk) begin
    if rising_edge(clk) then
      if rst = '1' then
        pos <= "00";
      elsif lp = '1' then
        if pos = "11" then
          pos <= "00";
        else
          pos <= pos + 1;
        end if;
      end if;
    end if;
  end process;

  -- *****************************
  -- * 16 bit register           *
  -- *****************************
  process(clk) begin
    if rising_edge(clk) then
      if rst = '1' then
        tal(15 downto 0) <= X"0000";
      elsif lp = '1' then
        case pos is
          when "00" => tal(15 downto 12) <= sreg(4 downto 1);
          when "01" => tal(11 downto 8) <= sreg(4 downto 1);
          when "10" => tal(7 downto 4) <= sreg(4 downto 1);
          when others => tal(3 downto 0) <= sreg(4 downto 1);
        end case;
      end if;
    end if;
  end process;

  -- *****************************
  -- * Multiplexad display       *
  -- *****************************
  led: leddriver port map (clk, rst, seg, an, tal);
end Behavioral;

