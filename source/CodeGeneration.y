/*
    File Name:      CodeGeneration.y
    Instructor:     Prof. Mohamed Zahran
    Grader:         Robert Soule
    Author:         Shen Li
    UID:            N14361265
    Department:     Computer Science
    Note:           This CodeGeneration.y file includes
                    Rule Definitions and User Definitions.
*/

/*Prologue*/
%{
    /*Head File*/
    #include <stdio.h>
    #include <stdlib.h>
    #include "CodeGeneration.h"
    #include "lex.yy.c"

    /*Variable Definition*/
    PSYMTYP     pretype_table;          //predefine type table link chain
    PSYMTYP     type_table;             //type definition table link chain
    PSYMFNCT    stack;                  //symbol table stack
    PCODEQUEUE  code_queue;             //intermediate code queue

    PSYMTYP     var_ref_type = NULL;    //variable reference type
    PSYMTYP     array_type = NULL;      //temporary array type
    PSYMREC     rtn_symbol = NULL;      //function return symbol
%}

/*Declarations*/
%union {
    int         ival;       //number type
    char        cval;       //symbol type
    char*       sval;       //identifer type
    PSYMREC     symptr;     //symbol table pointer
    PSYMTYP     typptr;     //type table pointer
}

%start  program

%token  <sval> AND PBEGIN FORWARD DIV DO ELSE END FOR FUNCTION IF ARRAY MOD NOT OF OR PROCEDURE PROGRAM RECORD THEN TO TYPE VAR WHILE
%token  <ival> NUMBER
%token  <sval> STRING
%token  <symptr> ID
%token  <cval> PLUS MINUS MULTI DIVIS
%token  <sval> ASSIGNOP
%token  <cval> LT EQ GT
%token  <sval> LE GE NE
%token  <cval> LPARENTHESIS RPARENTHESIS LBRACKET RBRACKET
%token  <cval> DOT COMMA COLON SEMICOLON
%token  <sval> DOTDOT

%type   <ival> constant
%type   <typptr> type result_type
%type   <symptr> expression simple_expression simple_expression_list
%type   <symptr> term factor
%type   <symptr> variable
%type   <symptr> function_reference
%type   <symptr> component_selection
%type   <symptr> identifier_list
%type   <symptr> variable_declarations variable_declaration_list
%type   <symptr> formal_parameter_list formal_parameter_list_section
%type   <symptr> actual_parameter_list actual_parameter_list_section
%type   <symptr> field_list field_list_section

%right  ASSIGNOP
%left   PLUS MINUS OR
%left   MULTI DIVIS DIV MOD AND
%right  POS NEG
%nonassoc   LT EQ GT LE GE NE

/*Grammer Rules*/
%%

program :   PROGRAM ID
                {
                    PSYMREC formal = initSymbolTable(CONST_FORMAL);

                    putSymbolTable( formal,
                                    CONST_FALSE,
                                    ID_VARIABLE,
                                    getTypeTable(CONST_BOOLEAN, TYPE_SIMPLE, NULL, NULL),
                                    NULL,
                                    NULL);
                    putSymbolTable( formal,
                                    CONST_TRUE,
                                    ID_VARIABLE,
                                    getTypeTable(CONST_BOOLEAN, TYPE_SIMPLE, NULL, NULL),
                                    NULL,
                                    NULL);
                    push(   stack,
                            $2->name,
                            0,
                            getTypeTable(CONST_VOID, TYPE_SIMPLE, NULL, NULL),
                            formal,
                            NULL);
                }
            SEMICOLON type_definitions variable_declarations
                {
                    PSYMFNCT top = getTop(stack);
                    top->local_list = $6;
                }
            subprogram_declarations
                {
                    putQuadrupleQueue(  code_queue,
                                        CONST_BEGIN,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL);
                }
            compound_statement DOT
                {
                    putQuadrupleQueue(  code_queue,
                                        NULL,
                                        CONST_PRORTN,
                                        NULL,
                                        NULL,
                                        NULL);
                    YYACCEPT;
                }
        ;
type_definitions    :   /*empty*/
                    |   TYPE type_definition_list
                    ;
type_definition_list    :   type_definition_list type_definition SEMICOLON
                        |   type_definition SEMICOLON
                        ;
variable_declarations   :   /*empty*/                       {$$ = initSymbolTable(CONST_VAR);}
                        |   VAR variable_declaration_list   {$$ = $2;}
                        ;
variable_declaration_list   :   variable_declaration_list identifier_list COLON type SEMICOLON
                                    {
                                        PSYMREC     node;
                                        PSYMFNCT    top = getTop(stack);

                                        $$ = $1;
                                        for (node = $2; node != NULL; node = node->next){
                                            if ((NULL == getSymbolTable($$, node->name))
                                                    && (NULL == getSymbolTable(top->formal_list, node->name))){
                                                putSymbolTable( $$,
                                                                node->name,
                                                                ID_VARIABLE,
                                                                $4,
                                                                NULL,
                                                                node->location);
                                            }
                                            else{
                                                fprintf(stderr, "Line %u:%u error: Multiple Declaration of Variable '%s'\n",    node->location->line,
                                                                                                                                node->location->column,
                                                                                                                                node->name);
                                            }
                                        }
                                    }
                            |   identifier_list COLON type SEMICOLON
                                    {
                                        PSYMREC     node;
                                        PSYMFNCT    top = getTop(stack);

                                        $$ = initSymbolTable(CONST_VAR);
                                        for (node = $1; node != NULL; node = node->next){
                                            if ((NULL == getSymbolTable($$, node->name))
                                                    && (NULL == getSymbolTable(top->formal_list, node->name))){
                                                putSymbolTable( $$,
                                                                node->name,
                                                                ID_VARIABLE,
                                                                $3,
                                                                NULL,
                                                                node->location);
                                            }
                                            else{
                                                fprintf(stderr, "Line %u:%u error: Multiple Declaration of Variable '%s'\n",    node->location->line,
                                                                                                                                node->location->column,
                                                                                                                                node->name);
                                            }
                                        }
                                    }
                            ;
subprogram_declarations :   /*empty*/
                        |   procedure_declaration SEMICOLON subprogram_declarations
                        |   function_declaration SEMICOLON subprogram_declarations
                        ;
type_definition :   ID EQ type
                        {
                            if (NULL == getTypeTable(   $1->name,
                                                        TYPE_SIMPLE,
                                                        NULL,
                                                        NULL)){
                                putTypeTable(   type_table,
                                                $1->name,
                                                TYPE_SIMPLE,
                                                $3,
                                                NULL,
                                                NULL,
                                                $3->size);
                            }
                            else{
                                fprintf(stderr, "Line %u:%u : Multiple Definition of Type Identifier '%s'\n",   $1->location->line,
                                                                                                                $1->location->column,
                                                                                                                $1->name);
                            }
                        }
                ;
