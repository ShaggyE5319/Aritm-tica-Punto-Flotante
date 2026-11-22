
from cpu import CPU
from enlazador_cargador import EnlazadorCargador
from memoria import MemoriaRAM


def main():
    print("==================================================")
    print("    EMULADOR DE ARQUITECTURA 64-BIT - SPRY 1.0    ")
    print("==================================================")
    
    ram = MemoriaRAM(size_bytes=4096)  
    cpu = CPU(ram)
    cargador = EnlazadorCargador(ram, cpu)
    
    while True:
        print("\n--- MENÚ PRINCIPAL ---")
        print("1. Cargar archivo binario en RAM")
        print("2. Ver estado de la CPU y Banco de Registros")
        print("3. Ver contenido de la RAM")
        print("4. Ejecutar modo Paso a Paso")
        print("5. Ejecutar modo Automático (hasta HLT)")
        print("6. Salir")
        print("7. Escribir un bit directamente en RAM")
        
        opcion = input("Selecciona una opción: ").strip()
        
        if opcion == "1":
            ruta = input("Ingresa la ruta del archivo de código máquina (ej. programa.txt): ").strip()
            base_str = input("Dirección base en Hex [Por defecto 0x200]: ").strip()
            direccion_base = int(base_str, 16) if base_str else 0x200
            inicializar_str = input(
                "¿Inicializar PC y registros con esta carga? [S/n]: "
            ).strip().lower()
            inicializar_cpu = inicializar_str not in ("n", "no")
            cargador.cargar_programa(
                ruta,
                direccion_base=direccion_base,
                inicializar_cpu=inicializar_cpu,
            )
            
        elif opcion == "2":
            cpu.mostrar_estado()
            
        elif opcion == "3":
            try:
                inicio_str = input("Dirección inicial en Hex (ej. 0x200) [Por defecto 0x200]: ").strip()
                inicio = int(inicio_str, 16) if inicio_str else 0x200
                
                palabras_str = input("Cantidad de palabras a mostrar [Por defecto 16]: ").strip()
                cantidad = int(palabras_str) if palabras_str else 16
                
                ram.volcado_memoria(inicio=inicio, cantidad_palabras=cantidad)
            except ValueError:
                print("[Error] Formato de dirección o cantidad inválido. Use hexadecimal para la dirección.")
                
        elif opcion == "4":
            if cpu.halted:
                print("[Aviso] El procesador está en estado HLT. Recarga el programa o reinicia.")
                continue
                
            print("\n--- MODO PASO A PASO (Presiona Enter para avanzar) ---")
            while not cpu.halted:
                cpu.mostrar_estado()
                input("Presiona [Enter] para ejecutar el siguiente ciclo de reloj...")
                continuar = cpu.ejecutar_ciclo()
                if not continuar:
                    break
            print("\n[CPU] Ejecución detenida o finalizada.")
            cpu.mostrar_estado()
            
        elif opcion == "5":
            if cpu.halted:
                print("[Aviso] El procesador está en estado HLT. Recarga el programa o reinicia.")
                continue
                
            print("\n--- MODO AUTOMÁTICO ---")
            cpu.correr_automatico()
            print("\n[CPU] Ejecución automática completada.")
            cpu.mostrar_estado()
            
        elif opcion == "6":
            print("¡Saliendo del emulador Spry 1.0. Hasta luego!")
            break
        elif opcion == "7":
            try:
                direccion = int(input("Dirección de RAM en Hex: ").strip(), 16)
                bit = int(input("Posición del bit (0-7): ").strip())
                valor = int(input("Valor del bit (0 o 1): ").strip())
                ram.escribir_bit(direccion, bit, valor)
                byte_actual = ram.leer_byte(direccion)
                print(
                    f"[RAM] Bit escrito correctamente. "
                    f"Byte en 0x{direccion:03X}: 0x{byte_actual:02X}"
                )
            except (ValueError, IndexError) as error:
                print(f"[Error] No se pudo escribir el bit: {error}")
        else:
            print("Opción inválida. Por favor, selecciona un número del 1 al 7.")

if __name__ == "__main__":
    main()