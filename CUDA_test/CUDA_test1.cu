// This test is the same as CUDA_test0 except it uses the higher level API in Thrust
// TODO: implement the lower level version

#include <iostream>
#include <algorithm>
#include "thrust/host_vector.h"
#include "thrust/device_vector.h"

#define ARR_SIZE 1000
#define BLOCK_SIZE 32;

__global__ void times_two(double* d_a, size_t N){
    auto idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < N) d_a[idx] *= 2;
}


// this function checks if the elements of two vectors are equal
template <typename T>
bool all_equal(typename thrust::host_vector<T>::iterator a_first,
               typename thrust::host_vector<T>::iterator a_last,
               typename thrust::host_vector<T>::iterator b_first){
    while (a_first != a_last){
        if (*a_first != *b_first){
            return false;
        }
        ++a_first;
        ++b_first;
    };
    return true;
};


using namespace std;
int main(){
    cout << "Testing a basic CUDA kernel" << endl;

    // allocate a vector that is equivalent to calling MATLAB 1:ARR_SIZE
    thrust::host_vector<double> h_a(ARR_SIZE,0);
    thrust::transform(h_a.begin(), h_a.end(), h_a.begin(), [](const double& a){
        static double counter = 0;
        return counter++;
    });

    // allocate memory on the GPU
    thrust::device_vector<double> d_a = h_a;

    // perform the double on the device in CUDA
    times_two<<<1, ARR_SIZE>>>(thrust::raw_pointer_cast(d_a.data()), d_a.size());

    // copy the result back to host
    thrust::host_vector<double> d_answer = d_a;

    // perform the doubling on the host side in C++
    for (auto &i:h_a)i*=2;

    // for (auto &i:h_a)cout << i << endl;

    // print the first value of both arrays
    cout << d_answer[1] << endl;
    cout << h_a[1] << endl;

    // make sure the GPU is done
    cudaDeviceSynchronize();

    // compare results
    if (all_equal<double>(h_a.begin(),h_a.end(),d_answer.begin()))cout << "CPU and GPU results are equal" << endl;
}