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
            when "0101" => value <= ('0' & A) - B; --sub
                           useflag <= '1';
            when "0110" => value <= '0' & A and '0' & B; -- and
                           useflag <= '1';
            when "0111" => value <= '0' & A or '0' & B; -- or
                           useflag <= '1';
            when "1000" => value <= STD_LOGIC_VECTOR('0' & unsigned(A) + unsigned(B)); --add noflag
                           useflag <= '0';
            when "1001" => value <= a & '0'; -- ASL/LSL
                           useflag <= '1';
            when "1011" => value <= a(0) & a(15) & a(15 downto 1); -- ASR
                           useflag <= '1';
            when "1101" => value <= a(0) & '0' & a(15 downto 1); -- LSR
                           useflag <= '1';
            when others => useflag <= '0';
        end case;
    end process;
    
    process(clk) begin
        if rising_edge(clk) then
            result <= value(15 downto 0);
            if useflag = '1' then
                if value(15 downto 0) = X"0000" then
                    zero <= '1';
                else
                    zero <= '0';
                end if;
                if value(16) = '1' then carry <= '1';
                else carry <= '0'; 
                end if;
                if value(15) = '1' then negative <= '1'; 
                else negative <= '0'; 
                end if;
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
    Port (clk,rst : in  STD_LOGIC;
        sw: in STD_LOGIC_VECTOR(7 downto 0);
        seg: out  STD_LOGIC_VECTOR(7 downto 0);
        an : out  STD_LOGIC_VECTOR (3 downto 0);
        led : out STD_LOGIC_VECTOR (7 downto 0);
        vr_we : out STD_LOGIC;
        vr_addr : out STD_LOGIC_VECTOR(4 downto 0);
        vr_i : out STD_LOGIC_VECTOR(15 downto 0);
        vr_o : in STD_LOGIC_VECTOR(15 downto 0);
        fV: in STD_LOGIC;
        up, right, down, left : in STD_LOGIC);
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
        Port (clk : in STD_LOGIC;
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

    -- Flags
    signal fZ : STD_LOGIC := '1';
    signal fN : STD_LOGIC := '0';
    signal fC : STD_LOGIC := '0';
    signal fO : STD_LOGIC := '0';
    signal fL : STD_LOGIC := '0';

    -- Primary memory
    type PrimMem_type is array (0 to 2047) of STD_LOGIC_VECTOR(15 downto 0);
    signal PrimMem : PrimMem_type := (0=> X"0100",1=> X"0000",2=> X"0110",3=> X"0040",4=> X"0120",5=> X"0001",6=> X"0510",7=> X"001e",8=> X"0500",9=> X"001f",10=> X"0500",11=> X"0020",12=> X"0500",13=> X"0021",14=> X"0500",15=> X"0022",16=> X"0500",17=> X"0000",18=> X"0500",19=> X"0024",20=> X"0500",21=> X"0025",22=> X"0500",23=> X"0026",24=> X"0520",25=> X"0027",26=> X"0520",27=> X"0028",28=> X"0d00",29=> X"0029",30=> X"0000",31=> X"0000",32=> X"0000",33=> X"0000",34=> X"0000",35=> X"0000",36=> X"0000",37=> X"0000",38=> X"0000",39=> X"0000",40=> X"0000",41=> X"3500",42=> X"07ff",43=> X"2500",44=> X"003e",45=> X"2500",46=> X"006a",47=> X"2500",48=> X"00a1",49=> X"2500",50=> X"00be",51=> X"0220",52=> X"0022",53=> X"0230",54=> X"0026",55=> X"0240",56=> X"0025",57=> X"0250",58=> X"0021",59=> X"1c00",60=> X"0d00",61=> X"002b",62=> X"2d00",63=> X"0000",64=> X"2d00",65=> X"0000",66=> X"0200",67=> X"8001",68=> X"0210",69=> X"8003",70=> X"2001",71=> X"4d00",72=> X"0055",73=> X"1500",74=> X"005f",75=> X"0110",76=> X"0001",77=> X"0510",78=> X"0026",79=> X"0110",80=> X"0001",81=> X"0510",82=> X"0025",83=> X"0d00",84=> X"0065",85=> X"0110",86=> X"0001",87=> X"0510",88=> X"0026",89=> X"0110",90=> X"0000",91=> X"0510",92=> X"0025",93=> X"0d00",94=> X"0065",95=> X"0110",96=> X"0000",97=> X"0510",98=> X"0026",99=> X"0d00",100=> X"0065",101=> X"3100",102=> X"0000",103=> X"3100",104=> X"0000",105=> X"2800",106=> X"2d00",107=> X"0000",108=> X"2d00",109=> X"0000",110=> X"0200",111=> X"0021",112=> X"2200",113=> X"0025",114=> X"1500",115=> X"0076",116=> X"1900",117=> X"007e",118=> X"0200",119=> X"0022",120=> X"0a00",121=> X"0026",122=> X"0500",123=> X"0022",124=> X"0d00",125=> X"0092",126=> X"0200",127=> X"0022",128=> X"3a00",129=> X"0026",130=> X"4d00",131=> X"0088",132=> X"0500",133=> X"0022",134=> X"0d00",135=> X"0092",136=> X"5600",137=> X"0022",138=> X"0500",139=> X"0022",140=> X"5600",141=> X"0021",142=> X"0900",143=> X"0001",144=> X"0500",145=> X"0021",146=> X"0200",147=> X"0022",148=> X"2100",149=> X"0003",150=> X"4d00",151=> X"009c",152=> X"0100",153=> X"0003",154=> X"0500",155=> X"0022",156=> X"3100",157=> X"0000",158=> X"3100",159=> X"0000",160=> X"2800",161=> X"2d00",162=> X"0000",163=> X"2d00",164=> X"0000",165=> X"2d00",166=> X"0000",167=> X"0200",168=> X"0022",169=> X"0210",170=> X"001e",171=> X"0280",172=> X"0021",173=> X"2180",174=> X"0001",175=> X"1900",176=> X"00b4",177=> X"0810",178=> X"0d00",179=> X"00b5",180=> X"3810",181=> X"0510",182=> X"001e",183=> X"3100",184=> X"0000",185=> X"3100",186=> X"0000",187=> X"3100",188=> X"0000",189=> X"2800",190=> X"2d00",191=> X"0000",192=> X"0200",193=> X"001e",194=> X"0500",195=> X"9000",196=> X"0200",197=> X"001f",198=> X"0500",199=> X"9001",200=> X"3100",201=> X"0000",202=> X"2800",
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
                                    10=>X"05100000",
                                    11=>X"0A300600",
                                    12=>X"15000000",
                                    13=>X"4A000000",
                                    14=>X"07A00600",
                                    15=>X"05400600",
                                    16=>X"00002A0F",
                                    17=>X"00000600",
                                    18=>X"0000220F",
                                    19=>X"00000600",
                                    20=>X"0000240F",
                                    21=>X"00000600",
                                    22=>X"00003816",
                                    23=>X"00000600",
                                    24=>X"1A000000",
                                    25=>X"55000600",
                                    26=>X"09100000",
                                    27=>X"04300000",
                                    28=>X"05420600",
                                    29=>X"00010000",
                                    30=>X"09100000",
                                    31=>X"03400600",
                                    32=>X"09100000",
                                    33=>X"0A320600",
                                    34=>X"00010000",
                                    35=>X"09100000",
                                    36=>X"03A00600",
                                    37=>X"05900600",
                                    38=>X"1A000000",
                                    39=>X"55000000",
                                    40=>X"07A00600",
                                    41=>X"05008000",
                                    42=>X"1A000000",
                                    43=>X"D0004000",
                                    44=>X"0000322B",
                                    45=>X"07A00600",
                                    46=>X"05008000",
                                    47=>X"1A000000",
                                    48=>X"90004000",
                                    49=>X"00003230",
                                    50=>X"07A00600",
                                    51=>X"15000000",
                                    52=>X"6A000000",
                                    53=>X"07A00600",
                                    54=>X"15000000",
                                    55=>X"7A000000",
                                    56=>X"07A00600",
                                    57=>X"04180000",
                                    58=>X"13000000",
                                    59=>X"4A040000",
                                    60=>X"07100000",
                                    61=>X"03500200",
                                    62=>X"0000260F",
                                    63=>X"00000600",
                                    64=>X"0000280F",
                                    65=>X"00000600",
                                    66=>X"30000000",
                                    67=>X"55000000",
                                    68=>X"07A00600",
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
                            1=>"000001010", --STORE
                            2=>"000001100", --ADD
                            3=>"000001111", --BRA
                            4=>"000010000", --BCS
                            5=>"000010010", --BEQ
                            6=>"000010100", --BNE
                            7=>"000010110", --WVS
                            8=>"000011000", --CMP
                            9=>"000011010", --JSR
                            10=>"000011101", --RTS
                            11=>"000100000", --PUSH
                            12=>"000100010", --POP
                            13=>"000100101", --SSP
                            14=>"000100110", --SUB
                            15=>"000101001", --LSR
                            16=>"000101110", --LSL
                            17=>"000110011", --AND
                            18=>"000110110", --OR
                            19=>"000111110", --BMI
                            20=>"001000000", --BPL
                            21=>"001000010", --INV
                            others=>"111111111"); --HULT

    type K2_type is array (0 to 3) of STD_LOGIC_VECTOR(8 downto 0);
    signal K2 : K2_type := (0=>"000000011", --reg-reg
                            1=>"000000100", --imm
                            2=>"000000110", --indir
                            3=>"000111001", --index
                            others=>"000000000");

    type gr_array is array (0 to 15) of STD_LOGIC_VECTOR(15 downto 0);
    signal rGR : gr_array := (others=> X"0000");

    signal tempGR : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    signal tempPM : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    signal tempMM : STD_LOGIC_VECTOR(15 downto 0) := X"0000";


    ---------- DEBUG --------
    signal old_step : STD_LOGIC := '0';

begin
    ctrlword <= uMem(conv_integer(uPC));

    led_driver: leddriver port map (clk, rst, seg, an, led, rGR(2), rGR(5)(0) & rGR(4)(0) & "00000" & rGR(3)(0)); --rGR(2) 7-seg, rGR(3) leds
    --led_driver: leddriver port map (clk, rst, seg, an, led, rGR(2), rGR(5)(7 downto 0)); --rGR(2) 7-seg, rGR(3) leds
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
                    when "01" => rLC <= rLC - 1;
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
                    when "11111" => null;
                    when others => null;
                end case;
                
                -- FROM BUS
                case cFB is
                    when "0001" => rASR <= databus;
                    when "0010" => rIR <= databus;
                    when "0011" => 
                        if (rASR(15) = '0') then
                            PrimMem(conv_integer(rASR)) <= databus;
                        elsif (rASR(15 downto 12) = X"9") then -- VR
                            vr_i <= databus;
                        end if;
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
                    when others => null;
                end case;
            end if;
        end if;
    end process;

    with rLC select
    fL <= '0' when X"00",
          '1' when others;

    --process(cFB, rASR, databus) begin
    process(clk) begin
        if rising_edge(clk) then
            if cFB = "0011" and rASR(15 downto 12) = X"9" then -- 9xxx address
                vr_we <= '1';
                --vr_i <= databus;
            else
                vr_we <= '0';
            end if;
        end if;
    end process;

    vr_addr <= rASR(4 downto 0);

    -- TO BUS
    with cTB select
    databus <= rASR when "0001",
                rIR when "0010",
                tempPM when "0011", -- PM/MM
                rPC when "0100",
                rDR when "0101",
                --uMem(conv_integer(uPC)) when "0110",
                rAR when "0111",
                rHR when "1000",
                rSP when "1001",
                tempGR when "1010",
                --vr_o when "1011",
                X"0000" when others;

    -- PM/MemMap
    with rASR(15) select
    tempPM <= PrimMem(conv_integer(rASR)) when '0',
              tempMM when others;

    -- MemMap
    with rASR select
    tempMM <= "000000000000000" & up when X"8000",
              "000000000000000" & right when X"8001",
              "000000000000000" & down when X"8002",
              "000000000000000" & left when X"8003",
              X"00" & sw when X"8004",
              --X"00" & ledval when X"A000",
              --value when X"A001",
              vr_o when X"9000",vr_o when X"9001",vr_o when X"9002",vr_o when X"9003",
              vr_o when X"9004",vr_o when X"9005",vr_o when X"9006",vr_o when X"9007",
              vr_o when X"9008",vr_o when X"9009",vr_o when X"900A",vr_o when X"900B",
              vr_o when X"900C",vr_o when X"900D",vr_o when X"900E",vr_o when X"900F",
              vr_o when X"9010",vr_o when X"9011",vr_o when X"9012",vr_o when X"9013",
              vr_o when X"9014",vr_o when X"9015",vr_o when X"9016",vr_o when X"9017",
              vr_o when X"9018",vr_o when X"9019",vr_o when X"901A",vr_o when X"901B",
              vr_o when X"901C",vr_o when X"901D",vr_o when X"901E",vr_o when X"901F",
              X"EEEE" when others;

    -- M bit
    with cM select
    tempGR <= rGR(conv_integer(rIR(7 downto 4))) when '0',
              rGR(conv_integer(rIR(3 downto 0))) when others;

end cpu_one;
