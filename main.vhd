library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity main is
	Port ( clk,rst,step: in STD_LOGIC;
            vgaRed, vgaGreen: out STD_LOGIC_VECTOR (2 downto 0);
            vgaBlue : out STD_LOGIC_VECTOR (2 downto 1);
            Hsync,Vsync : out STD_LOGIC;
            seg : out STD_LOGIC_VECTOR(7 downto 0);
            an : out STD_LOGIC_VECTOR (3 downto 0);
            led : out STD_LOGIC_VECTOR (7 downto 0);
            value : in STD_LOGIC_VECTOR (15 downto 0);
            ledval : in STD_LOGIC_VECTOR (7 downto 0));
end main;

architecture Behavioral of main is
    signal fV : STD_LOGIC := '0';

    signal vr_we : STD_LOGIC := '0';
    signal vr_addr : STD_LOGIC_VECTOR(4 downto 0) := "00000";
    signal vr_i : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    signal vr_o : STD_LOGIC_VECTOR(15 downto 0) := X"0000";

    component gpu
        Port ( clk,rst : in  STD_LOGIC;
            vgaRed, vgaGreen: out  STD_LOGIC_VECTOR (2 downto 0);
            vgaBlue : out  STD_LOGIC_VECTOR (2 downto 1);
            Hsync,Vsync : out  STD_LOGIC;
            vr_we : in STD_LOGIC;
            vr_addr: in STD_LOGIC_VECTOR(4 downto 0);
            vr_i: in STD_LOGIC_VECTOR(15 downto 0);
            vr_o: out STD_LOGIC_VECTOR(15 downto 0);
            fV : out STD_LOGIC);
    end component;

    component cpu
    	Port ( clk,rst,step : in  STD_LOGIC;
        seg: out  STD_LOGIC_VECTOR(7 downto 0);
        an : out  STD_LOGIC_VECTOR (3 downto 0);
        led : out STD_LOGIC_VECTOR (7 downto 0);
        vr_we : out STD_LOGIC;
        vr_addr : out STD_LOGIC_VECTOR(4 downto 0);
        vr_i : out STD_LOGIC_VECTOR(15 downto 0);
        vr_o : in STD_LOGIC_VECTOR(15 downto 0);
        fV : in STD_LOGIC);
    end component;

begin
    --gpu_instance : gpu port map (clk, rst, vgaRed, vgaGreen, vgaBlue, Hsync, Vsync, vr_addr, vr_we, vr_i, vr_o, fV);
    gpu_instance : gpu port map (clk, rst, vgaRed, vgaGreen, vgaBlue, Hsync, Vsync, vr_we, vr_addr, vr_i, vr_o, fV);
    cpu_instance : cpu port map (clk, rst, step, seg, an, led, vr_we, vr_addr, vr_i, vr_o, fV);
    --cpu_instance : cpu port map (clk, rst, step, seg, an, led, vr_addr, vr_we, vr_i, vr_o, fV);

end Behavioral;
