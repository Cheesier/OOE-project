library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity boardinput is
    Port (clk, up, right, down, left : in STD_LOGIC;
          cUp, cRight, cDown, cLeft : out STD_LOGIC);
end boardinput;

architecture boardinput_one of boardinput is
begin
    process(clk) begin
        if rising_edge(clk) then
            cUp <= up;
            cRight <= right;
            cDown <= down;
            cLeft <= left;
        end if;
    end process;
end boardinput_one;

