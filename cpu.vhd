library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity cpu is
    Port ( clk,rst,step : in  STD_LOGIC;
        seg: out  STD_LOGIC_VECTOR(7 downto 0);
        an : out  STD_LOGIC_VECTOR (3 downto 0);
        led : out STD_LOGIC_VECTOR (7 downto 0));
end cpu;

architecture cpu_one of cpu is
    component leddriver
        Port ( clk,rst : in  STD_LOGIC;
           seg : out  STD_LOGIC_VECTOR(7 downto 0);
           an : out  STD_LOGIC_VECTOR (3 downto 0);
           led : out STD_LOGIC_VECTOR (7 downto 0);
           value : in  STD_LOGIC_VECTOR (15 downto 0);
           ledval : in STD_LOGIC_VECTOR (7 downto 0));

    end component;

    signal databus : STD_LOGIC_VECTOR(15 downto 0) := X"0000";

    -- Registers
    signal rASR : STD_LOGIC_VECTOR(15 downto 0) := X"2222";
    signal rIR : STD_LOGIC_VECTOR(15 downto 0) := X"0300";
    signal rPC : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    signal rDR : STD_LOGIC_VECTOR(15 downto 0) := X"1111";
    signal rAR : STD_LOGIC_VECTOR(15 downto 0) := X"1234";
    signal rHR : STD_LOGIC_VECTOR(15 downto 0) := X"7421";
    signal rSP : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    signal rLC : STD_LOGIC_VECTOR(7 downto 0) := X"00";

    signal rALU : STD_LOGIC_VECTOR(16 downto 0) := '0' & X"0000";

    -- Flags
    signal fV : STD_LOGIC := '0';
    signal fZ : STD_LOGIC := '1';
    signal fN : STD_LOGIC := '0';
    signal fC : STD_LOGIC := '0';
    signal fO : STD_LOGIC := '0';
    signal fL : STD_LOGIC := '0';

    -- Primary memory
    type PrimMem_type is array (0 to 30000) of STD_LOGIC_VECTOR(15 downto 0);
    signal PrimMem : PrimMem_type := (others=> (others=>'0'));

    -- Micro memory
    type uMem_type is array (0 to 511) of STD_LOGIC_VECTOR(31 downto 0);
    constant uMem : uMem_type := (0=>X"00002208", 
                                  1=>X"05800000",
                                  2=>X"07880000",
                                  3=>X"08780000",
                                  4=>X"00002000",
                            others=> X"00000000");

    -- uPC
    signal uPC : STD_LOGIC_VECTOR(8 downto 0) := (others=>'0');
    signal SuPC : STD_LOGIC_VECTOR(8 downto 0) := (others=>'0');

    type K1_type is array (0 to 63) of STD_LOGIC_VECTOR(8 downto 0);
    signal K1 : K1_type := (others=> (others=>'0'));

    type K2_type is array (0 to 3) of STD_LOGIC_VECTOR(8 downto 0);
    signal K2 : K2_type := (others=> (others=>'0'));

    type gr_array is array (0 to 15) of STD_LOGIC_VECTOR(15 downto 0);
    signal rGR : gr_array := (others=> (others=>'0'));

    --maybe move this to main, should be shared with GPU
    --maybe make CPU main and have the GPU as a second file
    type vr_array is array (0 to 31) of STD_LOGIC_VECTOR(15 downto 0);
    signal rVR : vr_array;

    ---------- DEBUG --------
    signal old_step : STD_LOGIC := '0';

