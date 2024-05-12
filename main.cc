#include <stdio.h>
#include <stdlib.h>
#include <fstream>
#include <string>
#include <iostream>
#include "1805082_SymbolTable.h"

using namespace std;

extern int yydebug;
extern FILE *yyin, *yyout;
FILE *inputFile;

extern int MVL_LINNUM;

extern void yyerror(const char *s);
extern int yyparse ();

std::ofstream logFile, errFile, sym_tables;

extern int error_count, line_count;

extern SymbolTable table;

int main( int argc, const char* argv[] )
{
    if(argc<2) {
        std::cout << "command: ./fparse input.c [DEBUG]" << std::endl;
        return 0;
    }

    for (int i = 1; i < argc; ++i) {
        if (std::string(argv[i]) == "DEBUG") {
            yydebug = 1;  // Enable Bison's debug mode
            break;
        }
    }

    if((inputFile=fopen(argv[1],"r"))==NULL) {
        printf("Cannot Open Input File.\n");
        exit(1);
    }

    if(yydebug){
        logFile.open("log.txt");
        errFile.open("error.txt");
        sym_tables.open("sym_tables.txt");
    }

    yyin=inputFile;

    yyparse();
    
    table.exitScope();

    if(yydebug){
        logFile << endl;
        logFile << "Total lines: " << line_count << endl;
        logFile << "Total errors: " << error_count << endl << endl;

        table.printCurrScopeTable(); // Print the current scope table

        logFile.close();
        sym_tables.close();
        errFile.close();

    }
    
    fclose(yyin);
    
    return 0;

}
