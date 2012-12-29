///////////////////////////////////////////////////////////
/*
 * File Name:       CodeGeneration.h
 * Instructor:      Prof. Mohamed Zahran
 * Grader:          Robert Soule
 * Author:          Shen Li
 * UID:             N14361265
 * Department:      Computer Science
 * Note:            This CodeGeneration.h file includes
 *                  variable, macro, structure, function
 *                  declaration and precompile.
*/
///////////////////////////////////////////////////////////

//////////Precompile//////////
#ifndef CODEGENERATION_H
#define CODEGENERATION_H

//////////Head File//////////
#include <stdbool.h>

//////////Macro Declaration//////////
/*file definition*/
#define CONST_FILE      "a.txt"
/*type definition*/
#define CONST_VOID      "void"
#define CONST_INTEGER   "integer"
#define CONST_BOOLEAN   "boolean"
#define CONST_STRING    "string"
#define CONST_RECORD    "record"
/*variable definition*/
#define CONST_TRUE      "true"
#define CONST_FALSE     "false"
/*table head name definition*/
#define CONST_SYMBOL    "SYMBOL TABLE"
#define CONST_PREDEF    "PREDEFINE"
#define CONST_TYPE      "TYPE"
#define CONST_VAR       "VARIABLE"
#define CONST_FORMAL    "FORMAL"
#define CONST_ACTUAL    "ACTUAL"
#define CONST_FIELD     "FIELD"
/*intermediate code operation definition*/
#define CONST_BEGIN     "begin"
#define CONST_PARAM     "param"
#define CONST_PROCALL   "call"
#define CONST_FUNCALL   "funcall"
#define CONST_PRORTN    "return"
#define CONST_FUNRTN    "funreturn"
#define CONST_IFFALSE   "ifFalse"
#define CONST_GOTO      "goto"
#define CONST_ASSIGN    ":="

//////////Type Declaration//////////
typedef unsigned short  u_int16;
typedef unsigned int    u_int32;

//////////Enum Declaration//////////
enum    identifier_type{
    ID_VARIABLE = 1,
    ID_PROCEDURE,
    ID_FUNCTION,
};

enum    type_property{
    TYPE_SIMPLE = 1,
    TYPE_ARRAY,
    TYPE_RECORD,
};

enum    type_length{
    BOOLEAN_LENGTH = 1,
    VOID_LENGTH = 4,
    INTEGER_LENGTH = 8,
    STRING_LENGTH = 16,
    OTHER_LENGTH = 2,
};
//////////Struct Declaration//////////
/*Array Bound Structure*/
typedef struct _arrayinfo{
    u_int16 start;              //array bound start
    u_int16 end;                //array bound end
    struct _symtyp  *basic;     //array basic type
}ARRAYINFO, *PARRAYINFO;

/*Symbol Location Structure*/
typedef struct _symloc{
    u_int32 line;
    u_int16 column;
}SYMLOC, *PSYMLOC;

/*Type Definition Structure*/
typedef struct _symtyp{
    char*   name;               //type name
    u_int16 property;           //type property: simple, array or record
    union{
        struct _symtyp      *equal; //type equivalence
        struct _arrayinfo   *array; //type info for array
        struct _symrec      *field; //type name field list for record
    }value;                     //type value
    size_t  size;               //type size
    struct _symtyp  *next;      //link field
}SYMTYP, *PSYMTYP;

/*Symbol Table Structure*/
typedef struct _symrec{
    char*   name;               //identifier name
    u_int16 property;           //identifier property: variable, function or procedure
    union{
        PSYMTYP         type;   //variable type
        struct _symfnct *fnct;  //function or procedure struct
    }value;
    PSYMLOC location;           //identifier location
    struct _symrec  *next;      //link field
}SYMREC, *PSYMREC;

/*Symbol Table Function (or Procedure) Structure*/
typedef struct _symfnct{
    char*   name;               //function name 
    size_t  parameter;          //function parameter number
    PSYMTYP rtn;                //function return type
    PSYMREC formal_list;        //function formal parameter list
    PSYMREC local_list;         //function local variable list
    struct _symfnct *next;      //link chain
}SYMFNCT, *PSYMFNCT;

/*Intermediate Code Quadruples Structure*/
typedef struct _quadruple{
    char*   label;              //quadruple label
    char*   op;                 //quadruple operation
    char*   arg1;               //quadruple argument one
    char*   arg2;               //quadruple argument two
    char*   result;             //quadruple result
    struct _quadruple   *prev;  //link chain
    struct _quadruple   *next;  //link chain
}QUADRUPLE, *PQUADRUPLE;