procedure_declaration   :   PROCEDURE ID
                                {
                                    PSYMFNCT    old_top;
                                    PSYMFNCT    new_top;

                                    old_top = getTop(stack);
                                    if (NULL == getSymbolTable(old_top->local_list, $2->name)){
                                        push(   stack,
                                                $2->name,
                                                0,
                                                getTypeTable(CONST_VOID, TYPE_SIMPLE, NULL, NULL),
                                                NULL,
                                                NULL);
                                        new_top = getTop(stack);
                                        putSymbolTable( old_top->local_list,
                                                        $2->name,
                                                        ID_PROCEDURE,
                                                        NULL,
                                                        new_top,
                                                        $2->location);
                                    }
                                    else{
                                        fprintf(stderr, "Line %u:%u error: Multiple Declaration of Procedure '%s'\n",   $2->location->line,
                                                                                                                        $2->location->column,
                                                                                                                        $2->name);
                                        push(   stack,
                                                $2->name,
                                                0,
                                                getTypeTable(CONST_VOID, TYPE_SIMPLE, NULL, NULL),
                                                NULL,
                                                NULL);
                                    }
                                }
                            LPARENTHESIS formal_parameter_list RPARENTHESIS SEMICOLON
                                {
                                    PSYMFNCT top = getTop(stack);
                                    reverseSymbolTable($5);
                                    top->parameter = getLengthSymbolTable($5);
                                    top->formal_list = $5;
                                    putQuadrupleQueue(  code_queue,
                                                        $2->name,
                                                        NULL,
                                                        NULL,
                                                        NULL,
                                                        NULL);
                                }
                            declaration_body
                                {
                                    putQuadrupleQueue(  code_queue,
                                                        NULL,
                                                        CONST_PRORTN,
                                                        NULL,
                                                        NULL,
                                                        NULL);
                                    pop(stack);
                                }
                        ;
function_declaration    :   FUNCTION ID
                                {
                                    PSYMFNCT    old_top;
                                    PSYMFNCT    new_top;

                                    old_top = getTop(stack);
                                    if (NULL == getSymbolTable(old_top->local_list, $2->name)){
                                        push(stack, $2->name, 0, NULL, NULL, NULL);
                                        new_top = getTop(stack);
                                        putSymbolTable( old_top->local_list,
                                                        $2->name,
                                                        ID_FUNCTION,
                                                        NULL,
                                                        new_top,
                                                        $2->location);
                                    }
                                    else{
                                        fprintf(stderr, "Line %u:%u error: Multiple Declaration of Function '%s'\n",    $2->location->line,
                                                                                                                        $2->location->column,
                                                                                                                        $2->name);
                                        push(stack, $2->name, 0, NULL, NULL, NULL);
                                    }
                                }
                            LPARENTHESIS formal_parameter_list RPARENTHESIS COLON result_type SEMICOLON
                                {
                                    PSYMFNCT top = getTop(stack);
                                    reverseSymbolTable($5);
                                    top->parameter = getLengthSymbolTable($5);
                                    top->rtn = $8;
                                    top->formal_list = $5;
                                    putQuadrupleQueue(  code_queue,
                                                        $2->name,
                                                        NULL,
                                                        NULL,
                                                        NULL,
                                                        NULL);
                                }
                            declaration_body
                                {
                                    if (NULL == rtn_symbol){
                                        fprintf(stdout, "Line %u:%u warning: Function '%s' without a return value\n",   line_number,
                                                                                                                        column_number,
                                                                                                                        $2->name);
                                        putQuadrupleQueue(  code_queue,
                                                            NULL,
                                                            CONST_FUNRTN,
                                                            NULL,
                                                            NULL,
                                                            NULL);
                                    }
                                    else{
                                        putQuadrupleQueue(  code_queue,
                                                            NULL,
                                                            CONST_FUNRTN,
                                                            rtn_symbol->name,
                                                            NULL,
                                                            NULL);
                                    }
                                    rtn_symbol = NULL;
                                    pop(stack);
                                }
                        ;
declaration_body    :   block
                    |   FORWARD 
                            {
                                PSYMREC local = initSymbolTable(CONST_VAR);
                                PSYMFNCT top = getTop(stack);
                                top->local_list = local;
                            }
                    ;
formal_parameter_list   :   /*empty*/                       {$$ = initSymbolTable(CONST_FORMAL);}
                        |   formal_parameter_list_section   {$$ = $1;}
                        ;
formal_parameter_list_section   :   formal_parameter_list_section SEMICOLON identifier_list COLON type
                                        {
                                            PSYMREC     node;

                                            $$ = $1;
                                            for (node = $3; node != NULL; node = node->next){
                                                if (NULL == getSymbolTable($$, node->name)){
                                                    putSymbolTable( $$,
                                                                    node->name,
                                                                    ID_VARIABLE,
                                                                    $5,
                                                                    NULL,
                                                                    node->location);
                                                }
                                                else{
                                                    fprintf(stderr, "Line %u:%u error: Multiple Declaration of Variable '%s'\n",    node->location->line,
                                                                                                                                    node->location->column,
                                                                                                                                    node->name);
                                                }
                                            }
                                        }
                                |   identifier_list COLON type
                                        {
                                            PSYMREC     node;

                                            $$ = initSymbolTable(CONST_FORMAL);
                                            for (node = $1; node != NULL; node = node->next){
                                                if (NULL == getSymbolTable($$, node->name)){
                                                    putSymbolTable( $$,
                                                                    node->name,
                                                                    ID_VARIABLE,
                                                                    $3,
                                                                    NULL,
                                                                    node->location);
                                                }
                                                else{
                                                    fprintf(stderr, "Line %u:%u error: Multiple Declaration of Variable '%s'\n",    node->location->line,
                                                                                                                                    node->location->column,
                                                                                                                                    node->name);
                                                }
                                            }
                                        }
                                ;
block   :   variable_declarations   {PSYMFNCT top = getTop(stack); top->local_list = $1;}
            compound_statement
        ;
compound_statement  :   PBEGIN statement_sequence END
                    ;
statement_sequence  :   statement_sequence SEMICOLON statement
                    |   statement
                    ;
statement   :   open_statement
            |   closed_statement
            ;
open_statement  :   open_if_statement
                |   open_while_statement
                |   open_for_statement
                ;
closed_statement    :   /*empty*/
                    |   assignment_statement
                    |   procedure_statement
                    |   compound_statement
                    |   closed_if_statement
                    |   closed_while_statement
                    |   closed_for_statement
                    ;
