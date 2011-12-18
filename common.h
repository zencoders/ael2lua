#ifndef _COMMON_H_
#define _COMMON_H_

/**
 * Method used to dynamically allocate a string.
 * @param d The string to allocate
 * @return the new pointer for the string
**/
char* calloc_string(char* d);

/**
 * Method used to destroy a dinamically allocated string previously archived
 * @param p The string to delete
**/
void destroy_string(char* p);

/**
 * Method used to clean the archive containing all strings dinamically allocated
**/
void recycle_garbage();

/**
 * Method used to dinamically allocate a string and store it inside temporary archive
 * @param d The string to allocate
 * @return a char pointer to the beginning od the newly allocated string
**/
char* alloc_string(char* d);

/**
 * Method used to concatenate two strings
 * @param head The beginning sting
 * @param tail The end string
 * @return a char pointer to the beginning od the newly allocated string
**/
char* grow_string(char* head, char* tail);

/**
 * Method used to extract the variable's name from the variable in string passed
 * @param s The string containing the variable
 * @return the variable's name extracted
**/
char* extract_variable(char* s);

/**
 * Method used to extract a binary expression from components
 * @param a The left size of the expression
 * @param b The symbol
 * @param c The right part of the expression
 * @return The newly created exception
**/
char* extract_binary_expr(char* a, char* b, char* c);

/**
 * Method used to extract a unary expression from components
 * @param a The symbol
 * @param b The right part of the expression
 * @return The newly created exception
**/
char* extract_unary_expr(char* a, char* b);

/**
 * Method used to extract a condition expression from components
 * @param a The left size of the expression
 * @param b The symbol
 * @param c The right part of the expression
 * @return The newly created exception
**/
char* extract_conditional_op(char* a, char* b, char* c);
#endif
