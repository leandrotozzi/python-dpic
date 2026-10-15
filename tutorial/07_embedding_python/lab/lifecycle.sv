// Step 07, experiment "lifecycle": what finalize does, calling after finalize,
// never finalizing, and re-initializing per call (the anti-pattern).
import "DPI-C" function int  life_init();
import "DPI-C" function void life_fin();
import "DPI-C" function int  life_say(input string msg);
import "DPI-C" function int  life_raw_say(input string msg);
import "DPI-C" function real life_cycle_ms(input int n, input int with_numpy);

module top;
  string mode = "fin";

  task automatic cycle();
    $display("LOG cycle plain_ms=%0.2f", life_cycle_ms(20, 0));
    $display("LOG cycle numpy_ms=%0.2f", life_cycle_ms(3, 1));
    $finish;
    $display("LOG after_finish still running");   // $finish does not stop this process here
  endtask

  task automatic normal();
    void'(life_init());
    void'(life_say("hello from python"));
    $display("SV after say");
    if (mode == "guard" || mode == "raw") begin
      life_fin();
      $display("SV finalized, calling again");
      if (mode == "guard") $display("LOG guard rc=%0d", life_say("after fin"));
      else                 $display("LOG raw rc=%0d", life_raw_say("after fin"));
    end
    $finish;
  endtask

  initial begin
    void'($value$plusargs("mode=%s", mode));
    $display("SV mode=%s", mode);
    if (mode == "cycle") cycle();
    else                 normal();
  end

  final begin
    if (mode == "fin") life_fin();                // nofin: never finalized
    $display("SV final block done");
  end
endmodule
