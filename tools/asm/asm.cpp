#include <algorithm>
#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <map>
#include <stdlib.h>
#include <sstream>
#include <iomanip>
#include "asm.h"
#include <string.h>
#include <stdio.h>
using namespace std;

#define MAX_WORDS_PER_LINE 10
#define MEMORY_LENGTH 0xFFF

int max_addr = 0;

bool debug = false;
int numberToDisplay = 0x200;

string *currentLine;
int currentLineNum;

map<string, int> labels;
int memoryLocation = 0;
short primMemory[MEMORY_LENGTH]; // primary memory
string assembly[MEMORY_LENGTH];

map<string, int> ops;
map<string, int> special;

// the number of bits to leftshift to get correct weight
enum {
    WEIGHT_OP =  10,
    WEIGHT_M =   8,
    WEIGHT_GRa = 4,
    WEIGHT_GRb = 0
};

enum {
    MODE_REGISTER =  0x0,
    MODE_IMMEDIATE = 0x1,
    MODE_INDIRECT =  0x2,
    MODE_INDEXED =   0x3
};

enum {
    SPECIAL_OP_DAT,
    SPECIAL_OP_ORG
};

void initializeOps() {
    string line;
    ifstream myfile ("csf");
    
    if (myfile.is_open()) {
        while ( getline (myfile,line) ) {
            
            vector<string> ret(MAX_WORDS_PER_LINE);
            int i;
            int words = getWords(line, ret);
            
            ops.insert(pair<string, int>( ret[1], toDec(ret[0])));
        }
        myfile.close();
    }
    else {
        cout << "Did not find a computer spec file (\".csf\" file)." << endl;
        cout << "The .csf file should follow the following format:" << endl;
        cout << "\"addr  OP\"" << endl;
        cout << "Example:" << endl
        << "A0  LOAD" << endl
        << "A1  STORE" << endl;
        exit(2);
    }
    
    special.insert(pair<string, int>( "DAT",   SPECIAL_OP_DAT ));
    special.insert(pair<string, int>( "ORG",   SPECIAL_OP_ORG ));
}

int main (int argc, char* argv[]) {
    int i = 1;
    
    if (!(argc > 1)) { // no arguments
        usage(argv[0]);
        return 0;
    }


    initializeOps();
    string line;
    currentLine = &line;
    ifstream srcfile (argv[i]);

    string name(argv[i]);
    name = name.substr (0, name.find_last_of("."));
    //name.append(".proc");
    
    if (srcfile.is_open()) {
        int words;
        
        // Find all labels
        while ( getline (srcfile,line) ) {
            currentLineNum++;
            vector<string> ret(MAX_WORDS_PER_LINE);
            words = getWords(line, ret);
            findLabels(ret, words);
        }
        
        srcfile.clear();
        srcfile.seekg(0);
        memoryLocation = 0;
        currentLineNum = 0;

        // Used to resolve labels to values
        ofstream outFile(name + ".proc");
        bool wrote = false;
        
        // Replace all labels for values
        while ( getline (srcfile,line) ) {
            currentLineNum++;
            vector<string> ret(10);
            words = getWords(line, ret);
            replaceLabels(ret, words);
            for (unsigned i = 0; i < words; i++) {
                if (wrote)
                    outFile << " ";

                if (ret[i][0] != ':') {
                    outFile << ret[i];
                    wrote = true;
                }
            }
            if (wrote)
                outFile << endl;
            wrote = false;
        }

        outFile.close();
        srcfile.close();
        ifstream myfile (name + ".proc");

        memoryLocation = 0;
        currentLineNum = 0;
        
        // Evaluate and fill memory
        while ( getline (myfile,line) ) {
            currentLineNum++;
            vector<string> ret(MAX_WORDS_PER_LINE);
            words = getWords(line, ret);
            fillMemory(ret, words);
        }
        
        myfile.close();
    }
    else {
        cout << "Unable to open '" << argv[i];
        exit(1);
    }
    
    memoryDump();
    return 0;
}

