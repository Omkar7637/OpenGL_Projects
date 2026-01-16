#include <stdio.h>
#include <stdlib.h>

#define CL_TARGET_OPENCL_VERSION 200

// OpenCL headers
#include <CL/opencl.h>

int main(void)
{
	// function declarations
	void printOpenCLDeviceProperties(void);

	// code
	printOpenCLDeviceProperties();
}

void printOpenCLDeviceProperties(void)
{
	// code
	printf("OpenCL INFORMATION : \n");
	printf("======================================================================================================\n");

	cl_int result;
	cl_platform_id ocl_platform_id;
	cl_uint dev_count;
	cl_device_id* ocl_device_ids;
	char oclPlatformInfo[512];

	// get first platform ID
	result = clGetPlatformIDs(1, &ocl_platform_id, NULL);
	if (result != CL_SUCCESS)
	{
		printf("clGetPlatformIDs() Failed : %d\n", result);
		exit(EXIT_FAILURE);
	}

	// get GPU device count
	result = clGetDeviceIDs(ocl_platform_id, CL_DEVICE_TYPE_GPU, 0, NULL, &dev_count);
	if (result != CL_SUCCESS)
	{
		printf("clGetDeviceIDs() Failed : %d\n", result);
		exit(EXIT_FAILURE);
	}
	else if (dev_count == 0)
	{
		printf("There is no OpenCL Supported Device On This System\n");
		exit(EXIT_FAILURE);
	}
	else
	{
		// get platform name
		clGetPlatformInfo(ocl_platform_id, CL_PLATFORM_NAME, 500, &oclPlatformInfo, NULL);
		printf("OpenCL Supporting GPU Platform Name : %s\n", oclPlatformInfo);

		// get platform version
		clGetPlatformInfo(ocl_platform_id, CL_PLATFORM_VERSION, 500, &oclPlatformInfo, NULL);
		printf("OpenCL Supporting GPU Platform Version : %s\n", oclPlatformInfo);

		// print supporting device number
		printf("Total Number of OpenCL supporting GPU Device/Devices On This System : %d\n", dev_count);

		// allocate memory to hold those device ids
		ocl_device_ids = (cl_device_id*)malloc(sizeof(cl_device_id) * dev_count);

		// get ids into allocated buffer
		clGetDeviceIDs(ocl_platform_id, CL_DEVICE_TYPE_GPU, dev_count, ocl_device_ids, NULL);

		char ocl_dev_prop[1024];

		int i;
		for (i = 0; i < (int)dev_count; i++)
		{

		}

	}
}


