-- B Zhukovsky
-- a_high_amount:
--  a_reg for registering  new|^reg                     1cycle system lat
--  a_count for counting            |^cnt2|^cnt1|^cnt0|
--                         cmp if    count+1

-- a_high:
--  1  if   a_count >= 5

-- b_q:
-- b_reg for registering  new|^reg
--      if 1 -> b_q_new <= !b_q_reg

-- b_q_vector:
--  3 downto 0 <-- b_q

-- a and b:
--  a_and_b_reg for registering in "a" domain
--      1.  b ---> synchro 3 flip ---> b_3reg or just 1 reg
--      im concerned about just one clk latency on the waveform picture
--      its not enough for a proper synchronization

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
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
end entity top;

architecture behav of top is

  signal a_new       : std_logic;
  signal a_reg       : std_logic;
  signal b_q_new     : std_logic;
  signal a_and_b_new : std_logic;
  signal a_and_b_reg : std_logic;

  signal a_count_new, a_count_reg : std_logic_vector(2 downto 0);
  signal b_q_vector_new           : std_logic_vector(3 downto 0);

  -- A mechanism to force `b_q_vector` to constant low at compile time.
  signal b_q_vector_reg : std_logic_vector(3 downto 0) := "0000";
  -- A mechanism to force `b_q` to constant low at compile time.
  signal b_q_reg : std_logic := '0';

begin
  -----------------------------------------------------------------
  -- regs
  -----------------------------------------------------------------  
  a_domain : process (clk_a, rst_n, clear_a) is
  begin

    if (rising_edge(clk_a)) then
      if (rst_n = '0') then
        a_reg       <= '0';
        a_and_b_reg <= '0';
        a_count_reg <= (others => '0');
        elsif (clear_a = '1') then
        a_reg       <= a_new;
        a_and_b_reg <= a_and_b_new;
        a_count_reg <= (others => '0');
        else
        a_reg       <= a_new;
        a_and_b_reg <= a_and_b_new;
        a_count_reg <= a_count_new;
      end if;
    end if;

  end process a_domain;

  b_domain : process (clk_b, rst_n) is
  begin
    if (rising_edge(clk_b)) then
      if (rst_n = '0') then
        b_q_reg        <= '0';
        b_q_vector_reg <= (others => '0');
        else
        b_q_reg        <= b_q_new;
        b_q_vector_reg <= b_q_vector_new;
      end if;
    end if;
  end process b_domain;
  ----------------------------------------------------------
  -- assignements
  ----------------------------------------------------------  
  a_new             <= a;
  a_high_amount     <= a_count_reg;
  b_q_vector_new(0) <= b_q_reg;
  b_q               <= b_q_reg;
  b_q_vector        <= b_q_vector_reg;
  a_and_b           <= a_and_b_reg;
  a_and_b_new       <= a and b; -- metastability possible
  -- ideally 1 reg is not enough to resolve possible metastability

  a_high <= '1' when unsigned(a_count_reg) >= 4 else '0';
  -------------------------------------------------------------------
  -- next state logic
  -------------------------------------------------------------------  
  b_q_new <= not b_q_reg when b = '1' else b_q_reg;

  bq_vector : for i in b_q_vector'left downto 1 generate
    b_q_vector_new(i) <= b_q_vector_reg(i - 1);
  end generate bq_vector;

  --   a_count : process (a_reg, a_new, a_count_reg) is
  a_count : process (all) is
  begin
    if ((a_reg = '1' and a_new = '1') or (a_reg = '0' and a_new = '1')) then
      if (a_count_reg = "111") then
        a_count_new <= "111";
        else
        a_count_new <= std_logic_vector(unsigned(a_count_reg) + 1);
      end if;
      else
      a_count_new <= "000";
    end if;
  end process a_count;

end architecture behav;