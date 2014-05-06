library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alu is
    Port (  clk : in STD_LOGIC;
            op : in STD_LOGIC_VECTOR(3 downto 0);
            A, B : in STD_LOGIC_VECTOR(15 downto 0);
            result : out STD_LOGIC_VECTOR(15 downto 0);
            carry, zero, negative, overflow : out STD_LOGIC);
end alu;

architecture alu_one of alu is
    signal value : STD_LOGIC_VECTOR(16 downto 0) := "00000000000000000";
    signal useflag : STD_LOGIC := '0';

begin
    process(A, B, op, value) begin
        case op is
            when "0001" => value <= '0' & B; --databus
                           useflag <= '1';
            when "0011" => value <= "00000000000000000"; --nollställ
                           useflag <= '1';
            when "0100" => value <= STD_LOGIC_VECTOR('0' & unsigned(A) + unsigned(B)); --add
                           useflag <= '1';
            when "0101" => value <= STD_LOGIC_VECTOR('0' & unsigned(A) - unsigned(B)); --sub
                           useflag <= '1';
            when "0110" => value <= '0' & A and B; -- and
                           useflag <= '1';
            when "0111" => value <= '0' & A or B; -- or
                           useflag <= '1';
            when "1000" => value <= STD_LOGIC_VECTOR('0' & unsigned(A) + unsigned(B)); --add noflag
                           useflag <= '0';
            when "1001" => value <= a & '0'; -- ASL/LSL
                           useflag <= '0';
            when "1011" => value <= a(0) & a(15) & a(15 downto 1); -- ASR
                           useflag <= '0';
            when "1101" => value <= a(0) & '0' & a(15 downto 1); -- LSR
                           useflag <= '0';
            when others => useflag <= '0';
        end case;
    end process;
    
    process(clk) begin
        if rising_edge(clk) then
            result   <= value(15 downto 0);
            if useflag = '1' then
                if value(15 downto 0) = X"0000" then
                    zero <= '1';
                else
                    zero <= '0';
                end if;
                if value(16) = '1' then carry <= '1'; end if;
                if value(15) = '1' then negative <= '1'; end if;
                overflow <= (A(15) xnor B(15)) and (A(15) xor value(15)); 
            end if; 
        end if;
    end process;
