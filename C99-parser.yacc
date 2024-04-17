%{
#include<bits/stdc++.h>
#include "1805082_SymbolTable.h"
void yyerror(char const *s);
extern int yylex (void);

int error_count = 0;

extern ofstream logFile;
extern ofstream errFile;

SymbolTable table(30);
%}

%union{
	SymbolInfo * sym;
	vector <SymbolInfo*> *symList;
}

%token<sym> IDENTIFIER STRING_LITERAL SIZEOF
%token<sym> PTR_OP INC_OP DEC_OP LEFT_OP RIGHT_OP LE_OP GE_OP EQ_OP NE_OP
%token<sym> AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token<sym> SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN
%token<sym> XOR_ASSIGN OR_ASSIGN

%token<sym> TYPEDEF EXTERN STATIC AUTO REGISTER INLINE RESTRICT
%token<sym> CHAR SHORT INT LONG SIGNED UNSIGNED FLOAT DOUBLE CONST VOLATILE VOID
%token<sym> BOOL COMPLEX IMAGINARY
%token<sym> STRUCT UNION ENUM ELLIPSIS

%token<sym> CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN

%token<sym> HEX_CONSTANT OCTAL_CONSTANT DECIMAL_CONSTANT CHAR_CONSTANT
%token<sym> FLOAT_CONSTANT HEX_FLOAT_CONSTANT

%type<sym> type_specifier struct_or_union_specifier enum_specifier struct_or_union
%type<sym> storage_class_specifier direct_declarator declarator declaration_specifiers
%type<sym> init_declarator initializer	primary_expression postfix_expression unary_expression
%type<sym> cast_expression multiplicative_expression additive_expression shift_expression
%type<sym> relational_expression equality_expression and_expression exclusive_or_expression
%type<sym> inclusive_or_expression logical_and_expression logical_or_expression
%type<sym> conditional_expression assignment_expression expression constant_expression
%type<symList> init_declarator_list


%start translation_unit
%%

primary_expression
    : IDENTIFIER
    | DECIMAL_CONSTANT	{ $$ = $1;}
    | OCTAL_CONSTANT
    | HEX_CONSTANT
    | CHAR_CONSTANT
    | FLOAT_CONSTANT	{ $$ = $1;}
    | HEX_FLOAT_CONSTANT
    | STRING_LITERAL
    | '(' expression ')'
    ;

postfix_expression
	: primary_expression	{ $$ = $1; }
	| postfix_expression '[' expression ']'
	| postfix_expression '(' ')'
	| postfix_expression '(' argument_expression_list ')'
	| postfix_expression '.' IDENTIFIER
	| postfix_expression PTR_OP IDENTIFIER
	| postfix_expression INC_OP
	| postfix_expression DEC_OP
	| '(' type_name ')' '{' initializer_list '}'
	| '(' type_name ')' '{' initializer_list ',' '}'
	;

argument_expression_list
	: assignment_expression
	| argument_expression_list ',' assignment_expression
	;

unary_expression
	: postfix_expression	{ $$ = $1; }
	| INC_OP unary_expression
	| DEC_OP unary_expression
	| unary_operator cast_expression
	| SIZEOF unary_expression
	| SIZEOF '(' type_name ')'
	;

unary_operator
	: '&'
	| '*'
	| '+'
	| '-'
	| '~'
	| '!'
	;

cast_expression
	: unary_expression	{ $$ = $1; }
	| '(' type_name ')' cast_expression
	;

multiplicative_expression
	: cast_expression	{ $$ = $1; }
	| multiplicative_expression '*' cast_expression
	| multiplicative_expression '/' cast_expression
	| multiplicative_expression '%' cast_expression
	;

additive_expression
	: multiplicative_expression	{ $$ = $1; }
	| additive_expression '+' multiplicative_expression
	| additive_expression '-' multiplicative_expression
	;

shift_expression
	: additive_expression	{ $$ = $1; }
	| shift_expression LEFT_OP additive_expression
	| shift_expression RIGHT_OP additive_expression
	;