open_if_statement   :   IF expression THEN statement
							{
                                PQUADRUPLE  node = getQuadrupleByOperation(code_queue, CONST_IFFALSE);
                                char*       new_label = getLabelName();

                                if ($2->value.type != getTypeTable(CONST_BOOLEAN, TYPE_SIMPLE, NULL, NULL)){
                                    fprintf(stdout, "Line %u:%u warning: Condition would be '%s' instead of '%s'\n",    line_number,
                                                                                                                        column_number,
                                                                                                                        CONST_BOOLEAN,
                                                                                                                        $2->value.type->name);
                                }
                                if (NULL == node){
                                    dieWithUserMessage("Parser() failed", "Could not find 'ifFalse' operation!");
                                }
                                else{
                                    setArgument(node, $2->name, NULL);
                                    setResult(node, new_label);
                                }
                                putQuadrupleQueue(  code_queue,
                                                    new_label,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL);
                            }
                    |   IF expression THEN closed_statement ELSE open_statement
							{
                                PQUADRUPLE  node_goto = getQuadrupleByOperation(code_queue, CONST_GOTO);
                                PQUADRUPLE  node_if = getQuadrupleByOperation(code_queue, CONST_IFFALSE);
                                char*       new_label = getLabelName();

                                if ($2->value.type != getTypeTable(CONST_BOOLEAN, TYPE_SIMPLE, NULL, NULL)){
                                    fprintf(stdout, "Line %u:%u warning: Condition would be '%s' instead of '%s'\n",    line_number,
                                                                                                                        column_number,
                                                                                                                        CONST_BOOLEAN,
                                                                                                                        $2->value.type->name);
                                }
                                if (NULL == node_goto){
                                    dieWithUserMessage("Parser() failed", "Could not find 'goto' operation!");
                                }
                                else if (NULL == node_if){
                                    dieWithUserMessage("Parser() failed", "Could not find 'ifFalse' operation!");
                                }
                                else{
                                    setArgument(node_goto, new_label, NULL);
                                    setArgument(node_if, $2->name, NULL);
                                    setResult(node_if, node_goto->next->label);
                                }
                                putQuadrupleQueue(  code_queue,
                                                    new_label,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL);
                            }
                    ;
closed_if_statement :   IF expression THEN closed_statement ELSE closed_statement
							{
								PQUADRUPLE  node_goto = getQuadrupleByOperation(code_queue, CONST_GOTO);
                                PQUADRUPLE  node_if = getQuadrupleByOperation(code_queue, CONST_IFFALSE);
                                char*       new_label = getLabelName();

                                if ($2->value.type != getTypeTable(CONST_BOOLEAN, TYPE_SIMPLE, NULL, NULL)){
                                    fprintf(stdout, "Line %u:%u warning: Condition would be '%s' instead of '%s'\n",    line_number,
                                                                                                                        column_number,
                                                                                                                        CONST_BOOLEAN,
                                                                                                                        $2->value.type->name);
                                }
                                if (NULL == node_goto){
                                    dieWithUserMessage("Parser() failed", "Could not find 'goto' operation!");
                                }
                                else if (NULL == node_if){
                                    dieWithUserMessage("Parser() failed", "Could not find 'ifFalse' operation!");
                                }
                                else{
                                    setArgument(node_goto, new_label, NULL);
                                    setArgument(node_if, $2->name, NULL);
                                    setResult(node_if, node_goto->next->label);
                                }
                                putQuadrupleQueue(  code_queue,
                                                    new_label,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL);
                            }
                    ;
open_while_statement    :   WHILE expression DO open_statement
								{
                                    PQUADRUPLE  node = getQuadrupleByOperation(code_queue, CONST_IFFALSE);
                                    char*       new_label = getLabelName();

                                    if ($2->value.type != getTypeTable(CONST_BOOLEAN, TYPE_SIMPLE, NULL, NULL)){
                                        fprintf(stdout, "Line %u:%u warning: Condition would be '%s' instead of '%s'\n",    line_number,
                                                                                                                            column_number,
                                                                                                                            CONST_BOOLEAN,
                                                                                                                            $2->value.type->name);
                                    }
                                    if (NULL == node){
                                        dieWithUserMessage("Parser() failed", "Could not find 'ifFalse' operation!");
                                    }
                                    else{
                                        setArgument(node, $2->name, NULL);
                                        setResult(node, new_label);
                                    }
                                    putQuadrupleQueue(  code_queue,
                                                        NULL,
                                                        CONST_GOTO,
                                                        node->prev->label,
                                                        NULL,
                                                        NULL);
                                    putQuadrupleQueue(  code_queue,
                                                        new_label,
                                                        NULL,
                                                        NULL,
                                                        NULL,
                                                        NULL);
                                }
                        ;
closed_while_statement  :   WHILE expression DO closed_statement
								{
                                    PQUADRUPLE  node = getQuadrupleByOperation(code_queue, CONST_IFFALSE);
                                    char*       new_label = getLabelName();

                                    if ($2->value.type != getTypeTable(CONST_BOOLEAN, TYPE_SIMPLE, NULL, NULL)){
                                        fprintf(stdout, "Line %u:%u warning: Condition would be '%s' instead of '%s'\n",    line_number,
                                                                                                                            column_number,
                                                                                                                            CONST_BOOLEAN,
                                                                                                                            $2->value.type->name);
                                    }
                                    if (NULL == node){
                                        dieWithUserMessage("Parser() failed", "Could not find 'ifFalse' operation!");
                                    }
                                    else{
                                        setArgument(node, $2->name, NULL);
                                        setResult(node, new_label);
                                    }
                                    putQuadrupleQueue(  code_queue,
                                                        NULL,
                                                        CONST_GOTO,
                                                        node->prev->label,
                                                        NULL,
                                                        NULL);
                                    putQuadrupleQueue(  code_queue,
                                                        new_label,
                                                        NULL,
                                                        NULL,
                                                        NULL,
                                                        NULL);
                                }
                        ;
