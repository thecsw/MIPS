LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.my_package.ALL;

ENTITY CU IS
   PORT( 
      Instr      : IN     std_logic_vector (n_bits_instr - 1 DOWNTO 0);
      ALUControl : OUT    std_logic_vector (n_bits_of(n_functions_alu) - 1 DOWNTO 0);
      RegDst     : OUT    std_logic;
      ALUSrc     : OUT    std_logic;
      MemToReg   : OUT    std_logic;
      RegWrite   : OUT    std_logic;
      MemWrite   : OUT    std_logic; 
      BEQ        : OUT    std_logic;
      J          : OUT    std_logic;
      BNE        : OUT    std_logic;
      Jal        : OUT    std_logic;      
      Jr         : OUT    std_logic
   );
END CU;

ARCHITECTURE behav OF CU IS

	SIGNAL opcode : NATURAL RANGE 0 TO (2**(opcode_end - opcode_start + 1) - 1);
	SIGNAL funct  : NATURAL RANGE 0 TO (2**(funct_end - funct_start + 1) - 1);
	SIGNAL ALUControl_int : NATURAL RANGE 0 TO (n_functions_alu - 1);

BEGIN

   -- **************************** --
   -- DO NOT MODIFY or CHANGE the ---
   -- code template provided above --
   -- **************************** --
   
   ----- insert your code here ------

   opcode <= TO_INTEGER(UNSIGNED(Instr(opcode_end DOWNTO opcode_start)));
   funct <= TO_INTEGER(UNSIGNED(Instr(funct_end DOWNTO funct_start)));
   ALUControl  <= STD_LOGIC_VECTOR(TO_UNSIGNED(ALUControl_int, ALUControl'length));
   
   ---------------------------------------------------------------------------
   process1: PROCESS(opcode, funct)
   ---------------------------------------------------------------------------
   BEGIN
	-- Default Values --
	ALUControl_int <= 0;
	RegDst <= '0';
	ALUSrc <= '0';
	MemToReg <= '0';
	RegWrite <= '0';
	MemWrite <= '0';
	BEQ <= '0';
        J <= '0';
        BNE <= '0';
        Jal <= '0';
        Jr <= '0';
        case opcode is
		when 0 =>                     -- R-Type
            case funct is
                when 36 =>            -- R-Type, AND
                    ALUControl_int <= 0;
                    RegDst <= '1';
                    RegWrite <= '1';
                when 37 =>            -- R-Type, OR
                    ALUControl_int <= 1;
                    RegDst <= '1';
                    RegWrite <= '1';
                when 32 =>            -- R-Type, add
                    ALUControl_int <= 2;
                    RegDst <= '1';
                    RegWrite <= '1';
                when 34 =>            -- R-Type, sub
                    ALUControl_int <= 6;
                    RegDst <= '1';
                    RegWrite <= '1';
                when 42 =>            -- R-Type, slt
                    ALUControl_int <= 7;
                    RegDst <= '1';
                    RegWrite <= '1';
                when 39 =>            -- R-Type, NOR
                    ALUControl_int <= 12;
                    RegDst <= '1';
                    RegWrite <= '1';
                when 8 =>             -- R-Type, jr (NEW COMMAND)
                    Jr <= '1';
                when others => NULL;
            END case;
		when 35 =>                    -- I-Type, lw
             ALUControl_int <= 2;
             ALUSrc <= '1';
             MemToReg <= '1';
             RegWrite <= '1';
		when 43 =>                    -- I-Type, sw
             ALUControl_int <= 2;
             ALUSrc <= '1';
             MemWrite <= '1';
		when 4 =>                     -- I-Type, beq
             ALUControl_int <= 6;
             BEQ <= '1';
		when 2 =>                     -- J-Type, j
             J <= '1';
		when 8 =>                     -- I-Type, addi
             ALUControl_int <= 2;
             ALUSrc <= '1';
             RegWrite <= '1';
             -- NEW COMMANDS
               when 5 =>                      -- I-type, bne
             ALUControl_int <= 6;
             BNE <= '1';
               when 3 =>                      -- J-Type, jal
             RegWrite <= '1';
             Jal <= '1';
               when 13 =>                     -- I-type, ori
             ALUControl_int <= 13;
             ALUSrc <= '1';
             RegWrite <= '1';
               when 15 =>                     -- I-type, lui
             ALUControl_int <= 15;
             ALUSrc <= '1';
             RegWrite <= '1';             
		when others => NULL;
	END case;
   END PROCESS process1;

   ----------------------------------
   
END behav;