relational_expression
	: shift_expression	{ $$ = $1; }
	| relational_expression '<' shift_expression
	| relational_expression '>' shift_expression
	| relational_expression LE_OP shift_expression
	| relational_expression GE_OP shift_expression
	;

equality_expression
	: relational_expression	{ $$ = $1; }
	| equality_expression EQ_OP relational_expression
	| equality_expression NE_OP relational_expression
	;

and_expression
	: equality_expression	{ $$ = $1; }
	| and_expression '&' equality_expression
	;

exclusive_or_expression
	: and_expression	{ $$ = $1; }
	| exclusive_or_expression '^' and_expression
	;

inclusive_or_expression
	: exclusive_or_expression	{ $$ = $1; }
	| inclusive_or_expression '|' exclusive_or_expression
	;

logical_and_expression
	: inclusive_or_expression	{ $$ = $1; }
	| logical_and_expression AND_OP inclusive_or_expression
	;

logical_or_expression
	: logical_and_expression	{ $$ = $1; }
	| logical_or_expression OR_OP logical_and_expression
	;

conditional_expression
	: logical_or_expression	{ $$ = $1; }
	| logical_or_expression '?' expression ':' conditional_expression
	;

assignment_expression
	: conditional_expression	{ $$ = $1; }
	| unary_expression assignment_operator assignment_expression
	;

assignment_operator
	: '='
	| MUL_ASSIGN
	| DIV_ASSIGN
	| MOD_ASSIGN
	| ADD_ASSIGN
	| SUB_ASSIGN
	| LEFT_ASSIGN
	| RIGHT_ASSIGN
	| AND_ASSIGN
	| XOR_ASSIGN
	| OR_ASSIGN
	;

expression
	: assignment_expression
	| expression ',' assignment_expression
	;

constant_expression
	: conditional_expression
	;

declaration
	: declaration_specifiers ';'
	| declaration_specifiers init_declarator_list ';' {
		for(std::vector<SymbolInfo*>::size_type i = 0; i < $2->size(); i++){
			if($2->at(i)->getVariableType() == "DECIMAL_CONSTANT" && $1->getSymbolType() != "INT"){
				logFile << "Error: Type mismatch in declaration of " << $2->at(i)->getSymbolName() << endl;
				errFile << "Error: Type mismatch in declaration of " << $2->at(i)->getSymbolName() << endl;
				error_count++;
			}
			if($2->at(i)->getVariableType() == "FLOAT_CONSTANT" && $1->getSymbolType() != "FLOAT"){
				logFile << "Error: Type mismatch in declaration of " << $2->at(i)->getSymbolName() << endl;
				errFile << "Error: Type mismatch in declaration of " << $2->at(i)->getSymbolName() << endl;
				error_count++;
			}
			$2->at(i)->setVariableType($1->getSymbolType());
			if (table.insert($2->at(i))) {
				logFile << "Inserted: " << $2->at(i)->getSymbolName() << " in scope " << table.printScopeId() << endl;
			}
			else {
				logFile << "Error: " << $2->at(i)->getSymbolName() << " already exists in scope " << endl;
				errFile << "Error: " << $2->at(i)->getSymbolName() << " already exists in scope " << endl;
				error_count++;
			}
		}
	
	}
	;

declaration_specifiers
	: storage_class_specifier
	| storage_class_specifier declaration_specifiers
	| type_specifier
	| type_specifier declaration_specifiers
	| type_qualifier
	| type_qualifier declaration_specifiers
	| function_specifier
	| function_specifier declaration_specifiers
	;

init_declarator_list
	: init_declarator	{ $$ = new vector<SymbolInfo*>(); $$->push_back($1); }
	| init_declarator_list ',' init_declarator
	;

init_declarator
	: declarator	{ $$ = $1; }
	| declarator '=' initializer	{ $1->setVariableType($3->getSymbolType()); $$ = $1;}
	;

