-------------------------------------------------------------------------------
-- Owen Collins
-- generic add_sub
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity generic_add_sub is
  generic (
    bits    : integer := 8
  );
  port (
    a       : in  std_logic_vector(bits-1 downto 0);
    b       : in  std_logic_vector(bits-1 downto 0);
    add_sub : in std_logic;
    result    : out std_logic_vector(bits downto 0)
  );
end entity generic_add_sub;

architecture beh of generic_add_sub is

signal a_ext   : unsigned(bits downto 0);
signal b_ext  : unsigned(bits downto 0);

begin

  -- Add guard bit
  a_ext <= unsigned('0' & a);
  b_ext <= unsigned('0' & b);

  process(a_ext, b_ext, add_sub)
  begin

    if add_sub = '0' then

      -- Addition
      result <= std_logic_vector(a_ext + b_ext);

    else

      -- Subtraction
      result <= std_logic_vector(a_ext - b_ext);

    end if;

  end process;

end beh;