void findLabels(vector<string> & ret, int words) {
    int i = 0;
    
    for (i = 0; i < words; i++) {
        if (isLabel(ret[i])) {
            if (!labelExists(ret[i]))
                addLabel(ret[i]);
        }
        else if (isOperation(ret[i])) {
            memoryLocation++;
            if (words == 3 || words == 2) { // standard operation
                if (getAddressMode(ret, words) != MODE_REGISTER) {
                    memoryLocation++;
                }
            }
        }
        else if (isSpecial(ret[i])) {
            // Assuming the next word is a value
            performSpecialOp(special[ret[i]], ret[i+1]);
        }
        else {
            if (i == 0) {
                reportError("Unknown operation '" + ret[i] + "'");
            }
        }
        if (memoryLocation > max_addr)
            max_addr = memoryLocation;
    }
}

void replaceLabels(vector<string> & ret, int words) {
    for (unsigned i = 0; i < words; i++) {
        if (labelExists(ret[i])) {
            ret[i] = to_string(labels[ret[i]]);
        }
        else {
            switch(ret[i][0]) {
                case '#':
                    if (isLabel(ret[i].substr(1, ret[i].length())))
                        ret[i] = to_string(labels[ret[i].substr(1, ret[i].length())]);
                    break;
                case '[':
                    if (isLabel(ret[i].substr(1, ret[i].length()-2)))
                        ret[i] = '[' + to_string(labels[ret[i].substr(1, ret[i].length()-2)]) + ']';
                    break;
                case '(':
                    if (isLabel(ret[i].substr(1, ret[i].length()-2)))
                        ret[i] = '(' + to_string(labels[ret[i].substr(1, ret[i].length()-2)]) + ')';
                    break;
            }
        }
        //cout << "ret[" << i << "] = " << "\"" << ret[i] << "\"" << endl;
    }
    //cout << endl;
    return;
}

void fillMemory(vector<string> & ret, int words) {
    int i = 0;
    for (i = 0; i < words; i++) {
        if (isLabel(ret[i])) {
            // do nothing
        }
        else if (isOperation(ret[i])) {
            int finalValue = 0;
            int op = 0;
            int mode = 0;
            int gra = 0;
            int grb = 0;
            short immediateValue = 0;

            op = ops[ret[i]];
            mode = getAddressMode(ret, words);

            switch(mode) {
                case MODE_REGISTER:
                    if (words == 3) {
                        gra = getRegisterNumber(ret[1]);
                        grb = getRegisterNumber(ret[2]);
                    }
                    break;
                case MODE_IMMEDIATE:
                    if (words == 3) {
                        gra = getRegisterNumber(ret[1]);
                        immediateValue = getAdr(ret[2]);
                    }
                    if (words == 2) {
                        if (isGR(ret[1])) {
                            gra = getRegisterNumber(ret[1]);
                            //mode = MODE_REGISTER;
                        }
                        else
                            immediateValue = getAdr(ret[1]);
                    }
                    break;
                case MODE_INDIRECT:
                    gra = getRegisterNumber(ret[1]);
                    immediateValue = getAdr(ret[2]);
                    break;
                case MODE_INDEXED:
                    gra = getRegisterNumber(ret[1]);
                    immediateValue = getAdr(ret[2]);
                    grb = 15;
                    break;
            }

            for (unsigned i = 0; i < words; i++) {
                if (i == 1 && words == 3)
                    assembly[memoryLocation] += ret[i] + ", ";
                else
                    assembly[memoryLocation] += ret[i] + " ";
            }

            if (debug) cout << assembly[memoryLocation] << " ";
            

            if (debug)
                cout << "op:" << hex << op << ", "
                << "mode:" << hex << mode << ", "
                << "gra:" << hex << gra << ", "
                << "grb:" << hex << grb << endl;
            
            
            finalValue += op << WEIGHT_OP;
            finalValue += mode << WEIGHT_M;
            finalValue += gra << WEIGHT_GRa;
            finalValue += grb << WEIGHT_GRb;
            
            if (debug)
                cout << "  Instruction: 0x" << setfill ('0') << setw(4)
                << hex << finalValue << endl;
            
            primMemory[memoryLocation] = finalValue;
            memoryLocation++;
            
            if (mode != MODE_REGISTER) {
                //if (debug) cout << "MEMORY FROM MODE_IMMEDIATE: 0x" << immediateValue << endl;
                primMemory[memoryLocation] = immediateValue;
                assembly[memoryLocation] = "";
                unsigned w;

                if (words == 3) { 
                    w = 0; // strange bug when this line is not present
                    assembly[memoryLocation] += " ";
                }

                for (unsigned w = 0; w < words-1; w++) {
                    for (unsigned s = 0; s < ret[w].length()+1; s++){
                        assembly[memoryLocation] += " ";
                    }
                }

                //if (debug) cout << "comparing to :" << ret[w+words-1] << endl;
                //cout << endl;
                for (unsigned l = 0; l < ret[w+words-1].length(); l++)
                    assembly[memoryLocation] += "^";
                memoryLocation++;
            }
            return;
        }
        else if (isSpecial(ret[i])) {
            // Assuming the next word is a value,
            performSpecialOp(special[ret[i]], ret[i+1]);
            i++;
        }
        else {
            cerr << "WARNING: unknown word '" << ret[i] << "'" << endl;
        }
    }
}

