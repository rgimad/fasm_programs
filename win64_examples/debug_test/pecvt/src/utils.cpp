/*
	  Program add symbolic debug information in Microsoft-CodeView format into
	object file produced by fasm.
	Author Sergey Choomak.
	Released 15.02.2009.
	Free to use and modify.
*/
#include "utils.h"

u32 copy_raw_data(FILE *pfin,FILE *pfout,u32 off,u32 len)
{
	size_t lenm=len;
	const size_t BUFLEN=1024;
	char buf[BUFLEN];
	fseek(pfin,off,SEEK_SET);
	while(!feof(pfin)&&lenm)
	{
		size_t sz=(lenm>BUFLEN)?BUFLEN:lenm;
		sz=fread(buf,1,sz,pfin);
		if(!sz)
		{
			printf("read problem\n");throw 7;
		}
		fwrite(buf,1,sz,pfout);
		lenm-=sz;
	}
	return len;
}

std::string load_string_by_offset(FILE *pfin,u32 stringtableoffset,u32 offset)
{
	fseek(pfin,stringtableoffset+offset,SEEK_SET);
	std::string rc;
	while(!feof(pfin))
	{
		int ch=fgetc(pfin);
		if(!ch) break;
		rc.push_back(char(ch));
	}
	return rc;
}
std::string load_pascal_string_by_offset(FILE *pfin,u32 stringtableoffset,u32 offset)
{
	fseek(pfin,stringtableoffset+offset,SEEK_SET);
	int len=fgetc(pfin);if(!len) return std::string();
	std::string rc(len,char('\0'));
	fread(&*rc.begin(),1,len,pfin);
	return rc;
}

std::string check_string_by_offset(FILE *pfin,u32 stringtableoffset,u32 offset)
{
	u32 ok=ftell(pfin);
	std::string rc=load_string_by_offset(pfin,stringtableoffset,offset);
	fseek(pfin,ok,SEEK_SET);
	return rc;
}
std::string check_pascal_string_by_offset(FILE *pfin,u32 stringtableoffset,u32 offset)
{
	u32 ok=ftell(pfin);
	std::string rc=load_pascal_string_by_offset(pfin,stringtableoffset,offset);
	fseek(pfin,ok,SEEK_SET);
	return rc;
}

std::string make_string_8(const char *ps)
{
	return std::string(ps,ps+8).c_str();
}