storage_class_specifier
	: TYPEDEF		{ $$ = new SymbolInfo("typedef", "TYPEDEF"); }
	| EXTERN		{ $$ = new SymbolInfo("extern", "EXTERN"); }
	| STATIC		{ $$ = new SymbolInfo("static", "STATIC"); }
	| AUTO			{ $$ = new SymbolInfo("auto", "AUTO"); }
	| REGISTER		{ $$ = new SymbolInfo("register", "REGISTER"); }
	;

type_specifier
    : VOID          { $$ = new SymbolInfo("void", "VOID"); }
    | CHAR          { $$ = new SymbolInfo("char", "CHAR"); }
    | SHORT         { $$ = new SymbolInfo("short", "SHORT"); }
    | INT           { $$ = new SymbolInfo("int", "INT"); }
    | LONG          { $$ = new SymbolInfo("long", "LONG"); }
    | FLOAT         { $$ = new SymbolInfo("float", "FLOAT"); }
    | DOUBLE        { $$ = new SymbolInfo("double", "DOUBLE"); }
    | SIGNED        { $$ = new SymbolInfo("signed", "SIGNED"); }
    | UNSIGNED      { $$ = new SymbolInfo("unsigned", "UNSIGNED"); }
    | BOOL          { $$ = new SymbolInfo("bool", "BOOL"); }
    | COMPLEX       { $$ = new SymbolInfo("complex", "COMPLEX"); }
    | IMAGINARY     { $$ = new SymbolInfo("imaginary", "IMAGINARY"); }
    | struct_or_union_specifier  { $$ = $1; }
    | enum_specifier             { $$ = $1; }
    ;

struct_or_union_specifier
	: struct_or_union IDENTIFIER '{' struct_declaration_list '}'
	| struct_or_union '{' struct_declaration_list '}'
	| struct_or_union IDENTIFIER
	;

struct_or_union
	: STRUCT		{ $$ = new SymbolInfo("struct", "STRUCT"); }
	| UNION			{ $$ = new SymbolInfo("union", "UNION"); }
	;

struct_declaration_list
	: struct_declaration
	| struct_declaration_list struct_declaration
	;

struct_declaration
	: specifier_qualifier_list struct_declarator_list ';'
	;

specifier_qualifier_list
	: type_specifier specifier_qualifier_list
	| type_specifier
	| type_qualifier specifier_qualifier_list
	| type_qualifier
	;

struct_declarator_list
	: struct_declarator
	| struct_declarator_list ',' struct_declarator
	;

struct_declarator
	: declarator
	| ':' constant_expression
	| declarator ':' constant_expression
	;

enum_specifier
	: ENUM '{' enumerator_list '}'
	| ENUM IDENTIFIER '{' enumerator_list '}'
	| ENUM '{' enumerator_list ',' '}'
	| ENUM IDENTIFIER '{' enumerator_list ',' '}'
	| ENUM IDENTIFIER
	;

enumerator_list
	: enumerator
	| enumerator_list ',' enumerator
	;

enumerator
	: IDENTIFIER
	| IDENTIFIER '=' constant_expression
	;

type_qualifier
	: CONST
	| RESTRICT
	| VOLATILE
	;

function_specifier
	: INLINE
	;

declarator
	: pointer direct_declarator
	| direct_declarator	{ $$ = $1; }
	;


direct_declarator
	: IDENTIFIER		{ $$ = $1; }
	| '(' declarator ')'
	| direct_declarator '[' type_qualifier_list assignment_expression ']'
	| direct_declarator '[' type_qualifier_list ']'
	| direct_declarator '[' assignment_expression ']'
	| direct_declarator '[' STATIC type_qualifier_list assignment_expression ']'
	| direct_declarator '[' type_qualifier_list STATIC assignment_expression ']'
	| direct_declarator '[' type_qualifier_list '*' ']'
	| direct_declarator '[' '*' ']'
	| direct_declarator '[' ']'
	| direct_declarator '(' parameter_type_list ')'
	| direct_declarator '(' identifier_list ')'
	| direct_declarator '(' ')'
	;