void performSpecialOp(int operation, string word) {
    //int arg = atoi(word.c_str()); // decimal
    int arg;
    if (word.substr(0,2).compare("0X") == 0)
        arg = toHex(word.substr(2));
    else
        arg = toDec(word);
    
    switch(operation) {
        case SPECIAL_OP_DAT:
            primMemory[memoryLocation] = arg;
            assembly[memoryLocation] = "DAT " + word;
            memoryLocation++;
            break;
        case SPECIAL_OP_ORG:
            memoryLocation = arg;
            break;
    }
}
int getAddressMode(vector<string> & ret, int words) {
    // check if the operation is a reg-reg
    // or reg-mem operation
    switch(words) {
        case 3:
            return helpGetAddressMode(ret[2]);
        case 2:
            return MODE_IMMEDIATE;
            break;
        case 1:
            return MODE_REGISTER;
            break;
        default:
            return -1; // never going to happen?
    }
}

int helpGetAddressMode(string word) {
    switch(word[0]) {
        //case '#':
        //    return MODE_IMMEDIATE;
        case '[':
            return MODE_INDIRECT;
        case '(':
            return MODE_INDEXED;
        default:
            if (isGR(word) || isVR(word))
                return MODE_REGISTER;
            else
                return MODE_IMMEDIATE;
            return -1;
    }
}

bool isLabel(string word) {
    return word[0] == ':' || labelExists(word);
}

bool labelExists(string word) {
    if (labels.count(word) > 0)
        return true;
    return false;
}

bool addLabel(string word) {
    // save where the label was found
    labels.insert(pair<string, int>( word.substr(1),  memoryLocation ));
    cout << "addr: " << setfill('0') << setw(2) << memoryLocation << " label '" << word.substr(1) << "'" << endl;
    return true;
}

bool isOperation(string word) {
    if (ops.count(word)) {
        return true;
    }
    return false;
}

bool isSpecial(string word) {
    if (special.count(word)) {
        return true;
    }
    return false;
}

