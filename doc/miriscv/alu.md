# miriscv_alu.sv #

##### Описание модуля ######
Модуль miriscv_alu.sv представляет из себя описание арифметико-логического устройства (АЛУ) и предназначен для выполнения арифметических и логических операций. АЛУ расположено на стадии EXECUTE нашего конвейерного процессора. Параметры модуля представлены в таблице 1, порты в таблице 2, значения выходных портов в зависимости от инструкции в таблице 3.
  


##### Таблица 1. Параметры модуля miriscv_alu.sv #####
| Название параметра | Значение по умолчанию | Назначение             |
|:-|:--------:|:---|
|XLEN                |         32            | Разрядность шины данных|
|ALU_OP_WIDTH        |         5             | Разрядность кода инструкции АЛУ|                    
|ALU_ADD             |         0             | Код операции суммирования| 
|ALU_SUB             |         1             | Код операции разности|      
|ALU_EQ              |         2             | Код операции сравнения (равно)|  
|ALU_NE              |         3             | Код операции сравнения (не равно)|                                                                                                                              
|ALU_LT              |         4             | Код операции сравнения с знаком  (меньше)| 
|ALU_LTU             |         5             | Код операции сравнения без знака (меньше)|                                
|ALU_GE              |         6             | Код операции сравнения с знаком  (больше или равно)| 
|ALU_GEU             |         7             | Код операции сравнения без знака (больше или равно)|
|ALU_SLT             |         8             | В АЛУ эта операция аналогична LT, но затем результат сравнения записывается в регистровый файл|                                                        
|ALU_SLTU            |         9             | В АЛУ эта операция аналогична LTU, но затем результат сравнения записывается в регистровый файл| 
|ALU_SLL             |         10            | Код операции логического сдвига влево|
|ALU_SRL             |         11            | Код операции логического сдвига вправо|
|ALU_SRA             |         12            | Код операции арифметического сдвига вправо|
|ALU_XOR             |         13            | Код операции побитового исключающего или (xor)|
|ALU_OR              |         14            | Код операции побитового или (or)|
|ALU_AND             |         15            | Код операции побитового и (and)|
|ALU_JAL             |         16            | Код операции безусловного перехода с записью в регистр номера текущей инструкции|  
  
  
  
  
##### Таблица 2. Порты модуля miriscv_alu.sv #####
| Название сигнала      | Разрядность | Назначение                                    |
|:-|:--------|:---|
|alu_port_a_i           | XLEN        | Первый операнд инструкции в АЛУ|                                                                                    
|alu_port_b_i           | XLEN        | Второй операнд инструкции в АЛУ|                    
|alu_op_i               | ALU_OP_WIDTH| Идентификатор операции для АЛУ|                                    
|alu_result_o           | XLEN        | Результат выполненной инструкции|                                 
|alu_branch_des_o       | 1           | Идентификатор выполнения условия перехода инструкции типа branch|    
      
  
  
##### Таблица 3. Значения выходных портов #####
| Операция              |                                     Результат операции                                                     |   
|:-|:--------|
|ALU_ADD                |  alu_result_o&nbsp; = &nbsp;alu_port_a_i&nbsp; + &nbsp;alu_port_b_i <br>  alu_branch_des_o&nbsp; =&nbsp;  0                                    |                                                                                    
|ALU_SUB                |   alu_result_o&nbsp; = &nbsp;alu_port_a_i&nbsp; - &nbsp;alu_port_b_i <br> alu_branch_des_o&nbsp;=&nbsp;0|                                                                                                                                                                     
|ALU_EQ                 |   alu_result_o&nbsp; = &nbsp;alu_port_b_i <br> alu_branch_des_o&nbsp; =  &nbsp;alu_port_a_i&nbsp;  ==&nbsp;  alu_port_b_i                      |                                    
|ALU_NE                 |   alu_result_o&nbsp; =&nbsp; alu_port_b_i <br> alu_branch_des_o&nbsp;=&nbsp; alu_port_a_i&nbsp;  != &nbsp;alu_port_b_i                      |                                 
|ALU_LT                 |   alu_result_o&nbsp; = &nbsp;alu_port_b_i <br> alu_branch_des_o&nbsp;= &nbsp; alu_port_a_i &nbsp; <&nbsp;   alu_port_b_i                      |
|ALU_LTU                |   alu_result_o&nbsp; =&nbsp; alu_port_b_i <br> alu_branch_des_o&nbsp; =&nbsp;  alu_port_a_i&nbsp;  <&nbsp;   alu_port_b_i                      |  
|ALU_GE                 |   alu_result_o&nbsp; =&nbsp; alu_port_b_i <br> alu_branch_des_o&nbsp; =&nbsp;  alu_port_a_i&nbsp;  >=&nbsp;  alu_port_b_i                      | 
|ALU_GEU                |   alu_result_o&nbsp; =&nbsp; alu_port_b_i <br> alu_branch_des_o&nbsp; =&nbsp;  alu_port_a_i&nbsp;  >=  alu_port_b_i                      |
|ALU_SLT                |   alu_result_o&nbsp; =&nbsp; alu_port_a_i&nbsp;  <&nbsp;   alu_port_b_i <br> alu_branch_des_o&nbsp; =&nbsp;  0                                 |
|ALU_SLTU               |   alu_result_o&nbsp; =&nbsp; alu_port_a_i&nbsp;  <&nbsp;   alu_port_b_i <br> alu_branch_des_o&nbsp; =&nbsp;  0                                 |
|ALU_SLL                |   alu_result_o&nbsp; =&nbsp; alu_port_a_i&nbsp; <<&nbsp;  shift <br> alu_branch_des_o&nbsp; =&nbsp;  0                                      |
|ALU_SRL                |   alu_result_o&nbsp; =&nbsp; alu_port_a_i&nbsp; >>&nbsp;  shift <br> alu_branch_des_o&nbsp; =&nbsp;  0                                      |
|ALU_SRA                |   alu_result_o&nbsp; =&nbsp; alu_port_a_i&nbsp; >>>&nbsp; shift <br> alu_branch_des_o&nbsp; =&nbsp;  0                                     | 
|ALU_OR                 |   alu_result_o&nbsp; =&nbsp; alu_port_a_i&nbsp; \|&nbsp; alu_port_b_i <br> alu_branch_des_o&nbsp; =&nbsp;  0                                     | 
|ALU_XOR                |   alu_result_o&nbsp; =&nbsp; alu_port_a_i &nbsp;^&nbsp; alu_port_b_i  <br> alu_branch_des_o&nbsp;=&nbsp;  0                               |
|ALU_AND                |   alu_result_o&nbsp; =&nbsp; alu_port_a_i&nbsp; &&nbsp; alu_port_b_i      <br> alu_branch_des_o&nbsp; =&nbsp;  0                              |
|ALU_JAL                |   alu_result_o&nbsp; =&nbsp; alu_port_b_i                     <br> alu_branch_des_o&nbsp; =&nbsp;  0                              |
  
  
  
  
  
