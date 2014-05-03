library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
--use work.my_types.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity cpu is
    Port (clk,rst,step : in  STD_LOGIC;
        seg: out  STD_LOGIC_VECTOR(7 downto 0);
        an : out  STD_LOGIC_VECTOR (3 downto 0);
        led : out STD_LOGIC_VECTOR (7 downto 0);
        vr_addr : out std_logic_vector(4 downto 0);
        vr_we : out std_logic;
        vr_i : out std_logic_vector(15 downto 0);
        vr_o : in std_logic_vector(15 downto 0);
        fV: in STD_LOGIC);
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
    signal rASR : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    signal rIR : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    signal rPC : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    signal rDR : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    signal ARin : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    signal ARout : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    signal rHR : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    signal rSP : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    signal rLC : STD_LOGIC_VECTOR(7 downto 0) := X"00";

    signal rALU : STD_LOGIC_VECTOR(16 downto 0) := '0' & X"0000";
    signal fADD : STD_LOGIC := '0';

    -- Flags
    --signal fV : STD_LOGIC := '0';
    signal fZ : STD_LOGIC := '1';
    signal fN : STD_LOGIC := '0';
    signal fC : STD_LOGIC := '0';
    signal fO : STD_LOGIC := '0';
    signal fL : STD_LOGIC := '0';

    -- Primary memory
    type PrimMem_type is array (0 to 2047) of STD_LOGIC_VECTOR(15 downto 0);
    signal PrimMem : PrimMem_type := ( 
        0=> X"0500",1=> X"0000",2=> X"0100",3=> X"0001",4=> X"1400",5=> X"1900",6=> X"0004",
        others=> X"0000");

    -- Micro memory
    type uMem_type is array (0 to 511) of STD_LOGIC_VECTOR(31 downto 0);
    constant uMem : uMem_type := (  0=>X"04100000",
                                    1=>X"03280000",
                                    2=>X"00000400",
                                    3=>X"0A540200",
                                    4=>X"04180000",
                                    5=>X"03500200",
                                    6=>X"04180000",
                                    7=>X"03100000",
                                    8=>X"03500200",
                                    9=>X"05A00600",
                                    10=>X"05B00600",
                                    11=>X"0A300600",
                                    12=>X"0BA00600",
                                    13=>X"15000000",
                                    14=>X"4A000000",
                                    15=>X"07A00600",
                                    16=>X"15000000",
                                    17=>X"4B000000",
                                    18=>X"07B00600",
                                    19=>X"05400600",
                                    20=>X"00002A13",
                                    21=>X"00000600",
                                    22=>X"00002213",
                                    23=>X"00000600",
                                    24=>X"00003818",
                                    25=>X"00000600",
                                    others=> X"00000000");

    -- uPC
    signal uPC : STD_LOGIC_VECTOR(8 downto 0) := (others=>'0');
    signal SuPC : STD_LOGIC_VECTOR(8 downto 0) := (others=>'0');

    signal ctrlword : STD_LOGIC_VECTOR(31 downto 0) := X"00000000";
    alias cALU : STD_LOGIC_VECTOR(3 downto 0) is ctrlword(31 downto 28);
    alias cTB : STD_LOGIC_VECTOR(3 downto 0) is ctrlword(27 downto 24);
    alias cFB : STD_LOGIC_VECTOR(3 downto 0) is ctrlword(23 downto 20);
    alias cP : STD_LOGIC is ctrlword(19);
    alias cM : STD_LOGIC is ctrlword(18);
    alias cSP : STD_LOGIC_VECTOR(1 downto 0) is ctrlword(17 downto 16);
    alias cLC : STD_LOGIC_VECTOR(1 downto 0) is ctrlword(15 downto 14);
    alias cSEQ : STD_LOGIC_VECTOR(4 downto 0) is ctrlword(13 downto 9);
    alias cADR : STD_LOGIC_VECTOR(8 downto 0) is ctrlword(8 downto 0);

    type K1_type is array (0 to 63) of STD_LOGIC_VECTOR(8 downto 0);
    signal K1 : K1_type := (0=>"000001001", --MOVE
                            1=>"000001010", --MOVEV
                            2=>"000001011", --STR
                            3=>"000001100", --STRV
                            4=>"000001101", --ADD
                            5=>"000010000", --ADDV
                            6=>"000010011", --JMP
                            7=>"000010100", --JMPC
                            8=>"000010110", --JMPZ
                            9=>"000011000", --WVS
                            others=>"000000000");

    type K2_type is array (0 to 3) of STD_LOGIC_VECTOR(8 downto 0);
    signal K2 : K2_type := (0=>"000000011", --reg-reg
                            1=>"000000100", --imm
                            2=>"000000110", --indir
                            others=>"000000000");

    type gr_array is array (0 to 15) of STD_LOGIC_VECTOR(15 downto 0);
    signal rGR : gr_array := (others=> X"0000");

    signal tempGR : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    signal tempVR : STD_LOGIC_VECTOR(15 downto 0) := X"0000";


    ---------- DEBUG --------
    signal old_step : STD_LOGIC := '0';

