///////////////////////////////////////////////////////////
/*
 * File Name:       Quadruple.c
 * Instructor:      Prof. Mohamed Zahran
 * Grader:          Robert Soule
 * Author:          Shen Li
 * UID:             N14361265
 * Department:      Computer Science
 * Note:            This Quadruple.c file includes
 *                  Process Intermediate Code Quadruples
 *                  Structure Functions
*/
///////////////////////////////////////////////////////////

//////////Head File//////////
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "CodeGeneration.h"

//////////Function Definition//////////
/*  Initialize Intermediate Code Queue Function
    Variable Definition
    -- void
    Return Value: NULL
*/
void initQuadrupleQueue(void){
    //Allocate memory for intermediate code queue
    code_queue = (CODEQUEUE*)malloc(sizeof(PCODEQUEUE));
    //Initialize queue front and rear
    code_queue->front = code_queue->rear = NULL;

    return;
}

/*  Clear Intermediate Code Queue Function
    Variable Definition:
    -- q: intermediate code quadruple queue
    Return Value: NULL
*/
void clearQuadrupleQueue(PCODEQUEUE q){
    PQUADRUPLE  node;       //_quadruple struct node

    //Initialize node
    node = q->front;
    //Free all node in intermediate code quadruple queue link chain
    while (node != NULL){
        //Remove node fron queue
        q->front = q->front->next;
        //Free _quadruple struct node
        free(node);
        //Update node pointer
        node = q->front;
    }
    //Update queue rear as NULL
    q->rear = NULL;
    //Free _codequeue struct node
    free(q);

    return;
}

/*  Put Intermediate Code Quadruple into Queue Function
    Variable Definition:
    -- q: intermediate code queue
    -- label: quadruple label
    -- operation: quadruple operation
    -- argument_one: first quadruple argument
    -- argument_two: second quadruple argument
    -- result: quadruple result
    Return Value: NULL
*/
void putQuadrupleQueue( PCODEQUEUE  q,
                        const char* label,
                        const char* operation,
                        const char* argument_one,
                        const char* argument_two,
                        const char* result){
    PQUADRUPLE  node;       //_quadruple struct node

    //Allocate memory for intermediate code quadruple node
    node = (QUADRUPLE*)malloc(sizeof(QUADRUPLE));
    //Set "label" field
    if (NULL == label){
        node->label = NULL;
    }
    else{
        node->label = (char*)malloc(strlen(label) + 1);
        node->label = strdup(label);
    }
    //Set "op" field
    if (NULL == operation){
        node->op = NULL;
    }
    else{
        node->op = (char*)malloc(strlen(operation) + 1);
        node->op = strdup(operation);
    }
    //Set "arg1" field
    if (NULL == argument_one){
        node->arg1 = NULL;
    }
    else{
        node->arg1 = (char*)malloc(strlen(argument_one) + 1);
        node->arg1 = strdup(argument_one);
    }
    //Set "arg2" field
    if (NULL == argument_two){
        node->arg2 = NULL;
    }
    else{
        node->arg2 = (char*)malloc(strlen(argument_two) + 1);
        node->arg2 = strdup(argument_two);
    }
    //Set "result" field
    if (NULL == result){
        node->result = NULL;
    }
    else{
        node->result = (char*)malloc(strlen(result) + 1);
        node->result = strdup(result);
    }
    //Set "prev" field
    node->prev = NULL;
    //Set "next" field
    node->next = NULL;

    //Put intermediate code quadruple into queue
    if (NULL == q->front){
        //this quadruple is front as well as rear
        q->front = q->rear = node;
    }
    else{
        //Update previous quadruple
        node->prev = q->rear;
        //this quadruple is rear
        q->rear = q->rear->next = node;
    }

    return;
}

/*  Combine Label & Intermediate Code in Quadruple Queue Function
    Variable Definition:
    -- q: intermediate code quadruple queue
    Return Value: NULL
*/
void combineQuadrupleQueue(PCODEQUEUE q){
    PQUADRUPLE  node;       //_quadruple struct node

    //Combine label and intermediate code
    for (node = q->front; (node != q->rear) && (node != NULL); node = node->next){
        //Check "label" field
        if (node->label != NULL){
            //Update intermediate code quadruple node
            node = node->next;
            //Set "label" field
            setLabel(node, node->prev->label);
            deleteQuadruple(q, node->prev);
        }
    }

    return;
}

