#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <irq.h>
#include <uart.h>
#include <console.h>
#include <generated/csr.h>

char dataPixel[21]= "";
char data;
long long int integerValue;
int direccion = 0;
int contador = 0;
int changeRam = 0;
int i = 0;
char past_read = 0;
char readm = 0;


void my_busy_wait(unsigned int ms)
{
	timer0_en_write(0);
	timer0_reload_write(0);
	timer0_load_write(CONFIG_CLOCK_FREQUENCY/1000*ms);
	timer0_en_write(1);
	timer0_update_value_write(1);
	while(timer0_value_read()) timer0_update_value_write(1);
}

void clean_memories()
{
	for (int dir = 0; dir < 3200; dir++)
	{
		pantalla_addrWrite_write(dir);
		pantalla_wr_write(1);
		pantalla_dataLine1_write(0);
		pantalla_wr_write(0);
		pantalla_dataLine2_write(0);
	}	
}

int main(void)
{
	irq_setmask(0);
	irq_setie(1);
	uart_init();
	puts("\nCPU testing PANTALLA SoC\n");
	printf("Hola Mundo \n");
	
	while(1) {
		// Obtencion dato serial
   		while(1){
			data = uart_read();
			if (data >= '0' && data <= '9')
			{
				dataPixel[i]=data;
				i++;
			} else 
			{
				dataPixel[i]='\0'; // Finalizacion de linea
				break;
			}
		}

		i = 0;
		integerValue = atoll(dataPixel); // Pasar string a long long int
		pantalla_enable_write(1); // Prender pantalla
	   	pantalla_RamTime_write(2*41250000); // = 25M/(2*1/3.3seg) 
	   	//pantalla_RamTime_write(2*50000000); // = 25M/(2*1/4seg) 
		
		if (direccion == 3200) { // Reseteo de direccion
			direccion = 0;
		}
		pantalla_addrWrite_write(direccion);
		//printf("Direccion: %d,Entero: %lld\n ", direccion,integerValue);
		direccion = direccion + 1; //Incremento de direccion
		

		//Switcheo de RAM
		if (contador <= 3200) {
			contador++;
		} else {
			contador = 0;
			//printf("\nantes\n");
			//readm = pantalla_requireData_read();
			//past_read = readm;
			while (past_read == readm) {
				past_read = readm;
				readm = pantalla_requireData_read();
			}
			//printf("dddddddddddddddd");
			/*for (char intento = 0; intento < 5; intento++)
			{
				uart_write(100);
			}
			//uart_write(100);*/
			if (changeRam == 0) 
			{
				changeRam = 1;
			} else 
			{
				changeRam = 0;
			}
		}

		//Switcheo de RAM
		if (changeRam == 1){
			pantalla_wr_write(1);
			pantalla_dataLine1_write(integerValue);
		} else {
			pantalla_wr_write(0);
			pantalla_dataLine2_write(integerValue);
		}
	}
}