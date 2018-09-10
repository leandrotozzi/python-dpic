 ////////////////////////////////////////////////////////////////////////
 //IMPORT FUNCTION DPI DECLARATION FROM C
 ////////////////////////////////////////////////////////////////////////            
import "DPI-C" function void python_sign_msg(string key_file_name, string msg_file_name, string signed_file_name );
import "DPI-C" function string return_string_in_c(string text, inout string output_txt);    
 
program automatic test;
    initial begin
	//////////////////////
	//USE OF DPI
	//////////////////////
	string output_c, output2_c;
	output_c = return_string_in_c("This text",output2_c); 
	python_sign_msg("file.txt","bla","blo");
 
    for (int i=1; i<=10; i++)
        $display("%0d! = %0d", i, i);
    end

endprogram