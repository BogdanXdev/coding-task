-- B Zhukovsky

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testbench is
end entity testbench;

architecture sim of testbench is

  -- Constants
  constant clk_period_a : time := 10 ns; -- 100 MHz
  constant clk_period_b : time := 8 ns;  -- 125 MHz

  -- provide manually 2 random decimals
  constant rand_input_a : std_logic_vector := x"F0FF64FFF000F0FAB9F0FFEF6FF0F";
  constant rand_input_b : std_logic_vector := x"F0FFFFFFFFEEEFEFAF0FFF1FFFF0F";

  -- Signals
  signal clk_a         : std_logic := '0';
  signal clk_b         : std_logic := '0';
  signal clear_a       : std_logic := '0';
  signal rst_n         : std_logic;
  signal a             : std_logic;
  signal b             : std_logic;
  signal b_q           : std_logic;
  signal a_high        : std_logic;
  signal a_and_b       : std_logic;
  signal a_high_amount : std_logic_vector(2 downto 0);
  signal b_q_vector    : std_logic_vector(3 downto 0);
  signal finished      : boolean;
  signal init_finished : boolean;

  -- checker part signals
  signal a_high_amount_check : natural;
  signal a_high_check        : std_logic;

  component top is
    port
    (
      rst_n   : in std_logic;
      clk_a   : in std_logic;
      clear_a : in std_logic;
      a       : in std_logic;
      clk_b   : in std_logic;
      b       : in std_logic;

      a_high_amount : out std_logic_vector(2 downto 0);
      a_high        : out std_logic;
      b_q           : out std_logic;
      b_q_vector    : out std_logic_vector(3 downto 0);
      a_and_b       : out std_logic
    );
  end component;

begin
  -------------------------------------------------------------
  -- init -----------------------------------------------------
  -------------------------------------------------------------
  -- DUT
  dut_inst : component top
    port map
    (
      rst_n, clk_a, clear_a, a, clk_b, b, a_high_amount,
      a_high, b_q, b_q_vector, a_and_b
    );

    clk_aa : process is
    begin
      wait for clk_period_a / 2;
      clk_a <= not clk_a;
    end process clk_aa;

    clk_bb : process is
    begin
      wait for clk_period_b / 2;
      clk_b <= not clk_b;
    end process clk_bb;

    rst_control : process is
    begin
      rst_n <= '0';
      wait for clk_period_a * 4;
      rst_n <= '1';
      wait until finished = true;
    end process rst_control;

    clear_a_control : process is
    begin
      wait for clk_period_a * 10;
      clear_a <= '1';
      wait for clk_period_a * 16;
      clear_a <= '0';
      wait until finished = true;
    end process clear_a_control;
    ------------------------------------------
    -- data generator-------------------------
    ------------------------------------------    
    a_data_gen : process is
    begin
      for i in rand_input_a'range loop
        a <= rand_input_a(i);
        wait for clk_period_a;
      end loop;
    end process a_data_gen;

    b_data_gen : process is
    begin
      for j in rand_input_b'range loop
        b <= rand_input_b(j);
        wait for clk_period_b;
      end loop;
    end process b_data_gen;
    -------------------------------------------------------
    -- self checker----------------------------------------
    -------------------------------------------------------    
    -- a_high_amount
    check_a_high_amount : process is
    begin
      wait until rising_edge(clk_a);
      wait for 1 ns;
      if (clear_a = '1' or rst_n = '0' or a = '0') then
        a_high_amount_check <= 0;
        elsif (a_high_amount_check = 7 and a = '1') then
        a_high_amount_check <= a_high_amount_check;
        else
        a_high_amount_check <= a_high_amount_check + 1;
      end if;
    end process check_a_high_amount;
    process
    begin
      wait until rising_edge(clk_a);
      wait for 2 ns;
      assert (std_logic_vector(to_unsigned(a_high_amount_check, 3)) = a_high_amount)
      report "a_high_amount failure " & time'image(now)
      severity error;
    end process;

    -- a_high
    check_a_high : process
    begin
      wait until rising_edge(clk_a);
      wait for 1 ns;
      if unsigned(a_high_amount) >= 4 then
        a_high_check <= '1';
        else
        a_high_check <= '0';
      end if;
    end process check_a_high;
    process
    begin
      wait until rising_edge(clk_a);
      wait for 2 ns;
      assert a_high_check = a_high
      report "a_high failure " & time'image(now)
      severity error;
    end process;
    -- other checkers next time :)
    -- for this design complexity visual inspection is not that bad
    ------------------------------------------------------
    --time------------------------------------------------
    ------------------------------------------------------
    time_control : process is
    begin
      wait for clk_period_a * 500;
      finished <= true;
      assert false report "Test done." severity note;
      wait;
    end process time_control;

  end architecture sim;