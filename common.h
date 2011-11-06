#ifndef _COMMON_H_
#define _COMMON_H_

char* calloc_string(char* d);

void destroy_string(char* p);

void recycle_garbage();

char* alloc_string(char* d);

char* grow_string(char* head, char* tail);

char* extract_variable(char* s);

char* extract_binary_expr(char* a, char* b, char* c);

char* extract_unary_expr(char* a, char* b);

char* extract_conditional_op(char* a, char* b, char* c);
#endif
