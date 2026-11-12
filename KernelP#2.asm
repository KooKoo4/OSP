;----------------------- BUG EXPLANATION ----------------------------------------------bits 16
org 0x7e00

;------------------SWITCH AND CALL TO 32-BIT PROTECTED MODE---------------------------
;----------------------- BUG EXPLANATION ----------------------------------------------
enter_protected_mode: ;note: last time 11-9-2026, you put this code after the GDT'S, it made the KERNEL not work. After some few debugging, this line below must be first.
					  ;Don't worry about the rest of the code not being activated, my guess is; the "jmp CODE_SEG:start_protected_mode" call the GDT'S code below. 
					  ;This automatically activates all the GDT code below that we have just wrote.

	mov ax, 0x2401 ; BIOS function to enable A20  
	int 0x15 ; Call BIO SYSTEM SERVICE


	cli ;clears all the interrupts
	lgdt [GDT_descriptor] ;call the GDT
	;The switch to protected mode
	mov eax, cr0
	or eax, 1
	mov cr0, eax
	;The switch to protected mode
	
	jmp CODE_SEG:start_protected_mode ;FAR JUMP
;----------------------- BUG EXPLANATION ----------------------------------------------






; Build the GDT(The Global Descriptor Table)

; Descriptors - Describe the properties of a segments (Using a "list")
; We will use memory models flat memory model - instead of using traditional segmentation to manage memory
; the system treats memory as a single, contiguous address space.
; By setting the base to 0 and the limit to the maximum possible size
; the OS essentially bypasses the complexities of segmented memory, allowing the entire range of available memory to be addressed uniformly 

;GDT must contain code segment(cs) and data segment(ds)
;CODE SEGMENTS - Define the location(Base  and limit) and size of our segment()
;Base - the starting points, must be 0, base = location.
;Limit - maximum limit, must be the maximum value 20 bits can hold(0xffff), Limit = size.

; Next properties is called Present, Privilege, and Type.
; Present - is a single bit and if the segments is used it should be 1(Binary, or 0 if not used).
; Privilege - a two bit value from 0 to 3(00 | 01 | 10| 11) - used to define segment hiearchy
; hiearchy means the computer hiearchy, we all know this as "Ring0", or "User mode", levels of the computer. Usually we are at 3(lowest).
; Type - another single bit, 1 if code segment OR data segments.

; The other properties is flag
; Flag - is a single bit that represents boolean property(True or False). 1 for True and 0 for False\
; sets of flags
; Type flags(4 bits) 
; Other flags (4 bits)

; How to do the Type flags:
; Type flags has 4 bits we can put value in, he first boolean property is: "Will this segment contain code? if yes, 1, if no, 0."
; Type flags:  1___
; Conforming: "Can this code be executed by lower privilege segments? if no, 0, if yes, 1" We put 0, this ensures that only at the highest level(Ring 0) can execute this and not User-level (Ring 3)
;Type flags: 10__
; Readable?: "Can this segment be read, or is it only executable? if 1 we would be able to read constants defined in our code, if 0 then inverse of what I just said".
;Types flags: 101_
; Accessed: Managed by the CPU: 0 - This bit is used by the CPU, it is set to one if when it is using the segment. Set it to 0 and let the CPU do its thing.
;Type flags: 1010
; Further explanation of the Accessed: The Accessed bit is a flag used by the CPU to track if a specific memory segment has been used.
; Initial State (0):  When you define the segment in the GDT, you typically initialize the Accessed bit to 0. This signals to the CPU that the segment has not yet been used.
; CPU Behavior (1): Once the CPU loads the segment into a segment register and begins accessing memory through that segment, it will automatically flip this bit from 0 to 1.
;Think of the Accessed bit as a "Used" sticker that the CPU places on a file folder:

;You (The Programmer): You set the bit to 0 when you first create the segment in the GDT. This is like putting a clean, empty folder into a cabinet.
;The CPU (The Processor): The CPU acts like an automated clerk. The moment it actually opens that folder to read or execute code
; it automatically swaps the 0 for a 1. You don't have to touch it; the hardware handles that update itself.

; OTHER FLAGS
; Granularity - when this bit is set to 1, the limit is multiplied by hex 0x1000 so we can span a whole four gigabytes of memory (4096MB)
;Other flags:  1___
;"Is this flag going to use 32 bit memory?", yes, we set to 1, we want that 4GB!!
;Other flags: 11__
; We won't use the last two bits, so we set it two 0. This is because these are reserved for a more specific purposes that are not required for the simple flat memory model that we are using.
;Other flags: 1100

