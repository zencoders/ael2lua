#ifndef _COMMON_H_
#define _COMMON_H_

char* calloc_string(char* d);

void destroy_string(char* p);

void recycle_garbage();

char* alloc_string(char* d);

char* grow_string(char* head, char* tail);

char* extract_variable(char* s);
#endif