begin
    ctrlword <= uMem(conv_integer(uPC));

    
    led_driver: leddriver port map (clk, rst, seg, an, led, rDR, X"00");

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
                case cLC is
                    when "01" => rLC <= rLC - rLC;
                    when "10" => rLC <= databus(7 downto 0);
                    when "11" => rLC <= cADR(7 downto 0);
                    when others => null;
                end case;

                -- P control
                if cP = '1' then
                    rPC <= rPC + 1; 
                end if;

                -- SP control
                case cSP is
                    when "01" => rSP <= rSP + 1;
                    when "10" => rSP <= rSP - 1;
                    when others => null;
                end case;

                -- SEQ
                case cSEQ is
                    when "00000" => uPC <= uPC + 1;
                    when "00001" => uPC <= K1(conv_integer(rIR(15 downto 10)));
                    when "00010" => uPC <= K2(conv_integer(rIR(9 downto 8)));
                    when "00011" => uPC <= "000000000";
                    when "10000" => uPC <= cADR;
                    when "10001" => if fZ = '1' then uPC <= cADR; end if;
                    when "10010" => if fZ = '0' then uPC <= cADR; end if;
                    when "10011" => if fN = '1' then uPC <= cADR; end if;
                    when "10100" => if fN = '0' then uPC <= cADR; end if;
                    when "10101" => if fC = '1' then uPC <= cADR; end if;
                    when "10110" => if fC = '0' then uPC <= cADR; end if;
                    when "10111" => if fO = '1' then uPC <= cADR; end if;
                    when "11000" => if fO = '0' then uPC <= cADR; end if;
                    when "11001" => if fL = '1' then uPC <= cADR; end if;
                    when "11010" => if fL = '0' then uPC <= cADR; end if;
                    when "11011" => if fV = '1' then uPC <= cADR; end if;
                    when "11100" => if fV = '0' then uPC <= cADR; end if;
                    when "11101" => 
                        uPC <= cADR; 
                        SuPC <= uPC+1;
                    when "11110" => uPC <= SuPC;
                    when others => null;
                end case;

                -- FROM BUS
                case cFB is
                    when "0001" => rASR <= databus;
                    when "0010" => rIR <= databus;
                    when "0011" => PrimMem(conv_integer(rASR)) <= databus;
                    when "0100" => rPC <= databus;
                    when "0101" => rDR <= databus;
                    when "0110" => null; -- can't write to uM
                    when "0111" => null; -- can't write to AR
                    when "1000" => rHR <= databus;
                    when "1001" => rSP <= databus;
                    when "1010" => 
                        if cM = '0' then 
                            rGR(conv_integer(rIR(7 downto 4))) <= databus;
                        else
                            rGR(conv_integer(rIR(3 downto 0))) <= databus;
                        end if;
                    --when "1011" => rVR(conv_integer(cM & rIR(7 downto 4))) <= databus;
                    when "1011" =>
                        vr_we <= '1';
                        vr_addr <= cM & rIR(7 downto 4);
                        vr_i <= databus;
                    when others => vr_we <= '0';
                end case;
            end if;
        end if;
    end process;

    -- TO BUS
    with cTB select
    databus <= rASR when "0001",
                rIR when "0010",
                PrimMem(conv_integer(rASR)) when "0011",
                rPC when "0100",
                rDR when "0101",
                --uMem(conv_integer(uPC)) when "0110",
                ARout when "0111",
                rHR when "1000",
                rSP when "1001",
                tempGR when "1010",
                vr_o when "1011",
                X"0000" when others;

    -- M bit
    with cM select
    tempGR <= rGR(conv_integer(rIR(7 downto 4))) when '0',
              rGR(conv_integer(rIR(3 downto 0))) when others;

    --tempVR <= rVR(conv_integer(cM & rIR(7 downto 4)));
    vr_addr <= cM & rIR(7 downto 4);

    -- *****************************
    -- * ALU - TODO                *
    -- *****************************

--    rAR <= rALU(15 downto 0);
--    with uMem(conv_integer(uPC))(31 downto 28) select
--    rALU <= ('0' & databus) when "0001",            -- rAr = databus
--            '0' & X"0000" when "0011",               -- rAR = 0
--            rALU + ('0' & databus) when "0100",     -- rAR = rAR + databus
--            rALU when others;
            
    process(rALU, cALU) begin
	    case cALU is
            when "0001" => ARin <= databus;                         -- rAr = databus
            when "0011" => ARin <= X"0000"; fZ <= '1'; fN <= '0';     -- rAR = 0
            when "0100" => rALU <= STD_LOGIC_VECTOR(unsigned('0' & ARin) + unsigned(databus));   -- ar + databus
                           ARout <= rALU(15 downto 0);
 	                       fC <= rALU(16);

            --when "0101" =>                                                  -- res = |nib1 - nib2|, flag = 1 iff nib2 > nib1
	            --if (ARin >= databus) then
	            --    ARout <= std_logic_vector(unsigned(ARin) - unsigned(databus));
	            --    fO <= '0';
	            --else
	            --    ARout <= std_logic_vector(unsigned(databus) - unsigned(ARin));
	            --    fO <= '1';
	            --end if;
            when others => null;
        end case;
    end process;

end cpu_one;