open_for_statement  :   FOR ID ASSIGNOP expression TO expression DO open_statement
                            {
                                PSYMREC     node = find($2->name);
                                PQUADRUPLE  node_if = getQuadrupleByOperation(code_queue, CONST_IFFALSE);
                                char*       new_label = getLabelName();
                                char*       argument;

                                if ($4->value.type != $6->value.type){
                                    fprintf(stdout, "Line %u:%u warning: Initialization '%s' and Termination '%s' without a cast\n",	$2->location->line,
                                                                                                                                        $2->location->column,
                                                                                                                                        $4->value.type->name,
                                                                                                                                        $6->value.type->name);
                                }
                                if (NULL == node){
									fprintf(stderr, "Line %u:%u error: Undeclaration of Variable '%s'\n", 	$2->location->line,
                                                                                                            $2->location->column,
                                                                                                            $2->name);
                                    node = createTemporarySymbol(   $2->name,
                                                                    getTypeTable(CONST_VOID, TYPE_SIMPLE, NULL, NULL));
                                }
                                else if (node->property != ID_VARIABLE){
                                    fprintf(stderr, "Line %u:%u error: Function or Procedure could not be a left-operand\n",	$2->location->line,
                                                                                                                                $2->location->column);
                                    node = createTemporarySymbol(node->name, node->value.fnct->rtn);
                                }
                                else if ($4->value.type != node->value.type){
                                    fprintf(stdout, "Line %u:%u warning: Assignment '%s' with '%s' without a cast\n",	$2->location->line,
                                                                                                                        $2->location->column,
                                                                                                                        node->value.type->name,
                                                                                                                        $4->value.type->name);
                                }
                                if (NULL == node_if){
                                    dieWithUserMessage("Parser() failed", "Could not find 'ifFalse' operation!");
                                }
                                else{
                                    argument = (char*)malloc(strlen(node->name) + strlen($6->name) + 5);
                                    sprintf(argument, "%s <= %s", node->name, $6->name);
                                    setArgument(node_if, argument, NULL);
                                    setResult(node_if, new_label);
                                    insertQuadruple(code_queue,
                                                    node_if->prev,
                                                    NULL,
                                                    $3,
                                                    $4->name,
                                                    NULL,
                                                    node->name);
                                }
                                putQuadrupleQueue(  code_queue,
                                                    NULL,
                                                    "+",
                                                    node->name,
                                                    "1",
                                                    node->name);
                                putQuadrupleQueue(  code_queue,
                                                    NULL,
                                                    CONST_GOTO,
                                                    node_if->prev->label,
                                                    NULL,
                                                    NULL);
                                putQuadrupleQueue(  code_queue,
                                                    new_label,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL);
                            }
                    ;
closed_for_statement    :   FOR ID ASSIGNOP expression TO expression DO closed_statement
                                {
                                	PSYMREC		node = find($2->name);
									PQUADRUPLE  node_if = getQuadrupleByOperation(code_queue, CONST_IFFALSE);
                                	char*       new_label = getLabelName();
                                	char*       argument;

                                    if ($4->value.type != $6->value.type){
                                        fprintf(stdout, "Line %u:%u warning: Initialization '%s' and Termination '%s' without a cast\n",    $2->location->line,
                                                                                                                                            $2->location->column,
                                                                                                                                            $4->value.type->name,
                                                                                                                                            $6->value.type->name);
                                    }
                                    if (NULL == node){
										fprintf(stderr, "Line %u:%u error: Undeclaration of Variable '%s'\n", 	$2->location->line,
                                                                                                                $2->location->column,
                                                                                                                $2->name);
                                        node = createTemporarySymbol(   $2->name,
                                                                        getTypeTable(CONST_VOID, TYPE_SIMPLE, NULL, NULL));
                                    }
                                    else if (node->property != ID_VARIABLE){
                                        fprintf(stderr, "Line %u:%u error: Function or Procedure could not be a left-operand\n",    $2->location->line,
                                                                                                                                    $2->location->column);
                                        node = createTemporarySymbol(node->name, node->value.fnct->rtn);
                                    }
                                    else if ($4->value.type != node->value.type){
                                        fprintf(stdout, "Line %u:%u warning: Assignment '%s' with '%s' without a cast\n",   $2->location->line,
                                                                                                                            $2->location->column,
                                                                                                                            node->value.type->name,
                                                                                                                            $4->value.type->name);
                                    }
									if (NULL == node_if){
                                    	dieWithUserMessage("Parser() failed", "Could not find 'ifFalse' operation!");
                                	}
                                	else{
                                    	argument = (char*)malloc(strlen(node->name) + strlen($6->name) + 5);
                                    	sprintf(argument, "%s <= %s", node->name, $6->name);
                                    	setArgument(node_if, argument, NULL);
                                    	setResult(node_if, new_label);
                                        insertQuadruple(code_queue,
                                                        node_if->prev,
                                                        NULL,
                                                        $3,
                                                        $4->name,
                                                        NULL,
                                                        node->name);
                                	}
                                	putQuadrupleQueue(  code_queue,
                                                    	NULL,
                                                    	"+",
                                                    	node->name,
                                                    	"1",
                                                    	node->name);
                                	putQuadrupleQueue(  code_queue,
                                                    	NULL,
                                                    	CONST_GOTO,
                                                    	node_if->prev->label,
                                                    	NULL,
                                                    	NULL);
                                	putQuadrupleQueue(  code_queue,
                                                    	new_label,
                                                    	NULL,
                                                    	NULL,
                                                    	NULL,
                                                    	NULL);
                                }
                        ;
assignment_statement    :   variable ASSIGNOP expression
                                {
                                    PSYMFNCT top = getTop(stack);

                                    if ($1->value.type != $3->value.type){
                                        fprintf(stderr, "Line %u:%u warning: Assignment '%s' with '%s' without a cast\n",   line_number,
                                                                                                                            column_number,
                                                                                                                            $1->value.type->name,
                                                                                                                            $3->value.type->name);
                                    }
                                    if (0 == strcmp($1->name, top->name)){
                                        rtn_symbol = $3;
                                    }
                                    putQuadrupleQueue(  code_queue,
                                                        NULL,
                                                        $2,
                                                        $3->name,
                                                        NULL,
                                                        $1->name);
                                }
                        ;
