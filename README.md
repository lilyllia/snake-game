![][image1]  
UNIVERSIDADE FEDERAL DO CARIRI  
CENTRO DE CIÊNCIAS E TECNOLOGIA  
CIÊNCIA DA COMPUTAÇÃO

EMILY FERNANDA DA SILVA GALVÃO MODESTO  
YASMIM MONTEIRO GOMES 

**RELATÓRIO DO PROJETO SNAKE GAME 2**

Juazeiro do Norte  
Março/2026  
**SUMÁRIO**

[**1\. IMPLEMENTAÇÕES NO MARS	2**](#1.-implementações-no-mars)

[1.1. Convenção de variáveis e registradores](#1.1.-convenção-de-variáveis-e-registradores)	3

[1.2. Funções: write\_grid e random\_pos](#1.2.-funções:-write_grid-e-random_pos)	3

[1.3. Inicialização do jogo](#1.3.-inicialização-do-jogo)	3

[1.4. Loop do jogo](#1.4.-loop-do-jogo)	3

[1.5. Delay e Non-blocking](#1.5.-delay-e-non-blocking)	4

[1.6  Macros: uso da pilha](#1.6-macros:-uso-da-pilha)	4

[**2\. MODIFICAÇÕES NO LOGISIM**](#2.-modificações-no-logisim)	**5**

[2.1. Organização visual](#2.1.-organização-visual)	5

[2.2. Incremento de 4 no PC](#2.2.-incremento-de-4-no-pc)	5

[2.3. Desvio relativo](#2.3.-desvio-relativo)	5

[2.4 Salto pseudodireto](#2.4-salto-pseudodireto)	5

[2.5 Registradores de Pipeline	5](#2.5-registradores-de-pipeline)

[**3\. INSTRUÇÕES IMPLEMENTADAS NO LOGISIM	6**](#3.-instruções-implementadas-no-logisim)

[3.1. Move	6](#3.1.-move)

[3.2. Load Immediate (li)	6](#3.2.-load-immediate-\(li\))

[3.3. Branch if Less Than (blt)	6](#3.3.-branch-if-less-than-\(blt\))

[**4\. DESAFIOS E SOLUÇÕES	7**](#4.-desafios-e-soluções)

[4.1. Incompatibilidade de bits	7](#4.1.-incompatibilidade-de-bits)

[4.2. Concatenamento de bits e uso do splitter	7](#4.2.-concatenamento-de-bits-e-uso-do-splitter)

[4.3. Utilização do LUI	7](#4.3.-utilização-do-lui)

4.4 Syscalls	7

[**5\. FORWARDING E HAZARD DETECTION	8**](#5.-forwarding-e-hazard-detection)

[5.1. Forwarding (Bypass)	8](#5.1.-forwarding-\(bypass\))

[5.2. Hazard Detection	8](#5.2.-hazard-detection)

[5.3. Desafios com Branches (Saltos)	8](#5.3.-desafios-com-branches-\(saltos\))

[**6\. REFERÊNCIAS	10**](#6.-referências)

## [**1\.**](#heading=h.x5ehk9sltlr8) **[IMPLEMENTAÇÕES NO MARS](#heading=h.l8e51nkgp08o)** {#1.-implementações-no-mars}

### [**1.1. Convenção de variáveis e registradores**](#heading=h.xqqib7hi7im) {#1.1.-convenção-de-variáveis-e-registradores}

A primeira decisão tomada foi em relação a definição de como representar as variáveis do jogo.c em *assembly*. Considerando a necessidade constante de mudar os valores das variáveis globais definidas no jogo.c, que ocasionaram um constante uso de load e store, caso fossem variáveis globais no snake-game.asm também, optamos por não utilizá-las dessa forma, mas como convenções de registradores. É importante pontuar também que, na linguagem C, necessitamos que tais variáveis sejam definidas globalmente, pois utiliza-se as mesmas em diversos escopos. O conceito de “escopo” em assembly, por funcionar de forma distinta, não requer essa mesma definição. Segue abaixo, a convenção adotada:

$s0: Posição X da Cobra (x\_pos)  
$s1: Posição Y da Cobra (y\_pos)  
$s2: Posição X da Comida (x\_food)  
$s3: Posição Y da Comida (y\_food  
$s4: Tempo de delay (delay\_time)  
$s5: Pontuação (score)  
$s6: Direção atual (key\_pressed)  
   
Ademais, dentro do código, as cores para o píxel são constantes globais, ou seja, definidas na seção .data do arquivo. Conforme o pedido do professor, as cores são: vermelho para a comida, verde para a cobra e preto para o plano de fundo.

### [**1.2. Funções: write\_grid e random\_pos**](#heading=h.2jqmfc28up54) {#1.2.-funções:-write_grid-e-random_pos}

**write\_grid:** Consiste em receber o valor **X** em **$a0**, **Y** em **$a1** e a cor a ser desenhada em **$a2**. Em seguida, calcula-se o endereço **$gp \+ (y \* 16 \+ x) \* 4**, que corresponde à posição correta de memória onde a cor armazenada em **$a2** deve ser gravada.

**random\_pos:** Utilizando os registradores $a0 para definir o mínimo e $a1 o máximo, podemos chamar syscall para $v0 \= 42 e conseguir um valor aleatório nesse intervalo.

### [**1.3. Inicialização do jogo**](#heading=h.92n80n3t86ul) {#1.3.-inicialização-do-jogo}

Inicia-se o jogo definindo um valor inicial para as variáveis, baseado no código em C, e usando esses valores, aplicados a função write\_grid, para imprimir o posicionamento inicial do jogo.

### [**1.4. Loop do jogo**](#heading=h.gxl6tes4g8xj) {#1.4.-loop-do-jogo}

Inicialmente, aplica-se o DELAY e acessamos o endereço que armazena se alguma tecla foi apertada (1) ou não (0). Tal execução será explicada posteriormente.  
Caso alguma tecla tenha sido apertada, checa-se qual foi: W, A, S ou D. Se porventura tenha sido uma dessas, atualizamos o registrador convencionado para representar a direção atual e repete-se o movimento e o loop. Caso contrário, repete-se o movimento imediatamente, sem checar qual foi a última tecla pressionada.   
Antes de finalizar o laço do loop, é feita uma checagem para verificar se as coordenadas da cobra e da comida são iguais. Se sim, será somado 1 a pontuação e checado se a condição de fim de jogo foi alcançada.

### [**1.5. Delay e Non-blocking**](#heading=h.28tfevzihx1b) {#1.5.-delay-e-non-blocking}

 No código em C, o **delay** foi implementado por meio do decremento de 1 em um número extenso. Contudo, quando se trata do MARS, tal operação ocorre quase que instantaneamente, criando-se, assim, a necessidade de usar um valor extremamente alto para gerar um resultado notável em relação ao atraso.   
Além de dificultar a implementação da redução do delay e, por consequência, o controle do tempo de espera, não é eficiente “parar” o jogo com uma função que mantém o processador ocupado com uma tarefa que torna-se desnecessária, visto que existe uma syscall feita com essa finalidade. Visando solucionar esse problema, temos a syscall Sleep que realiza exatamente essa função e ainda permite um controle mais preciso do tempo, já que recebe como argumento um valor exato em milisegundos.  
Em relação ao non-blocking, se o bit de controle (**endereço ffff0004**, que retorna 1 quando uma tecla é apertada e 0 caso contrário) não for utilizado, surge um problema: enquanto uma tecla válida não for pressionada, o código não continua a ser executado. Para resolver esse problema, utiliza-se esse endereço para verificar se uma nova tecla foi apertada. Do contrário, o laço de movimento do jogo continua sendo executado e a verificação ocorre novamente, para que assim o jogo prossiga de maneira fluída.

### **1.6  Macros: uso da pilha** {#1.6-macros:-uso-da-pilha}

As macros dentro do código funcionam  como atalhos para evitar a repetição. São essas: 

**PUSH e POP:** Responsáveis pelo gerenciamento da pilha. O PUSH irá guardar um registrador na memória e o POP o recupera.

**SAVE\_CONTEXT e GET\_CONTEXT**: Irão salvar e restaurar todos os registradores importantes ($ra, $fp, $s0-$s7). No código, é essencial dentro das funções para garantir que uma sub-rotina não prejudique ou afete os dados da função principal.

**DELAY**: Atua no controle da velocidade do jogo. Usando a syscall 32 do MARS, essa macro realiza uma pausa na execução por alguns milissegundos, para que, assim, consigamos o efeito de aceleração da cobra com o passar das fases do jogo.

## [**2\.**](#heading=h.l8e51nkgp08o) **[MODIFICAÇÕES NO LOGISIM](#heading=h.x5ehk9sltlr8)** {#2.-modificações-no-logisim}

### [**2.1. Organização visual**](#heading=h.3onchgdyags) {#2.1.-organização-visual}

Para facilitar a compreensão e manutenção do circuito, algumas seções que continham muitos SHIFTs, splitters e multiplexadores em subcircuitos, que realizam a lógica desejada de forma oculta e com maior organização.

### [**2.2. Incremento de 4 no PC**](#heading=h.6iqxn94rrje3) {#2.2.-incremento-de-4-no-pc}

No MIPS real, a memória é organizada em bytes. Logo, para executar cada instrução, precisa-se buscá-la na memória, sendo assim necessário incrementar o contador de programa (PC) de maneira que o faça apontar para a próxima instrução, que está localizada 4 bytes depois, pois cada instrução no MIPS possui 32 bits (4 bytes).   
Para isso, somamos 4 a PC, pois a próxima instrução está 4 bytes adiante na memória. Em hexadecimal, cada par de dígitos corresponde a 1 byte (8 bits), logo uma instrução completa, com 8 dígitos hexadecimais, representa 4 bytes.

### [**2.3. Desvio relativo**](#heading=h.fimdakbebbk1) {#2.3.-desvio-relativo}

Anteriormente, a função Branch utilizava o imediato como endereçamento direto. Na arquitetura real, não funciona assim. No MIPS real existe um offset de 16 bits que calcula o endereço de destino do desvio de forma relativa ao endereço da instrução de desvio. Assim, no lugar do campo do imediato, nas instruções bqe ou bne, ao invés de termos o endereço final, teremos o deslocamento em relação ao PC.  
Para implementar isso, precisa-se calcular o endereço de destino:

                **Endereço destino** \= PC \+ 4 \+ (offset \* 4\)

Precisa-se do endereço da instrução seguinte ao desvio para realizar o cálculo, por isso usamos PC \+ 4 que corresponde ao endereço da próxima instrução, como foi explicado anteriormente, somado ao offset (valor imediato da instrução) vezes 4, pois cada uma delas ocupa 4 bytes. Essa multiplicação por 4, na arquitetura, corresponde ao deslocamento de 2 bits para a esquerda.  
Se os operandos da instrução branch forem iguais, o endereço de destino do desvio se torna o novo PC e o desvio ocorre, se forem distintos o PC incrementado substitui o PC atual e o desvio não é tomado. Logo, é necessário que o caminho de dados de desvio calcule o endereço de destino do desvio e compare o que está nos registradores. 

### **2.4 Salto pseudodireto** {#2.4-salto-pseudodireto}

Para contornar a limitação de espaço no formato das instruções, os saltos das instruções do tipo J utilizam o endereçamento pseudodireto. Em tal tipo de endereçamento, o campo de endereço da instrução possui 26 bits, mas como as instruções no MIPS possuem 4 bytes, 32 bits, os dois bits menos significativos do endereço são sempre 0, permitindo que o endereço seja deslocado 2 bits à esquerda e formando 28 bits. Os demais 4 bits mais significativos são obtidos do PC \+ 4, formando, assim, o endereço de 32 bits.

### **2.5 Registradores de Pipeline** {#2.5-registradores-de-pipeline}

O pipeline organiza a execução das instruções em fases para aumentar a eficiência, no entanto, algumas vezes a próxima instrução não pode ser executada logo em seguida no ciclo de clock, chamamos esse conflito de hazard. Visando executar esse processo em etapas, o pipeline utiliza registradores intermediários entre os estágios, sendo esses os registradores de pipeline.   
Os registradores de pipeline vão armazenar temporariamente os dados necessários para cada fase, permitindo, assim, que múltiplas instruções sejam executadas no processador sem que seus dados se misturem, liberando o estágio anterior para a próxima instrução da fila.  
Temos, então os seguintes registradores principais:

**IF/ID (Instruction Fetch/Instruction Decode):** Busca a instrução na   
memória e armazena a instrução e o valor do PC, assim como também realiza   
a decodificação e a leitura do banco de registradores.

**ID/EX (Instruction Decod /Execute):** Decodifica a instrução e prepara para   
a execução, bem como identifica as operações e os operandos necessários   
para isso.

**EX/MEM (Execute/Memory):** Executa a operação na ALU,  calcula os   
endereços de acesso à memória e as flags necessárias para a tomada de decisão na próxima fase.

**MEM/WB (Memory / Write Back):** Acessa a memória de dados caso seja   
necessário e escreve o resultado de volta no banco de registradores.

Na implementação dos registradores o caminho de dados é dividido em 5 partes, cada uma correspondendo ao seu estágio. Entre cada parte, foi colocado um registrador que irá guardar os dados com os sinais de controle e os demais dados que precisam ser guardados, sendo estes atualizados a cada ciclo de clock para permitir que diversas instruções sejam executadas simultaneamente.

## **3[.](#heading=h.xw760wmras6s) INSTRUÇÕES IMPLEMENTADAS NO LOGISIM** {#3.-instruções-implementadas-no-logisim}

### **3[.1.](#heading=h.6iqxn94rrje3) Move** {#3.1.-move}

O move é uma pseudoinstrução do MIPS que, na prática, funciona como um add, ou seja, uma soma, na qual cada operando é zero. Muitas vezes é necessário passar parâmetros dentro do MIPS, para isso temos o move, que copia os parâmetros de um registrador para outro registrador antes do procedimento. Seu principal uso no circuito é no mux que define a entrada write\_data do banco de registradores.  
Formato Tipo I:  
6 bits                \-                5 bits                \-                5 bits                \-                16 bits  
(opcode)                 (registrador origem)                (registrador destino)                (livres)

### **3[.2.](#heading=h.6iqxn94rrje3) Load Immediate (li)**  {#3.2.-load-immediate-(li)}

A instrução load immediate (li) funciona semelhante a um load comum, no entanto, enquanto o lw carrega um valor da memória, o li carrega um imediato em um registrador, sendo esse imediato um valor que já está no código. Seu principal uso no circuito é no mux que define a entrada write\_data do banco de registradores.  
Formato Tipo I:  
6 bits                \-                5 bits                \-                5 bits                \-                16 bits  
(opcode)                          (livres)                      (registrador destino)                (imediato)

### **3[.3.](#heading=h.6iqxn94rrje3) Branch if Less Than (blt)** {#3.3.-branch-if-less-than-(blt)}

O branch if less than, no montador do MIPS, equivale como uma combinação das instruções slt e bne. O blt compara dois registradores e, se o valor do primeiro for menor que o do segundo, o programa salta para a label escolhida. Seu principal uso no circuito é no mux que define se a flag should\_branch deve ou não forçar um desvio e consequentemente, no mux que define o valor do PC.:  
Formato Tipo I, igual ao BEQ e BNE:  
6 bits                \-                5 bits                \-                5 bits                \-                16 bits  
(opcode)                             (rs)                                     (rt)                                (imediato)

## **4[.](#heading=h.xw760wmras6s) DESAFIOS E SOLUÇÕES** {#4.-desafios-e-soluções}

### **4[.1.](#heading=h.6iqxn94rrje3) Incompatibilidade de bits** {#4.1.-incompatibilidade-de-bits}

Ao fazer as alterações no circuito do projeto anterior para implementar o sistema de deslocamento de 2 bits para a esquerda, houve uma incompatibilidade entre as componentes do processador. O tamanho em bits de PC \+ 4 e do imediato, após passar pelo deslocamento de 2 bits, eram incompatíveis quando conectados em um somador. Visando solucionar esse problema, alteramos PC \+ 4 para 32 bits.

### **4[.2.](#heading=h.6iqxn94rrje3) Concatenamento de bits e uso do splitter** {#4.2.-concatenamento-de-bits-e-uso-do-splitter}

Ainda falando sobre o circuito, na atualização do PC para 32 bits e a necessidade de realizar saltos e desvios que utilizam o valor de PC \+ 4, surgiu um outro problema: o uso de splitters e deslocadores para manipular os bits. Específicamente, na criação do splitter da Memória de Instrução, que carregaria os 26 bits do imediato tipo J, houve muita dificuldade e o excesso de fios criou a necessidade de se fazer os UPGRADES visuais mencionados anteriormente.  
Felizmente, fazendo-se uma pesquisa nas principais referências, logo achamos a explicação, semelhante ao que o professor deu em sala de aula, sobre como fazer os deslocamentos e concatenar bis utilizando splitters no Logisim.

### **4[.3.](#heading=h.6iqxn94rrje3) Utilização do LUI**  {#4.3.-utilização-do-lui}

     Utilização do LUI em valores muito altos se deu somente no MARS, visto que os endereços e valores utilizados no MIPS-Logisim não eram tão altos. Ainda assim, foi necessário entender a funcionalidade para realizar esse uso no código assembly.

### **4[.4.](#heading=h.6iqxn94rrje3) Syscalls**

No MARS, temos uma ferramenta bastante útil e amplamente utilizável, que são as syscalls. Contudo, na hora de fazer uma código para o nosso processador personalizado no Logisim, elas se tornam um problema, visto que precisamos adaptar. Aqui vai, retirado diretamente do código no arquivo snake-game.asm explicando as substituições feitas:  
\# 32 \- sleep:   
\# move $t4, $s4;  
\# addi $t4, $t4, \-1  
\# bne $t4, $0, \-2  
\#  
\# 10 \- exit:  
\# jump FFFF  
\#  
\# 42 \- random int range.  
\# lw $t5, FF00  
\# move $v0, $t5

## **5[.](#heading=h.xw760wmras6s) FORWARDING E HAZARD DETECTION** {#5.-forwarding-e-hazard-detection}

### **5.1[.](#heading=h.6iqxn94rrje3) Forwarding (Bypass)**  {#5.1.-forwarding-(bypass)}

O Forwarding permite que o resultado de uma instrução seja utilizado por uma instrução seguinte antes de ser escrito no banco de registradores. A lógica de implementação do forwarding consiste em comparar os registadores de origem da instrução atual, que estará em ID/EX, com os registadores de destino das instruções que estão nos estágios seguintes.  
Adicionamos multiplexadores nas entradas da ALU, assim, se a unidade detectar uma igualdade nos números dos registradores, ela sinaliza ao multiplexador para selecionar o dado vindo do registrador de pipeline em vez do dado lido do banco de registradores.  
Existem as seguintes condições do forwarding, referentes ao hazard:

**Hazard EX:** Ocorre quando a instrução anterior gera um resultado que a instrução atual precisa.  
EX/MEM.Rd \= ID/EX.Rs (ou Rt).

**Hazard MEM:** Ocorre quando a instrução produziu o resultado necessário.  
MEM/WB.Rd \= ID/EX.rRs (ou Rt).

### **5.2[.](#heading=h.6iqxn94rrje3) Hazard Detection**  {#5.2.-hazard-detection}

Apesar do forwarding ser fundamental, há situações em que ele não consegue resolver ou que não é possível usá-lo. Para isso, existe a Hazard Detection Unit, que detecta quando é necessário parar o pipeline, sendo esse processo o stall. A lógica do stall, ou bolha, funciona da seguinte forma: como o dado do lw está disponível apenas no final do MEM, mas eu necessito dele no estágio EX, que vem anterior a esse, a instrução seguinte não o recebe a tempo.   
Para isso ocorrer, temos as seguintes condições de stall:

Se **ID/EX.MemRead \= 1:** A instrução no estágio EX é um load;

Então: **ID/EX.Rt \== IF/[ID.Rs](http://ID.Rs)**  ou **ID/EX.Rt \== IF/[ID.Rt](http://ID.Rt)**

Assim, a unidade de detecção impede que novas instruções sejam processadas e que a instrução atual saia do estágio de decodificação, ou seja, o PC não avança e o IF/ID não é atualizado, ambos permanecem parados.  
Ademais, os sinais de controle no registrador ID/EX são zerados para garantir que a instrução não escreva na memória nem nos registradores enquanto o pipeline aguarda o dado, criando assim uma NOP (bolha).

### **5.3[.](#heading=h.6iqxn94rrje3) Desafios com Branches (Saltos)** {#5.3.-desafios-com-branches-(saltos)}

Ao trabalhar com as instruções de desvio (beq, bne) no pipeline são gerados os chamados Hazards de Controle. Os hazards de controle ocorrem quando o processador não identifica se o desvio vai ser executado ou qual é o endereço de destino até que a instrução branch seja processada. Logo, se o pipeline continua buscando as instruções, eventualmente poderá trazer instruções incorretas.  
Algumas das maneiras de resolver esse problema são: parar o pipeline até confirmar se o resultado está correto; mover o hardware de comparação de igualdade e o cálculo do endereço de destino do estágio EX para o estágio ID, visando reduzir o número de ciclos; e prever se o salto será tomado, limpando os registradores caso a previsão esteja errada e transformando-os em NOPs.

## **6[. REFERÊNCIAS](#heading=h.xw760wmras6s)** {#6.-referências}

Organização e Projeto de Computadores (David A. Patterson, John L. Hennessy) 

https://youtube.com/playlist?list=PLR2tpXhN7CHd9MTiglTMUCyeAoEtjXzRw\&si=I4g46OB9BGipnGED

[image1]: <data:image/png;base64,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>