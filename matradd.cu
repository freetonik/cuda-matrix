#include <stdio.h>
#include <stdlib.h>
#include <fstream>
#include <iostream>
using namespace std;

//matrix structure
typedef struct {
	int n;
	int *el;
} Matrix;


//KERNEL
// D = AxB
__global__ void calcD(int n, Matrix D, Matrix A, Matrix B, Matrix C)
{
	int Cv = 0;
	int row = blockIdx.y * blockDim.y + threadIdx.y;
	int col = blockIdx.x * blockDim.x + threadIdx.x;
	for (int e=0; e<n; ++e)
		Cv+=A.el[row*n+e] * B.el[e*n+col];	//calculate one value
	D.el[row*n+col]=Cv+C.el[row*n+col];		//add value from C and write to D
}

//HOST CODE
int main(int argc, char* argv[])
{
	if (argc<2) {
		cout << "Input file not specified. Please, specify it as a first argument." << endl;
		cout << "example: " << argv[0] << " matr.txt" << endl;
		return -1;
	} 	
	ifstream file(argv[1]);
	ofstream output("output.txt");

	if (!file)
	{
		cout << "Error opening file" << endl;
		return -1;
	}

	int n;
	file >> n;			//size N
	if (argc>2) cout << "N=" << n << endl;

	Matrix A, B, C, D;	//host matrices
	A.el = new int[n*n];	//....	
	B.el = new int[n*n];	//...
	C.el = new int[n*n];	//..
	D.el = new int[n*n];	//.

	//reading from file into matrices
	for (int i=0; i<(n*n); i++)
		file >> A.el[i];
	for (int i=0; i<n*n; i++)
		file >> B.el[i];
	for (int i=0; i<n*n; i++)
		file >> C.el[i];

	//preparing for the device
	Matrix d_A;
	d_A.n=n;
	size_t size = n*n*sizeof(int);
	cudaMalloc(&d_A.el, size);		//allocate memory for A
	cudaMemcpy(d_A.el, A.el, size, cudaMemcpyHostToDevice);	//copy A to deviceA (d_A)
	
	Matrix d_B;
	d_B.n=n;
	cudaMalloc(&d_B.el, size);		//same for B
	cudaMemcpy(d_B.el, B.el, size, cudaMemcpyHostToDevice);

	Matrix d_C;
	d_C.n=n;
	cudaMalloc(&d_C.el, size);		//same for C
	cudaMemcpy(d_C.el, C.el, size, cudaMemcpyHostToDevice);

	Matrix d_D;				//resulting matrix D
	d_D.n=n;
	size = n*n*sizeof(int);
	cudaMalloc(&d_D.el, size);		//only allocate memory
	
	//kernel call
	dim3 dimBlock(n,n);	// USING ONE BLOCK
	dim3 dimGrid(1,1);	// WITH NxN THREADS
	calcD<<<dimGrid, dimBlock>>>(n, d_D, d_A, d_B, d_C);

	//read matrix E back
	cudaMemcpy(D.el, d_D.el, size, cudaMemcpyDeviceToHost);

	//write output to file
	output << "Matrix D:" << endl;
	for (int i=0; i<n; i++)	{
		for (int j=0; j<n; j++)	
			output << D.el[(i*n+j)] << " ";
		output << endl;
	}
	
	//print out resulting matrix D if second argument was present
	if (argc>2) {
		cout << endl << "Matrix D:" << endl;
		for (int i=0; i<n; i++)	{
			for (int j=0; j<n; j++)	
				cout << D.el[(i*n+j)] << " ";
			cout << endl;
		}
	}
	
	//free the memory on device
	cudaFree(d_A.el);
	cudaFree(d_B.el);
	cudaFree(d_C.el);
	cudaFree(d_D.el);
	//free the memory on host
	delete[] A.el;
	delete[] B.el;
	delete[] C.el;
	delete[] D.el;
	file.close();
	output.close();
	cout << endl << "Done. " << endl;
	return 0;
}