/*  Reverse Intermediate Code Quarduple Queue Function
    Variable Definition:
    -- q: intermediate code quadruple queue
    Return Value: NULL
*/
void reverseQuadrupleQueue(PCODEQUEUE q){
    PQUADRUPLE  node;       //_quadruple struct node

    //Find "begin" label
    for (node = q->front; node != NULL; node = node->next){
        if ((NULL != node->label)
                && (0 == strcmp(node->label, CONST_BEGIN))){
            break;
        }
    }
    //Reverse intermediate code quadruple queue
    if (NULL == node){
        dieWithUserMessage("reverseQuadrupleQueue() failed", "No main procedure!");
    }
    else if (node == q->front){
        //Do nothing
    }
    else{
        //Concatente front and end
        q->rear->next = q->front;
        q->front->prev = q->rear;
        //Update front and rear
        q->front = node;
        q->rear = node->prev;
        //Delete the loop in queue
        q->front->prev = q->rear->next = NULL;
    }

    return; 
}

/*  Get Intermediate Code Quadruple By Operation Function
    Variable Definition:
    -- q: intermediate code quadruple queue
    -- operation: operation name
    Return Value: quadruple node
*/
PQUADRUPLE getQuadrupleByOperation( PCODEQUEUE  q,
                                    const char* operation){
    PQUADRUPLE  node;       //_quadruple struct node

    //Find intemediate code quadruple node
    for (node = q->rear; node != NULL; node = node->prev){
        if ((NULL != node->op)
                && (0 == strcmp(node->op, operation))
                && (NULL == node->arg1)){
            break;
        }
    }

    return node;
}

/*  Set Quadruple Label Field Function
    Variable Definition:
    -- p: quadruple node
    -- label: label name
    Return Value: NULL
*/
void setLabel(  PQUADRUPLE  p,
                const char* label){
    //Check whether label is null
    if (NULL == label){
        p->label = NULL;
    }
    else{
        //Set "label" field
        p->label = (char*)malloc(strlen(label) + 1);
        p->label = strdup(label);
    }
    
    return;
}

/*  Set Quadruple Op Field Function
    Variable Definition:
    -- p: quadruple node
    -- operation: operation name
    Return Value: NULL
*/
void setOperation(  PQUADRUPLE  p,
                    const char* operation){
    //Check whether operation is null
    if (NULL == operation){
        p->op = NULL;
    }
    else{
        //Set "op" field
        p->op = (char*)malloc(strlen(operation) + 1);
        p->op = strdup(operation);
    }

    return;
}

/*  Set Quadruple Argument Field Function
    Variable Definition:
    -- p: quadruple node
    -- argument_one: first argument name
    -- argument_two: second argument name
    Return Value: NULL
*/
void setArgument(   PQUADRUPLE  p,
                    const char* argument_one,
                    const char* argument_two){
    //Check whether argument_one is null
    if (NULL == argument_one){
        p->arg1 = NULL;
    }
    else{
        //Set "arg1" field
        p->arg1 = (char*)malloc(strlen(argument_one) + 1);
        p->arg1 = strdup(argument_one);
    }
    //Check whether argument_two is null
    if (NULL == argument_two){
        p->arg2 = NULL;
    }
    else{
        //Set "arg2" field
        p->arg2 = (char*)malloc(strlen(argument_two) + 1);
        p->arg2 = strdup(argument_two);
    }

    return;
}

/*  Set Quadruple Result Field Function
    Variable Definition:
    -- p: quadruple node
    -- resulr: result name
    Return Value: NULL
*/
void setResult( PQUADRUPLE  p,
                const char* result){
    //Check whether result is null
    if (NULL == result){
        p->result = NULL;
    }
    else{
        //Set "result" field
        p->result = (char*)malloc(strlen(result) + 1);
        p->result = strdup(result);
    }

    return;
}

/*  Insert Intermediate Code Quadruple Function
    Variable Definition:
    -- q: intermediate code quadruple queue
    -- p: quadruple node
    -- label: label name
    -- operation: operation name
    -- argument_ont: first argument
    -- argument_two: second argument
    -- result: result name
*/
void insertQuadruple(   PCODEQUEUE  q,
                        PQUADRUPLE  p,
                        const char* label,
                        const char* operation,
                        const char* argument_one,
                        const char* argument_two,
                        const char* result){
    PQUADRUPLE  node;       //_quadruple struct node

    //Check intermediate code quadruple node p
    if (NULL == p){
        dieWithUserMessage("insertQuadruple() failed", "The intermediate code quadruple node does not exist!");
    }
    //Allocate memory for intermediate code quadruple node
    node = (QUADRUPLE*)malloc(sizeof(QUADRUPLE));
    //Set "label" field
    if (NULL == label){
        node->label = NULL;
    }
    else{
        node->label = (char*)malloc(strlen(label) + 1);
        node->label = strdup(label);
    }
    //Set "op" field
    if (NULL == operation){
        node->op = NULL;
    }
    else{
        node->op = (char*)malloc(strlen(operation) + 1);
        node->op = strdup(operation);
    }
    //Set "arg1" field
    if (NULL == argument_one){
        node->arg1 = NULL;
    }
    else{
        node->arg1 = (char*)malloc(strlen(argument_one) + 1);
        node->arg1 = strdup(argument_one);
    }
    //Set "arg2" field
    if (NULL == argument_two){
        node->arg2 = NULL;
    }
    else{
        node->arg2 = (char*)malloc(strlen(argument_two) + 1);
        node->arg2 = strdup(argument_two);
    }
    //Set "result" field
    if (NULL == result){
        node->result = NULL;
    }
    else{
        node->result = (char*)malloc(strlen(result) + 1);
        node->result = strdup(result);
    }
    //Set "prev" field
    node->prev = NULL;
    //Set "next" field
    node->next = NULL;

    //Insert intermediate code quadruple into queue
    if (p == q->front){
        //this quadruple is front
        p->prev = node;
        node->next = p;
        //Update front
        q->front = node;
    }
    else{
        //this quadruple is middle
        node->next = p;
        node->prev = p->prev;
        //Update intermediate code quadruple node p
        p->prev->next = node;
        p->prev = node;
    }

	return;
}

