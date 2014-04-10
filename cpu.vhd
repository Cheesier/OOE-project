library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

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

	signal rASR : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
	signal rIR : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
	signal rPC : STD_LOGIC_VECTOR(15 downto 0) := X"0000";
	signal rDR : STD_LOGIC_VECTOR(15 downto 0) := X"1004";
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

	type K1_type is array (0 to 63) of std_logic_vector(8 downto 0);
	signal K1 : K1_type := (others=> (others=>'0'));

	type K2_type is array (0 to 3) of std_logic_vector(8 downto 0);
	signal K2 : K2_type := (others=> (others=>'0'));

	type gr_array is array (0 to 15) of std_logic_vector(15 downto 0);
	signal rGR : gr_array := (others=> (others=>'0'));

	--maybe move this to main, should be shared with GPU
	type vr_array is array (0 to 31) of std_logic_vector(15 downto 0);
	signal rVR : vr_array;

begin
	led: leddriver port map (clk, rst, seg, an, rDR);


end cpu_one;
