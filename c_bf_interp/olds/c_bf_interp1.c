#include <stdio.h>
#include <stdlib.h>

int mem_tape[30000];

int main()
{
    FILE *fp;
    char file_name[] = "hw_complex1.txt"; // "hw_complex1.txt";
    if (!(fp = fopen(file_name, "r")))
    {
        printf("[-] File %s was not found\n", file_name);
        exit(1);
    }
    fseek(fp, 0, SEEK_END);
    int file_size = ftell(fp);
    rewind(fp);
    printf("Size of %s = %d bytes\n", file_name, file_size);

    char *code = (char *)malloc(file_size + 1);
    int code_length;
    code_length = fread(code, 1, file_size, fp); // code_length = bytes read
    printf("code_length = %d\n", code_length);
    code[code_length] = '\0';
    printf("File contents:\n\n%s\n", code);

    int open_braces_cnt = 0;
    int i;
    for (i = 0; i < code_length; i++)
    {
        if (code[i] == '[')
        {
            open_braces_cnt++;
        }
    }
    printf("open_braces_cnt = %d\n", open_braces_cnt);
    int *stack = (int *)malloc((open_braces_cnt + 5)*4);
    int stack_top = -1; // empty

    int cmd_pos = 0;
    int cell_pos = 0;
    while (cmd_pos < code_length)
    {
        //printf("cmd_pos = %d  stack: %d %d %d\n", cmd_pos, stack[0], stack[1], stack[2]);
        switch (code[cmd_pos])
        {
        case '+':
            mem_tape[cell_pos]++;
            break;
        case '-':
            mem_tape[cell_pos]--;
            break;
        case '>':
            cell_pos++;
            break;
        case '<':
            cell_pos--;
            break;
        case '.':
            putchar(mem_tape[cell_pos]);
            break;
        case ',':
            mem_tape[cell_pos] = getchar();
            break;
        case '[':
            if (mem_tape[cell_pos])
            {
                //just push cmd_pos to stack
                stack[++stack_top] = cmd_pos;
                //printf("stack[stack_top] = %d\n", stack[stack_top]);
            } else
            {
                // skip current [...] block
                int balance = 0;
                for (i = cmd_pos; i < code_length; i++)
                {
                    if (code[i] == '[') balance++;
                    if (code[i] == ']')
                    {
                        balance--;
                        if (balance < 0) break;
                    }
                    if (balance == 0) break;
                }
                if (balance == 0)
                {
                    cmd_pos = i;//
                } else
                {
                    printf("Error: unbalanced braces");// on i ?
                }
            }
            break;
        case ']':
            // if mem_tape[cell_pos] != 0 then pop position from stack and assign it to cmd_pos and go to the beginning of while
            if (mem_tape[cell_pos])
            {
                // todo check if stack is empty
                int loop_beg = stack[stack_top];
                //printf("loop_beg = %d\n", loop_beg);
                cmd_pos = loop_beg;
            } else
            {
                //todo check if stack is empty
                stack_top--;
            }
            break;
        //default:
            //break;
            //
        }
        cmd_pos++;
    }

    fclose(fp);
    return 0;
}