end alu_one;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cpu is
    Port (clk,rst,step : in  STD_LOGIC;
        seg: out  STD_LOGIC_VECTOR(7 downto 0);
        an : out  STD_LOGIC_VECTOR (3 downto 0);
        led : out STD_LOGIC_VECTOR (7 downto 0);
        vr_we : out STD_LOGIC;
        vr_addr : out STD_LOGIC_VECTOR(4 downto 0);
        vr_i : out STD_LOGIC_VECTOR(15 downto 0);
        vr_o : in STD_LOGIC_VECTOR(15 downto 0);
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

    component alu
        Port (  clk : in STD_LOGIC;
            op : in STD_LOGIC_VECTOR(3 downto 0);
            A, B : in STD_LOGIC_VECTOR(15 downto 0);
            result : out STD_LOGIC_VECTOR(15 downto 0);
            carry, zero, negative, overflow : out STD_LOGIC);
    end component;

    signal databus : STD_LOGIC_VECTOR(15 downto 0) := X"0000";

    -- Registers
    signal rASR : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    signal rIR : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    signal rPC : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    signal rDR : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    signal rAR : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    signal rHR : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    signal rSP : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    signal rLC : STD_LOGIC_VECTOR(7 downto 0) := X"00";

    signal rALU : STD_LOGIC_VECTOR(16 downto 0) := '0' & X"0000";
    signal fADD : STD_LOGIC := '0';

    -- Flags
    signal fZ : STD_LOGIC := '1';
    signal fN : STD_LOGIC := '0';
    signal fC : STD_LOGIC := '0';
    signal fO : STD_LOGIC := '0';
    signal fL : STD_LOGIC := '0';

    -- Primary memory
    type PrimMem_type is array (0 to 2047) of STD_LOGIC_VECTOR(15 downto 0);
    signal PrimMem : PrimMem_type := ( 0=> X"0500",1=> X"fe10",2=> X"0900",3=> X"0001",4=> X"1c00",5=> X"3d00",6=> X"0280",7=> X"2d00",8=> X"0000",9=> X"3400",10=> X"2500",11=> X"0004",12=> X"0000",13=> X"0000",14=> X"0000",15=> X"0000",16=> X"0000",17=> X"0000",18=> X"0000",19=> X"0000",20=> X"0000",21=> X"0000",22=> X"0000",23=> X"0000",24=> X"0000",25=> X"0000",26=> X"0000",27=> X"0000",28=> X"0000",29=> X"0000",30=> X"0000",31=> X"0000",32=> X"0000",33=> X"0000",34=> X"0000",35=> X"0000",36=> X"0000",37=> X"0000",38=> X"0000",39=> X"0000",40=> X"0000",41=> X"0000",42=> X"0000",43=> X"0000",44=> X"0000",45=> X"0000",46=> X"0000",47=> X"0000",48=> X"0000",49=> X"0000",50=> X"0000",51=> X"0000",52=> X"0000",53=> X"0000",54=> X"0000",55=> X"0000",56=> X"0000",57=> X"0000",58=> X"0000",59=> X"0000",60=> X"0000",61=> X"0000",62=> X"0000",63=> X"0000",64=> X"0000",65=> X"0000",66=> X"0000",67=> X"0000",68=> X"0000",69=> X"0000",70=> X"0000",71=> X"0000",72=> X"0000",73=> X"0000",74=> X"0000",75=> X"0000",76=> X"0000",77=> X"0000",78=> X"0000",79=> X"0000",80=> X"0000",81=> X"0000",82=> X"0000",83=> X"0000",84=> X"0000",85=> X"0000",86=> X"0000",87=> X"0000",88=> X"0000",89=> X"0000",90=> X"0000",91=> X"0000",92=> X"0000",93=> X"0000",94=> X"0000",95=> X"0000",96=> X"0000",97=> X"0000",98=> X"0000",99=> X"0000",100=> X"0000",101=> X"0000",102=> X"0000",103=> X"0000",104=> X"0000",105=> X"0000",106=> X"0000",107=> X"0000",108=> X"0000",109=> X"0000",110=> X"0000",111=> X"0000",112=> X"0000",113=> X"0000",114=> X"0000",115=> X"0000",116=> X"0000",117=> X"0000",118=> X"0000",119=> X"0000",120=> X"0000",121=> X"0000",122=> X"0000",123=> X"0000",124=> X"0000",125=> X"0000",126=> X"0000",127=> X"0000",128=> X"0000",129=> X"0000",130=> X"0000",131=> X"0000",132=> X"0000",133=> X"0000",134=> X"0000",135=> X"0000",136=> X"0000",137=> X"0000",138=> X"0000",139=> X"0000",140=> X"0000",141=> X"0000",142=> X"0000",143=> X"0000",144=> X"0000",145=> X"0000",146=> X"0000",147=> X"0000",148=> X"0000",149=> X"0000",150=> X"0000",151=> X"0000",152=> X"0000",153=> X"0000",154=> X"0000",155=> X"0000",156=> X"0000",157=> X"0000",158=> X"0000",159=> X"0000",160=> X"0000",161=> X"0000",162=> X"0000",163=> X"0000",164=> X"0000",165=> X"0000",166=> X"0000",167=> X"0000",168=> X"0000",169=> X"0000",170=> X"0000",171=> X"0000",172=> X"0000",173=> X"0000",174=> X"0000",175=> X"0000",176=> X"0000",177=> X"0000",178=> X"0000",179=> X"0000",180=> X"0000",181=> X"0000",182=> X"0000",183=> X"0000",184=> X"0000",185=> X"0000",186=> X"0000",187=> X"0000",188=> X"0000",189=> X"0000",190=> X"0000",191=> X"0000",192=> X"0000",193=> X"0000",194=> X"0000",195=> X"0000",196=> X"0000",197=> X"0000",198=> X"0000",199=> X"0000",200=> X"0000",201=> X"0000",202=> X"0000",203=> X"0000",204=> X"0000",205=> X"0000",206=> X"0000",207=> X"0000",208=> X"0000",209=> X"0000",210=> X"0000",211=> X"0000",212=> X"0000",213=> X"0000",214=> X"0000",215=> X"0000",216=> X"0000",217=> X"0000",218=> X"0000",219=> X"0000",220=> X"0000",221=> X"0000",222=> X"0000",223=> X"0000",224=> X"0000",225=> X"0000",226=> X"0000",227=> X"0000",228=> X"0000",229=> X"0000",230=> X"0000",231=> X"0000",232=> X"0000",233=> X"0000",234=> X"0000",235=> X"0000",236=> X"0000",237=> X"0000",238=> X"0000",239=> X"0000",240=> X"0000",241=> X"0000",242=> X"0000",243=> X"0000",244=> X"0000",245=> X"0000",246=> X"0000",247=> X"0000",248=> X"0000",249=> X"0000",250=> X"0000",251=> X"0000",252=> X"0000",253=> X"0000",254=> X"0000",255=> X"0000",                                       others=> X"0000");

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
                                    24=>X"00002413",
                                    25=>X"00000600",
                                    26=>X"0000381A",
                                    27=>X"00000600",
                                    28=>X"1A000000",
                                    29=>X"55000600",
                                    30=>X"1B000000",
                                    31=>X"55000600",
                                    32=>X"09103A00",
                                    33=>X"04300000",
                                    34=>X"05420600",
                                    35=>X"00020000",
                                    36=>X"12200000",
                                    37=>X"06800C00",
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
    signal K1 : K1_type := (0=>"000001010", --MOVEV Low
                            1=>"000001010", --MOVEV High
                            2=>"000001001", --MOVE
                            3=>"000001011", --STORE
                            4=>"000001100", --STOREV Low
                            5=>"000001100", --STOREV High
                            6=>"000010000", --ADDV Low
                            7=>"000010000", --ADDV High
                            8=>"000001101", --ADD
                            9=>"000010011", --BRA
                            10=>"000010100", --BCS
                            11=>"000010110", --BEQ
                            12=>"000011000", --BNE
                            13=>"000011010", --WVS
                            14=>"000011110", --CMPV Low
                            15=>"000011110", --CMPV High
                            16=>"000011100", --CMP
                            17=>"000100000", --JSR
                            18=>"000100011", --RTS
                            19=>"000100110", --PUSH
                            20=>"000101000", -- POP
                            others=>"000000000");

    type K2_type is array (0 to 3) of STD_LOGIC_VECTOR(8 downto 0);
    signal K2 : K2_type := (0=>"000000011", --reg-reg
                            1=>"000000100", --imm
                            2=>"000000110", --indir
                            others=>"000000000");

    type gr_array is array (0 to 15) of STD_LOGIC_VECTOR(15 downto 0);
    signal rGR : gr_array := (others=> X"0000");

    signal tempGR : STD_LOGIC_VECTOR(15 downto 0) := X"0000";


    ---------- DEBUG --------
    signal old_step : STD_LOGIC := '0';

begin
    ctrlword <= uMem(conv_integer(uPC));

    
    led_driver: leddriver port map (clk, rst, seg, an, led, rDR, rPC(7 downto 0));
    alu_instance: alu port map(clk, cALU, rAR, databus, rAR, fC, fZ, fN, fO);

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
                    when "10001" => if fZ = '1' then uPC <= cADR; else uPC <= uPC + 1; end if;
                    when "10010" => if fZ = '0' then uPC <= cADR; else uPC <= uPC + 1; end if;
                    when "10011" => if fN = '1' then uPC <= cADR; else uPC <= uPC + 1; end if;
                    when "10100" => if fN = '0' then uPC <= cADR; else uPC <= uPC + 1; end if;
                    when "10101" => if fC = '1' then uPC <= cADR; else uPC <= uPC + 1; end if;
                    when "10110" => if fC = '0' then uPC <= cADR; else uPC <= uPC + 1; end if;
                    when "10111" => if fO = '1' then uPC <= cADR; else uPC <= uPC + 1; end if;
                    when "11000" => if fO = '0' then uPC <= cADR; else uPC <= uPC + 1; end if;
                    when "11001" => if fL = '1' then uPC <= cADR; else uPC <= uPC + 1; end if;
                    when "11010" => if fL = '0' then uPC <= cADR; else uPC <= uPC + 1; end if;
                    when "11011" => if fV = '1' then uPC <= cADR; else uPC <= uPC + 1; end if;
                    when "11100" => if fV = '0' then uPC <= cADR; else uPC <= uPC + 1; end if;
                    when "11101" => 
                        uPC <= cADR; 
                        SuPC <= uPC+1;
                    when "11110" => uPC <= SuPC;
                    when others => null;
                end case;
                
                -- FROM BUS
                if cFB = "1011" then
                    vr_we <= '1';
                else
                    vr_we <= '0';
                end if;

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
                    when "1011" => vr_i <= databus;
                    when others => null;
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
                rAR when "0111",
                rHR when "1000",
                rSP when "1001",
                tempGR when "1010",
                vr_o when "1011",
                X"0000" when others;

    -- M bit
    with cM select
    tempGR <= rGR(conv_integer(rIR(7 downto 4))) when '0',
              rGR(conv_integer(rIR(3 downto 0))) when others;

    vr_addr <= rIR(10) & rIR(7 downto 4);
end cpu_one;
