#include <stdlib.h>
#include <iostream>
#include <fstream>
#include <string>
#include <stdio.h>

#include <iomanip>

using namespace std;

#define MAX_LAYERS 8
#define MAX_WIDTH 100
#define MAX_HEIGHT 40
int mapArray[MAX_LAYERS][MAX_WIDTH*MAX_HEIGHT];
int layers = -1;
int elements = 0;
int addr = 0;

void memoryDump() {
  int i;
  cout << "Full dump at tiles.out" << endl;

  ofstream outFile("tiles.out");

  int l;
  int current;
  int id = 0;
  //cout << "found " << elements << " layers" << endl;
  for (l = 0; l < layers+1; l++) {
    id = 0;
    for (current = 0; current < MAX_WIDTH*MAX_HEIGHT; current++) {
      //outFile << mapArray[l][current];
      if (current % 100 == 0) {
        outFile << dec << setfill(' ') << setw(2) << id << "=> (";
        id++;
      }
      outFile << "X\"";
      outFile << hex << setfill('0') << setw(2);
      if (mapArray[l][current] == 0)
        outFile << 0 << "\""; //<< endl;
      else
        outFile << (mapArray[l][current]-1) << "\""; // compensate for 1 indexing

      if ((current+1) % 100 != 0)
        outFile << ",";

      if ((current+1) % (MAX_HEIGHT*MAX_WIDTH) == 0)
        outFile << ")";
      else if ((current+1) % 100 == 0)
        outFile << "),"; // endl
    }

    outFile << endl;

    id = 0;
    int row;
    int col;
    bool found_invalid = false;
    for (row = 0; row < MAX_HEIGHT; row++) {
      if (found_invalid)
        break;
      for (col = 0; col-16 < MAX_WIDTH; col += 16) {
        outFile << dec << addr << "=> ";
        outFile << "X\"";
        outFile << hex << setfill('0') << setw(4);

        addr++;
        int val = 0;

        int num;
        for (num = 0; num < 16; num++) {
          if (num != 0)
            val = val << 1;
          if (col+num < 100 && mapArray[l][row*100+col+num] == 2)
            val += 1;
          /*else if (mapArray[l][row*100+col+num] > 2) {
            found_invalid = true;
            break;
          }*/
        }

        outFile << val << "\",";

      }
    }

    outFile << endl << endl;
  }
  outFile.close();
  
}

int main (int argc, char* argv[]) {
  int i;
  string line;
  ifstream myfile (argv[1]);
  int layer = -1;
  bool data = false;

  if (myfile.is_open()) {
    ofstream outFile("tiles.raw");
    while ( getline (myfile,line) ) {
      //cout << line << endl;

      if (line.find("<data encoding=\"csv\">") != std::string::npos ) {
        layer++;
        if (layer > 0)
          outFile << ",";
        outFile << "layer,";
        data = true;
        layers++;
      }
      else if (data) {
        if (line.find("</data>") != std::string::npos) {
          data = false;
          continue;
        }
        switch(line[0]) {
          case '\n':
          case '\r': // ignore
            break;
          default:
            outFile << line;
            elements++;
            break;
        }
      }
    }
    outFile.close();
    myfile.close();
  }
  else {
    cout << "Unable to open '" << argv[i];
    exit(1);
  }

  int current = 0;
  layers = -1;

  ifstream rawfile ("tiles.raw");
  if (rawfile.is_open()) {
    while ( getline (rawfile,line, ',') ) {
      //cout << line << endl;
      if (line.find("layer") != std::string::npos) {
        layers++;
        current = 0;
        //cout << "layer: " << layers << endl;
        //cout << endl << endl;
      }
      else if (line[0] == '\n') {

      }
      else {
        mapArray[layers][current] = atoi(&line[0]);
        //cout << atoi(&line[0]) << ",";
        current++;
        elements++;
        //cout << hex << setfill('0') << setw(2) << atoi(&line[0]) << ",";
      }

    }
    memoryDump();
  }
  else {
    cout << "Unable to open raw file";
    exit(1);
  }
  return 0;
}