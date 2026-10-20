#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <cstdint>
#include <cstring>
#include <cstdio>
#include <cstdlib>

using namespace std;

// Constantes de memoria y layout de Spry OS 1.0
const uint16_t RAM_SIZE = 4096;
const uint16_t MASK_12B = 0x0FFF;

const uint16_t KERNEL_BASE = 0x020;
const uint16_t USER_BASE   = 0x200;
const uint16_t USER_END    = 0xDFF;
const uint16_t INIT_SP     = 0xFFF;

// Banderas FR
const uint8_t FLAG_Z = (1 << 0);
const uint8_t FLAG_N = (1 << 1);
const uint8_t FLAG_C = (1 << 2);
const uint8_t FLAG_V = (1 << 3);
const uint8_t FLAG_I = (1 << 4);

// Opcodes principales
const uint16_t OP_JMP   = 0x0001;
const uint16_t OP_ADD   = 0x0011;
const uint16_t OP_SUB   = 0x0012;
const uint16_t OP_MUL   = 0x0013;
const uint16_t OP_CMP   = 0x0025;
const uint16_t OP_STORE = 0x0032;
const uint16_t OP_MOV   = 0x0033;
const uint16_t OP_LOADA = 0x0034;
const uint16_t OP_LDI   = 0x0038;
const uint16_t OP_JZ    = 0x0042;
const uint16_t OP_JL    = 0x0045;
const uint16_t OP_HLT   = 0x1200;
const uint16_t OP_LOAD  = 0x8C00;

// Formatos en la tabla de reubicacion
enum TipoReub : uint8_t {
    FMT_SALTO_28B = 3,
    FMT_MEM_40B   = 5,
    FMT_MEM_64B   = 15,
    FMT_SALTO_64B = 16
};

#pragma pack(push, 1)
struct Header {
    uint16_t n_bytes;
    uint16_t offset_pc;
    uint16_t num_reub;
};

struct Reubicacion {
    uint16_t offset;
    uint8_t formato;
};
#pragma pack(pop)

struct Binario {
    Header hdr;
    vector<uint8_t> codigo;
    vector<Reubicacion> tabla;

    bool guardar(const string& ruta) {
        ofstream f(ruta, ios::binary);
        if (!f) return false;
        f.write((const char*)&hdr, sizeof(Header));
        f.write((const char*)codigo.data(), codigo.size());
        f.write((const char*)tabla.data(), tabla.size() * sizeof(Reubicacion));
        return f.good();
    }

    static Binario leer(const string& ruta) {
        ifstream f(ruta, ios::binary);
        if (!f) {
            cerr << "No se pudo abrir: " << ruta << endl;
            exit(1);
        }
        Binario b;
        f.read((char*)&b.hdr, sizeof(Header));
        b.codigo.resize(b.hdr.n_bytes);
        f.read((char*)b.codigo.data(), b.hdr.n_bytes);
        b.tabla.resize(b.hdr.num_reub);
        f.read((char*)b.tabla.data(), b.hdr.num_reub * sizeof(Reubicacion));
        return b;
    }
};

struct Computador {
    uint8_t ram[RAM_SIZE];
    uint8_t cache_l1[128];
    uint64_t cache_l2[64];

    // Registros CPU
    uint64_t r[16];
    uint16_t pc;
    uint64_t ir;
    uint16_t mar;
    uint64_t mdr;
    uint16_t sp;
    uint8_t fr;
    bool fetch;

    Computador() {
        memset(ram, 0, sizeof(ram));
        memset(cache_l1, 0, sizeof(cache_l1));
        memset(cache_l2, 0, sizeof(cache_l2));
        memset(r, 0, sizeof(r));
        pc = 0; ir = 0; mar = 0; mdr = 0;
        sp = INIT_SP;
        r[13] = INIT_SP;
        fr = 0;
        fetch = false;
    }

    // Escritura en RAM simulando bus de direcciones (MAR) y de datos (MDR)
    void escribir_bus(uint16_t dir, uint64_t dato, int bytes) {
        mar = dir & MASK_12B;
        mdr = dato;
        for (int i = 0; i < bytes; i++) {
            uint16_t pos = (mar + i) & MASK_12B;
            ram[pos] = (uint8_t)((mdr >> (56 - 8 * i)) & 0xFF);
        }
    }

    void flush_caches() {
        memset(cache_l1, 0, sizeof(cache_l1));
        memset(cache_l2, 0, sizeof(cache_l2));
    }
};

// Extrae o modifica 12 bits de una instruccion en RAM
uint16_t leer_dir12(const uint8_t* ram, uint16_t addr, int bit_ini) {
    uint64_t ventana = 0;
    for (int i = 0; i < 8; i++) {
        ventana = (ventana << 8) | ram[(addr + i) & MASK_12B];
    }
    int shift = 64 - (bit_ini + 12);
    return (uint16_t)((ventana >> shift) & MASK_12B);
}