begin
    led_driver: leddriver port map (clk, rst, seg, an, led, rHR, uPC(7 downto 0));

    -- *****************************
    -- * CONTROL UNIT              *
    -- *****************************
    process(clk) begin
        if rising_edge(clk) then
            
            -- rst
            if rst = '1' then
                rPC <= X"0000";
                uPC <= "000000000";
            else

                -- LC control
                case uMem(conv_integer(uPC))(15 downto 14) is
                    when "01" => rLC <= rLC - rLC;
                    when "10" => rLC <= databus(7 downto 0);
                    when "11" => rLC <= uMem(conv_integer(uPC))(7 downto 0);
                    when others => null;
                end case;

                -- P control
                if uMem(conv_integer(uPC))(19) = '1' then
                    rPC <= rPC + 1;
                end if;

                -- SP control
                case uMem(conv_integer(uPC))(17 downto 16) is
                    when "01" => rSP <= rSP + 1;
                    when "10" => rSP <= rSP - 1;
                    when others => null;
                end case;

                -- SEQ
                case uMem(conv_integer(uPC))(13 downto 9) is
                    when "00000" => uPC <= uPC + 1;
                    when "00001" => uPC <= K1(conv_integer(rIR(15 downto 10)));
                    when "00010" => uPC <= K2(conv_integer(rIR(9 downto 8)));
                    when "00011" => uPC <= "000000000";
                    when "10000" => uPC <= uMem(conv_integer(uPC))(8 downto 0);
                    when "10001" => if fZ = '1' then uPC <= uMem(conv_integer(uPC))(8 downto 0); end if;
                    when "10010" => if fZ = '0' then uPC <= uMem(conv_integer(uPC))(8 downto 0); end if;
                    when "10011" => if fN = '1' then uPC <= uMem(conv_integer(uPC))(8 downto 0); end if;
                    when "10100" => if fN = '0' then uPC <= uMem(conv_integer(uPC))(8 downto 0); end if;
                    when "10101" => if fC = '1' then uPC <= uMem(conv_integer(uPC))(8 downto 0); end if;
                    when "10110" => if fC = '0' then uPC <= uMem(conv_integer(uPC))(8 downto 0); end if;
                    when "10111" => if fO = '1' then uPC <= uMem(conv_integer(uPC))(8 downto 0); end if;
                    when "11000" => if fO = '0' then uPC <= uMem(conv_integer(uPC))(8 downto 0); end if;
                    when "11001" => if fL = '1' then uPC <= uMem(conv_integer(uPC))(8 downto 0); end if;
                    when "11010" => if fL = '0' then uPC <= uMem(conv_integer(uPC))(8 downto 0); end if;
                    when "11011" => if fV = '1' then uPC <= uMem(conv_integer(uPC))(8 downto 0); end if;
                    when "11100" => if fV = '0' then uPC <= uMem(conv_integer(uPC))(8 downto 0); end if;
                    when "11101" => 
                        uPC <= uMem(conv_integer(uPC))(8 downto 0); 
                        SuPC <= uPC+1;
                    when "11110" => uPC <= SuPC;
                    when others => null;
                end case;

                -- FROM BUS
                case uMem(conv_integer(uPC))(23 downto 20) is
                    when "0001" => rASR <= databus;
                    when "0010" => rIR <= databus;
                    when "0011" => null; -- PM, PLES FIXES
                    when "0100" => rPC <= databus;
                    when "0101" => rDR <= databus;
                    when "0110" => null; -- can't write to uM
                    when "0111" => null; -- can't write to AR
                    when "1000" => rHR <= databus;
                    when "1001" => rSP <= databus;
                    --when "1010" => rGR <= databus; -- GR mux
                    --when "1011" => rVR <= databus; -- GR mux
                    when others => null;
                end case;
            end if;
        end if;
    end process;
    
    -- TO BUS
    with uMem(conv_integer(uPC))(27 downto 24) select
	databus <= rASR when "0001",
			   rIR when "0010",
			   --PM when "0011",
               rPC when "0100",
               rDR when "0101",
               --uMem(conv_integer(uPC)) when "0110",
               rAR when "0111",
               rHR when "1000",
               rSP when "1001",
               --rGR when "1010",
               --rVR when "1011",
               X"0000" when others;

    -- *****************************
    -- * ALU - TODO                *
    -- *****************************
    process(clk) begin
        case uMem(conv_integer(uPC))(31 downto 28) is
            when "0001" => rAR <= databus; -- rAr = databus
            when "0011" => rALU <= '0' & X"0000"; fZ <= '1'; fN <= '0'; -- rAR = X"0000"
            --when "1001" => rALU <= ('0' & rAR) + ('0' & databus); rAR <= rALU(3 downto 0); fC <= rALU(4); -- ar + databus
            when "0100" => -- res = |nib1 - nib2|, flag = 1 iff nib2 > nib1
         	    if (rAR >= databus) then
         	        rAR <= std_logic_vector(unsigned(rAR) - unsigned(databus));
         	        --flag  <= '0';
                else
         	        rAR <= std_logic_vector(unsigned(databus) - unsigned(rAR));
         	        --flag   <= '1';
                end if;
            when others => null;
        end case;
        rAR <= rALU(15 downto 0);
    end process;
            


end cpu_one;
