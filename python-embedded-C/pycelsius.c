#include <Python.h>

/*
Free up Python objects that you've created but no longer need:
    You don't have to free the objects directly: Instead, you tell Python
    through the Py_DECREF function to decrement the reference count for the object. In
    Python (and other languages), when the reference count to a variable reaches zero,
    the object is automatically deleted as part of the garbage-collection process.
*/

/* Create a function to handle errors when they occur */
void error(char errstring)
{
    printf("%s\n",errstring);
    exit(1);
}

int main()
{
    /* Set up the variables to hold methods, functions and class
    instances. farenheit will hold our return value */
    PyObject *ret, *mymod, *class, *method, *args, *object;
    float farenheit;

    Py_Initialize();

    /* Load our module */
    mymod = PyImport_ImportModule("celsius");

    /* If we dont get a Python object back there was a problem */
    if (mymod == NULL)
        error("Can't open module");

    /* Find the class */
    class = PyObject_GetAttrString(mymod, "celsius");

    /* If found the class we can dump mymod, since we won't use it
    again */
    Py_DECREF(mymod);
    
    /* Check to make sure we got an object back */
    if (class == NULL){
        Py_DECREF(class);
        error("Can't find class");
    }

    /* Build the argument call to our class - these are the arguments
    that will be supplied when the object is created */
    args = Py_BuildValue("(f)", 100.0);
    if (args == NULL){
        Py_DECREF(args);
        error("Can't build argument list for class instance");
    }

    /* Create a new instance of our class by calling the class
    with our argument list */
    object = PyEval_CallObject(class, args);
    if (object == NULL){
        Py_DECREF(object);
        error("Can't create object instance");
    }
    /* Decrement the argument counter as we'll be using this again */
    Py_DECREF(args);

    /* Get the object method - note we use the object as the object
    from which we access the attribute by name, not the class */
    method = PyObject_GetAttrString(object, "farenheit");
    if (method == NULL){
        Py_DECREF(method);
        error("Can't find method");
    }
    /* Decrement the counter for our object, since we now just need
    the method reference */
    Py_DECREF(object);

    /* Build our argument list - an empty tuple because there aren't
    any arguments */
    args = Py_BuildValue("()");
    if (args == NULL){
        Py_DECREF(args);
        error("Can't build argument list for method call");
    }

    /* Call our object method with arguments */
    ret = PyEval_CallObject(method,args);
    if (ret == NULL){
        Py_DECREF(ret);
        error("Couldn't call method");
    }

    /* Convert the return value back into a C variable and display it */
    PyArg_Parse(ret, "f", &farenheit);
    printf("Farenheit: %f\n", farenheit);

    /* Kill the remaining objects we don't need */
    Py_DECREF(method);
    Py_DECREF(ret);

    /* Close off the interpreter and terminate */
    Py_Finalize();
    return 0;
}