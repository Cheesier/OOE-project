library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity leddriver is
    Port ( clk,rst : in  STD_LOGIC;
           seg : out  STD_LOGIC_VECTOR(7 downto 0);
           an : out  STD_LOGIC_VECTOR (3 downto 0);
           led : out STD_LOGIC_VECTOR (7 downto 0);
           value : in  STD_LOGIC_VECTOR (15 downto 0);
           ledval : in STD_LOGIC_VECTOR (7 downto 0));
end leddriver;

architecture Behavioral of leddriver is
	signal segments : STD_LOGIC_VECTOR (6 downto 0);
	signal counter_r :  unsigned(17 downto 0) := "000000000000000000";
	signal v : STD_LOGIC_VECTOR (3 downto 0);
  signal dp : std_logic;

begin
  -- decimal point not used
  dp <= '1';
  seg <= (dp & segments);
     
   with counter_r(17 downto 16) select
     v <= value(15 downto 12) when "00",
          value(11 downto 8) when "01",	
          value(7 downto 4) when "10",
          value(3 downto 0) when others;

   process(clk) begin
     if rising_edge(clk) then 
       counter_r <= counter_r + 1;
       case v is
         when "0000" => segments <= "0000001";
         when "0001" => segments <= "1001111";
         when "0010" => segments <= "0010010";
         when "0011" => segments <= "0000110";
         when "0100" => segments <= "1001100";
         when "0101" => segments <= "0100100";
         when "0110" => segments <= "0100000";
         when "0111" => segments <= "0001111";
         when "1000" => segments <= "0000000";
         when "1001" => segments <= "0000100";
         when "1010" => segments <= "0001000";
         when "1011" => segments <= "1100000";
         when "1100" => segments <= "0110001";
         when "1101" => segments <= "1000010";
         when "1110" => segments <= "0110000";
         when others => segments <= "0111000";
       end case;
      
       case counter_r(17 downto 16) is
         when "00" => an <= "0111";
         when "01" => an <= "1011";
         when "10" => an <= "1101";
         when others => an <= "1110";
       end case;

       led <= ledval;
     end if;
   end process;
	
end Behavioral;

