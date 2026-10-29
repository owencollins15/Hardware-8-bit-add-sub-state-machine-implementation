-------------------------------------------------------------------------------
-- Lab 5 - Add / Subtract Top Level
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity add_sub is
    port (
        clk      : in std_logic;
        reset    : in std_logic;

        -- 8-bit switch input
        sw       : in std_logic_vector(7 downto 0);

        -- FSM advance button
        next_btn : in std_logic;

        -- Seven-segment displays
        a_bcd      : out std_logic_vector(6 downto 0);
        b_bcd      : out std_logic_vector(6 downto 0);
        result_bcd : out std_logic_vector(6 downto 0);

        -- State LEDs
        leds : out std_logic_vector(3 downto 0)
    );
end add_sub;


architecture structural of add_sub is

    -- Synchronized switch input
    signal sw_sync : std_logic_vector(7 downto 0);

    -- Pushbutton signals
    signal btn_press  : std_logic;
    signal next_pulse : std_logic;

    -- Reset synchronization
    signal reset_pipe : std_logic_vector(1 downto 0)
        := (others => '0');

    signal reset_safe : std_logic;

    -- FSM control signals
    signal load_a   : std_logic;
    signal load_b   : std_logic;
    signal disp_sel : std_logic_vector(1 downto 0);

    -- Operand registers
    signal a_reg : std_logic_vector(7 downto 0);
    signal b_reg : std_logic_vector(7 downto 0);

    -- Arithmetic signals
    signal add_sub_sel : std_logic;
    signal result_sig  : std_logic_vector(8 downto 0);

    -- 12-bit display value
    signal result_padded : std_logic_vector(11 downto 0);

    -- BCD digits
    signal hundreds : std_logic_vector(3 downto 0);
    signal tens     : std_logic_vector(3 downto 0);
    signal ones     : std_logic_vector(3 downto 0);

begin

    --------------------------------------------------
    -- Reset Synchronization
    -- Asynchronous assertion, synchronous release
    --------------------------------------------------

    process(clk, reset)
    begin
        if reset = '1' then
            reset_pipe <= (others => '0');

        elsif rising_edge(clk) then
            reset_pipe <= reset_pipe(0) & '1';

        end if;
    end process;

    reset_safe <= not reset_pipe(1);


    --------------------------------------------------
    -- 8-Bit Switch Synchronizer
    --------------------------------------------------

    U_SW_SYNC : entity work.synchronizer_8bit
        port map (
            clk      => clk,
            reset    => reset_safe,
            async_in => sw,
            sync_out => sw_sync
        );


    --------------------------------------------------
    -- Pushbutton Rising Edge Synchronizer
    --------------------------------------------------

    -- DE1-SoC pushbutton is active low
    btn_press <= not next_btn;

    U_BUTTON : entity work.rising_edge_synchronizer
        port map (
            clk       => clk,
            reset     => reset_safe,
            async_in  => btn_press,
            sync_edge => next_pulse
        );


    --------------------------------------------------
    -- Finite State Machine
    --------------------------------------------------

    U_FSM : entity work.fsm
        port map (
            clk        => clk,
            reset      => reset_safe,
            next_pulse => next_pulse,

            load_a     => load_a,
            load_b     => load_b,

            disp_sel   => disp_sel,
            leds       => leds
        );


    --------------------------------------------------
    -- Operand Registers
    --------------------------------------------------

    U_REG : entity work.op_reg
        port map (
            clk     => clk,
            reset   => reset_safe,

            load_a  => load_a,
            load_b  => load_b,

            sw_sync => sw_sync,

            a_reg   => a_reg,
            b_reg   => b_reg
        );


    --------------------------------------------------
    -- Addition / Subtraction Selection
    --------------------------------------------------

    -- 0 = Addition
    -- 1 = Subtraction

    add_sub_sel <= '1' when disp_sel = "11"
                   else '0';


    --------------------------------------------------
    -- Generic 8-Bit Add/Subtract Component
    --------------------------------------------------

    U_ADD_SUB : entity work.generic_add_sub
        generic map (
            bits => 8
        )
        port map (
            a       => a_reg,
            b       => b_reg,

            add_sub => add_sub_sel,
            result  => result_sig
        );


    --------------------------------------------------
    -- Display Multiplexer
    --------------------------------------------------

    -- 00 = Display input A from switches
    -- 01 = Display input B from switches
    -- 10 = Display sum
    -- 11 = Display difference

    with disp_sel select
        result_padded <=
            "0000" & sw_sync   when "00",
            "0000" & sw_sync   when "01",
            "000" & result_sig when "10",
            "000" & result_sig when "11",
            (others => '0')    when others;


    --------------------------------------------------
    -- Double Dabble
    -- Professor-provided conversion process
    --------------------------------------------------

    bcd1 : process(result_padded)

        variable temp : std_logic_vector(11 downto 0);

        variable bcd : unsigned(15 downto 0)
            := (others => '0');

    begin

        -- Clear BCD variable
        bcd := (others => '0');

        -- Read binary input
        temp(11 downto 0) := result_padded;

        -- Convert binary to BCD
        for i in 0 to 11 loop

            if bcd(3 downto 0) > 4 then
                bcd(3 downto 0) :=
                    bcd(3 downto 0) + 3;
            end if;

            if bcd(7 downto 4) > 4 then
                bcd(7 downto 4) :=
                    bcd(7 downto 4) + 3;
            end if;

            if bcd(11 downto 8) > 4 then
                bcd(11 downto 8) :=
                    bcd(11 downto 8) + 3;
            end if;

            -- Shift BCD left one bit
            bcd := bcd(14 downto 0) & temp(11);

            -- Shift input left one bit
            temp := temp(10 downto 0) & '0';

        end loop;

        -- BCD digit outputs
        ones <= std_logic_vector(
            bcd(3 downto 0)
        );

        tens <= std_logic_vector(
            bcd(7 downto 4)
        );

        hundreds <= std_logic_vector(
            bcd(11 downto 8)
        );

    end process bcd1;


    --------------------------------------------------
    -- Seven-Segment Decoder: Hundreds
    --------------------------------------------------

    U_HUNDREDS : entity work.seven_seg
        port map (
            clk           => clk,
            reset         => reset_safe,

            bcd           => hundreds,
            seven_seg_out => a_bcd
        );


    --------------------------------------------------
    -- Seven-Segment Decoder: Tens
    --------------------------------------------------

    U_TENS : entity work.seven_seg
        port map (
            clk           => clk,
            reset         => reset_safe,

            bcd           => tens,
            seven_seg_out => b_bcd
        );


    --------------------------------------------------
    -- Seven-Segment Decoder: Ones
    --------------------------------------------------

    U_ONES : entity work.seven_seg
        port map (
            clk           => clk,
            reset         => reset_safe,

            bcd           => ones,
            seven_seg_out => result_bcd
        );

end structural;

