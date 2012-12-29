///////////////////////////////////////////////////////////
/*
 * File Name:       Utility.c
 * Instructor:      Prof. Mohamed Zahran
 * Grader:          Robert Soule
 * Author:          Shen Li
 * UID:             N14361265
 * Department:      Compute Science
 * Note:            This Utility.c file includes
 *                  Several Auxiliary Functions
*/
///////////////////////////////////////////////////////////

//////////Head File//////////
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "CodeGeneration.h"

//////////Function Definition//////////
/*  Parser Error Function
    Variable Definition:
    -- detail: detail error message
    Return Value: NULL
*/
void yyerror(const char* detail){
    fprintf(stderr, "Line %u:%u : %s\n",    line_number,
                                            column_number,
                                            detail);
    
    return;
}

/*  Initialize Analyzer Function
    Variable Definition:
    -- void
    Return Value: NULL
*/
void init(void){
    //Initialize predefine and type table
    initTypeTable();
    //Initialize symbol table stack
    initStack();
    //Initialize intermediate code quadruple queue
    initQuadrupleQueue();

    return;
}

/*  Clear Analyzer Function
    Variable Definition:
    -- void
    Return Value: NULL
*/
void clear(void){
    PSYMFNCT    top;        //_symfnct struct node

    //Get the top element of stack
    top = getTop(stack);
    //Free top element
    clearStack(top);
    //Free stack head node
    free(stack);
    //Free pretype table
    clearTypeTable(pretype_table);
    //Free type table
    clearTypeTable(type_table);
    //Free quadruple queue
    clearQuadrupleQueue(code_queue);

    return;
}

/*  Convert Number to String Function
    Variable Definition:
    -- number: original number
    Return Value: corresponding string
*/
char* itoa(u_int16 number){
    u_int16     i = number;     //number
    u_int16     j;              //counter
    u_int16     power;          //power
    char*       string;         //convert string

    //Allocate memory for string
    string = (char*)malloc(sizeof(char) * 9);
    //Find the maximum power
    for (power = 1, j = 1; i >= 10; i /= 10, j++){
        power *= 10;
    }
    //Get the string
    for (; power > 0; power /= 10){
        *string++ = '0' + number / power;
        number %= power;
    }
    //Set the end of the string
    *string = '\0';

    return string - j;
}

/*  Get Temporary Identifier Name Function
    Variable Definition:
    -- void
    Return Value: temporary identifier name
*/
char* getTemporarySymbolName(void){
    static u_int16  count = 1;          //temporary identifier count
    char*           n = itoa(count);    //temporary identifier count string
    char*           temp;               //temporary identifier name

    //Allocate memory for temporary identifier
    temp = (char*)malloc(strlen(n) + 2);
    //Set temporary identifier name
    sprintf(temp, "t%u", count++);
    //Free count string
    free(n);

    return temp;
}

/*  Get Intermediate Code Label Name Function
    Variable Definition:
    -- void
    Return Value: label name
*/
char* getLabelName(void){
    static u_int16  count = 1;          //label count
    char*           n = itoa(count);    //label count string
    char*           label;              //label name

    //Allocate memory for label name
    label = (char*)malloc(strlen(n) + 2);
    //Set label name
    sprintf(label, "L%u", count++);
    //Free count string
    free(n);

    return label;
}

/*  Create Temporary Idnetifier Function
    Variable Definition:
    -- name: identifier name
    -- type: identifier type
    Return Value: temporary identifier _symrec struct node
*/
PSYMREC createTemporarySymbol(  const char* name,
                                PSYMTYP     type){
    PSYMREC     symbol;     //_symrec struct node

    //Allocate memory for temporary identifier node
    symbol = (SYMREC*)malloc(sizeof(SYMREC));
    //Set "name" field
    symbol->name = (char*)malloc(strlen(name) + 1);
    symbol->name = strdup(name);
    //Set "property" field
    symbol->property = ID_VARIABLE;
    //Set identifier type field
    symbol->value.type = type;
    //Set "location" field
    symbol->location = NULL;
    //Set "next" field
    symbol->next = NULL;

    return symbol;
}

/*  Get Record Size Function
    Variable Definition:
    -- table: record field table
    Return Value: record size
*/
size_t getRecordSize(const PSYMREC table){
    PSYMREC     node;               //_symrec struct node
    size_t      record_size = 0;    //record field size

    //Compute the record size
    for (node = table->next; node != NULL; node = node->next){
        if (ID_VARIABLE == node->property){
            record_size += node->value.type->size;
        }
        else if (ID_PROCEDURE == node->property){
            record_size += VOID_LENGTH;
        }
        else if (ID_FUNCTION == node->property){
            record_size += node->value.fnct->rtn->size;
        }
    }

    return record_size;
}
