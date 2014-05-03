library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--package my_types is     
--    type vr_array is array (0 to 31) of STD_LOGIC_VECTOR(15 downto 0);
--end package my_types;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

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
    --constant rVR : vr_array := (others=> X"0050");
    --attribute ram_style: string;
    --attribute ram_style of rVR : signal is "distributed";
    
    signal fV : STD_LOGIC := '0';

    signal vr_addr : std_logic_vector(4 downto 0) := "00000";
    signal vr_we : std_logic := '0';
    signal vr_i : std_logic_vector(15 downto 0) := X"0000";
    signal vr_o : std_logic_vector(15 downto 0) := X"0000";

    component gpu
        Port ( clk,rst : in  STD_LOGIC;
            vgaRed, vgaGreen: out  STD_LOGIC_VECTOR (2 downto 0);
            vgaBlue : out  STD_LOGIC_VECTOR (2 downto 1);
            Hsync,Vsync : out  STD_LOGIC;
            vr_addr : out std_logic_vector(4 downto 0);
            vr_we : out std_logic;
            vr_i : out std_logic_vector(15 downto 0);
            vr_o : in std_logic_vector(15 downto 0);
            fV : out STD_LOGIC);
    end component;

    component cpu
    	Port ( clk,rst,step : in  STD_LOGIC;
        seg: out  STD_LOGIC_VECTOR(7 downto 0);
        an : out  STD_LOGIC_VECTOR (3 downto 0);
        led : out STD_LOGIC_VECTOR (7 downto 0);
        vr_addr : out std_logic_vector(4 downto 0);
        vr_we : out std_logic;
        vr_i : out std_logic_vector(15 downto 0);
        vr_o : in std_logic_vector(15 downto 0);
        fV : in STD_LOGIC);
    end component;

    component vr_mem
        port (clk : in std_logic;
              vr_addr : in std_logic_vector(4 downto 0);
              vr_we : in std_logic;
              vr_i : in std_logic_vector(15 downto 0);
              vr_o : out std_logic_vector(15 downto 0)
     );
    end component;
    

begin
    gpu_instance : gpu port map (clk, rst, vgaRed, vgaGreen, vgaBlue, Hsync, Vsync, vr_addr, vr_we, vr_i, vr_o, fV);
    cpu_instance : cpu port map (clk, rst, step, seg, an, led, vr_addr, vr_we, vr_i, vr_o, fV);
    vr_mem_instance : vr_mem port map(clk, vr_addr, vr_we, vr_i, vr_o);

end Behavioral;
