LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.my_package.ALL;

ENTITY mips_single_cycle IS
   PORT( 
      clk : IN     std_logic;
      rst : IN     std_logic
   );
END mips_single_cycle ;

ARCHITECTURE struct OF mips_single_cycle IS
   
   -- PC Register Signals --
   SIGNAL PC_next          : std_logic_vector (n_bits_address - 1 DOWNTO 0);
   SIGNAL PC_current       : std_logic_vector (n_bits_address - 1 DOWNTO 0);
   SIGNAL PC_inc           : std_logic_vector (n_bits_address - 1 DOWNTO 0);
   SIGNAL PC_cond_branch   : std_logic_vector (n_bits_address - 1 DOWNTO 0);
   SIGNAL PC_uncond_branch : std_logic_vector (n_bits_address - 1 DOWNTO 0); 
   SIGNAL PC_uncond_jr     : std_logic_vector (n_bits_address - 1 DOWNTO 0);   
   
   -- Instruction Memory Signals --
   SIGNAL InstrMem_A     : std_logic_vector (n_bits_address - 1 DOWNTO 0);
   SIGNAL InstrMem_Instr : std_logic_vector (instr_mem_width - 1 DOWNTO 0);
   
   -- Register File Signals --
   SIGNAL RegFile_RA1      : std_logic_vector (n_bits_of(reg_file_depth) - 1 DOWNTO 0);
   SIGNAL RegFile_RA2      : std_logic_vector (n_bits_of(reg_file_depth) - 1 DOWNTO 0);
   SIGNAL RegFile_RegWrite : std_logic;
   SIGNAL RegFile_WA       : std_logic_vector (n_bits_of(reg_file_depth) - 1 DOWNTO 0);
   SIGNAL RegFile_WD       : std_logic_vector (reg_file_width - 1 DOWNTO 0);
   SIGNAL RegFile_RD1      : std_logic_vector (reg_file_width - 1 DOWNTO 0);
   SIGNAL RegFile_RD2      : std_logic_vector (reg_file_width - 1 DOWNTO 0);
   
   -- ALU Signals --
   SIGNAL ALU_A          : std_logic_vector (n_bits_alu - 1 DOWNTO 0);
   SIGNAL ALU_ALUControl : std_logic_vector (n_bits_of(n_functions_alu) - 1 DOWNTO 0);
   SIGNAL ALU_B          : std_logic_vector (n_bits_alu - 1 DOWNTO 0);
   SIGNAL ALU_C          : std_logic_vector (n_bits_alu - 1 DOWNTO 0);
   SIGNAL ALU_zero       : std_logic;
   SIGNAL ALU_overflow   : std_logic; 
   
   -- Data Memory Signals --
   SIGNAL DataMem_A        : std_logic_vector (n_bits_address - 1 DOWNTO 0);
   SIGNAL DataMem_MemWrite : std_logic;
   SIGNAL DataMem_WD       : std_logic_vector (data_mem_width - 1 DOWNTO 0);
   SIGNAL DataMem_RD       : std_logic_vector (data_mem_width - 1 DOWNTO 0);

   -- Control Unit Signals --
   SIGNAL CU_Instr      : std_logic_vector (n_bits_instr - 1 DOWNTO 0);
   SIGNAL CU_ALUControl : std_logic_vector (n_bits_of(n_functions_alu) - 1 DOWNTO 0);
   SIGNAL CU_ALUSrc     : std_logic;
   SIGNAL CU_BEQ        : std_logic;
   SIGNAL CU_J          : std_logic;
   SIGNAL CU_MemToReg   : std_logic;
   SIGNAL CU_MemWrite   : std_logic;
   SIGNAL CU_RegDst     : std_logic;
   SIGNAL CU_RegWrite   : std_logic;
   SIGNAL CU_BNE        : std_logic;
   SIGNAL CU_Jal        : std_logic;      
   SIGNAL CU_Jr         : std_logic;
   
   -- Format-Dependent Signals --
   SIGNAL opcode         : std_logic_vector (        opcode_end DOWNTO opcode_start);
   SIGNAL rs             : std_logic_vector (            rs_end DOWNTO rs_start);
   SIGNAL rt             : std_logic_vector (            rt_end DOWNTO rt_start);
   SIGNAL rd             : std_logic_vector (            rd_end DOWNTO rd_start);
   SIGNAL shamt          : std_logic_vector (         shamt_end DOWNTO shamt_start);
   SIGNAL funct          : std_logic_vector (         funct_end DOWNTO funct_start);
   SIGNAL immediate      : std_logic_vector (     immediate_end DOWNTO immediate_start);
   SIGNAL pseudo_address : std_logic_vector (pseudo_address_end DOWNTO pseudo_address_start);

   -- Internal Signals --
   SIGNAL immediate_Sign_Extended : std_logic_vector (n_bits_alu - 1 DOWNTO 0);
   SIGNAL relative_address        : std_logic_vector (n_bits_address - 1 DOWNTO 0);
   SIGNAL branch_taken            : std_logic;

   -- Component Declarations
   
	COMPONENT PC_register
	   PORT( 
	      PC_next    : IN     std_logic_vector (n_bits_address - 1 DOWNTO 0);
	      clk        : IN     std_logic;
	      rst        : IN     std_logic;
	      PC_current : OUT    std_logic_vector (n_bits_address - 1 DOWNTO 0)
	   );
	END COMPONENT;   

	COMPONENT InstrMem
	   PORT( 
	      A     : IN  std_logic_vector (n_bits_address - 1 DOWNTO 0);
	      rst   : IN  std_logic;
	      Instr : OUT std_logic_vector (instr_mem_width - 1 DOWNTO 0)
	   );
	END COMPONENT;

	COMPONENT RegFile 
	   PORT( 
	      RA1      : IN  std_logic_vector (n_bits_of(reg_file_depth) - 1 DOWNTO 0);
	      RA2      : IN  std_logic_vector (n_bits_of(reg_file_depth) - 1 DOWNTO 0);
	      RegWrite : IN  std_logic;
	      WA       : IN  std_logic_vector (n_bits_of(reg_file_depth) - 1 DOWNTO 0);
	      WD       : IN  std_logic_vector (reg_file_width - 1 DOWNTO 0);
	      clk      : IN  std_logic;
	      rst      : IN  std_logic;
	      RD1      : OUT std_logic_vector (reg_file_width - 1 DOWNTO 0);
	      RD2      : OUT std_logic_vector (reg_file_width - 1 DOWNTO 0)
	   );
	END COMPONENT;	

	COMPONENT ALU
	   PORT( 
	      A           : IN     std_logic_vector (n_bits_alu - 1 DOWNTO 0);
	      ALUControl  : IN     std_logic_vector (n_bits_of(n_functions_alu) - 1 DOWNTO 0);
	      B           : IN     std_logic_vector (n_bits_alu - 1 DOWNTO 0);
	      C           : OUT    std_logic_vector (n_bits_alu - 1 DOWNTO 0);
	      zero        : OUT    std_logic;
	      overflow    : OUT    std_logic
	   );
	END COMPONENT;	
   
	COMPONENT DataMem
	   PORT( 
	      A        : IN  std_logic_vector (n_bits_address - 1 DOWNTO 0);
	      MemWrite : IN  std_logic;
	      WD       : IN  std_logic_vector (data_mem_width - 1 DOWNTO 0);
	      clk      : IN  std_logic;
	      rst      : IN  std_logic;
	      RD       : OUT std_logic_vector (data_mem_width - 1 DOWNTO 0)
	   );
	END COMPONENT;

	COMPONENT CU
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
	END COMPONENT;

