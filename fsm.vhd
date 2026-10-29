--------------------------------------------------------------------------------------
-- Owen Collins
-- FSM
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity fsm is
    port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        next_pulse : in  std_logic;

        load_a     : out std_logic;
        load_b     : out std_logic;

        disp_sel   : out std_logic_vector(1 downto 0);
        leds       : out std_logic_vector(3 downto 0)
    );
end fsm;

architecture beh of fsm is

    -- Four FSM states
    type state_type is (
        input_a,
        input_b,
        disp_sum,
        disp_diff
    );

    signal current_state : state_type := input_a;

begin

    -- async reset
    process(clk, reset)
    begin

        if reset = '1' then
            current_state <= input_a;

        elsif rising_edge(clk) then

            if next_pulse = '1' then

                case current_state is

                    when input_a =>
                        current_state <= input_b;

                    when input_b =>
                        current_state <= disp_sum;

                    when disp_sum =>
                        current_state <= disp_diff;

                    when disp_diff =>
                        current_state <= input_a;

                end case;

            end if;

        end if;

    end process;


    -- Register load signals
    load_a <= '1' when
        current_state = input_a and
        next_pulse = '1' and
        reset = '0'
        else '0';

    load_b <= '1' when
        current_state = input_b and
        next_pulse = '1' and
        reset = '0'
        else '0';


    -- Display selection
    with current_state select
        disp_sel <=
            "00" when input_a,
            "01" when input_b,
            "10" when disp_sum,
            "11" when disp_diff;


    -- State LEDs
    with current_state select
        leds <=
            "0001" when input_a,
            "0010" when input_b,
            "0100" when disp_sum,
            "1000" when disp_diff;

end beh;
