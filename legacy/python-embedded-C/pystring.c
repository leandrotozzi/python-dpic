#include <Python.h>

int main()
{
    printf("String execution\n");
    Py_Initialize();
    PyRun_SimpleString("import string");
    PyRun_SimpleString("words = string.split('rod jane freddy')");
    PyRun_SimpleString("print string.join(words,', ')");
    Py_Finalize();
    return 0;
}