// Step 07, experiment "config": initialize Python with PyConfig (3.8+) or PyInitConfig (3.14),
// point it at a venv, and see what the interpreter thinks it is.
import "DPI-C" function int  cfg_init(input string api, input string venv, input int replace_path);
import "DPI-C" function void cfg_report();
import "DPI-C" function void cfg_fin();

module top;
  string api = "config", venv = "";
  int replace_path;
  initial begin
    void'($value$plusargs("api=%s", api));
    void'($value$plusargs("venv=%s", venv));
    void'($value$plusargs("replace_path=%d", replace_path));
    if (cfg_init(api, venv, replace_path) != 0) begin
      $display("LOG init failed");
      $finish;
    end else begin
      cfg_report();
      $finish;
    end
  end
  final cfg_fin();
endmodule