void escribir_dir12(uint8_t* ram, uint16_t addr, int bit_ini, uint16_t nueva_dir) {
    uint64_t ventana = 0;
    for (int i = 0; i < 8; i++) {
        ventana = (ventana << 8) | ram[(addr + i) & MASK_12B];
    }
    int shift = 64 - (bit_ini + 12);
    uint64_t mask = ~((uint64_t)MASK_12B << shift);
    ventana = (ventana & mask) | ((uint64_t)(nueva_dir & MASK_12B) << shift);

    for (int i = 0; i < 8; i++) {
        ram[(addr + i) & MASK_12B] = (uint8_t)((ventana >> (56 - 8 * i)) & 0xFF);
    }
}

// Fases del enlazador-cargador
bool validar_limites(uint16_t base, uint16_t n) {
    cout << "Validando limites..." << endl;
    if ((int)base + (int)n > RAM_SIZE) {
        cerr << "Error: el programa supera los 4096 bytes de la RAM." << endl;
        return false;
    }
    if (base < USER_BASE || (base + n - 1) > USER_END) {
        cout << "  Nota: cargando fuera del rango de usuario (0x200 - 0xDFF)" << endl;
    }
    printf("  OK: 0x%03X a 0x%03X (%u bytes)\n", base, base + n - 1, n);
    return true;
}

void transferir_ram(Computador& comp, const Binario& bin, uint16_t base) {
    cout << "Cargando en RAM..." << endl;
    size_t total = bin.codigo.size();
    size_t idx = 0;

    while (idx < total) {
        uint64_t bloque = 0;
        int n = (total - idx < 8) ? (total - idx) : 8;
        for (int i = 0; i < n; i++) {
            bloque |= ((uint64_t)bin.codigo[idx + i] << (56 - 8 * i));
        }
        comp.escribir_bus(base + idx, bloque, n);
        idx += n;
    }
    printf("  %zu bytes transferidos desde 0x%03X\n", total, base);
}

void reubicar_codigo(Computador& comp, const Binario& bin, uint16_t base) {
    cout << "Aplicando reubicacion..." << endl;
    for (size_t i = 0; i < bin.tabla.size(); i++) {
        uint16_t dir_inst = (base + bin.tabla[i].offset) & MASK_12B;
        int bit_offset = 0;

        if (bin.tabla[i].formato == FMT_SALTO_28B) bit_offset = 16;
        else if (bin.tabla[i].formato == FMT_MEM_40B || bin.tabla[i].formato == FMT_MEM_64B) bit_offset = 22;
        else if (bin.tabla[i].formato == FMT_SALTO_64B) bit_offset = 20;

        uint16_t d_rel = leer_dir12(comp.ram, dir_inst, bit_offset);
        uint16_t d_fis = (d_rel + base) % RAM_SIZE;
        escribir_dir12(comp.ram, dir_inst, bit_offset, d_fis);

        printf("  #%zu [offset 0x%03X]: dir_rel 0x%03X -> dir_fis 0x%03X\n",
               i + 1, dir_inst, d_rel, d_fis);
    }
}

void invalidar_cache(Computador& comp) {
    cout << "Limpiando caches..." << endl;
    comp.flush_caches();
    cout << "  L1 (128B) y L2 (512B) limpias." << endl;
}

void iniciar_cpu(Computador& comp, uint16_t base, uint16_t offset_pc) {
    cout << "Inicializando CPU..." << endl;
    comp.pc = (base + offset_pc) & MASK_12B;
    comp.sp = INIT_SP;
    comp.r[13] = INIT_SP;
    comp.fr = 0x00;
    comp.fetch = true;

    printf("  PC = 0x%03X | SP (R13) = 0x%03X | FR = 0x%02X | Fetch = ACTIVO\n",
           comp.pc, comp.sp, comp.fr);

    comp.fr |= FLAG_I;
    comp.r[14] = KERNEL_BASE;
    printf("  [Spry OS] Interrupciones activas (FR = 0x%02X), LR (R14) = 0x%03llX\n",
           comp.fr, (unsigned long long)comp.r[14]);
}

void mostrar_ram(const Computador& comp, uint16_t base, size_t len) {
    printf("\nVolcado de RAM (0x%03X):\n", base);
    for (size_t i = 0; i < len; i += 8) {
        uint16_t dir = (base + i) & MASK_12B;
        printf("0x%03X: ", dir);
        size_t tope = (len - i < 8) ? (len - i) : 8;
        for (size_t j = 0; j < 8; j++) {
            if (j < tope) printf("%02X ", comp.ram[(dir + j) & MASK_12B]);
            else printf("   ");
        }
        printf("\n");
    }
    printf("\n");
}

