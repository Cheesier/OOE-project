library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity cpu is
    Port ( clk,rst : in  STD_LOGIC;
        seg: out  STD_LOGIC_VECTOR(7 downto 0);
        an : out  STD_LOGIC_VECTOR (3 downto 0));
end cpu;

architecture cpu_one of cpu is
    component leddriver
        Port ( clk,rst : in  STD_LOGIC;
           seg : out  STD_LOGIC_VECTOR(7 downto 0);
           an : out  STD_LOGIC_VECTOR (3 downto 0);
           value : in  STD_LOGIC_VECTOR (15 downto 0));
    end component;

    signal databus : STD_LOGIC_VECTOR(15 downto 0) := X"0000";

    signal rASR : STD_LOGIC_VECTOR(15 downto 0) := X"2222";
    signal rIR : STD_LOGIC_VECTOR(15 downto 0) := X"0300";
    signal rPC : STD_LOGIC_VECTOR(15 downto 0) := X"0010";
    signal rDR : STD_LOGIC_VECTOR(15 downto 0) := X"1111";
    signal rAR : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    signal rHR : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
    signal rSP : STD_LOGIC_VECTOR(15 downto 0) := X"0000";

    signal fV : STD_LOGIC := '0';
    signal fZ : STD_LOGIC := '1';
    signal fN : STD_LOGIC := '0';
    signal fC : STD_LOGIC := '0';
    signal fO : STD_LOGIC := '0';
    signal fL : STD_LOGIC := '0';
    signal rLC : STD_LOGIC_VECTOR(7 downto 0) := X"00";

    
    signal uPC : STD_LOGIC_VECTOR(8 downto 0) := (others=>'0');
    signal SuPC : STD_LOGIC_VECTOR(8 downto 0) := (others=>'0');

    type K1_type is array (0 to 63) of std_logic_vector(8 downto 0);
    signal K1 : K1_type := (others=> (others=>'0'));

    type K2_type is array (0 to 3) of std_logic_vector(8 downto 0);
    signal K2 : K2_type := (others=> (others=>'0'));

    type gr_array is array (0 to 15) of std_logic_vector(15 downto 0);
    signal rGR : gr_array := (others=> (others=>'0'));

    --maybe move this to main, should be shared with GPU
    type vr_array is array (0 to 31) of std_logic_vector(15 downto 0);
    signal rVR : vr_array;

    signal uRow : STD_LOGIC_VECTOR(31 downto 0) := X"00080000";

begin
    led: leddriver port map (clk, rst, seg, an, rPC);


    -- *****************************
    -- * CONTROL UNIT              *
    -- *****************************
    process(clk) begin
        if rising_edge(clk) then
            -- uPC control
            case uRow(13 downto 9) is
                when "00000" => uPC <= uPC + 1;
                when "00001" => uPC <= K1(conv_integer(rIR(15 downto 10)));
                when "00010" => uPC <= K2(conv_integer(rIR(9 downto 8)));
                when "00011" => uPC <= (others => '0');
                when others => null;
            end case;

            -- P control
            if uRow(19) = '1' then
                rPC <= rPC + 1;
            end if;

            -- SP control
            case uRow(17 downto 16) is
                when "01" => rSP <= rSP + 1;
                when "10" => rSP <= rSP - 1;
                when others => null;
            end case;

        end if;
    end process;

    -- *****************************
    -- * BUS HANDLER               *
    -- *****************************
    process(clk) begin
        if rising_edge(clk) then
            -- TO BUS
            case uRow(27 downto 24) is
                when "0001" => databus <= rASR;
                when "0010" => databus <= rIR;
                when "0011" => null; -- PM
                when "0100" => databus <= rPC;
                when "0101" => databus <= rDR;
                when "0110" => null; -- uM
                when "0111" => databus <= rAR;
                when "1000" => databus <= rHR;
                when "1001" => databus <= rSP;
                --when "1010" => databus <= rGR; -- GR mux
                --when "1011" => databus <= rVR; -- VR mux
                when others => null;
            end case;

            -- FROM BUS
            case uRow(23 downto 20) is
                when "0001" => rASR <= databus;
                when "0010" => rIR <= databus;
                when "0011" => null; -- PM
                when "0100" => rPC <= databus;
                when "0101" => rDR <= databus;
                when "0110" => null; -- uM
                when "0111" => null; -- AR
                when "1000" => rHR <= databus;
                when "1001" => rSP <= databus;
                --when "1010" => rGR <= databus; -- GR mux
                --when "1011" => rVR <= databus; -- GR mux
                when others => null;
            end case;
        end if;
    end process;


end cpu_one;