procedure_statement :   ID LPARENTHESIS actual_parameter_list RPARENTHESIS
                            {
                                PSYMREC node = find($1->name);
                                PSYMREC temp_1;
                                PSYMREC temp_2;
                                size_t  para_num = getLengthSymbolTable($3);
                                u_int16 count = 1;

                                if (NULL == node){
                                    fprintf(stderr, "Line %u:%u error: Undeclaration of Procedure '%s'\n",  $1->location->line,
                                                                                                            $1->location->column,
                                                                                                            $1->name);
                                }
                                else if (ID_PROCEDURE != node->property){
                                   fprintf(stderr, "Line %u:%u error: Undeclaration of Procedure '%s'\n",   $1->location->line,
                                                                                                            $1->location->column,
                                                                                                            $1->name);
                                }
                                else if (para_num < node->value.fnct->parameter){
                                    fprintf(stderr, "Line %u:%u error: Too few arguments to Procedure '%s'\n",  $1->location->line,
                                                                                                                $1->location->column,
                                                                                                                $1->name);
                                }
                                else if (para_num > node->value.fnct->parameter){
                                    fprintf(stderr, "Line %u:%u error: Too many arguments to Procedure '%s'\n", $1->location->line,
                                                                                                                $1->location->column,
                                                                                                                $1->name);
                                }
                                else{
                                    temp_1 = $3->next;
                                    temp_2 = node->value.fnct->formal_list->next;
                                    while ((temp_1 != NULL)
                                            && (temp_2 != NULL)){
                                        if (temp_1->value.type != temp_2->value.type){
                                            fprintf(stdout, "Line %u:%u warning: Passing argument %u of '%s' makes '%s' from '%s' without a cast\n",    $1->location->line,
                                                                                                                                                        $1->location->column,
                                                                                                                                                        count,
                                                                                                                                                        $1->name,
                                                                                                                                                        temp_1->value.type->name,
                                                                                                                                                        temp_2->value.type->name);
                                        }
                                        putQuadrupleQueue(  code_queue,
                                                            NULL,
                                                            CONST_PARAM,
                                                            temp_1->name,
                                                            NULL,
                                                            NULL);
                                        temp_1 = temp_1->next;
                                        temp_2 = temp_2->next;
                                        count++;
                                    }
                                    putQuadrupleQueue(  code_queue,
                                                        NULL,
                                                        CONST_PROCALL,
                                                        $1->name,
                                                        itoa(para_num),
                                                        NULL);
                                }
                            }
                    ;
type    :   ID
                {
                    $$ = getTypeTable($1->name, TYPE_SIMPLE, NULL, NULL);
                    if (NULL == $$){
                        fprintf(stderr, "Line %u:%u error: Undefine Type Identifier '%s'\n",    $1->location->line,
                                                                                                $1->location->column,
                                                                                                $1->name);
                        putTypeTable(   pretype_table,
                                        $1->name,
                                        TYPE_SIMPLE,
                                        NULL,
                                        NULL,
                                        NULL,
                                        OTHER_LENGTH);
                        $$ = pretype_table->next;
                    }
                    else if ($$->value.equal != NULL){
                        $$ = $$->value.equal;
                    }
                }
        |   ARRAY LBRACKET constant DOTDOT constant RBRACKET OF type
                {
                    PARRAYINFO  p_array = (ARRAYINFO*)malloc(sizeof(ARRAYINFO));
                    size_t      type_size;
                    
                    p_array->start = $3;
                    p_array->end = $5;
                    p_array->basic = $8;
                    $$ = getTypeTable($8->name, TYPE_ARRAY, p_array, NULL);
                    if (NULL == $$){
                        type_size = (p_array->end - p_array->start + 1) * (p_array->basic->size);
                        putTypeTable(   pretype_table,
                                        $8->name,
                                        TYPE_ARRAY,
                                        NULL,
                                        p_array,
                                        NULL,
                                        type_size);
                        $$ = pretype_table->next;
                    }
                }
        |   RECORD field_list END
                {
                    size_t  type_size;

                    $$ = getTypeTable($1, TYPE_RECORD, NULL, $2);
                    if (NULL == $$){
                        type_size = getRecordSize($2);
                        putTypeTable(   pretype_table,
                                        $1,
                                        TYPE_RECORD,
                                        NULL,
                                        NULL,
                                        $2,
                                        type_size);
                        $$ = pretype_table->next;
                    }
                }
        ;
result_type :   ID
                    {
                        $$ = getTypeTable($1->name, TYPE_SIMPLE, NULL, NULL);
                        if (NULL == $$){
                            fprintf(stderr, "Line %u:%u error: Undefine Type Identifier '%s'\n",    $1->location->line,
                                                                                                    $1->location->column,
                                                                                                    $1->name);
                            putTypeTable(   pretype_table,
                                            $1->name,
                                            TYPE_SIMPLE,
                                            NULL,
                                            NULL,
                                            NULL,
                                            OTHER_LENGTH);
                            $$ = pretype_table->next;
                        }
                        else if ($$->value.equal != NULL){
                            $$ = $$->value.equal;
                        }
                    }
            ;
field_list  :   /*empty*/			{$$ = initSymbolTable(CONST_FIELD);}
            |   field_list_section	{$$ = $1;}
            ;
field_list_section  :   field_list_section SEMICOLON identifier_list COLON type
                            {
                                PSYMREC     node;

                                $$ = $1;
                                for (node = $3; node != NULL; node = node->next){
                                    if (NULL == getSymbolTable($$, node->name)){
                                        putSymbolTable( $$,
                                                        node->name,
                                                        ID_VARIABLE,
                                                        $5,
                                                        NULL,
                                                        node->location);
                                    }
                                    else{
                                        fprintf(stderr, "Line %u:%u error: Multiple Declaration of Variable '%s'\n",    node->location->line,
                                                                                                                        node->location->column,
                                                                                                                        node->name);
                                    }
                                }
                            }
                    |   identifier_list COLON type
                            {
                                PSYMREC     node;

                                $$ = initSymbolTable(CONST_FIELD);
                                for (node = $1; node != NULL; node = node->next){
                                    if (NULL == getSymbolTable($$, node->name)){
                                        putSymbolTable( $$,
                                                        node->name,
                                                        ID_VARIABLE,
                                                        $3,
                                                        NULL,
                                                        node->location);
                                    }
                                    else{
                                        fprintf(stderr, "Line %u:%u error: Multiple Delcaration of Variable '%s'\n",    node->location->line,
                                                                                                                        node->location->column,
                                                                                                                        node->name);
                                    }
                                }
                            }
                    ;
constant    :   NUMBER                      {$$ = $1;}
            |   PLUS NUMBER     %prec POS   {$$ = +$1;}
            |   MINUS NUMBER    %prec NEG   {$$ = -$1;}
            ;
