library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_signed.all;

entity project_reti_logiche is
    port (
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_start : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        o_address : out std_logic_vector(15 downto 0);
        o_done : out std_logic;
        o_en : out std_logic;
        o_we : out std_logic;
        o_data : out std_logic_vector (7 downto 0)
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
    component datapath is
        Port(
                i_clk :         in std_logic;
                i_rst :         in std_logic;
                i_data :        in std_logic_vector(7 downto 0);
                o_data :        out std_logic_vector (7 downto 0);

                Rend_sel        :   in STD_LOGIC;
                Rend_load       :   in STD_LOGIC;
                
                RegSSP_sel      :   in STD_LOGIC;
                RegSSP_load     :   in STD_LOGIC;
                RegSS_load      :   in STD_LOGIC;
                Rout_load       :   in STD_LOGIC;
                out_sel         :   in STD_LOGIC;
                o_end           :   out STD_LOGIC
        );
    end component;


    signal Rend_sel        :   STD_LOGIC;
    signal Rend_load       :   STD_LOGIC;
    
    signal RegSSP_sel      :   STD_LOGIC;
    signal RegSSP_load     :   STD_LOGIC;
    signal RegSS_load      :   STD_LOGIC;
    signal Rout_load       :   STD_LOGIC;
    signal out_sel         :   STD_LOGIC;
    signal o_end           :   STD_LOGIC;

type State is (
    START,
    READ_LENGTH,
    WAIT_READ_LENGTH,
    FIX_COUNT,
    READ_BYTE,
    WAIT_READ_BYTE,
    WRITE_BYTE1,
    WAIT_WRITE_BYTE1,
    WRITE_BYTE2,
    WAIT_WRITE_BYTE2,
    DONE);

signal cur_state, next_state : State;

--implementazione counter-------------------------------------
signal Rcounter1_sel    :   STD_LOGIC;
signal Rcounter1_load   :   STD_LOGIC;
signal mux_counter1     :   STD_LOGIC_VECTOR(15 downto 0);
signal o_regCOUNTER1    :   STD_LOGIC_VECTOR(15 downto 0);
signal add              :   STD_LOGIC_VECTOR(15 downto 0);
--------------------------------------------------------------

begin
    DATAPATH0 : datapath port map(
        i_clk,
        i_rst,
        i_data,
        o_data,
        
        Rend_sel,
        Rend_load,
        
        RegSSP_sel,
        RegSSP_load,
        RegSS_load,
        Rout_load,
        out_sel,
        o_end
    );
    
    
    process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            cur_state <= START;
        elsif rising_edge(i_clk) then
            cur_state <= next_state;
        end if;
    end process;
    
    process(cur_state, i_start, o_end)
    begin
        next_state <= cur_state;
        case cur_state is
            
            when START =>
                if i_start = '1' then
                    next_state <= READ_LENGTH;
                else next_state <= START;
                end if;
                
            when READ_LENGTH =>
                next_state <= WAIT_READ_LENGTH;
            
            when WAIT_READ_LENGTH =>
                next_state <= FIX_COUNT;
                       
            when FIX_COUNT =>
                if o_end = '1' then
                    next_state <= DONE;
                else
                    next_state <= READ_BYTE;
                end if;
                
            when READ_BYTE =>
                next_state <= WAIT_READ_BYTE;
                       
            when WAIT_READ_BYTE =>
                next_state <= WRITE_BYTE1;
                       
            when WRITE_BYTE1 =>
                next_state <= WAIT_WRITE_BYTE1;
                       
            when WAIT_WRITE_BYTE1 => 
                next_state <= WRITE_BYTE2;
                       
            when WRITE_BYTE2 =>
                next_state <= WAIT_WRITE_BYTE2;
                       
            when WAIT_WRITE_BYTE2 =>
                if o_end = '1' then
                    next_state <= DONE;
                else
                    next_state <= READ_BYTE;
                end if;
                       
            when DONE =>
                if i_start = '0' then
                    next_state <= START;
                else
                    next_state <= DONE;
                end if;
        end case;
    end process;
    
    process(cur_state)
    begin
        o_address <= "0000000000000000";
        o_done <= '0';
        o_en <= '0';
        o_we <= '0';
        
        Rcounter1_sel <= '0';
        Rcounter1_load <= '0';
        
        Rend_sel <= '0';
        Rend_load <= '0';
        
        RegSSP_sel <= '0';
        RegSSP_load <= '0';
        RegSS_load <= '0';
        Rout_load <= '0';
        out_sel <= '0';
        
        case cur_state is
            when START =>
            
            when READ_LENGTH =>
                --inizializzazione counter
                Rcounter1_sel <= '0';
                Rcounter1_load <= '1';
                --inizializzazione registri SSP
                RegSSP_sel <= '0';
                RegSSP_load <= '1';
                --inizializzazione del resto
                o_address <= "0000000000000000";
                o_en <= '1';
                o_we <= '0';
            
            when WAIT_READ_LENGTH =>
                o_address <= "0000000000000000";
                o_en <= '1';
                o_we <= '0';
                Rend_sel <= '0';
                Rend_load <= '1';
            
            when FIX_COUNT =>
                Rcounter1_sel <= '1';
                Rcounter1_load <= '1';
                Rend_sel<='1';
                Rend_load<='1';
            
            when READ_BYTE =>
                o_address <= "0000000000000000" + o_regCOUNTER1;
                o_en <= '1';
                o_we <= '0';
            
            when WAIT_READ_BYTE =>
                 o_address <= "0000000000000000" + o_regCOUNTER1;
                 o_en <= '1';
                 o_we <= '0';
                 RegSS_load <= '1';
                 
            when WRITE_BYTE1 =>
                o_address <= "0000001111101000" + o_regCOUNTER1 + o_regCOUNTER1 - "0000000000000010";
                o_we <= '1';
                Rout_load <= '1';
            
            when WAIT_WRITE_BYTE1 =>
                o_address <= "0000001111101000" + o_regCOUNTER1 + o_regCOUNTER1 - "0000000000000010";
                o_en <= '1';
                o_we <= '1';
                out_sel <= '1';
            
            when WRITE_BYTE2 =>
                o_address <= "0000001111101000" + o_regCOUNTER1 + o_regCOUNTER1 - "0000000000000001";
                o_en <= '1';
            
            when WAIT_WRITE_BYTE2 =>
                o_address <= "0000001111101000" + o_regCOUNTER1 + o_regCOUNTER1 - "0000000000000001";
                o_en <= '1';
                o_we <= '1';
                out_sel <= '0';
                --decremento Rend
                Rend_sel <= '1';
                Rend_load <= '1';
                --incremento counter
                Rcounter1_sel <= '1';
                Rcounter1_load <= '1';
                --preparazione registri SSP
                RegSSP_sel <= '1';
                RegSSP_load <= '1';
            
            when DONE =>
                o_done <= '1';
            
        end case;
    end process;
    
    --implementazione counter----------------------
    Rcounter: process(i_clk, i_rst)
    begin
        if i_rst='1' then
            o_regCOUNTER1 <= "0000000000000000";
        elsif rising_edge(i_clk) then
            if Rcounter1_load = '1' then
                o_regCOUNTER1 <= mux_counter1;
            end if;
        end if;
    end process;
    
    with Rcounter1_sel select
        mux_counter1 <=  add when '1',
                        "0000000000000000" when '0',
                        "XXXXXXXXXXXXXXXX" when others;
        
    add <= o_regCOUNTER1 + "0000000000000001";
    ---------------------------------------------------

end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity datapath is
    Port (
        i_clk :         in std_logic;
        i_rst :         in std_logic;
        i_data :        in std_logic_vector(7 downto 0);
        o_data :        out std_logic_vector (7 downto 0);
        
        Rend_sel        :   in STD_LOGIC;
        Rend_load       :   in STD_LOGIC;
        
        RegSSP_sel      :   in STD_LOGIC;
        RegSSP_load     :   in STD_LOGIC;
        RegSS_load      :   in STD_LOGIC;
        Rout_load       :   in STD_LOGIC;
        out_sel         :   in STD_LOGIC;
        o_end           :   out STD_LOGIC
    );
end datapath;

architecture Behavioral of datapath is

signal o_regSS  : STD_LOGIC_VECTOR(7 downto 0);
signal o_regSSP : STD_LOGIC_VECTOR(1 downto 0);
signal o_muxSSP : STD_LOGIC_VECTOR(1 downto 0);
signal f_xor    : STD_LOGIC_VECTOR(15 downto 0);
signal o_regOUT : STD_LOGIC_VECTOR(15 downto 0);
signal o_regEND : STD_LOGIC_VECTOR(7 downto 0);
signal mux_end  : STD_LOGIC_VECTOR(7 downto 0);
signal sub      : STD_LOGIC_VECTOR(7 downto 0);

begin

    --parte1

    RegSS: process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            o_regSS <= "00000000";
        elsif rising_edge(i_clk) then
            if RegSS_load = '1' then
                o_regSS <= i_data;
            end if;
        end if;
    end process;
    
    RegSSP: process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            o_regSSP <= "00";
        elsif rising_edge(i_clk) then
            if RegSSP_load = '1' then
                o_regSSP <= o_muxSSP;
            end if;
        end if;
    end process;
    
    with RegSSP_sel select
        o_muxSSP <= o_regSS(1 downto 0) when '1',
                    "00" when '0',
                    "XX" when others;
    
    f_xor(0) <= o_regSS(2) xor o_regSS(1) xor o_regSS(0);
    f_xor(1) <= o_regSS(2) xor o_regSS(0);
    f_xor(2) <= o_regSS(3) xor o_regSS(2) xor o_regSS(1);
    f_xor(3) <= o_regSS(3) xor o_regSS(1);
    f_xor(4) <= o_regSS(4) xor o_regSS(3) xor o_regSS(2);
    f_xor(5) <= o_regSS(4) xor o_regSS(2);
    f_xor(6) <= o_regSS(5) xor o_regSS(4) xor o_regSS(3);
    f_xor(7) <= o_regSS(5) xor o_regSS(3);
    f_xor(8) <= o_regSS(6) xor o_regSS(5) xor o_regSS(4);
    f_xor(9) <= o_regSS(6) xor o_regSS(4);
    f_xor(10) <= o_regSS(7)xor o_regSS(6) xor o_regSS(5);
    f_xor(11) <= o_regSS(7) xor o_regSS(5);
    f_xor(12) <= o_regSSP(0) xor o_regSS(7) xor o_regSS(6);
    f_xor(13) <= o_regSSP(0) xor o_regSS(6);
    f_xor(14) <= o_regSSP(1) xor o_regSSP(0) xor o_regSS(7);
    f_xor(15) <= o_regSSP(1) xor o_regSS(7);
    
    RegOUT: process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            o_regOUT <= "0000000000000000";
        elsif rising_edge(i_clk) then
            if Rout_load = '1' then
                o_regOUT <= f_xor;
            end if;
        end if;
    end process;
        
    with out_sel select
        o_data <=   o_regOUT(15 downto 8) when '1',
                    o_regOUT(7 downto 0) when '0',
                    "XXXXXXXX" when others;
                    
   --parte 2
    
    with Rend_sel select
        mux_end <=    i_data when '0',
                      sub when '1',
                      "XXXXXXXX" when others;
                        
    RegEND: process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            o_regEND <= "00000001";
        elsif rising_edge(i_clk) then
            if Rend_load = '1' then
                o_regEND <= mux_end;
            end if;
        end if;
    end process;
    
    sub <= o_regEND - "0000001";
    
    o_end <= '1' when (o_regEND = "00000000") else '0';

end Behavioral;
