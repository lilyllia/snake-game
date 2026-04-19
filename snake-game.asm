
# algumas coisas foram mudadas, pois o objetivo não era cosntruir o código assembly mais simples e limpo,
# mas sim construir um código assembly que poderia facilmente ser convertido para o processador no MIPS
# que criamos. devido à isso, nçao foram utilizadas pseudoinstruções (salvo as que foram implementadas no 
# prórpio MIPS: move, li, blt)
#
# SYSCALLS
# no mars, utilizamos 3 syscallls, segue abaixo quais e seu substituto no MIPS do Logisim
# 32 - sleep: 
# move $t4, $s4;
# addi $t4, $t4, -1
# bne $t4, $0, -2
#
# 10 - exit:
# jump FFFF
#
# 42 - random int range.
# lw $t5, FF00
# move $v0, $t5
#
# ==========================================
# MACROS
# ==========================================
.macro PUSH(%reg)
    addi $sp, $sp, -4
    sw   %reg, 0($sp)
.end_macro

.macro POP(%reg)
    lw   %reg, 0($sp)
    addi $sp, $sp, 4
.end_macro

.macro SAVE_CONTEXT()
    PUSH($ra)
    PUSH($fp)
    PUSH($s0)
    PUSH($s1)
    PUSH($s2)
    PUSH($s3)
    PUSH($s4)
    PUSH($s5)
    PUSH($s6)
    PUSH($s7)
    move $fp, $sp
.end_macro

.macro GET_CONTEXT()
    move $sp, $fp
    POP($s7)
    POP($s6)
    POP($s5)
    POP($s4)
    POP($s3)
    POP($s2)
    POP($s1)
    POP($s0)
    POP($fp)
    POP($ra)
    jr   $ra
.end_macro

# delay inline e com syscall sleep
.macro DELAY(%time_reg)
    move $a0, %time_reg
    li   $v0, 32
    syscall
.end_macro

# ==========================================
# DATA SEGMENT
# ==========================================
.data
SNAKE:  .word 0x0060923A    # verde
APPLE:  .word 0x00990B12    # vermelho
BLACK:  .word 0x00000000    # preto

# ==========================================
# TEXT SEGMENT
# ==========================================
.text
.globl main

main:
    # inicializar
    li $s0, 4           # x_pos_cur
    li $s1, 4           # y_pos_cur
    li $s2, 2           # x_food
    li $s3, 2           # y_food
    li $s4, 256         # delay_time
    li $s5, 0           # score
    li $s6, 100   	# key_pressed começa como ascii do D, direita, ->      
	#li $sp, FFF (necessidade exclusiva do mips, pois $sp no mars já tem valor inicial
	
	
    # define a cobrinha no jogo
    move $a0, $s0
    move $a1, $s1
    lw   $a2, SNAKE
    jal  write_grid

    # define a maçã
    move $a0, $s2
    move $a1, $s3
    lw   $a2, APPLE
    jal  write_grid

# ==========================================
# LOOP DO JOGO
# ==========================================
game_loop:
    DELAY($s4)

    # lógica da bendita leitura não bloqueante
    lui  $t0, 0xffff		#pega o endereço do controle de tecla (usa o lui pois o imediato possui 32 bits no MARS)
    lw   $t1, 0($t0)		#pega o que está no endereço do controle de tecla
    beq  $t1, 0, move_snake

    lw   $t1, 4($t0)            # pega, agora, o que está no endereço do codigo ascii
    
    # switch
    li $t5, 119					#w
    beq  $t1, $t5, update_dir   # w
    li $t6, 97					#a
    beq  $t1, $t6,  update_dir  # a
    li $t7, 115					#s
    beq  $t1, $t7, update_dir   # s
    li $t8, 100					#d
    beq  $t1, $t8, update_dir   # d
    j    move_snake             # default

update_dir:
    move $s6, $t1               # atualiza/salva a direção

move_snake:
    move $t2, $s0		# pega a posição atual em um regtemp para atualizar
    move $t3, $s1

    # outro switch
    beq  $s6, $t6,  move_left
    beq  $s6, $t7, move_down
    beq  $s6, $t8, move_right
    beq  $s6, $t5, move_up

move_left:
    addi $t2, $s0, -1   
    blt $t2, $0, wrap_x    
    j    check_eaten
    
move_down:     
    addi $t3, $s1, 1    
    beq  $t3, 16, wrap_y_0
    j    check_eaten

move_right:
    addi $t2, $s0, 1    
    beq  $t2, 16, wrap_x_0
    j    check_eaten

move_up:
    addi $t3, $s1, -1   
    blt $t3, $0, wrap_y
    j    check_eaten

# wrap-around nas bordas
wrap_x:
    li   $t2, 15        
    j    check_eaten
wrap_x_0:
    li   $t2, 0         
    j    check_eaten
wrap_y:
    li   $t3, 15        
    j    check_eaten
wrap_y_0:
    li   $t3, 0         
    j    check_eaten

check_eaten:
    #passa desses bne somente se estiver no mesmo pixel
    bne  $t2, $s2, update_pos
    bne  $t3, $s3, update_pos

    # aumenta o score e diminui o delay pela metade
    addi $s5, $s5, 1    
    div  $s4, $s4, 2    

    # nova comida
    jal  random_position
    move $s2, $v0       
    jal  random_position
    move $s3, $v0       

    move $a0, $s2
    move $a1, $s3
    lw   $a2, APPLE
    jal  write_grid

update_pos:
    # apaga a cauda da cobrinha
    move $a0, $s0
    move $a1, $s1
    lw   $a2, BLACK
    jal  write_grid

    # atualiza/salva a posicao
    move $s0, $t2       
    move $s1, $t3       

    # desenha novamente, com as posições atualizadas
    move $a0, $s0
    move $a1, $s1
    lw   $a2, SNAKE
    jal  write_grid

    # checa se a pontução chegou a 5
    li   $t1, 5
    beq  $s5, $t1, end_game

    j    game_loop      

end_game:
    li   $v0, 10        
    syscall


# ==========================================
# FUNÇÕES
# ==========================================

# void write_grid(int x, int y, int cor)
# $a0 = x, $a1 = y, $a2 = cor
write_grid:
    SAVE_CONTEXT()         

    #(y * 16 + x) * 4
    mul  $s0, $a1, 16    
    add  $s0, $s0, $a0  
    mul  $s0, $s0, 4   
    
    # soma endereço base ($gp)
    add  $s0, $s0, $gp  
    
    # informa a cor
    sw   $a2, 0($s0)
   
    GET_CONTEXT()          

# int random_position()
# usa syscall para colocar número aleatório em $v0
random_position:
    SAVE_CONTEXT()
    
    li   $v0, 42        
    li   $a0, 0         
    li   $a1, 16        
    syscall
    move $v0, $a0       
    
    GET_CONTEXT()
