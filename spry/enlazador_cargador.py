
class EnlazadorCargador:
    def __init__(self, memoria_ram, cpu):
        self.ram = memoria_ram
        self.cpu = cpu

    def cargar_programa(self, ruta_archivo, direccion_base=0x200, inicializar_cpu=True):
        """
        Fases operativas del Cargador y Reubicador:
        1. Validación de límites: Base + N <= 4096 para no desbordar los 12 bits.
        2. Transferencia física: Copiar código y datos a la RAM a partir de la dirección base.
        3. Inicialización del procesador (PC, SP, FR) y arranque del ciclo fetch[cite: 1].
        """
        try:
            with open(ruta_archivo, 'r', encoding='utf-8') as f:
                contenido = f.read()

            from assembler import assemble_file
            try:
                palabras = [int(linea.strip(), 16) for linea in contenido.splitlines()
                            if linea.strip() and not linea.strip().startswith("#")]
            except ValueError:
                palabras = assemble_file(ruta_archivo, base=direccion_base)

            cantidad_instrucciones = len(palabras)
            tamanio_bytes = cantidad_instrucciones * 8
            
            if direccion_base + tamanio_bytes > 4096:
                raise ValueError(
                    f"Error de desbordamiento: El programa excede los límites de la RAM de 4 KB "
                    f"(Fin estimado: 0x{direccion_base + tamanio_bytes:03X})."
                )
            
            dir_actual = direccion_base
            for valor_binario in palabras:
                self.ram.escribir_palabra_64(dir_actual, valor_binario)
                dir_actual += 8  
                
            if inicializar_cpu:
                self.cpu.pc = direccion_base 
                self.cpu.regs[13] = 0xFFF    
                self.cpu.fr['I'] = 1         
                self.cpu.halted = False      
            
            print(f"[Cargador] ¡Éxito! Programa cargado en RAM desde 0x{direccion_base:03X}.")
            if inicializar_cpu:
                print(f"[Cargador] Registros inicializados: PC = 0x{self.cpu.pc:03X}, SP = 0x{self.cpu.regs[13]:03X}.")
            else:
                print("[Cargador] CPU conservada; solo se cargaron datos en RAM.")
            return True

        except (OSError, ValueError, IndexError, KeyError, TypeError) as e:
            print(f"[Error de Carga] No se pudo procesar el archivo: {e}")
            return False