expression  :   simple_expression   {$$ = $1;}
            |   simple_expression LT simple_expression
                    {
                        if ($1->value.type != $3->value.type){
                            fprintf(stdout, "Line %u:%u warning: Compare with '%s' and '%s' without a cast\n",  line_number,
                                                                                                                column_number,
                                                                                                                $1->value.type->name,
                                                                                                                $3->value.type->name);
                        }
                        $$ = createTemporarySymbol( getTemporarySymbolName(),
                                                    getTypeTable(CONST_BOOLEAN, TYPE_SIMPLE, NULL, NULL));
                        putQuadrupleQueue(  code_queue,
                                            NULL,
                                            "<",
                                            $1->name,
                                            $3->name,
                                            $$->name);
                    }
            |   simple_expression LE simple_expression
					{
                        if ($1->value.type != $3->value.type){
                            fprintf(stdout, "Line %u:%u warning: Compare with '%s' and '%s' without a cast\n",  line_number,
                                                                                                                column_number,
                                                                                                                $1->value.type->name,
                                                                                                                $3->value.type->name);
                        }
                        $$ = createTemporarySymbol( getTemporarySymbolName(),
                                                    getTypeTable(CONST_BOOLEAN, TYPE_SIMPLE, NULL, NULL));
                        putQuadrupleQueue(  code_queue,
                                            NULL,
                                            $2,
                                            $1->name,
                                            $3->name,
                                            $$->name);
                    }
            |   simple_expression EQ simple_expression
					{
                        if ($1->value.type != $3->value.type){
                            fprintf(stdout, "Line %u:%u warning: Compare with '%s' and '%s' without a cast\n",  line_number,
                                                                                                                column_number,
                                                                                                                $1->value.type->name,
                                                                                                                $3->value.type->name);
                        }
                        $$ = createTemporarySymbol( getTemporarySymbolName(),
                                                    getTypeTable(CONST_BOOLEAN, TYPE_SIMPLE, NULL, NULL));
                        putQuadrupleQueue(  code_queue,
                                            NULL,
                                            "=",
                                            $1->name,
                                            $3->name,
                                            $$->name);
                    }
            |   simple_expression GE simple_expression
					{
                        if ($1->value.type != $3->value.type){
                            fprintf(stdout, "Line %u:%u warning: Compare with '%s' and '%s' without a cast\n",  line_number,
                                                                                                                column_number,
                                                                                                                $1->value.type->name,
                                                                                                                $3->value.type->name);
                        }
                        $$ = createTemporarySymbol( getTemporarySymbolName(),
                                                    getTypeTable(CONST_BOOLEAN, TYPE_SIMPLE, NULL, NULL));
                        putQuadrupleQueue(  code_queue,
                                            NULL,
                                            $2,
                                            $1->name,
                                            $3->name,
                                            $$->name);
                    }
            |   simple_expression GT simple_expression
					{
                        if ($1->value.type != $3->value.type){
                            fprintf(stdout, "Line %u:%u warning: Compare with '%s' and '%s' without a cast\n",  line_number,
                                                                                                                column_number,
                                                                                                                $1->value.type->name,
                                                                                                                $3->value.type->name);
                        }
                        $$ = createTemporarySymbol( getTemporarySymbolName(),
                                                    getTypeTable(CONST_BOOLEAN, TYPE_SIMPLE, NULL, NULL));
                        putQuadrupleQueue(  code_queue,
                                            NULL,
                                            ">",
                                            $1->name,
                                            $3->name,
                                            $$->name);
                    }
            |   simple_expression NE simple_expression
					{
                        if ($1->value.type != $3->value.type){
                            fprintf(stdout, "Line %u:%u warning: Compare with '%s' and '%s' without a cast\n",  line_number,
                                                                                                                column_number,
                                                                                                                $1->value.type->name,
                                                                                                                $3->value.type->name);
                        }
                        $$ = createTemporarySymbol( getTemporarySymbolName(),
                                                    getTypeTable(CONST_BOOLEAN, TYPE_SIMPLE, NULL, NULL));
                        putQuadrupleQueue(  code_queue,
                                            NULL,
                                            $2,
                                            $1->name,
                                            $3->name,
                                            $$->name);
                    }
            ;
simple_expression   :   simple_expression_list          {$$ = $1;}
                    |   PLUS simple_expression_list     %prec POS
                        {
                            $$ = createTemporarySymbol( getTemporarySymbolName(),
                                                        $2->value.type);
                            putQuadrupleQueue(  code_queue,
                                                NULL,
                                                "pos",
                                                $2->name,
                                                NULL,
                                                $$->name);
                        }
                    |   MINUS simple_expression_list    %prec NEG
                        {
                            $$ = createTemporarySymbol( getTemporarySymbolName(),
                                                        $2->value.type);
                            putQuadrupleQueue(  code_queue,
                                                NULL,
                                                "neg",
                                                $2->name,
                                                NULL,
                                                $$->name);
                        }
                    ;
simple_expression_list  :   term	{$$ = $1;}
                        |   simple_expression_list PLUS term
								{
                        			if ($1->value.type != $3->value.type){
                            			fprintf(stdout, "Line %u:%u warning: Operate '%s' and '%s' without a cast\n",	line_number,
                                                                                                                  		column_number,
                                                                                                                		$1->value.type->name,
                                                                                                                		$3->value.type->name);
                        			}
                        			$$ = createTemporarySymbol( getTemporarySymbolName(),
                                                                $1->value.type);
                                    putQuadrupleQueue(  code_queue,
                                                        NULL,
                                                        "+",
                                                        $1->name,
                                                        $3->name,
                                                        $$->name);
                    			}
                        |   simple_expression_list MINUS term
								{
                        			if ($1->value.type != $3->value.type){
                            			fprintf(stdout, "Line %u:%u warning: Operate '%s' and '%s' without a cast\n",	line_number,
                                                                                                            		    column_number,
                                                                                                            		    $1->value.type->name,
                                                                                                            		    $3->value.type->name);
                        			}
                        			$$ = createTemporarySymbol( getTemporarySymbolName(),
                                                                $1->value.type);
                                    putQuadrupleQueue(  code_queue,
                                                        NULL,
                                                        "-",
                                                        $1->name,
                                                        $3->name,
                                                        $$->name);
                    			}
                        |   simple_expression_list OR term
								{
                        			if ($1->value.type != $3->value.type){
                            			fprintf(stdout, "Line %u:%u warning: Operate '%s' and '%s' without a cast\n",	line_number,
                                                                                                            		    column_number,
                                                                                                            		    $1->value.type->name,
                                                                                                            		    $3->value.type->name);
                        			}
                        			$$ = createTemporarySymbol( getTemporarySymbolName(),
                                                                getTypeTable(CONST_BOOLEAN, TYPE_SIMPLE, NULL, NULL));
                                    putQuadrupleQueue(  code_queue,
                                                        NULL,
                                                        $2,
                                                        $1->name,
                                                        $3->name,
                                                        $$->name);
                    			}
                        ;