BEGIN

      --------------------
      -- Important Hint --
      --------------------
        -- When you use the components "PC_register", "InstrMem", "RegFile", "ALU", "DataMem", and "CU", in this top-level design 
        -- "top_mips_single_cycle.vhd", name their instances by appending "_inst" to the end of the component name as follows 
        -- "PC_register_inst", "InstrMem_inst", "RegFile_inst", "ALU_inst", "DataMem_inst", and "CU_inst". 
        -- This will guarantee the correct setup of your waveform configuration for showing all needed signals. For example:
              -- PC_register_inst : PC_register
              --   PORT MAP ( 
              --             PC_next    => ... ,
              --             clk        => ... ,
              --             rst        => ... ,
              --             PC_current => ...
              --   );
      --------------------
      
   -- **************************** --
   -- DO NOT MODIFY or CHANGE the ---
   -- code template provided above --
   -- **************************** --
   
   ----- insert your code here ------
	   
   -- Let it begin
   -- Start mapping all the signals according to our CPU structure
   
   -- Load the instruction
   InstrMem_A <= PC_current;
   
   opcode         <= InstrMem_Instr(        opcode_end DOWNTO opcode_start);
   rs             <= InstrMem_Instr(            rs_end DOWNTO rs_start);
   rt             <= InstrMem_Instr(            rt_end DOWNTO rt_start);
   rd             <= InstrMem_Instr(            rd_end DOWNTO rd_start);
   shamt          <= InstrMem_Instr(         shamt_end DOWNTO shamt_start);
   funct          <= InstrMem_Instr(         funct_end DOWNTO funct_start);
   immediate      <= InstrMem_Instr(     immediate_end DOWNTO immediate_start);
   pseudo_address <= InstrMem_Instr(pseudo_address_end DOWNTO pseudo_address_start);
   
   immediate_Sign_Extended <= std_logic_vector(resize(signed(immediate), n_bits_alu));
   relative_address        <= std_logic_vector(shift_left(signed(immediate_Sign_Extended), 2));
   branch_taken            <= (ALU_zero and CU_BEQ) or (not ALU_zero and CU_BNE);

   -- Finid the next instruction
   -- Simple PC_inc
   PC_inc <= std_logic_vector(unsigned(PC_current) + 4);
   
   -- This is unconditional branch, where PC_uncond = PC_inc[31:28]:PA
   -- where PA is the Pseudo Address = 4 * Instr[25:0]
   PC_uncond_branch <= PC_inc(n_bits_alu - 1 downto (n_bits_alu - 4)) & std_logic_vector(signed(pseudo_address)) & "00";
   
   -- This is a conditional branch, awhere PC_cond = PC_inc + offset, where
   -- offset = SignExtend(4 * Instr[15:0]), in this case
   -- immediate_Sign_Extended is already Instr[15:0] extended onto 32 bits
   -- and then we just shift it two places, same thing as multiplying times 4
   PC_cond_branch <= std_logic_vector(signed(PC_inc) + signed(relative_address));
   
   PC_next <= PC_cond_branch when (branch_taken = '1') else
              PC_uncond_branch when (CU_J = '1' or CU_Jal = '1') else
              RegFile_RD1 when (CU_Jr = '1') else
              PC_inc;
   
   -- Feed the Control Unit
   CU_Instr <= InstrMem_Instr;
   
   -- Register file
   -- INPUT PORTS
   RegFile_RA1 <= rs;
   RegFile_RA2 <= rt;

   RegFile_WA <= std_logic_vector(to_unsigned(31, RegFile_WA'length)) when (CU_Jal = '1') else
                 rd when (CU_RegDst = '1') else
                 rt;
   RegFile_WD <= PC_Inc when (CU_Jal = '1') else
                 DataMem_RD when (CU_MemToReg = '1') else
                 ALU_C;
   RegFile_RegWrite <= CU_RegWrite;
    
   -- ALU
   -- INPUT PORTS
   ALU_A <= RegFile_RD1;
   ALU_ALUControl <= CU_ALUControl;
   with CU_ALUSrc select ALU_B <=
    RegFile_RD2 when '0',
    immediate_Sign_Extended when others;
    
   -- Data Memory
   -- INPUT PORTS
   DataMem_A <= ALU_C;
   DataMem_WD <= RegFile_RD2;
   DataMem_MemWrite <= CU_MemWrite;

   PC_register_inst : PC_register
           PORT MAP (
            PC_next    => PC_next,
            clk        => clk,
            rst        => rst,
            PC_current => PC_current
        );

   InstrMem_inst : InstrMem
	   PORT MAP ( 
	      A     => InstrMem_A,
	      rst   => rst,
	      Instr => InstrMem_Instr
	   );

   RegFile_inst : RegFile 
	   PORT MAP( 
	      RA1      => RegFile_RA1,
	      RA2      => RegFile_RA2,
	      RegWrite => RegFile_RegWrite,
	      WA       => RegFile_WA,
	      WD       => RegFile_WD,
	      clk      => clk,
	      rst      => rst,
	      RD1      => RegFile_RD1,
	      RD2      => RegFile_RD2
	   );

   ALU_inst : ALU
	   PORT MAP ( 
	      A           => ALU_A,
	      ALUControl  => ALU_ALUControl,
	      B           => ALU_B,
	      C           => ALU_C,
	      zero        => ALU_zero,
	      overflow    => ALU_overflow
	   );

   DataMem_inst : DataMem
	   PORT MAP ( 
	      A        => DataMem_A,
	      MemWrite => DataMem_MemWrite,
	      WD       => DataMem_WD,
	      clk      => clk,
	      rst      => rst,
	      RD       => DataMem_RD
	   );

   CU_inst : CU
	   PORT MAP ( 
	      Instr      => CU_Instr,
	      ALUControl => CU_ALUControl,
	      ALUSrc     => CU_ALUSrc,
	      BEQ        => CU_BEQ,
	      J          => CU_J,
	      MemToReg   => CU_MemToReg,
	      MemWrite   => CU_MemWrite,
	      RegDst     => CU_RegDst,
	      RegWrite   => CU_RegWrite,
              BNE        => CU_BNE,
              Jal        => CU_Jal,
              Jr         => CU_Jr
	   );
   
   ----------------------------------

END struct;
