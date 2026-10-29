-------------------------------------------------------------------------------
-- Owen Collins
-- rising edge synchronizer
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;      


entity rising_edge_synchronizer is 

port(
	clk : in std_logic;
	reset : in std_logic;
	async_in : in std_logic;
	sync_edge : out std_logic
);

end rising_edge_synchronizer;
 
 
architecture beh of rising_edge_synchronizer is
 
	signal sync_ff1 : std_logic;
	signal sync_ff2 : std_logic;
	signal prev_ff : std_logic;
 
 begin
 
 process(reset, clk)
	
	begin
 
		if reset = '1' then
			sync_ff1 <= '0';
			sync_ff2 <= '0';
			prev_ff <= '0';
 
 elsif rising_edge(clk) then
			sync_ff1 <= async_in;
			sync_ff2 <= sync_ff1;
			prev_ff <= sync_ff2;
 end if;
 end process;
 
			sync_edge <= sync_ff2 and not prev_ff;
 
 end beh;