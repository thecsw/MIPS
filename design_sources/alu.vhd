LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.my_package.ALL;

ENTITY ALU IS
   PORT( 
      A           : IN     std_logic_vector (n_bits_alu  - 1 DOWNTO 0);
      ALUControl  : IN     std_logic_vector (n_bits_of(n_functions_alu) - 1 DOWNTO 0);
      B           : IN     std_logic_vector (n_bits_alu  - 1 DOWNTO 0);
      C           : OUT    std_logic_vector (n_bits_alu  - 1 DOWNTO 0);
      zero        : OUT    std_logic;
      overflow    : OUT    std_logic
   );
END ALU;

ARCHITECTURE behav OF ALU IS

   -- Internal signal declarations
   SIGNAL ALUControl_int : natural RANGE 0 TO (n_functions_alu - 1);
   SIGNAL C_internal : std_logic_vector(n_bits_alu  - 1 DOWNTO 0);
   SIGNAL s_A, s_B, s_C : std_logic; -- Sign bits of A, B, C
   
   SIGNAL immediate : std_logic_vector (immediate_end DOWNTO immediate_start);
   SIGNAL immediate_Zero_Extended : std_logic_vector (n_bits_alu - 1 DOWNTO 0);

BEGIN

   -- **************************** --
   -- DO NOT MODIFY or CHANGE the ---
   -- code template provided above --
   -- **************************** --
   
   ----- insert your code here ------
   
       C <= C_internal;
       ALUControl_int <= TO_INTEGER(UNSIGNED(ALUControl));
       
       s_A <= A(A'length  - 1);
       s_B <= B(B'length  - 1);
       s_C <= C_internal(C_internal'length  - 1);
       
       immediate <= B(immediate_end DOWNTO immediate_start);
       immediate_Zero_Extended <= std_logic_vector(resize(unsigned(immediate), n_bits_alu));
       
       alu_functions : process (A, B, ALUControl_int)
       begin
          C_internal <= (others => '0');
          case ALUControl_int is
              when 0 =>
                  C_internal <= A and B;
              when 1 =>
                  C_internal <= A or B;
              when 2 =>
                  C_internal <= STD_LOGIC_VECTOR(SIGNED(A) + SIGNED(B));
              when 6 =>
                  C_internal <= STD_LOGIC_VECTOR(SIGNED(A) - SIGNED(B));
              when 7 =>
                 IF (SIGNED(A) < SIGNED(B)) then
                    C_internal(0) <= '1';
                 END IF;
              when 12 =>
                  C_internal <= A nor B;
              -- NEW COMMANDS
              when 13 => -- ori
                  C_internal <= A or immediate_Zero_Extended;
              when 15 => -- lui
                  C_internal <= B(15 downto 0) & "0000000000000000";
              when others =>
                  C_internal <= (others => '0');
          end case;
       end process alu_functions;

       alu_flags : process (s_A, s_B, s_C, C_internal, ALUControl_int)
       begin
          zero <= '0';
          overflow <= '0';
          if (C_internal = zeros) then
              zero <= '1';
          end if;          
          case ALUControl_int is
              when 2 =>
                  overflow <= ((not s_A) and (not s_B) and (    s_C)) or
                              ((    s_A) and (    s_B) and (not s_C)); 
              when 6 =>
                  overflow <= ((not s_A) and (    s_B) and (    s_C)) or
                              ((    s_A) and (not s_B) and (not s_C)); 
              when others =>
                  overflow <= '0';
          end case;
       end process alu_flags;
   
   ----------------------------------
   
END behav;
