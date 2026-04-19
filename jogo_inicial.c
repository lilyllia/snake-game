/*
 * Jogo simples em C: Um jogo tipo Snake onde o jogador controla um ponto em uma grade.
 * O objetivo é coletar comida (representada por 2) para aumentar a pontuação.
 * O jogo termina quando a pontuação atinge 5.
 * Controles: 1 (baixo), 2 (direita), 4 (cima), 8 (esquerda).
 */

#include <stdio.h>
#include <stdlib.h>

#define SIZE 16 // Tamanho da grade (16x16)

int grid[SIZE][SIZE]; // Matriz que representa a grade do jogo
int key_pressed;      // Tecla pressionada pelo usuário
int x_pos_cur = 4;    // Posição x atual do jogador
int y_pos_cur = 4;    // Posição y atual do jogador
int x_pos_next = 4;   // Próxima posição x
int y_pos_next = 4;   // Próxima posição y
int x_food = 2;       // Posição x da comida
int y_food = 2;       // Posição y da comida
int delay_time = 256; // Tempo de delay entre movimentos
int score = 0;        // Pontuação do jogador

void print_grid()
{
  system("cls"); // Limpa a tela do console
  for (int i = 0; i < SIZE; i++)
  {
    for (int j = 0; j < SIZE; j++)
    {
      printf("%d ", grid[i][j]); // Imprime o valor de cada célula da grade
    }
    printf("\n"); // Nova linha após cada linha da grade
  }
}

void delay(int i)
{
  do
  {
    i = i - 1; // Decrementa i até chegar a 0
  } while (i != 0); // Loop de delay simples
}

void write_grid(int x, int y, int value)
{
  grid[y][x] = value; // Define o valor na posição (x, y) da grade
}

int random_position()
{
  return rand() % SIZE; // Retorna uma posição aleatória entre 0 e SIZE-1
}

int read_key()
{
  int key;
  scanf("%d", &key); // Lê um inteiro do usuário
  return key;        // Retorna a tecla pressionada
}

int main()
{
  write_grid(x_pos_cur, y_pos_cur, 1); // Coloca o jogador na posição inicial
  write_xgrid(x_food, y_food, 2);       // Coloca a comida na posição inicial
  print_grid();                        // Imprime a grade inicial
  while (1)                            // Loop principal do jogo
  {
    key_pressed = read_key(); // Lê a entrada do usuário
    switch (key_pressed)      // Determina a próxima posição baseada na tecla
    {
    case 1: // Esquerda
      if (x_pos_cur - 1 < 0)
        x_pos_next = SIZE - 1;
      else
        x_pos_next = x_pos_cur - 1;
      break;
    case 2: // Baixo
      if (y_pos_cur + 1 >= SIZE)
        y_pos_next = 0;
      else
        y_pos_next = y_pos_cur + 1;
      break;
    case 4: // Direita
      if (x_pos_cur + 1 >= SIZE)
        x_pos_next = 0;
      else
        x_pos_next = x_pos_cur + 1;
      break;
    case 8: // Cima
      if (y_pos_cur - 1 < 0)
        y_pos_next = SIZE - 1;
      else
        y_pos_next = y_pos_cur - 1;
      break;
    default:
      break;
    };
    if (x_food == x_pos_next && y_food == y_pos_next) // Verifica se o jogador comeu a comida
    {
      x_food = random_position();    // Gera nova posição x para a comida
      y_food = random_position();    // Gera nova posição y para a comida
      write_grid(x_food, y_food, 2); // Coloca a comida na nova posição (nota: deveria ser 2?)
      delay_time = delay_time / 2;   // Aumenta a velocidade
      score++;                       // Incrementa a pontuação
    }
    write_grid(x_pos_cur, y_pos_cur, 0); // Limpa a posição anterior do jogador
    x_pos_cur = x_pos_next;              // Atualiza a posição x atual
    y_pos_cur = y_pos_next;              // Atualiza a posição y atual
    write_grid(x_pos_cur, y_pos_cur, 1); // Coloca o jogador na nova posição
    print_grid();                        // Imprime a grade atualizada
    delay(delay_time);                   // Aplica o delay
    if (score == 5)                      // Verifica se o jogo terminou
    {
      break; // Sai do loop
    }
    printf("\n\n\n"); // Nova linha após cada linha da grade
  };
  return 0;
}