term    :   factor	{$$ = $1;}
        |   term MULTI factor
				{
					if ($1->value.type!= $3->value.type){
						fprintf(stdout, "Line %u:%u warning: Operate '%s' and '%s' without a cast\n",	line_number,
                                                                                                        column_number,
                                                                                                        $1->value.type->name,
                                                                                                        $3->value.type->name);
					}
					$$ = createTemporarySymbol( getTemporarySymbolName(),
                                                $1->value.type);
                    putQuadrupleQueue(  code_queue,
                                        NULL,
                                        "*",
                                        $1->name,
                                        $3->name,
                                        $$->name);
				}
        |   term DIV factor
				{
					if ($1->value.type != $3->value.type){
						fprintf(stdout, "Line %u:%u warning: Operate '%s' and '%s' without a cast\n",	line_number,
                                                                                                        column_number,
                                                                                                        $1->value.type->name,
                                                                                                        $3->value.type->name);
					}
					$$ = createTemporarySymbol( getTemporarySymbolName(),
                                                $1->value.type);
                    putQuadrupleQueue(  code_queue,
                                        NULL,
                                        $2,
                                        $1->name,
                                        $3->name,
                                        $$->name);
				}
        |   term DIVIS factor
				{
					if ($1->value.type != $3->value.type){
						fprintf(stdout, "Line %u:%u warning: Operate '%s' and '%s' without a cast\n",	line_number,
                                                                                                        column_number,
                                                                                                        $1->value.type->name,
                                                                                                        $3->value.type->name);
					}
					$$ = createTemporarySymbol( getTemporarySymbolName(),
                                                $1->value.type);
                    putQuadrupleQueue(  code_queue,
                                        NULL,
                                        "/",
                                        $1->name,
                                        $3->name,
                                        $$->name);
				}
        |   term MOD factor
				{
					if ($1->value.type != $3->value.type){
						fprintf(stdout, "Line %u:%u warning: Operate '%s' and '%s' without a cast\n",	line_number,
                                                                                                        column_number,
                                                                                                        $1->value.type->name,
                                                                                                        $3->value.type->name);
					}
					$$ = createTemporarySymbol( getTemporarySymbolName(),
                                                $1->value.type);
                    putQuadrupleQueue(  code_queue,
                                        NULL,
                                        $2,
                                        $1->name,
                                        $3->name,
                                        $$->name);
				}
        |   term AND factor
				{
					if ($1->value.type != $3->value.type){
						fprintf(stdout, "Line %u:%u warning: Operate '%s' and '%s' without a cast\n",	line_number,
                                                                                                        column_number,
                                                                                                        $1->value.type->name,
                                                                                                        $3->value.type->name);
					}
					$$ = createTemporarySymbol( getTemporarySymbolName(),
                                                getTypeTable(CONST_BOOLEAN, TYPE_SIMPLE, NULL, NULL));
                    putQuadrupleQueue(  code_queue,
                                        NULL,
                                        $2,
                                        $1->name,
                                        $3->name,
                                        $$->name);
				}
        ;
factor  :   NUMBER
                {
                    $$ = createTemporarySymbol( itoa($1),
                                                getTypeTable(CONST_INTEGER, TYPE_SIMPLE, NULL, NULL));
                }
        |   STRING
                {
                    $$ = createTemporarySymbol( $1,
                                                getTypeTable(CONST_STRING, TYPE_SIMPLE, NULL, NULL));
                }
        |   variable                                {$$ = $1;}
        |   function_reference                      {$$ = $1;}
        |   NOT factor
                {
                    $$ = createTemporarySymbol( getTemporarySymbolName(),
                                                getTypeTable(CONST_BOOLEAN, TYPE_SIMPLE, NULL, NULL));
                    putQuadrupleQueue(  code_queue,
                                        NULL,
                                        $1,
                                        $2->name,
                                        NULL,
                                        $$->name);
                }
        |   LPARENTHESIS expression RPARENTHESIS    {$$ = $2;}
        ;
function_reference  :   ID LPARENTHESIS actual_parameter_list RPARENTHESIS
                            {
                                PSYMREC node = find($1->name);
                                PSYMREC temp_1;
                                PSYMREC temp_2;
                                size_t  para_num = getLengthSymbolTable($3);
                                u_int16 count = 1;

                                if (NULL == node){
                                    fprintf(stderr, "Line %u:%u error: Undeclaration of Function '%s'\n",	$1->location->line,
                                                                                                            $1->location->column,
                                                                                                            $1->name);
									$$ = createTemporarySymbol( $1->name,
                                                                getTypeTable(CONST_VOID, TYPE_SIMPLE, NULL, NULL));
                                }
                                else if (ID_FUNCTION != node->property){
                                    fprintf(stderr, "Line %u:%u error: Undeclaration of Function '%s'\n",   $1->location->line,
                                                                                                            $1->location->column,
                                                                                                            $1->name);
                                    $$ = createTemporarySymbol( node->name,
                                                                getTypeTable(CONST_VOID, TYPE_SIMPLE, NULL, NULL));
                                }
								else if (para_num < node->value.fnct->parameter){
                                    fprintf(stderr, "Line %u:%u error: Too few arguments to Function '%s'\n",   $1->location->line,
                                                                                                                $1->location->column,
                                                                                                                $1->name);
                                    $$ = createTemporarySymbol(node->name, node->value.fnct->rtn);
                                }
                                else if (para_num > node->value.fnct->parameter){
                                    fprintf(stderr, "Line %u:%u error: Too many arguments to Function '%s'\n",  $1->location->line,
                                                                                                                $1->location->column,
                                                                                                                $1->name);
                                    $$ = createTemporarySymbol(node->name, node->value.fnct->rtn);
                                }
                                else{
                                    temp_1 = $3->next;
                                    temp_2 = node->value.fnct->formal_list->next;
                                    while ((temp_1 != NULL)
                                            && (temp_2 != NULL)){
                                        if (temp_1->value.type != temp_2->value.type){
                                            fprintf(stdout, "Line %u:%u warning: Passing argument %u of '%s' makes '%s' from '%s' without a cast\n",    $1->location->line,
                                                                                                                                                        $1->location->column,
                                                                                                                                                        count,
                                                                                                                                                        $1->name,
                                                                                                                                                        temp_1->value.type->name,
                                                                                                                                                        temp_2->value.type->name);
                                        }
                                        putQuadrupleQueue(  code_queue,
                                                            NULL,
                                                            CONST_PARAM,
                                                            temp_1->name,
                                                            NULL,
                                                            NULL);
                                        temp_1 = temp_1->next;
                                        temp_2 = temp_2->next;
                                        count++;
                                    }
                                    $$ = createTemporarySymbol( getTemporarySymbolName(),
                                                                node->value.fnct->rtn);
                                    putQuadrupleQueue(  code_queue,
                                                        NULL,
                                                        CONST_FUNCALL,
                                                        $1->name,
                                                        itoa(para_num),
                                                        $$->name);
                                }
                            }
                    ;
