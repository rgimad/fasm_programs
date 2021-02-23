#pragma once
#include "utils.h"
#pragma pack(push)
#pragma pack(1)

namespace obj_win32
{
	struct obj_header
	{
		u16 Machine;// machine type
		u16 NumberOfSections;
		u32 TimeDateStamp;
		u32 PointerToSymbolTable;
		u32 NumberOfSymbols;
		u16 SizeOfOptionalHeader;
		u16 Characteristics;// flags
	};
	struct section_header
	{
		char Name[8];
		u32 VirtualSize;
		u32 VirtualAddress;
		u32 SizeOfRawData;
		u32 PointerToRawData;
		u32 PointerToRelocations;
		u32 PointerToLinenumbers;
		u16 NumberOfRelocations;
		u16 NumberOfLinenumbers;
		u32 Characteristics;// flags
	};
	struct relocation_item
	{
		u32 VirtualAddress;
		u32 SymbolTableIndex;
		u16 Type;
		void set_as_secrel();
		void set_as_section();
	};
	struct symbol_table_item
	{
		union
		{
			struct 
			{
				union
				{
					char Name[8];
					struct {u32 zeroes,Offset;};
				};
				u32 Value;
				u16 SectionNumber;
				u16 Type;
				u8 StorageClass;
				u8 NumberOfAuxSymbols;
			};
			u8 bindata[18];
		};
	};

	struct section_t
	{
		section_header objpart;
		std::string name;
		std::vector<relocation_item> relocations;// used only for prepared debug sections
		u32 symbol_index;// index of section name in symbol table
		// offsets for section data in original obj file
		u32 fullsectionoffset;
		u32 initPointerToRawData    ;
		u32 initPointerToRelocations;
		u32 initPointerToLinenumbers;
		void set_name(std::string s);
		void init(u32 flags);
		void save_init_pointers();
		void update_pointers(u32 add);
		//void update_pointers(u32 off0,u32 add);
		bool iscode() const;
	};
	void init_as_debug(section_t& s,std::string n);
	struct symbol_t
	{
		symbol_table_item objpart;
		std::string name;
		void set_name(std::string s);
		void set_as_local_code(std::string name,u32 section,u32 offset);
		void set_as_local_data(std::string name,u32 section,u32 offset);
	};

	// in memory realization
	class object
	{
		u16 initNumberOfSections;
		u32 initPointerToSymbolTable;
		u32 initNumberOfSymbols;
		u32 initstringtableoffset,initstringtablelen;
		FILE *pfin;
	public:
		int prepare_obj_header();
		object(bool v,FILE *pf) : verbose(v),pfin(pf) {}
		bool verbose;
		obj_header head;
		std::vector<section_t> sections;
		std::vector<symbol_t> symbols;
		std::pair<u32,u32> input_unchanged_head,input_unchanged_section_body;
		void load_obj();
		//bool save_obj(FILE *pfin);
		section_t& get_debugT() {return *(sections.end()-2);}
		section_t& get_debugS() {return *(sections.end()-1);}
		u32 debugT_id() const {return head.NumberOfSections-1;}
		u32 debugS_id() const {return head.NumberOfSections;}
		std::vector<obj_win32::section_t>::iterator siE;

		void save_obj(FILE *pfout,
			u8 *p_raw_debugS,u32 sizeS,
			u8 *p_rel_debugS,u32 size_relS);
	};

}
#pragma pack(pop)
