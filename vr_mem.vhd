--  ************************************
--  * VR Registers Test                *
--  ************************************

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity vr_mem is
port (clk : in std_logic;
      vr_addr : in std_logic_vector(4 downto 0);
      vr_we : in std_logic;
      vr_i : in std_logic_vector(15 downto 0);
      vr_o : out std_logic_vector(15 downto 0)
     );
end vr_mem;

architecture Behavioral of vr_mem is

type ram_t is array (0 to 31) of std_logic_vector(15 downto 0);
signal ram : ram_t := (others => X"0030");

attribute ram_style: string;
attribute ram_style of ram : signal is "distributed";

begin

--process for read and write operation.
PROCESS(vr_addr, vr_we, vr_i)
BEGIN
    --if(rising_edge(clk)) then
        if(vr_we='1') then
            ram(conv_integer(vr_addr)) <= vr_i;
        end if;
        vr_o <= ram(conv_integer(vr_addr));
    --end if; 
END PROCESS;

end Behavioral;

--  ************************************
--  * END OF VR Registers Test         *
--  ************************************