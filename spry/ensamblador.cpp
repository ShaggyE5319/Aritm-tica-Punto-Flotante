#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <unordered_map>
#include <iomanip>
#include <cstdint>
#include <cstdlib>
#include <stdexcept>

extern "C" {
    int yylex();
    extern FILE* yyin;
    extern char* yytext;
}

char* token_val = nullptr;

enum TokenType {
    T_NONE = 0,
    T_INSTRUCTION = 1,
    T_REGISTER = 2,
    T_NUMBER = 3,
    T_LABEL_DEF = 4,
    T_LABEL_REF = 5,
    T_DIRECTIVE = 6,
    T_COMMA = 7,
    T_NEWLINE = 8
};

struct Token {
    int type;
    std::string val;
};

struct SymbolTable {
    std::unordered_map<std::string, uint16_t> labels;
};

SymbolTable sym_table;

std::unordered_map<std::string, uint16_t> opcodes = {
    {"ADD", 0x0011}, {"SUB", 0x0012}, {"MUL", 0x0013}, {"DIV", 0x0014}, {"MOD", 0x0015},
    {"ADDI", 0x0016}, {"SUBI", 0x0017}, {"MULI", 0x0018}, {"INC", 0x0019}, {"DEC", 0x001A},
    {"AND", 0x0021}, {"OR", 0x0022}, {"XOR", 0x0023}, {"NOT", 0x0024}, {"CMP", 0x0025},
    {"SHL", 0x0026}, {"SHR", 0x0027}, {"ANDI", 0x0028}, {"ORI", 0x0029}, {"TEST", 0x002A},
    {"LOAD", 0x0031}, {"STORE", 0x0032}, {"MOV", 0x0033}, {"LOADA", 0x0034}, {"LOADR", 0x0034}, {"STORER", 0x0035},
    {"PUSH", 0x0036}, {"POP", 0x0037}, {"LDI", 0x0038}, {"LDP", 0x0038},
    {"JMP", 0x0041}, {"JZ", 0x0042}, {"JNZ", 0x0043}, {"JG", 0x0044}, {"JL", 0x0045},
    {"CALL", 0x0046}, {"RET", 0x0047}, {"HLT", 0x1200},
    {"IN", 0x0051}, {"OUT", 0x0052}, {"NET_SEND", 0x0053}, {"NET_RECV", 0x0054},
    {"WAIT_I", 0x0055}, {"WAIT_IO", 0x0055}, {"INT_EN", 0x0056}
};

uint8_t parse_register(const std::string& reg) {
    std::string r = reg;
    if (r[0] == '$') r = r.substr(1);
    if (r[0] == 'r' || r[0] == 'R') r = r.substr(1);
    return static_cast<uint8_t>(std::stoi(r));
}

uint16_t parse_number(const std::string& num) {
    std::string n = num;
    if (n[0] == '#') n = n.substr(1);
    if (n.size() >= 2 && n.front() == '{' && n.back() == '}') {
        n = n.substr(1, n.size() - 2);
    }
    if (n.find("0x") == 0 || n.find("0X") == 0) {
        return static_cast<uint16_t>(std::stoul(n, nullptr, 16));
    }
    return static_cast<uint16_t>(std::stoul(n, nullptr, 10));
}

void pasada_1(const std::string& filename) {
    yyin = fopen(filename.c_str(), "r");
    if (!yyin) {
        std::cerr << "Error al abrir el archivo fuente." << std::endl;
        exit(1);
    }

    uint16_t current_pc = 0x000;
    int tok;
    while ((tok = yylex()) != 0) {
        if (tok == T_DIRECTIVE) {
            std::string dir = token_val;
            if (dir == "ORG" || dir == "org") {
                tok = yylex();
                if (tok == T_NUMBER) {
                    current_pc = parse_number(token_val);
                }
            }
        } else if (tok == T_LABEL_DEF) {
            std::string label = token_val;
            label = label.substr(0, label.size() - 1);
            sym_table.labels[label] = current_pc;
        } else if (tok == T_INSTRUCTION) {
            current_pc += 8;
        }
    }
    fclose(yyin);
}