pointer
	: '*'
	| '*' type_qualifier_list
	| '*' pointer
	| '*' type_qualifier_list pointer
	;

type_qualifier_list
	: type_qualifier
	| type_qualifier_list type_qualifier
	;


parameter_type_list
	: parameter_list
	| parameter_list ',' ELLIPSIS
	;

parameter_list
	: parameter_declaration
	| parameter_list ',' parameter_declaration
	;

parameter_declaration
	: declaration_specifiers declarator
	| declaration_specifiers abstract_declarator
	| declaration_specifiers
	;

identifier_list
	: IDENTIFIER
	| identifier_list ',' IDENTIFIER
	;

type_name
	: specifier_qualifier_list
	| specifier_qualifier_list abstract_declarator
	;

abstract_declarator
	: pointer
	| direct_abstract_declarator
	| pointer direct_abstract_declarator
	;

direct_abstract_declarator
	: '(' abstract_declarator ')'
	| '[' ']'
	| '[' assignment_expression ']'
	| direct_abstract_declarator '[' ']'
	| direct_abstract_declarator '[' assignment_expression ']'
	| '[' '*' ']'
	| direct_abstract_declarator '[' '*' ']'
	| '(' ')'
	| '(' parameter_type_list ')'
	| direct_abstract_declarator '(' ')'
	| direct_abstract_declarator '(' parameter_type_list ')'
	;

initializer
	: assignment_expression	{ $$ = $1; }
	| '{' initializer_list '}'
	| '{' initializer_list ',' '}'
	;

initializer_list
	: initializer
	| designation initializer
	| initializer_list ',' initializer
	| initializer_list ',' designation initializer
	;

designation
	: designator_list '='
	;

designator_list
	: designator
	| designator_list designator
	;

designator
	: '[' constant_expression ']'
	| '.' IDENTIFIER
	;

statement
	: labeled_statement
	| compound_statement
	| expression_statement
	| selection_statement
	| iteration_statement
	| jump_statement
	;

labeled_statement
	: IDENTIFIER ':' statement
	| CASE constant_expression ':' statement
	| DEFAULT ':' statement
	;

compound_statement
	: '{' '}'
	| '{' block_item_list '}'
	;

block_item_list
	: block_item
	| block_item_list block_item
	;

block_item
	: declaration
	| statement
	;

expression_statement
	: ';'
	| expression ';'
	;

selection_statement
	: IF '(' expression ')' statement
	| IF '(' expression ')' statement ELSE statement
	| SWITCH '(' expression ')' statement
	;

iteration_statement
	: WHILE '(' expression ')' statement
	| DO statement WHILE '(' expression ')' ';'
	| FOR '(' expression_statement expression_statement ')' statement
	| FOR '(' expression_statement expression_statement expression ')' statement
	| FOR '(' declaration expression_statement ')' statement
	| FOR '(' declaration expression_statement expression ')' statement
	;

jump_statement
	: GOTO IDENTIFIER ';'
	| CONTINUE ';'
	| BREAK ';'
	| RETURN ';'
	| RETURN expression ';'
	;

translation_unit
	: external_declaration
	| translation_unit external_declaration
	;

external_declaration
	: function_definition
	| declaration
	;

function_definition
	: declaration_specifiers declarator declaration_list compound_statement
	| declaration_specifiers declarator compound_statement
	;

declaration_list
	: declaration
	| declaration_list declaration
	;


%%
#include <stdio.h>

extern char yytext[];
extern int column;
extern int line_count;

void yyerror(char const *s)
{
	logFile << "Error at line " << line_count << " column: " << column << ": syntax error" << endl << endl;
	errFile << "Error at line " << line_count << " column: " << column << ": syntax error" << endl << endl;
	error_count++;

	/* fflush(stdout);
	printf("\n%*s\n%*s\n", line_count, "^", column, s); */
}