int getWords(string line, vector<string> & ret) {
    bool mightBeHex = false;
    int count = 0;
    bool open = false;
    bool lineDone = false;
    int i;
    for (i = 0; i < line.length(); i++) {
        if (lineDone) break;
        switch(line[i]) {
            case '\n': // newlines
            case '\r': // carriage return
            case ';': // comments, we know we found all results
                lineDone = true;
                break;
            case ' ': // the 2 types of separators for arguments
            case '\t': // tab
            case ',':
                if (open) {
                    count++;
                    open = false;
                }
                break;
            default:
                open = true;
                if (mightBeHex && toupper(line[i]) == 'X') {
                    ret[count] += toupper(line[i]);
                    mightBeHex = false;
                }
                else
                    ret[count] += toupper(line[i]);
                if (line[i] == '0')
                    mightBeHex = true;
                break;
        }
    }
    
    if (open)
        count++;
    return count;
}

bool isHex(string number) {
    int i;
    for (i = 0; i < number.length(); i++) {
        if (!isxdigit(number[i]))
            return false;
    }
    return true;
}

int toHex(string number) {
    return (int)strtol(number.c_str(), NULL, 16);
}

int toDec(string number) {
    return atoi(number.c_str());
}

void toUpper(string *word) {
    transform(word->begin(), word->end(), word->begin(), ::toupper);
}

void toLower(string *word) {
    transform(word->begin(), word->end(), word->begin(), ::tolower);
}

bool isGR(string word) {
    return word.substr(0, 2).compare("GR") == 0;
}

bool isVR(string word) {
    return word.substr(0, 2).compare("VR") == 0;
}

int getRegisterNumber(string word) {
    if (word[1] == 'R') { // matches GR and VR
        return atoi(&word[2]);
    }
    else {
        reportError("Argument '" + word + "' is not a register");
        return -1;
    }
}

int getAdr(string word) {
    string actual;
    bool negative = false;
    short value = 0;

    switch(word[0]) {
        case '-': // negative number
            actual = word.substr(1, word.length());
            negative = true;
            break;
        case '(': // strip away junk, we already know the addressing mode
        case '[':
            actual = word.substr(1, word.length()-2);
            break;
        //case '#':
        //    actual = word.substr(1);
        //    break;
        default:
            actual = word;
    }
    if (actual.substr(0,2).compare("0X") == 0)
        value = toHex(actual.substr(2, word.length()));
    else
        value = toDec(actual);

    if (negative)
        value *= -1;
    return value;
}

int evalExpr(string word) {
    int i;
    string label;
    string value;
    string *current = &label;
    for (i = 0; i < word.length(); i++) {
        switch(word[i]) {
            case '+':
            case '-':
                current = &value;
                break;
            case ' ':
                break;
            default:
                *current += word[i];
                break;
        }
    }
    
    if (current == &label)
        return -1;
    
    cout << "label: '" << label << "' value: '" << value << "'" << endl;
    return labels[label] + toHex(value);
}

void memoryDump() {
    int i;
    
    for (i = 0; i < numberToDisplay; i++) {
        //cout << hex << setfill ('0') << setw(2);
        cout << dec << i << "=> X\"" << setw(4) << hex << primMemory[i] << "\"";
        if (assembly[i].compare("") != 0)
            cout << "    ; " << assembly[i];
        cout << endl;
    }
    cout << "Full dump at out.hex" << endl;
    
    ofstream outFile("out.hex");
    for (i = 0; i < max_addr; i++) {
        outFile << hex << setfill ('0') << setw(2);
        outFile << setw(0) << dec << i << "=> X\"" << setw(4) << hex << primMemory[i] << "\",";// << endl;
    }
    outFile.close();
    
}

void usage(string name) {
    cout << "Usage: " << name << " [flag] 'filename'" << endl;
    cout << "Common flags" << endl;
    cout << "  -v        verbose/debug output, see exactly how it interpreted the statements." << endl;
    cout << "  -n 'k'    shows 'k' number of lines in console, does not affect output in miasm.out." << endl;
}

void reportError(string message) {
    cerr << "On line " << currentLineNum << ": \"" 
    << *currentLine << "\"" << endl;
    cerr << "ERROR: " << message << endl;
    exit(1);
}