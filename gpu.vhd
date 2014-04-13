library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity gpu is
    Port ( clk,rst : in  STD_LOGIC;
            vgaRed, vgaGreen: out  STD_LOGIC_VECTOR (2 downto 0);
            vgaBlue : out  STD_LOGIC_VECTOR (2 downto 1);
            Hsync,Vsync : out  STD_LOGIC);
end gpu;

architecture gpu_one of gpu is
    signal xctr,yctr : STD_LOGIC_VECTOR(9 downto 0) := "0000000000";
    alias xtile : STD_LOGIC_VECTOR(5 downto 0) is xctr(9 downto 4);
    alias ytile : STD_LOGIC_VECTOR(5 downto 0) is yctr(9 downto 4);
    alias tilexoff : STD_LOGIC_VECTOR(3 downto 0) is xctr(3 downto 0);
    alias tileyoff : STD_LOGIC_VECTOR(3 downto 0) is yctr(3 downto 0);
    signal hs : STD_LOGIC := '1';
    signal vs : STD_LOGIC := '1';
    signal pixel : STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal video : STD_LOGIC_VECTOR(7 downto 0) := "00000000";
    alias red : STD_LOGIC_VECTOR(2 downto 0) is video(7 downto 5);
    alias green : STD_LOGIC_VECTOR(2 downto 0) is video(4 downto 2);
    alias blue : STD_LOGIC_VECTOR(1 downto 0) is video(1 downto 0);
    signal timer : STD_LOGIC_VECTOR(7 downto 0) := X"00";

    -- Tiles
    type tile_pixel_data_type is array (0 to 255) of STD_LOGIC_VECTOR(7 downto 0);
    type tile_pixel_mem_type is array (0 to 31) of tile_pixel_data_type;
    constant tile_pixel_mem : tile_pixel_mem_type := 
        (
             0 => (0 =>X"E0", others =>X"00"), -- röd
             1 => (0 =>X"1C", others =>X"00"), -- grön
             2 => (0 =>X"03", others =>X"00"), -- blå
        others => (others =>X"00") -- svart
        );

    type tile_mem_row_type is array(0 to 50) of STD_LOGIC_VECTOR(7 downto 0);
    type tile_mem_type is array(0 to 40) of tile_mem_row_type;
    signal layer1_mem : tile_mem_type := (others => (others => "00000001"));
    signal layer2_mem : tile_mem_type;

    signal current_tile : STD_LOGIC_VECTOR(7 downto 0);

begin
    -- Pixel clock
    process(clk) begin
     if rising_edge(clk) then
       if rst='1' then
         pixel <= "00";
       else
         pixel <= pixel + 1;
       end if;
     end if;
  end process;

  process(clk) begin
    if rising_edge(clk) then
      if rst='1' then
         xctr <= "0000000000";
      elsif pixel=3 then
       if xctr=799 then
         xctr <= "0000000000";
       else
         xctr <= xctr + 1;
       end if;
      end if;
      --
      if xctr=688 then
        hs <= '0';
      elsif xctr=784 then
        hs <= '1';
      end if;
    end if;
  end process;

  process(clk) begin
    if rising_edge(clk) then
      if rst='1' then
        yctr <= "0000000000";
      elsif xctr=799 and pixel=0 then
       if yctr=520 then
         yctr <= "0000000000";
       else
         yctr <= yctr + 1;
       end if;
       --
       if yctr=509 then
         vs <= '0';
       elsif  yctr=511 then
         vs <= '1';
       end if;
      end if;
    end if;
  end process;
  Hsync <= hs;
  Vsync <= vs;

  -- video
  -- en ram ritas runt spelplanen
  -- tycks medföra att AUTO funkar som avsett
  process(clk) begin
    if rising_edge(clk) then
      if pixel=3 then
        if xctr(3 downto 0) = "1111" then
          current_tile <= layer1_mem(0)(conv_integer(ytile));
          --current_tile <= layer1_mem(100)(0);
          --current_tile <= "00000010";
        end if;

        if xctr>640 or yctr>480 then
          video <= "00000000";
        --elsif xctr=0 or xctr=639 or yctr=0 or yctr=479 then
        --  video<="11111111";
        elsif yctr<480 and xctr<640 then
          video <= tile_pixel_mem(conv_integer(current_tile))(conv_integer(tilexoff*tileyoff));
        else
          video <= "00000000";
        end if;
      end if;
    end if;
  end process;

  vgaRed(2 downto 0) <= (red);
  vgaGreen(2 downto 0) <= (green(2 downto 1) & '0');
  vgaBlue(2 downto 1) <= (blue);


end gpu_one;