/*  Delete Intermediate Code Quadruple Function
    Variable Definition:
    -- q: intermediate code quadruple queue
    -- p: quadruple node
    Return Value: NULL
*/
void deleteQuadruple(   PCODEQUEUE  q,
                        PQUADRUPLE  p){
    //Intermediate code quadruple queue is empty
    if (NULL == q->front){
        dieWithUserMessage("deleteQuadruple() failed", "The intermediate code quadruple queue is empty!");
    }
    //Intermediate code quadruple queue has only one quadruple node
    else if (q->front == q->rear){
        q->front = q->rear = NULL;
    }
    //p is the front in intermediate code quadruple queue
    else if (p == q->front){
        q->front = p->next;
        p->next = NULL;
    }
    //p is the rear in intermediate code quadruple queue
    else if (p == q->rear){
        q->rear = p->prev;
        p->prev = NULL;
    }
    else{
        p->prev->next = p->next;
        p->next->prev = p->prev;
        p->next = p->prev = NULL;
    }

    //Free quadruple node p
    free(p);
    
    return;
}

/*  Output Intermediate Code Quadruple Function
    Variable Definition:
    -- q: intermediate code quadruple queue
    -- stream: output stream
    Return Value: NULL
*/
void outputQuadrupleQueue(  const PCODEQUEUE    q,
                            FILE*               stream){
    PQUADRUPLE  node;       //_quadruple struct node

    //Output intermediate code quadruple queue
    fputs("**********INTERMEDIATE CODE**********", stream);
    fputc('\n', stream);
    //Output intermediate code quadruple
    for (node = q->front; node != NULL; node = node->next){
        //Output label name
        if (NULL == node->label){
            fputs("\t\t\t", stream);
        }
        else{
            fputc('\n', stream);
            fprintf(stream, "%12s\t:\t", node->label);
        }
        //Output operation name
        if (NULL == node->op){
            fputs(" ", stream);
        }
        //Param command
        else if (0 == strcmp(node->op, CONST_PARAM)){
            fprintf(stream, "%s %s", node->op, node->arg1);
        }
        //Procedure call command
        else if (0 == strcmp(node->op, CONST_PROCALL)){
            fprintf(stream, "%s %s, %s", node->op, node->arg1, node->arg2);
        }
        //Function call command
        else if (0 == strcmp(node->op, CONST_FUNCALL)){
            fprintf(stream, "%s := %s %s, %s", node->result, node->op, node->arg1, node->arg2);
        }
        //Procedure return command
        else if (0 == strcmp(node->op, CONST_PRORTN)){
            fprintf(stream, "%s", node->op);
        }
        //Function return command
        else if (0 == strcmp(node->op, CONST_FUNRTN)){
            fprintf(stream, "%s %s", node->op, node->arg1);
        }
        //IfFalse command
        else if (0 == strcmp(node->op, CONST_IFFALSE)){
            fprintf(stream, "%s %s goto %s", node->op, node->arg1, node->result);
        }
        //Goto command
        else if (0 == strcmp(node->op, CONST_GOTO)){
            fprintf(stream, "%s %s", node->op, node->arg1);
        }
        //Assignment command
        else if (0 == strcmp(node->op, CONST_ASSIGN)){
            fprintf(stream, "%s %s %s", node->result, node->op, node->arg1);
        }
        //All command without second argument
        else if (NULL == node->arg2){
            fprintf(stream, "%s := %s %s", node->result, node->op, node->arg1);
        }
        //All other command
        else{
            fprintf(stream, "%s := %s %s %s", node->result, node->arg1, node->op, node->arg2);
        }
        fputc('\n', stream);
    }
    //Output intermediate code quadruple queue end
    fputs("**********INTERMEDIATE CODE end**********", stream);
    fputc('\n', stream);

    return;
}
