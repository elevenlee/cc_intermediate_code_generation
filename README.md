cc_intermediate_code_generation
===============================

In this last part of the project, we are adding one more part to the puzzle! In that part, your compiler is actually generating code.


1. The code was written under the Ubuntu Linux System (Version 11.10)
2. The Compiler version is GCC 4.6.1
3. I have written a "makefile" document
   So just type "make" command under current directory to compile source code.
   Also, type "make clean" under current directory to remove all files except source files. 
4. The format of running source code is as below:

    ./CodeGeneration <input file name>

   (1) The <input file name> argument is necessary;
   (2) The output file name is "a.txt"

5. Some additional information about Code Generation
   *Use "ifFalse" to implement conditional or unconditional jump.
   *Call procedure command is as below:
    
    param x1
    param x2
    ...
    param xn
    call <procedure name>, <procedure parameter number>

   *Call function command is as below:

    param x1
    param x2
    ...
    param xn
    funcall <function name>, <function parameter number>

   *Moreover, I add the "/" as division operation. Its token name is "DIVIS".