/*Intermediate Code Queue Structure*/
typedef struct _codequeue{
    PQUADRUPLE  front;          //queue front
    PQUADRUPLE  rear;           //queue rear
}CODEQUEUE, *PCODEQUEUE;

//////////Variable Declaration//////////
extern u_int32      line_number;
extern u_int16      column_number;
extern PSYMTYP      pretype_table;
extern PSYMTYP      type_table;
extern PSYMFNCT     stack;
extern PCODEQUEUE   code_queue;
extern PSYMTYP      var_ref_type;
extern PSYMTYP      array_type;
extern PSYMREC      rtn_symbol;

/////////Function Declaration//////////
/*DieWithMessage.c*/
void    dieWithUserMessage(const char* message, const char* detail);
void    dieWithSystemMessage(const char* message);
/*CodeGeneration.l*/
PSYMREC installID(void);
/*Utility.c*/
void    yyerror(const char* detail);
void    init(void);
void    clear(void);
char*   itoa(u_int16 number);
char*   getTemporarySymbolName(void);
char*   getLabelName(void);
PSYMREC createTemporarySymbol(  const char* name,
                                PSYMTYP     type);
size_t  getRecordSize(const PSYMREC table);
/*Type.c*/
void    initTypeTable(void);
void    clearTypeTable(PSYMTYP table);
void    putTypeTable(   PSYMTYP     table,
                        const char* name,
                        u_int16     property,
                        PSYMTYP     equal,
                        PARRAYINFO  array,
                        PSYMREC     field,
                        size_t      size);
PSYMTYP getTypeTable(   const char*         name,
                        u_int16             property,
                        const PARRAYINFO    array,
                        const PSYMREC       field);
void    outputType( const PSYMTYP   node,
                    FILE*           stream);
void    outputTypeTable(const PSYMTYP   table,
                        FILE*           stream);
/*Symbol.c*/
PSYMREC initSymbolTable(const char* name);
void    clearSymbolTable(PSYMREC table);
void    putSymbolTable( PSYMREC     table,
                        const char* name,
                        u_int16     property,
                        PSYMTYP     type,
                        PSYMFNCT    fnct,
                        PSYMLOC     location);
PSYMREC getSymbolTable( const PSYMREC   table,
                        const char*     name);
bool    compareSymbolTable( const PSYMREC   table_1,
                            const PSYMREC   table_2);
size_t  getLengthSymbolTable(const PSYMREC  table);
void    reverseSymbolTable(PSYMREC table);
void    outputSymbolTable(  const PSYMREC   table,
                            FILE*           stream);
/*Stack.c*/
void    initStack(void);
void    clearStack(PSYMFNCT s);
bool    emptyStack(const PSYMFNCT s);
void    push(   PSYMFNCT    s,
                const char* name,
                size_t      parameter,
                PSYMTYP     rtn,
                PSYMREC     formal_list,
                PSYMREC     local_list);
void    pop(PSYMFNCT s);
PSYMFNCT    getTop(const PSYMFNCT s);
PSYMREC find(const char* name);
void    outputStack(const PSYMFNCT  s,
                    FILE*           stream);
/*Quadruple.c*/
void    initQuadrupleQueue(void);
void    clearQuadrupleQueue(PCODEQUEUE q);
void    putQuadrupleQueue(  PCODEQUEUE  q,
                            const char* label,
                            const char* operation,
                            const char* argument_one,
                            const char* argument_two,
                            const char* result);
void    combineQuadrupleQueue(PCODEQUEUE q);
void    reverseQuadrupleQueue(PCODEQUEUE q);
PQUADRUPLE  getQuadrupleByOperation(PCODEQUEUE  q,
                                    const char* operation);
void    setLabel(   PQUADRUPLE  p,
                    const char* label);
void    setOperation(   PQUADRUPLE  p,
                        const char* operation);
void    setArgument(PQUADRUPLE  p,
                    const char* argument_one,
                    const char* argument_two);
void    setResult(  PQUADRUPLE  p,
                    const char* result);
void    insertQuadruple(PCODEQUEUE  q,
                        PQUADRUPLE  p,
                        const char* label,
                        const char* operation,
                        const char* argument_one,
                        const char* argument_two,
                        const char* result);
void    deleteQuadruple(PCODEQUEUE  q,
                        PQUADRUPLE  p);
void    outputQuadrupleQueue(   const PCODEQUEUE    q,
                                FILE*               stream);
#endif  //CODEGENERATION_H