void pasada_2(const std::string& filename, const std::string& output_filename) {
    yyin = fopen(filename.c_str(), "r");
    std::ofstream out(output_filename);

    uint16_t current_pc = 0x000;
    int tok;

    out << "MEMORIA RAM - CODIGO OBJETO (SPRY 1.0)\n";
    out << "---------------------------------------\n";

    while ((tok = yylex()) != 0) {
        if (tok == T_DIRECTIVE) {
            std::string dir = token_val;
            if (dir == "ORG" || dir == "org") {
                tok = yylex();
                if (tok == T_NUMBER) {
                    current_pc = parse_number(token_val);
                }
            }
        } else if (tok == T_INSTRUCTION) {
            std::string inst = token_val;
            uint16_t op = opcodes[inst];

            std::vector<Token> operands;
            while ((tok = yylex()) != 0 && tok != T_NEWLINE) {
                if (tok != T_COMMA) {
                    operands.push_back({tok, std::string(token_val)});
                }
            }

            out << "0x" << std::hex << std::uppercase << std::setw(3) << std::setfill('0') << current_pc << " | ";

            uint64_t palabra = (uint64_t)op << 48;

            if (inst == "HLT" || inst == "RET" || inst == "WAIT_IO" || inst == "WAIT_I" || inst == "INT_EN") {
                // Formato de control: solo opcode.
            }
            else if (inst == "INC" || inst == "DEC" || inst == "NOT" ||
                     inst == "PUSH" || inst == "POP" || inst == "NET_SEND" ||
                     inst == "NET_RECV") {
                if (operands.size() != 1 || operands[0].type != T_REGISTER)
                    throw std::runtime_error("Formato unario inválido");
                palabra |= (uint64_t)parse_register(operands[0].val) << 42;
            }
            else if (inst == "LOAD" || inst == "STORE") {
                if (operands.size() != 2)
                    throw std::runtime_error("LOAD/STORE requieren registro y dirección");
                uint8_t reg = parse_register(operands[0].val);
                uint16_t direccion = operands[1].type == T_LABEL_REF
                    ? sym_table.labels[operands[1].val]
                    : parse_number(operands[1].val);
                palabra |= (uint64_t)reg << 42;
                palabra |= (uint64_t)(direccion & 0xFFF) << 30;
            }
            else if (inst == "JMP" || inst == "JZ" || inst == "JNZ" ||
                     inst == "JG" || inst == "JL" || inst == "CALL") {
                if (operands.size() != 1)
                    throw std::runtime_error("Instrucción de salto inválida");
                uint16_t destino = operands[0].type == T_LABEL_REF
                    ? sym_table.labels[operands[0].val]
                    : parse_number(operands[0].val);
                palabra |= (uint64_t)(destino & 0xFFF) << 32;
            }
            else if (inst == "LDI" || inst == "LDP" || inst == "ADDI" ||
                     inst == "SUBI" || inst == "MULI" || inst == "ANDI" ||
                     inst == "ORI" || inst == "IN" || inst == "OUT") {
                if (operands.size() != 2)
                    throw std::runtime_error("Formato inmediato inválido");
                uint8_t rd = parse_register(operands[0].val);
                uint16_t inmediato = parse_number(operands[1].val);
                palabra |= (uint64_t)rd << 42;
                palabra |= (uint64_t)(inmediato & 0xFFFF) << 26;
            }
            else {
                uint8_t rd = 0, rs1 = 0, rs2 = 0;
                if (inst == "MOV" || inst == "FSQRT" || inst == "FITOF") {
                    if (operands.size() != 2)
                        throw std::runtime_error("Formato tipo-R de dos registros inválido");
                    rd = parse_register(operands[0].val);
                    rs1 = parse_register(operands[1].val);
                } else if (operands.size() == 3) {
                    rd = parse_register(operands[0].val);
                    rs1 = parse_register(operands[1].val);
                    rs2 = parse_register(operands[2].val);
                } else if ((inst == "CMP" || inst == "TEST") && operands.size() == 2) {
                    rs1 = parse_register(operands[0].val);
                    rs2 = parse_register(operands[1].val);
                } else {
                    throw std::runtime_error("Formato tipo-R inválido");
                }
                palabra |= (uint64_t)rd << 40;
                palabra |= (uint64_t)rs1 << 36;
                palabra |= (uint64_t)rs2 << 32;
            }

            out << std::hex << std::uppercase << std::setw(16) << std::setfill('0') << palabra;

            out << "\n";
            current_pc += 8;
        }
    }
    fclose(yyin);
    out.close();
}

int main(int argc, char** argv) {
    if (argc < 2) {
        std::cout << "Uso: ./ensamblador <archivo_fuente.asm> [archivo_salida.hex]\n";
        return 1;
    }

    std::string infile = argv[1];
    std::string outfile = (argc >= 3) ? argv[2] : "salida.hex";

    try {
        std::cout << "[Spry 1.0] Pasada 1 (Tabla de Símbolos)..." << std::endl;
        pasada_1(infile);

        std::cout << "[Spry 1.0] Pasada 2 (Generando Código Máquina)..." << std::endl;
        pasada_2(infile, outfile);

        std::cout << "[Spry 1.0] Proceso completado. Resultado en: " << outfile << std::endl;
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "[Error del ensamblador] " << error.what() << std::endl;
        return 1;
    }
}

