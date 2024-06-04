/*
 * Copyright (c) 2016, Stefan Lankes, RWTH Aachen University
 * All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0, <LICENSE-APACHE or
 * http://apache.org/licenses/LICENSE-2.0> or the MIT license <LICENSE-MIT or
 * http://opensource.org/licenses/MIT>, at your option. This file may not be
 * copied, modified, or distributed except according to those terms.
 */

#ifndef __hermit__
#define _GNU_SOURCE
#endif

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sched.h>
#include <pthread.h>
#ifndef __hermit__
#include <sys/syscall.h>

static inline long mygetpid(void)
{
	return syscall(__NR_getpid);
}
#else
static inline long mygetpid(void)
{
	return getpid();
}

int sched_yield(void);

#define PAGE_SIZE (4ULL*1024ULL)
#endif

#define N		10000000
#define M		(256+1)
#define BUFFSZ		(1ULL*1024ULL*1024ULL)

static char* buff[M];

#if 0
inline static unsigned long long rdtsc(void)
{
	unsigned long lo, hi;
	asm volatile ("lfence; rdtsc; lfence" : "=a"(lo), "=d"(hi) :: "memory");
	return ((unsigned long long) hi << 32ULL | (unsigned long long) lo);
}
#else
inline static unsigned long long rdtsc(void)
{
	unsigned int lo, hi;
	unsigned int id;

	asm volatile ("rdtscp; lfence" : "=a"(lo), "=c"(id), "=d"(hi));

	return ((unsigned long long)hi << 32ULL | (unsigned long long)lo);
}
#endif

static void* thread_func(void* arg)
{
	return (void*) rdtsc();
}

int main(int argc, char** argv)
{
	long i, j, ret;
	unsigned long long sum, start, end;
	const char str[] = "H";
	const size_t len = strlen(str);
	pthread_t thr_handle;

	printf("Determine systems performance\n");
	printf("=============================\n");

	// cache warm-up
	ret = mygetpid();
	ret = mygetpid();

	start = rdtsc();
	for(i=0; i<N; i++)
		ret = mygetpid();
	end = rdtsc();

	printf("Average time for getpid: %lld cycles, pid %ld\n", (end - start) / N, ret);

	// cache warm-up
	sched_yield();
	sched_yield();

	start = rdtsc();
	for(i=0; i<N; i++)
		sched_yield();
	end = rdtsc();

	printf("Average time for sched_yield: %lld cycles\n", (end - start) / N);

	sum = 0;
	start = rdtsc();
	for(i=0; i<10000; i++) {	
		pthread_create(&thr_handle, NULL, thread_func, NULL);
		sched_yield();
		pthread_join(thr_handle, (void**)&start);
	}
	end = rdtsc();

	printf("Average time to create a thread: %lld cycles\n", (end - start) / 10000);

#if 0
	write(2, (const void *)str, len);
	write(2, (const void *)str, len);
	start = rdtsc();
	for(i=0; i<N; i++)
		write(2, (const void *)str, len);
	end = rdtsc();

	printf("\nAverage time for write: %lld cycles\n", (end - start) / N);
#endif

	return 0;
}
