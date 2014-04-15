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
    signal xctr,yctr : STD_LOGIC_VECTOR(10 downto 0) := "00000000000";
    alias xtile : STD_LOGIC_VECTOR(5 downto 0) is xctr(10 downto 5);
    alias ytile : STD_LOGIC_VECTOR(5 downto 0) is yctr(10 downto 5);
    alias tilexoff : STD_LOGIC_VECTOR(3 downto 0) is xctr(4 downto 1);
    alias tileyoff : STD_LOGIC_VECTOR(3 downto 0) is yctr(4 downto 1);
    signal hs : STD_LOGIC := '1';
    signal vs : STD_LOGIC := '1';
    signal pixel : STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal video : STD_LOGIC_VECTOR(7 downto 0) := "00000000";
    alias red : STD_LOGIC_VECTOR(2 downto 0) is video(6 downto 4);
    alias green : STD_LOGIC_VECTOR(1 downto 0) is video(3 downto 2);
    alias blue : STD_LOGIC_VECTOR(1 downto 0) is video(1 downto 0);
    signal timer : STD_LOGIC_VECTOR(7 downto 0) := X"00";

    -- Tiles
    type tile_pixel_data_type is array (0 to 255) of STD_LOGIC_VECTOR(7 downto 0);
    type tile_pixel_mem_type is array (0 to 31) of tile_pixel_data_type;
    constant tile_pixel_mem : tile_pixel_mem_type := 
        (
             0 => (others =>X"00"), -- transparent
             1 => (others =>X"AC"), -- grön
             2 => (others =>X"A3"), -- blå
             10 => (0 =>X"E0", 1 =>X"1C", 2 =>X"03", 3 =>X"A6",4 =>X"E0", 5 =>X"1C", 6 =>X"03", 7 =>X"A6",
		           8 =>X"E0", 9 =>X"1C", 10 =>X"03", 11 =>X"A6",12 =>X"E0", 13 =>X"1C", 14 =>X"03",
                   15 =>X"A6",30 =>X"E0", 31 =>X"1C", 42 =>X"03", 53 =>X"A6",64 =>X"E0", 75 =>X"1C", 
                   86 =>X"03", 97 =>X"A6",108 =>X"E0", 119 =>X"1C", 110 =>X"03", 111 =>X"A6",112 =>X"E0",
                   213 =>X"1C", 244 =>X"03", 150 =>X"A6", others =>X"01"),
        others => (others =>X"00") -- transparent
        );

    type tile_mem_row_type is array(0 to 99) of STD_LOGIC_VECTOR(7 downto 0);
    type tile_mem_type is array(0 to 39) of tile_mem_row_type;

    constant layer0_mem : tile_mem_type := (10 => (others =>X"02"), others => (10 => X"02", others => X"00"));
    constant layer1_mem : tile_mem_type := (others => (others => X"0A"));
    constant layer2_mem : tile_mem_type := (others => (others => X"00"));
    constant layer3_mem : tile_mem_type := (others => (others => X"01"));

    signal current_tile0 : STD_LOGIC_VECTOR(7 downto 0) := X"00";
    signal current_tile1 : STD_LOGIC_VECTOR(7 downto 0) := X"00";
    signal current_tile2 : STD_LOGIC_VECTOR(7 downto 0) := X"00";
    signal current_tile3 : STD_LOGIC_VECTOR(7 downto 0) := X"00";


    signal current_pixel0 : STD_LOGIC_VECTOR(7 downto 0) := X"00";
    signal current_pixel1 : STD_LOGIC_VECTOR(7 downto 0) := X"00";
    signal current_pixel2 : STD_LOGIC_VECTOR(7 downto 0) := X"00";
    signal current_pixel3 : STD_LOGIC_VECTOR(7 downto 0) := X"00";

    signal pipeline_count : STD_LOGIC_VECTOR(1 downto 0) := "00";
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
         xctr <= "00000000000";
      elsif pixel=3 then
       if xctr=799 then
         xctr <= "00000000000";
       else
         xctr <= xctr + 1;
       end if;
      end if;
      --
      if xctr=656 then -- 688
        hs <= '0';
      elsif xctr=752 then -- 784
        hs <= '1';
      end if;
    end if;
  end process;

  process(clk) begin
    if rising_edge(clk) then
      if rst='1' then
        yctr <= "00000000000";
      elsif xctr=799 and pixel=0 then
       if yctr=520 then
         yctr <= "00000000000";
       else
         yctr <= yctr + 1;
       end if;
       --
       if yctr=490 then -- 509
         vs <= '0';
       elsif  yctr=492 then --511
         vs <= '1';
       end if;
      end if;
    end if;
  end process;
  Hsync <= hs;
  Vsync <= vs;



  process(clk) begin
    current_tile0 <= layer0_mem(conv_integer(ytile))(conv_integer(xtile));
    current_tile1 <= layer1_mem(conv_integer(ytile))(conv_integer(xtile));
    current_tile2 <= layer2_mem(conv_integer(ytile))(conv_integer(xtile));
    current_tile3 <= layer3_mem(conv_integer(ytile))(conv_integer(xtile));
    if rising_edge(clk) then
      --if pixel = "11" then
        if xctr>639 or yctr>479 then
          video <= "00000000";
        --elsif xctr=0 or xctr=639 or yctr=0 or yctr=479 then
        --  video<="11111111";
        elsif yctr<480 and xctr<640 then
            if pixel = "00" then
              current_pixel0 <= tile_pixel_mem(conv_integer(current_tile0))(conv_integer(tileyoff & tilexoff));
              current_pixel1 <= tile_pixel_mem(conv_integer(current_tile1))(conv_integer(tileyoff & tilexoff));
            elsif pixel = "01" then
              current_pixel2 <= tile_pixel_mem(conv_integer(current_tile2))(conv_integer(tileyoff & tilexoff));
              current_pixel3 <= tile_pixel_mem(conv_integer(current_tile3))(conv_integer(tileyoff & tilexoff));
            elsif pixel = "11" then
                if current_pixel0(7) = '1' then
                    video <= current_pixel0;
                elsif current_pixel1(7) = '1' then
                    video <= current_pixel1;
                elsif current_pixel2(7) = '1' then
                    video <= current_pixel2;
                else
                    video <= current_pixel3;
                end if;
            end if;
        else
          video <= "00000000";
        end if;
      --end if;
    end if;
  end process;

  vgaRed(2 downto 0) <= (red);
  vgaGreen(2 downto 0) <= (green & '0');
  vgaBlue(2 downto 1) <= (blue);


end gpu_one;
