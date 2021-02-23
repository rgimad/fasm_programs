#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <vector>
#include "typedefs.h"

u32 copy_raw_data(FILE *pfin,FILE *pfout,u32 off,u32 len);
std::string load_string_by_offset(FILE *pfin,u32 stringtableoffset,u32 offset);
std::string load_pascal_string_by_offset(FILE *pfin,u32 stringtableoffset,u32 offset);
std::string check_string_by_offset(FILE *pfin,u32 stringtableoffset,u32 offset);
std::string check_pascal_string_by_offset(FILE *pfin,u32 stringtableoffset,u32 offset);
std::string make_string_8(const char *ps);

template<typename T> inline size_t load_data_value(T& data,FILE *pfin)
{
	return fread(&data,sizeof(T),1,pfin);
}
template<typename T> inline size_t check_data_value(T& data,FILE *pfin,u32 offset0,u32 offset)
{
	u32 off=ftell(pfin);
	fseek(pfin,offset0+offset,SEEK_SET);
	size_t sz=fread(&data,sizeof(T),1,pfin);
	fseek(pfin,off,SEEK_SET);
	return sz;
}
template<typename T> inline size_t save_data_value(const T& data,FILE *pfout)
{
	return fwrite(&data,sizeof(T),1,pfout);
}
template<typename T> inline size_t save_data_value(const T& data,std::vector<u8>& rc)
{
	const u8 *pd=reinterpret_cast<const u8*>(&data);
	rc.insert(rc.end(),pd,pd+sizeof(T));
	return sizeof(T);
}
template<> inline size_t save_data_value<std::string>(const std::string& data,std::vector<u8>& rc)
{
	const char *ps=data.c_str();
	rc.insert(rc.end(),ps,ps+data.size()+1);
	return data.size()+1;
}
template<typename T> inline size_t put_data_value(const T& data,std::vector<u8>::iterator& rc)
{
	const u8 *pd=reinterpret_cast<const u8*>(&data);
	std::copy(pd,pd+sizeof(T),rc);
	return sizeof(T);
}
inline u32 xtell(const std::vector<u8>& rc) {return static_cast<u32>(rc.size());}
inline u32 xtell(FILE *pf) {return static_cast<u32>(ftell(pf));}

inline u32 aligned4(u32 l) {return u32(l+3)&u32(~3);}

inline void align4(std::vector<u8>& rc) {rc.resize(aligned4(static_cast<u32>(rc.size())),0);}
