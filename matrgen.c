#include <stdio.h>
#include <stdlib.h>
#include <fstream>
#include <iostream>
#include <time.h>

using namespace std;

int main(int argc, char* argv[]){
	ofstream output("matr.txt"); //output file
	int n, x;
	srand(time(NULL));

	if (argc<2){
		cout << "Usage: " << argv[0] << " N [x]" <<endl;
		cout << "where N is the size of NxN matrix, and x [optional] is the limit of random number (number will be generated from range 0...x)" << endl;
		cout << "default x=10" << endl;
		return -1;
	}
	if (argc>2) x=atoi(argv[2]); else x=10;
	n = atoi(argv[1]);
	output << n << endl;

	for (int k=0; k<n*3; k++){
		for (int j=0; j<n; j++)
			output << rand()%x << " ";
		output << endl;
	}
}