#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <unordered_map>
#include <iomanip>
#include <cstdint>
#include <cstdlib>
#include <cstdio>
#include <stdexcept>
#include <algorithm>
#include <cctype>

extern "C" {
    int yylex();
    extern FILE* yyin;
    extern char* yytext;
    extern int lexical_error;
    void yyrestart(FILE*);
    char* token_val = nullptr;
}

enum TokenType {
    T_NONE = 0,
    T_INSTRUCTION = 1,
    T_REGISTER = 2,
    T_NUMBER = 3,
    T_LABEL_DEF = 4,
    T_LABEL_REF = 5,
    T_DIRECTIVE = 6,
    T_COMMA = 7,
    T_NEWLINE = 8,
    T_DATA_DIRECTIVE = 9,
    T_LBRACKET = 10,
    T_RBRACKET = 11,
    T_COLON = 12
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
    {"WAIT_I", 0xAA00}, {"WAIT_IO", 0x0055}, {"INT_EN", 0x0056},
    {"FADD", 0x0061}, {"FSUB", 0x0062}, {"FMUL", 0x0063}, {"FDIV", 0x0064},
    {"FSQRT", 0x0065}, {"FUNPACK", 0x0066}, {"FHERON", 0x0067}, {"FITOF", 0x0068}
};

uint8_t parse_register(const std::string& reg) {
    std::string r = reg;
    if (r.empty()) {
        throw std::invalid_argument("registro vacio");
    }
    if (r[0] == '$') r = r.substr(1);
    if (r.empty()) {
        throw std::invalid_argument("registro vacio");
    }
    if (r[0] == 'r' || r[0] == 'R') r = r.substr(1);
    int value = std::stoi(r);
    if (value < 0 || value > 15) {
        throw std::out_of_range("registro fuera de rango: " + reg);
    }
    return static_cast<uint8_t>(value);
}

uint16_t parse_number(const std::string& num) {
    unsigned long long value;
    std::string n = num;
    if (n.empty()) {
        throw std::invalid_argument("numero vacio");
    }
    if (n[0] == '#') n = n.substr(1);
    size_t parsed = 0;
    if (n.find("0x") == 0 || n.find("0X") == 0) {
        value = std::stoull(n.substr(2), &parsed, 16);
        if (parsed != n.size() - 2) {
            throw std::invalid_argument("numero invalido: " + num);
        }
    } else {
        value = std::stoull(n, &parsed, 10);
        if (parsed != n.size()) {
            throw std::invalid_argument("numero invalido: " + num);
        }
    }
    if (value > 0xFFFF) {
        throw std::out_of_range("numero fuera de 16 bits: " + num);
    }
    return static_cast<uint16_t>(value);
}

uint64_t parse_word(const std::string& num) {
    std::string n = num;
    if (!n.empty() && n[0] == '#') n = n.substr(1);
    if (n.empty()) throw std::invalid_argument("numero vacio");
    size_t parsed = 0;
    unsigned long long value;
    if (n.find("0x") == 0 || n.find("0X") == 0) {
        value = std::stoull(n.substr(2), &parsed, 16);
        if (parsed != n.size() - 2) {
            throw std::invalid_argument("numero invalido: " + num);
        }
    } else {
        value = std::stoull(n, &parsed, 10);
        if (parsed != n.size()) {
            throw std::invalid_argument("numero invalido: " + num);
        }
    }
    return static_cast<uint64_t>(value);
}

std::string uppercase(std::string value) {
    std::transform(value.begin(), value.end(), value.begin(),
                   [](unsigned char c) { return static_cast<char>(std::toupper(c)); });
    return value;
}

uint16_t resolve_symbol_or_number(const std::string& operand) {
    if (operand.empty()) {
        throw std::invalid_argument("operando vacio");
    }
    if (std::isdigit(static_cast<unsigned char>(operand[0])) ||
        operand[0] == '#') {
        return parse_number(operand);
    }
    std::string label = uppercase(operand);
    auto symbol = sym_table.labels.find(label);
    if (symbol == sym_table.labels.end()) {
        throw std::runtime_error("Etiqueta inexistente: " + label);
    }
    return symbol->second;
}

void abrir_scanner(const std::string& filename) {
    yyin = fopen(filename.c_str(), "r");
    if (!yyin) {
        throw std::runtime_error("Error al abrir el archivo fuente: " + filename);
    }
    lexical_error = 0;
    yyrestart(yyin);
}

void pasada_1(const std::string& filename) {
    abrir_scanner(filename);

    uint16_t current_pc = 0x000;
    int tok;
    while ((tok = yylex()) != 0) {
        if (tok == T_DIRECTIVE) {
            std::string dir = uppercase(token_val);
            if (dir == "ORG") {
                tok = yylex();
                if (tok == T_NUMBER) {
                    current_pc = parse_number(token_val);
                } else {
                    throw std::runtime_error("ORG requiere una direccion numerica");
                }
            }
        } else if (tok == T_LABEL_DEF) {
            std::string label = token_val;
            label = label.substr(0, label.size() - 1);
            label = uppercase(label);
            if (sym_table.labels.find(label) != sym_table.labels.end()) {
                throw std::runtime_error("Etiqueta duplicada: " + label);
            }
            sym_table.labels[label] = current_pc;
        } else if (tok == T_INSTRUCTION) {
            current_pc++;
        } else if (tok == T_DATA_DIRECTIVE) {
            tok = yylex();
            if (tok != T_NUMBER) {
                throw std::runtime_error("La directiva de datos requiere un numero");
            }
            parse_word(token_val);
            current_pc++;
        }
    }
    if (lexical_error) {
        fclose(yyin);
        throw std::runtime_error("La entrada contiene errores lexicos");
    }
    fclose(yyin);
}

