entity gpu is
    Port ( clk,rst : in  STD_LOGIC;
           vgaRed : out  STD_LOGIC_VECTOR (2 downto 0);
           vgaGreen, vgaBlue : out  STD_LOGIC_VECTOR (2 downto 1);
           Hsync,Vsync : out  STD_LOGIC);
end gpu;

architecture gpu_one of gpu is
end gpu_one;