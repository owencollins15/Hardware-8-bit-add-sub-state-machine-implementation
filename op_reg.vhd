-------------------------------------------------------------------------------
-- Owen Collins
-- op registers
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity op_reg is
port(
clk: in std_logic;
reset: in std_logic;

load_a: in std_logic;
load_b: in std_logic;

sw_sync: in std_logic_vector(7 downto 0);

a_reg: out std_logic_vector(7 downto 0);
b_reg: out std_logic_vector(7 downto 0)
);
end op_reg;

architecture beh of op_reg is 

signal a_store: std_logic_vector(7 downto 0);
signal b_store: std_logic_vector(7 downto 0);

begin

process (clk, reset)
begin 
if reset = '1' then
a_store <= (others => '0');
b_store <= (others => '0');

elsif rising_edge(clk) then
if load_a = '1'then
a_store <= sw_sync;
end if;

if load_b = '1' then 
b_store <= sw_sync;
end if;

end if;
end process;

a_reg <= a_store;
b_reg <= b_store;

end beh;