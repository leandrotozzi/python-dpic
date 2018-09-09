#include <Python.h>

int main()
{
    PyObject *strret, *mymod, *strfunc, *strargs;
    char *cstrret;

    Py_Initialize();

    // 1. Import the module that contains the function.
    //    PyImport_ImportModule() accepts a module name and returns a Python object
    //    (in this case, a module object).
    //    Note: Set PYTHON PATH, otherwise you will get Segmentation Fault.
    //          export PYTHONPATH=$PYTHONPATH:/home/leat/dpic/trials
    mymod = PyImport_ImportModule("rev");

    // 2. Get the reference to the function by accessing the attribute of the module.
    //    Pick the rstring function from the module.
    //    The resulting object is a function reference that you can use to call the function from
    //    within the C wrapper.
    strfunc = PyObject_GetAttrString(mymod, "rstring");

    // 3. Build the Python variable that you'll supply to the function.
    //    Note: argument from the command line:
    //          strargs = PyBuildValue("(s)", argv[1]);
    strargs = Py_BuildValue("(s)", "Hello World");

    // 4. Call the function.
    strret = PyEval_CallObject(strfunc, strargs);

    // 5. Convert the returned Python object back into a C variable.
    PyArg_Parse(strret, "s", &cstrret);

    printf("Reversed string: %s\n", cstrret);
    Py_Finalize();
    return 0;
}