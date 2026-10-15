/* Forward svDpiVersion() to SV. */
#include "svdpi.h"
extern "C" const char* dpi_version() { return svDpiVersion(); }
