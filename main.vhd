library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity main is
	Port ( clk,rst,step: in  STD_LOGIC;
            vgaRed, vgaGreen: out  STD_LOGIC_VECTOR (2 downto 0);
            vgaBlue : out  STD_LOGIC_VECTOR (2 downto 1);
            Hsync,Vsync : out  STD_LOGIC;
            seg : out  STD_LOGIC_VECTOR(7 downto 0);
            an : out  STD_LOGIC_VECTOR (3 downto 0);
            led : out STD_LOGIC_VECTOR (7 downto 0);
            value : in  STD_LOGIC_VECTOR (15 downto 0);
            ledval : in STD_LOGIC_VECTOR (7 downto 0));
end main;

architecture Behavioral of main is
	component gpu
        Port ( clk,rst : in  STD_LOGIC;
            vgaRed, vgaGreen: out  STD_LOGIC_VECTOR (2 downto 0);
            vgaBlue : out  STD_LOGIC_VECTOR (2 downto 1);
            Hsync,Vsync : out  STD_LOGIC);
    end component;

    component cpu
    	Port ( clk,rst,step : in  STD_LOGIC;
        seg: out  STD_LOGIC_VECTOR(7 downto 0);
        an : out  STD_LOGIC_VECTOR (3 downto 0);
        led : out STD_LOGIC_VECTOR (7 downto 0));
    end component;

begin
    gpu_instance : gpu port map (clk, rst, vgaRed, vgaGreen, vgaBlue, Hsync, Vsync);
    cpu_instance : cpu port map (clk, rst, step, seg, an, led);
end Behavioral;