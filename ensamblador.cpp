#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <unordered_map>
#include <iomanip>
#include <cstdint>
#include <cstdlib>

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
    {"LOAD", 0x0031}, {"STORE", 0x0032}, {"MOV", 0x0033}, {"LOADA", 0x0034}, {"STORER", 0x0035},
    {"PUSH", 0x0036}, {"POP", 0x0037}, {"LDI", 0x0038}, {"LDP", 0x0038},
    {"JMP", 0x0001}, {"JZ", 0x0042}, {"JNZ", 0x0043}, {"JG", 0x0044}, {"JL", 0x0045},
    {"CALL", 0x0006}, {"RET", 0xE200}, {"HLT", 0x1200},
    {"IN", 0x0051}, {"OUT", 0x0052}, {"NET_SEND", 0x0053}, {"NET_RECV", 0x0054},
    {"WAIT_I", 0xAA00}, {"INT_EN", 0x0056}
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
            current_pc++;
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

            if (inst == "HLT" || inst == "RET" || inst == "WAIT_I" || inst == "INT_EN") {
                out << std::hex << std::setw(4) << op << "000000000000";
            }
            else if (operands.size() == 1 && operands[0].type == T_REGISTER) {
                uint8_t r = parse_register(operands[0].val);
                out << std::hex << std::setw(4) << op << std::setw(1) << (int)r << "00000000";
            }
            else if (operands.size() >= 2 && operands[0].type == T_REGISTER && operands[1].type == T_REGISTER) {
                uint8_t r1 = parse_register(operands[0].val);
                uint8_t r2 = parse_register(operands[1].val);
                uint8_t r3 = (operands.size() == 3) ? parse_register(operands[2].val) : 0;
                out << std::hex << std::setw(4) << op << "0" << (int)r1 << (int)r2 << (int)r3;
            }
            else if (operands.size() >= 2 && operands[operands.size() - 1].type == T_NUMBER) {
                uint8_t r1 = parse_register(operands[0].val);
                uint16_t imm = parse_number(operands[operands.size() - 1].val);
                out << std::hex << std::setw(4) << op << "0" << (int)r1 << std::setw(4) << std::setfill('0') << imm;
            }
            else if (operands.size() == 1) {
                uint16_t target_addr = 0;
                if (operands[0].type == T_LABEL_REF) {
                    target_addr = sym_table.labels[operands[0].val];
                } else {
                    target_addr = parse_number(operands[0].val);
                }
                out << std::hex << std::setw(4) << op << "00" << std::setw(3) << std::setfill('0') << target_addr;
            }

            out << "\n";
            current_pc++;
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

    std::cout << "[Spry 1.0] Pasada 1 (Tabla de Símbolos)..." << std::endl;
    pasada_1(infile);

    std::cout << "[Spry 1.0] Pasada 2 (Generando Código Máquina)..." << std::endl;
    pasada_2(infile, outfile);

    std::cout << "[Spry 1.0] Proceso completado. Resultado en: " << outfile << std::endl;
    return 0;
}