bool ejecutar_cargador(Computador& comp, const Binario& bin, uint16_t base) {
    comp.sp = INIT_SP;
    comp.r[13] = INIT_SP;
    comp.fr &= ~FLAG_I;

    if (!validar_limites(base, bin.hdr.n_bytes)) return false;
    transferir_ram(comp, bin, base);
    reubicar_codigo(comp, bin, base);
    invalidar_cache(comp);
    iniciar_cpu(comp, base, bin.hdr.offset_pc);
    mostrar_ram(comp, base, bin.hdr.n_bytes);
    return true;
}

void inst_sin_op_16b(vector<uint8_t>& v, uint16_t op) {
    v.push_back((op >> 8) & 0xFF);
    v.push_back(op & 0xFF);
}

void inst_salto_28b(vector<uint8_t>& v, uint16_t op, uint16_t dir) {
    uint32_t w = ((uint32_t)op << 16) | ((uint32_t)(dir & 0xFFF) << 4);
    for (int i = 3; i >= 0; i--) v.push_back((w >> (i * 8)) & 0xFF);
}

void inst_alu_32b(vector<uint8_t>& v, uint16_t op, uint8_t modo, uint8_t rd, uint8_t rf1, uint8_t rf2) {
    uint32_t w = ((uint32_t)op << 16) | ((modo & 0xF) << 12) | ((rd & 0xF) << 8) | ((rf1 & 0xF) << 4) | (rf2 & 0xF);
    for (int i = 3; i >= 0; i--) v.push_back((w >> (i * 8)) & 0xFF);
}

void inst_mem_40b(vector<uint8_t>& v, uint16_t op, uint8_t modo, uint8_t reg, uint16_t dir) {
    uint64_t w = ((uint64_t)op << 24) | ((uint64_t)(modo & 0x3) << 22) | ((uint64_t)(reg & 0xF) << 18) | ((uint64_t)(dir & 0xFFF) << 6);
    for (int i = 4; i >= 0; i--) v.push_back((w >> (i * 8)) & 0xFF);
}

void inst_imm_40b(vector<uint8_t>& v, uint16_t op, uint8_t modo, uint8_t rd, uint16_t imm) {
    uint64_t w = ((uint64_t)op << 24) | ((uint64_t)(modo & 0x3) << 22) | ((uint64_t)(rd & 0xF) << 18) | ((uint64_t)imm << 2);
    for (int i = 4; i >= 0; i--) v.push_back((w >> (i * 8)) & 0xFF);
}

// Programa de prueba: suma de un arreglo en memoria
Binario armar_algoritmo_vector() {
    Binario b;
    inst_imm_40b(b.codigo, OP_LDI, 0, 0, 0x040);
    inst_imm_40b(b.codigo, OP_LDI, 0, 1, 5);
    inst_imm_40b(b.codigo, OP_LDI, 0, 2, 0);
    inst_imm_40b(b.codigo, OP_LDI, 0, 3, 1);
    
    inst_alu_32b(b.codigo, OP_CMP, 0, 1, 1, 3);
    inst_salto_28b(b.codigo, OP_JL, 0x030);
    inst_alu_32b(b.codigo, OP_LOADA, 0, 4, 0, 0);
    inst_alu_32b(b.codigo, OP_ADD, 0, 2, 2, 4);
    inst_alu_32b(b.codigo, OP_ADD, 0, 0, 0, 3);
    inst_alu_32b(b.codigo, OP_SUB, 0, 1, 1, 3);
    inst_salto_28b(b.codigo, OP_JMP, 0x014);
    
    inst_mem_40b(b.codigo, OP_STORE, 0, 2, 0x045);
    inst_sin_op_16b(b.codigo, OP_HLT);

    b.codigo.resize(0x048, 0);
    b.codigo[0x040] = 10;
    b.codigo[0x041] = 20;
    b.codigo[0x042] = 30;
    b.codigo[0x043] = 40;
    b.codigo[0x044] = 50;

    b.tabla = {
        { 0x018, FMT_SALTO_28B },
        { 0x02C, FMT_SALTO_28B },
        { 0x030, FMT_MEM_40B }
    };

    b.hdr.n_bytes = b.codigo.size();
    b.hdr.offset_pc = 0x000;
    b.hdr.num_reub = b.tabla.size();
    return b;
}

int main(int argc, char** argv) {
    Computador spry;
    uint16_t base = USER_BASE;

    if (argc >= 2) {
        string archivo = argv[1];
        if (argc >= 3) {
            base = (uint16_t)strtoul(argv[2], nullptr, 0);
        }
        Binario bin = Binario::leer(archivo);
        ejecutar_cargador(spry, bin, base);
        return 0;
    }

    Binario prog = armar_algoritmo_vector();
    prog.guardar("programa.bin");

    Binario cargado = Binario::leer("programa.bin");
    ejecutar_cargador(spry, cargado, base);

    return 0;
}