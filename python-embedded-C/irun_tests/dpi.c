// dpi.c
#include "svdpi.h"
#include <stdio.h>
#include <stdlib.h>
#include "vpi_user.h"
#include <Python.h>

extern void allocate_mem ( int size );

void ref_model ( svOpenArrayHandle p )
{
  Py_Initialize();
  Py_Finalize();
  
  int unsigned *pp;
  int i;
  vpi_printf("c: Ref model started\n");
  allocate_mem(10);
  pp = ( int unsigned * ) svGetArrayPtr(p);
  for(i=0;i<10;i++) {
    pp[i] = i+1;
    vpi_printf("c: pp[%0d]=%0d\n",i,i+1);
  }
  vpi_printf("c: Ref model finished\n");
}