variable    :   ID
                    {
                        PSYMFNCT top = getTop(stack);
                        PSYMREC node = find($1->name);

                        if (NULL == node){
                            fprintf(stderr, "Line %u:%u error: Undeclaration of Variable '%s'\n",   $1->location->line,
                                                                                                    $1->location->column,
                                                                                                    $1->name);
                            var_ref_type = getTypeTable(CONST_VOID, TYPE_SIMPLE, NULL, NULL);
                        }
                        else if (ID_VARIABLE == node->property){
                            var_ref_type = node->value.type;
                        }
                        else if (0 != strcmp(top->name, $1->name)){
                            fprintf(stderr, "Line %u:%u error: Function or Procedure could not be a left-operand\n",    $1->location->line,
                                                                                                                        $1->location->column);
                            var_ref_type = node->value.fnct->rtn;
                        }
                        else{
                            var_ref_type = top->rtn;
                        }
                    }
                component_selection
                    {
                        char*   symbol_name;

                        if (NULL == $3){
                            $$ = createTemporarySymbol($1->name, var_ref_type);
                        }
                        else{
                            symbol_name = (char*)malloc(strlen($1->name) + strlen($3->name) + 1);
                            sprintf(symbol_name, "%s%s", $1->name, $3->name);
                            $$ = createTemporarySymbol(symbol_name, $3->value.type);
                        }
                    }
            ;
component_selection :   /*empty*/   {$$ = NULL;}
                    |   DOT ID
                            {
                                PSYMREC     node;

                                if (TYPE_RECORD != var_ref_type->property){
                                    fprintf(stderr, "Line %u:%u error: Field is not record\n",  $2->location->line,
                                                                                                $2->location->column);
                                    var_ref_type = getTypeTable(CONST_VOID, TYPE_SIMPLE, NULL, NULL);
                                }
                                else{
                                    node = getSymbolTable(var_ref_type->value.field, $2->name);
                                    
                                    if (NULL == node){
                                        fprintf(stderr, "Line %u:%u error: Record has no member named '%s'\n",  $2->location->line,
                                                                                                                $2->location->column,
                                                                                                                $2->name);
                                        var_ref_type = getTypeTable(CONST_VOID, TYPE_SIMPLE, NULL, NULL);
                                    }
                                    else if (ID_VARIABLE == node->property){
                                        var_ref_type = node->value.type;
                                    }
                                    else{
                                        var_ref_type = node->value.fnct->rtn;
                                    }
                                }
                            }
                        component_selection
                            {
                                char*   symbol_name;

                                if (NULL == $4){
                                    symbol_name = (char*)malloc(strlen($2->name) + 2);
                                    sprintf(symbol_name, "%c%s", $1, $2->name);
                                    $$ = createTemporarySymbol(symbol_name, var_ref_type);
                                }
                                else{
                                    symbol_name = (char*)malloc(strlen($2->name) + strlen($4->name) + 2);
                                    sprintf(symbol_name, "%c%s%s", $1, $2->name, $4->name);
                                    $$ = createTemporarySymbol(symbol_name, $4->value.type);
                                }
                            }
                    |   LBRACKET
                            {
                                if (TYPE_ARRAY != var_ref_type->property){
                                    fprintf(stderr, "Line %u:%u error: Subscripted value is neither array nor vector\n",    line_number,
                                                                                                                            column_number);
                                    array_type = var_ref_type;
                                }
                                else{
                                    array_type = var_ref_type->value.array->basic;
                                }
                            }
                        expression RBRACKET
                            {
                                if ($3->value.type != getTypeTable(CONST_INTEGER, TYPE_SIMPLE, NULL, NULL)){
                                    fprintf(stderr, "Line %u:%u error: Array subscript is not an '%s'\n",   line_number,
                                                                                                            column_number,
                                                                                                            CONST_INTEGER);
                                }
                                var_ref_type = array_type;
                            }
                        component_selection
                            {
                                char*   temp = getTemporarySymbolName();
                                char*   symbol_name;

                                putQuadrupleQueue(  code_queue,
                                                    NULL,
                                                    "*",
                                                    $3->name,
                                                    itoa(array_type->size),
                                                    temp);
                                if (NULL == $6){
                                    symbol_name = (char*)malloc(strlen(temp) + 3);
                                    sprintf(symbol_name, "%c%s%c", $1, temp, $4);
                                    $$ = createTemporarySymbol(symbol_name, var_ref_type);
                                }
                                else{
                                    symbol_name = (char*)malloc(strlen(temp) + strlen($6->name) + 3);
                                    sprintf(symbol_name, "%c%s%c%s", $1, temp, $4, $6->name);
                                    $$ = createTemporarySymbol(symbol_name, $6->value.type);
                                }
                            }
                    ;
actual_parameter_list   :   /*empty*/                           {$$ = initSymbolTable(CONST_ACTUAL);}
                        |   actual_parameter_list_section       {$$ = $1;}
                        ;
actual_parameter_list_section   :   actual_parameter_list_section COMMA expression
                                        {
                                            $$ = $1;
                                            while ($1->next != NULL){
                                                $1 = $1->next;
                                            }
                                            $1->next = $3;
                                        }
                                |   expression
                                        {
                                            $$ = initSymbolTable(CONST_ACTUAL);
                                            $$->next = $1;
                                        }
                                ;
identifier_list :   identifier_list COMMA ID
                        {
                            $$ = $1;
                            while ($1->next != NULL){
                                $1 = $1->next;
                            }
                            $1->next = $3;
                        }
                |   ID  {$$ = $1;}
                ;

%%
/*Epilogue*/
/*  Main Function
    Variable Definition:
    -- argc: number of command arguments
    -- argv: each variable of command arguments(argv[0] is the path of execution file forever)
    Return Value: exit number
*/
int main(int argc, char *argv[]){
    //Test for correct number of arguments
    if (argc != 2){
        dieWithUserMessage("Parameter(s)", "<input file name>");
    }

    //Open file for reading input stream
    if (NULL == (yyin = fopen(argv[1], "r"))){
        dieWithUserMessage("fopen() failed", "Cannot open file to read input stream!");
    }

    //Initialize
    init();

    //Start syntax analysis
    do {
        yyparse();
    } while (!feof(yyin));

#ifdef DEBUG
    outputTypeTable(pretype_table, stdout);
    outputTypeTable(type_table, stdout);
    outputStack(getTop(stack), stdout);
#endif
    
    //Open file for writing intermediate code
    if (NULL == (yyout = fopen(CONST_FILE, "w"))){
        dieWithUserMessage("fopen() failed", "Cannot open file to write intermediate code!");
    }
    //Combine label and intermediate code quadruple
    combineQuadrupleQueue(code_queue);
    //Reverse intermediate code quadruple queue
    reverseQuadrupleQueue(code_queue);
    //Output intermediate code
    outputQuadrupleQueue(code_queue, stdout);
    //Output information
    fprintf(stdout, "Intermediate Code generates successful, please see %s file!\n", CONST_FILE);

    //Clear
    clear();
    //Close file stream
    fclose(yyin);
    fclose(yyout);

    return 0;
}
