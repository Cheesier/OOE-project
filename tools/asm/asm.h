using namespace std;

int toMachineCode(string line);
int getWords(string line, std::vector<std::string> & ret);
void findLabels(vector<string> & ret, int words);
void replaceLabels(vector<string> & ret, int words);
void fillMemory(vector<string> & ret, int words);
bool isLabel(string word);
bool isRegister(string word);
bool isArgument(string word);
bool isOperation(string word);
bool isSpecial(string word);
void performSpecialOp(int operation, string word);

bool addLabel(string word);
int getLabelValue(string word);
bool labelExists(string word);

int getAddressMode(vector<string> & ret, int words);
int helpGetAddressMode(string word);

int toHex(string number);
int toDec(string number);

bool isGR(string word);
bool isVR(string word);
int getRegisterNumber(string word);
int getAdr(string word);

bool isHex(string number);
bool isNumeric(string word);
int evalExpr(string word);

void memoryDump();
void usage(string name);

void reportError(string message);
