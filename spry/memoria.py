
class MemoriaRAM:
    def __init__(self, size_bytes=4096):
        """
        Inicializa la RAM principal de 4 KB (4096 bytes), direccionable por byte,
        siguiendo el layout de memoria del sistema:
        - 0x000 a 0x01F: Tabla de Vectores (IVT)
        - 0x020 a 0x1FF: Kernel del Sistema (Bootloader y Drivers)
        - 0x200 a 0xDFF: Espacio de Usuario (Código y Datos)
        - 0xE00 a 0xFFF: Stack del Sistema (Puntero R13 / SP)
        """
        self.size = size_bytes
        self.storage = bytearray(self.size)  

    def _verificar_limites(self, direccion):
        """Verifica que la dirección esté dentro del bus de 12 bits (0x000 a 0xFFF)[cite: 1]."""
        if not (0 <= direccion < self.size):
            raise IndexError(f"Segmentation Fault: Dirección de memoria 0x{direccion:03X} fuera del rango de 4 KB.")

    def leer_byte(self, direccion):
        """Lee un único byte (8 bits) desde la RAM."""
        self._verificar_limites(direccion)
        return self.storage[direccion]

    def escribir_byte(self, direccion, valor):
        """Escribe un único byte (8 bits) en la RAM."""
        self._verificar_limites(direccion)
        self.storage[direccion] = valor & 0xFF

    def leer_bit(self, direccion, bit):
        """Lee un bit de un byte de RAM; el bit 0 es el menos significativo."""
        self._verificar_limites(direccion)
        if not 0 <= bit <= 7:
            raise ValueError("La posición del bit debe estar entre 0 y 7.")
        return (self.storage[direccion] >> bit) & 1

    def escribir_bit(self, direccion, bit, valor):
        """Escribe un bit de un byte de RAM; el bit 0 es el menos significativo."""
        self._verificar_limites(direccion)
        if not 0 <= bit <= 7:
            raise ValueError("La posición del bit debe estar entre 0 y 7.")
        if valor not in (0, 1):
            raise ValueError("El valor del bit debe ser 0 o 1.")
        mascara = 1 << bit
        if valor:
            self.storage[direccion] |= mascara
        else:
            self.storage[direccion] &= ~mascara & 0xFF

    def leer_palabra_64(self, direccion):
        """
        Lee una palabra completa de 64 bits (8 bytes consecutivos) 
        a partir de una dirección base, usando formato Big-Endian.
        Vital para instrucciones de longitud variable y datos de 64 bits.
        """
        self._verificar_limites(direccion + 7)
        
        palabra = 0
        for i in range(8):
            palabra = (palabra << 8) | self.storage[direccion + i]
        return palabra

    def escribir_palabra_64(self, direccion, dato):
        """
        Escribe una palabra de 64 bits (8 bytes) dividiéndola 
        en 8 posiciones consecutivas de la RAM.
        """
        self._verificar_limites(direccion + 7)
        
        for i in range(7, -1, -1):
            self.storage[direccion + i] = dato & 0xFF
            dato >>= 8

    def volcado_memoria(self, inicio=0x200, cantidad_palabras=16):
        """
        Muestra un fragmento de la RAM en formato de palabras de 64 bits 
        para depuración visual por consola.
        """
        print(f"\n--- ESTADO DE LA RAM (Direccionamiento por Bytes - 4 KB) ---")
        print(f"Mostrando desde 0x{inicio:03X}:")
        
        for i in range(0, cantidad_palabras * 8, 8):
            dir_actual = inicio + i
            if dir_actual + 7 >= self.size:
                break
            try:
                valor = self.leer_palabra_64(dir_actual)
                print(f"0x{dir_actual:03X}: 0x{valor:016X}")
            except IndexError:
                break
        print("-----------------------------------------------------------\n")