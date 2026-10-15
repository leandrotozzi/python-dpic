//include DPI
#include "svdpi.h"
//include the IO files
#include <stdio.h>
//include string functions
#include <string.h>
//include use of malloc
#include <stdlib.h>
//include Phyton embed lib
#include <Python.h>
 
 
//to add the ability to use printf
// same inputs as defined in SV with python path which is the defined surrounded by double quotes ""
 
//#ifndef PYTHON_PATH
//#error You must define the path to the python file in gcc compiler with -D 'PYTHON_PATH="'$PYTHON_DIR'"' or vlog with -ccflags "-I/usr/include/python2.6/ -D 'PYTHON_PATH=\"$PYTHON_DIR\"'"
//#endif
 
 /* function declaration */
void python_sign_msg( char *key_file_name, char *msg_file_name, char *signed_file_name ) {
 
 
          //char *append_path = malloc(sizeof(char) * 1000);
          //append_path = PYTHON_PATH":.";
          //printf("Append to path is:\n%s\n", append_path);           
          //setenv("PYTHONPATH",append_path,1);//Set PYTHONPATH TO working directory <a href="https://www.ibm.com/support/knowledgecenter/en/SSLTBW_2.1.0/com.ibm.zos.v2r1.bpxbd00/setenv.htm
          //char *path = Py_GetPath();
          //printf("Python search path is:\n%s\n", path);
 
          int argc;
          char * argv[2];
          char *phyton_script_name = malloc(sizeof(char) * 100);
          phyton_script_name = "test";//don't use the .py extension here
 
 
          argc = 3;//argument count is 3 arguments
          argv[0] = phyton_script_name;//key_file_name;//"mymod";//the argument value vector is
          argv[1] = "4";
          argv[2] = "3";
 
           Py_Initialize();// Initialize the Python Interpreter
 
           //First import python script module name
 
           PySys_SetArgv(argc, argv);//set the previous arguments as calling arguments of the import module
           //PyObject* myPmodule = PyImport_ImportModule("sign_hmac-sha256");//don't put the .py extension here
           PyObject* myPmodule = PyImport_ImportModule(phyton_script_name);//IMPORTANT THE MAIN MODULE IS EXECUTED here with the PySys_SetArgv arguments
           if(myPmodule==NULL)
           {
               printf("Not able to load&execute main phyton script:\n%s\n", phyton_script_name);
               PyErr_Print();
           }
           ///////////////////////////////
           //Extract variables through dict
           //////////////////////////////
           //retrieve all variables and functions of the module in a namespace or dict
           PyObject *module_dict   = PyModule_GetDict(myPmodule);
 
           char *function_name = malloc(sizeof(char) * 100);
           function_name = "suma";//don't use the .py extension here
           //getting the reference to the specific python function you want from the python script
           PyObject* myPfunction = PyObject_GetAttrString(myPmodule, function_name);
 
           if (PyCallable_Check(myPfunction))
           {
               //EXAMPLE CREATE arguments in Python 
               //PyObject* myPargs=Py_BuildValue("(z)",(char*)"something");
               //PyObject* myPargs = PyTuple_Pack(1,PyFloat_FromDouble(2.0));
               //ok = PyArg_ParseTuple(args, "lls", &k, &l, &s); /* Two longs and a string */
               //PyObject* myPargs = Py_BuildValue("sss",key_file_name,msg_file_name,signed_file_name); /* Three strings */
               //Execute the function with arguments directly
               //PyObject* result = PyObject_CallObject(myPfunction, (char*)"something", (char*)"something", (char*)"something");/* Three strings */               
               //PyObject* myPargs = Py_BuildValue("zz","4" ,"3");
               PyObject* myPargs = Py_BuildValue("ii",4 ,3);
               PyObject* item=PyTuple_GetItem(myPargs,0);//get the item of the tuple position 0 
               printf("Python tuple: %d\n", (int)PyInt_AsSsize_t(item)); /*incase an integer*/
               //printf("Python tuple: %s\n", PyString_AsString(item));
               PyErr_Print();               
               PyObject* result = PyObject_CallObject(myPfunction, myPargs);//the myPargs must be always be a Pyobject               
 
               PyErr_Print();
               Py_DECREF(myPargs);
               Py_DECREF(item);
               Py_DECREF(result);
           } else 
           {
               printf("The function:\n%s\n", function_name);
               //Pring errors comming from Python
               PyErr_Print();
           }
 
 
           ////////////////////////////////////////
           // Clean up phase
           ////////////////////////////////////////
           Py_DECREF(myPmodule);
           Py_DECREF(myPfunction);
 
 
 
           Py_Finalize();// Finish the Python Interpreter
}
 
 /* function declaration text char stream passed as pointer value and text2 passed as pointer reference */
  char * return_string_in_c( char *text,  char **text2) {
    char *fix="This variable cannot be changed although it is a pointer, just as example";/*fix allocation and constant*/
    char dest[50]="Variable array created in a function:";/* String array max 50 chars allocated*/
    char *out = malloc(sizeof(char) * 100);/* Dynamic string max 100 chars allocated*/
    /* Concatenate input text and put in out of strcat*/
    //strcat(out, text);/* initialize out using text string*/
    snprintf(out, sizeof(char) * 100, "%s%s", out,text);
    printf("fix : |%s|,dest : |%s|,text : |%s|,out : |%s|\n", fix,dest,text,out);
    *text2=dest;/* allocate pointer value with dest*/
    *text2=out;/* allocate pointer value with out*/
    return out;
}
 
 /* main */
 void main() {
    char text[100]="from_main_text_variable";/*max 100 chars allocated*/
    char *text2;/* pointer not allocated*/
    char *point = return_string_in_c(text, &text2);/* &text2 passing by reference*/
    printf("Final destination string : |%s|\n", text2);
    printf("point output : |%s|\n", point);       
 
    //printf("DEFINED PYTHON_PATH: |%s|\n", PYTHON_PATH);
    python_sign_msg("","","");
    printf("Finished python\n");
 
 }