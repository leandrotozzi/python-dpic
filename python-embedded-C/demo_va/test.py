#!/usr/bin/python
# This program adds two numbers
import sys
 
if( len( sys.argv ) < 3 ) :
	raise( Exception( "Usage: test.py number1 number2" ) )
 
num1 = int(sys.argv[ 1 ])
print "sys.argv[ 1 ] : ",int(sys.argv[ 1 ])
num2 = int(sys.argv[ 2 ])
print "sys.argv[ 2 ] : ", int(sys.argv[ 2 ])
 
#the suma function definition
def suma( arg1, arg2 ):
	# Add both the parameters and return them."
	total = arg1 + arg2; # Here total is local variable.
	print "Inside the function local total : ", total
	return total;
 
# Display the suma
print('The sum using suma function of {0} and {1} is {2}'.format(num1, num2, suma(num1,num2)))
 
#num1 = 1.5
#num2 = 6.3
# Add two numbers
sum = float(num1) + float(num2)
# Display the sum
print('The sum of {0} and {1} is {2}'.format(num1, num2, sum))
 
 
#a dummy function definition
def multiply():
	c = 12345*6789
	print 'The result of 12345 x 6789 :', c
	return c