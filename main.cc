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

std::ofstream logFile, errFile;

extern int error_count, line_count;

extern SymbolTable table;

int main( int argc, const char* argv[] )
{
    if(argc!=4) {
        std::cout << "./fparse input.c log.txt error.txt" << std::endl;
        return 0;
    }

    if((inputFile=fopen(argv[1],"r"))==NULL) {
        printf("Cannot Open Input File.\n");
        exit(1);
    }

    logFile.open(argv[2]);

    errFile.open(argv[3]);

    yyin=inputFile;

    yydebug = 1;  // Enable Bison's debug mode

    yyparse();

    logFile << endl;
    logFile << "Total lines: " << line_count << endl;
    logFile << "Total errors: " << error_count << endl << endl;

    table.printAllScopeTables();
    

    logFile.close();
    errFile.close();
    fclose(yyin);
    
    return 0;

}