void pasada_2(const std::string& filename, const std::string& output_filename) {
    abrir_scanner(filename);
    const std::string temporary_output = output_filename + ".tmp";
    std::ofstream out(temporary_output);
    if (!out) {
        fclose(yyin);
        throw std::runtime_error("No se pudo crear el archivo de salida: " + temporary_output);
    }

    uint16_t current_pc = 0x000;
    int tok;

    out << "MEMORIA RAM - CODIGO OBJETO (SPRY 1.0)\n";
    out << "---------------------------------------\n";

    while ((tok = yylex()) != 0) {
        if (tok == T_DIRECTIVE) {
            std::string dir = uppercase(token_val);
            if (dir == "ORG") {
                tok = yylex();
                if (tok == T_NUMBER) {
                    current_pc = parse_number(token_val);
                } else {
                    throw std::runtime_error("ORG requiere una direccion numerica");
                }
            }
        } else if (tok == T_INSTRUCTION) {
            std::string inst = uppercase(token_val);
            auto opcode = opcodes.find(inst);
            if (opcode == opcodes.end()) {
                throw std::runtime_error("Opcode desconocido: " + inst);
            }

            std::vector<Token> operands;
            while ((tok = yylex()) != 0 && tok != T_NEWLINE) {
                if (tok != T_COMMA) {
                    operands.push_back({tok, std::string(token_val)});
                }
            }

            const uint16_t op = opcode->second;
            out << "0x" << std::hex << std::uppercase << std::setw(3)
                << std::setfill('0') << current_pc << " | ";

            if (inst == "HLT" || inst == "RET" || inst == "WAIT_I" || inst == "INT_EN") {
                if (!operands.empty()) {
                    throw std::runtime_error(inst + " no acepta operandos");
                }
                out << std::hex << std::setw(4) << op << "000000000000";
            }
            else if (operands.size() == 1 && operands[0].type == T_REGISTER) {
                uint8_t r = parse_register(operands[0].val);
                out << std::hex << std::setw(4) << op << std::setw(1) << (int)r << "00000000";
            }
            else if (operands.size() >= 2 && operands[0].type == T_REGISTER && operands[1].type == T_REGISTER) {
                uint8_t r1 = parse_register(operands[0].val);
                uint8_t r2 = parse_register(operands[1].val);
                if (operands.size() > 3) {
                    throw std::runtime_error("Demasiados operandos para " + inst);
                }
                uint8_t r3 = (operands.size() == 3) ? parse_register(operands[2].val) : 0;
                out << std::hex << std::setw(4) << op << "0" << (int)r1 << (int)r2 << (int)r3;
            }
            else if (operands.size() == 2 &&
                     operands[0].type == T_REGISTER &&
                     (operands[1].type == T_NUMBER ||
                      operands[1].type == T_LABEL_REF)) {
                uint8_t r1 = parse_register(operands[0].val);
                uint16_t value = resolve_symbol_or_number(operands[1].val);
                out << std::hex << std::setw(4) << op << "0" << (int)r1
                    << std::setw(4) << std::setfill('0') << value;
            }
            else if (operands.size() == 1) {
                uint16_t target_addr = 0;
                if (operands[0].type == T_LABEL_REF) {
                    std::string label = uppercase(operands[0].val);
                    auto symbol = sym_table.labels.find(label);
                    if (symbol == sym_table.labels.end()) {
                        throw std::runtime_error("Etiqueta inexistente: " + label);
                    }
                    target_addr = symbol->second;
                } else {
                    target_addr = parse_number(operands[0].val);
                }
                out << std::hex << std::setw(4) << op << "00" << std::setw(3) << std::setfill('0') << target_addr;
            } else {
                throw std::runtime_error("Operandos invalidos para " + inst);
            }

            out << "\n";
            current_pc++;
        } else if (tok == T_DATA_DIRECTIVE) {
            std::string directive = uppercase(token_val);
            tok = yylex();
            if (tok != T_NUMBER) {
                throw std::runtime_error(directive + " requiere un numero");
            }
            uint64_t value = parse_word(token_val);
            out << "0x" << std::hex << std::uppercase << std::setw(3)
                << std::setfill('0') << current_pc << " | "
                << std::setw(16) << std::setfill('0') << value << "\n";
            current_pc++;
        }
    }
    if (lexical_error) {
        fclose(yyin);
        throw std::runtime_error("La entrada contiene errores lexicos");
    }
    fclose(yyin);
    out.close();
    std::remove(output_filename.c_str());
    if (std::rename(temporary_output.c_str(), output_filename.c_str()) != 0) {
        throw std::runtime_error("No se pudo publicar el archivo de salida: " + output_filename);
    }
}

int main(int argc, char** argv) {
    if (argc < 2) {
        std::cout << "Uso: ./ensamblador <archivo_fuente.asm> [archivo_salida.hex]\n";
        return 1;
    }

    std::string infile = argv[1];
    std::string outfile = (argc >= 3) ? argv[2] : "salida.hex";

    std::cout << "[Spry 1.0] Pasada 1 (Tabla de Símbolos)..." << std::endl;
    try {
        pasada_1(infile);
        std::cout << "[Spry 1.0] Pasada 2 (Generando Codigo Maquina)..." << std::endl;
        pasada_2(infile, outfile);
        std::cout << "[Spry 1.0] Proceso completado. Resultado en: " << outfile << std::endl;
        return 0;
    } catch (const std::exception& error) {
        std::remove(outfile.c_str());
        std::remove((outfile + ".tmp").c_str());
        std::cerr << "[Error de ensamblado] " << error.what() << std::endl;
        return 1;
    }
}