; DATA SEGMENT
; the data segment is similar, we only need to change a few flags
; pres, priv, type = 1001
; Type flags = 0010, second bit is not "conforming" but "direction" now, meaning "Should this segment grows downwards?". And the "readable" becomes "Writables", it asks "Can data be written to this segments?"
; Other flags = 1100

; In order to define the gdt in assembly we need to define each of these properties in a certain order: To do this we can use the db(Define Byte), dw(Define Word)(Defines 2 bytes), dd(defines double words)(Defines 4 bytes).
;------THE GDT CODE------------
GDT_start: ; Beginning of our GDT
	null_terminator: ; At the beginning of every GDT, there must be an empty descriptor
	dd 0x0, 0x0 ; four times 00000000
	;dd 0x00 ; four times 00000000
	code_descriptor: ; The labels of code_descriptor and data_descriptor will be calculated later for the offset of the segment descriptor(code_descriptor and data_descriptor) relative to the beginning of the GDT(GDT_start)
	;define the first 16 bits of the limit
	dw 0xffff
	;next, define the first 24 bits of the base
	dw 0 ; 16 bits  
	db 0 ; 8 bits
	; 16 bits + 8 bits = 24
	;define the present, privilege, and type flags
	db 10011010b ;put "b" at the end to let the assembler know it is a binary
	; then define the other flags
	db 11001111b ; where did the "1111" came from? the 1111 came from the limit(0xffff), other flags + limit. So 1100(Other flags) + 1111(Limits) = 11001111
	; define last eight bits of the base
	db 0 ; 24 bits + 8 bits = 32 bits
	; Do the same for data_descriptor
	data_descriptor:
	dw 0xffff
	dw 0
	db 0
	db 10010010b
	db 11001111b
	db 0
	;The GDT is defined, so we can write a GDT end label
	GDT_end:
    ; we are not over yet, we still need to define a GDT descriptor.

	GDT_descriptor:
	;We have two entries, first is being the size of the GDT
	dw GDT_end - GDT_start - 1 ; size
	; and a pointer to the beginning of GDT
	dd GDT_start			   ; start

	CODE_SEG equ code_descriptor - GDT_start
	DATA_SEG equ data_descriptor - GDT_start ; "equ" is used to set values as constants

	;We are now ready to swtich to 32 bit protected mode, hooray!


;-------11/10/2026-------- A BUG!!!! Explanation above!!

	;first of all, we need to clear all interruptions
;	cli ;[off for now]
	; then we load the GDT
;	lgdt [GDT_descriptor] ;lgdt calls the GDT [off for now]
	; to do the switch, we need to change the last bit of the a special 32-bit register called cr0 to 1.
	; we cannot change the value of this register directly, so we need to use a 32-bit General Purpose register to indirectly change cr0.(GENERAL PURPOSE REGISTERS: EAX, EBX, ECX, EDX - "E" stands for "Extendex")
;	mov eax, cr0 ; move cr0 to eax [off for now]
;	or eax, 1 ; changes the last bit to 1 [off for now]
;	mov cr0, eax ; put it back to cr0 [off for now]

	; We are now in 32-bit protected mode!!!!
		; now do a far jump (jump to another segment)
		;jmp 0x08:start_protected_mode

;-------11/10/2026-------- A BUG!!!! Explanation above!!
		

			bits 32 ; since are now in 32 bits, write [bits 32] beforet the label.
		start_protected_mode:

	
		;print something to check if we are actually in 32-bit mode
		; We don't have bios anymore, we use VideoMemory = 0xb8000
		; VideoMemory = 0xb8000
		;first byte = character
		;Second byte = Color
		mov al, 72	;character [off for now]
		mov ah, 0x0a ;white on black(color) [off for now]
  		mov word [0xb8000], ax ; move ax to the beginning of video memory. [off for now]
  		mov al, 69
  		add al, 32
  		mov ax, 0x0a
  		mov word [0xb8002], ax
  	

		
		hlt

	; mov ax, 0x10    ; Load data segment selector
   ; mov ds, ax
   ; mov es, ax
    ;mov ss, ax
   ; mov esp, 0x90000 ; Setup stack pointer

    ; Print "32" in green text straight to video memory
    ;mov word [0xB8000], 0x0A33  ; 0x0A = Green text, 0x33 = ASCII '3'
    ;mov word [0xB8002], 0x0A32  ; 0x0A = Green text, 0x32 = ASCII '2'

    ;hlt

		;Now cat the previous file (BootP#5.bin) and this kernel > OSP#2.bin (Operating System Practice)
	
	
	
	

	

	
    

    
	
	
	
	













