# SystemVerilog version
run:	simv fib_server
	fib_server &
	./simv

simv:	client.sv client_dpi.c
	vcs -sverilog client.sv client_dpi.c



# Stand alone vresion
fib:	client fib_server
	fib_server &
	client 5

client: client.c
	gcc -g client.c -o client

fib_server: fib_server.c
	gcc -g fib_server.c -o fib_server



DIR = $(shell basename `pwd`)
tar:	clean
	cd ..; tar cvf ${DIR}.tar ${DIR}

clean:
	@rm -rf *~ *.log *.vpd vc_hdrs.h .vcsmx_rebuild *.o
	@rm -rf simv* csrc* core* *.vrh *shell.v .__solver* *.key .ucli*
	@rm -rf client server fib_server
