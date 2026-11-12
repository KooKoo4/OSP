bits 16
org 0x7c00
; Clearing of the CPU registers to zero.
xor ax, ax ; = 0
mov ds, ax ; = 0
mov es, ax ; = 0
mov ss, ax ; = 0
mov sp, 0x7c00 ; Sets the stack pointer to 0x7c00, we need the stack pointer to 0x7c00 or else the CPU will use the value of what is in sp(stack pointer) is in. 

; When the computer first boots up, the BIOS hands control over to your code 
; but the values left inside the segment registers (ds, es, ss) are unpredictable and depend entirely on the specific BIOS firmware.
; If you leave junk values in these registers, any attempt to read a variable (which relies on ds) or use the stack (which relies on ss) will
; point to a completely wrong, random place in memory.
; Clearing them to 0 establishes a clean, predictable baseline where your segment base is 0x0000
; meaning your offsets directly map to the lowest physical memory addresses.


 ; Reset disk system (Drive number is passed in DL by BIOS)
 ; Tells the motherboard's disk controller to reset and calibrate the boot drive.
 ; The BIOS passes the boot drive ID to your program inside the dl register. 
 ; By calling this interrupt(int 0x13) immediately, you ensure the drive controller is cleared of any spin-up errors and is 100% ready to copy your operating system files into RAM.
 
    mov ah, 0   
    int 0x13

 ; Right after this exact sequence, a bootloader typically uses Function 0x02 of int 0x13 to actually read the operating system sectors from the disk into memory

	mov ah, 0x02 ; function 2, means read sectors from drive
	mov al, 1 ; number of sectors to read
	mov ch, 0 ; cylinder number
	;mov dh, 0 ; head number
	mov cl, 2 ; sector number - 2 because it is defaulted to 1, which is the bootloader itself. 
	          ; So to read another sector we add sector + 1 or n(Anyvalue within range).
	          ; if you confused the cl and al,  sector number 2 and the number of sectors to read. It just means that;
	          ; 1 = how much we want to read (In this case, one only) and sector number is which part of the sector we'll read, (THis case above the bootloader).
	mov dh, 0
	mov dl, 0x80
	mov bx, 0x7e00 ; because ES:BX where ES is zero (Because of mov ex, ax where ax is zero) and bx is the offset.
				   ; so Physical address = segment(es, which is 0x0000) * 16 + Offset(bx, which is 0x7e00). So 0 * 16 = 0 + 0x7e00 = 0x7e00, no carry one.
	int 0x13       ; Call BIOS
	jc disk_read_error ;in case if there is no carry flag and it errors.

 ; Jump out of 0x7C00 and into 0x7E00
     jmp 0x0000:0x7e00 ;- we could jump to the 0x7e00 sector or just read what i've put inside 0x7e00 (Which is "T"). 
					; jmp 

					; read
    ;mov ah, 0x0e
    ;mov al, [0x7e00]
   ; int 0x10
   ; cli
   ; hlt


disk_read_error:
 mov ah, 0x0E
    mov al, 'E'
    int 0x10
    cli
    hlt

    ; Fill the rest of the 512-byte boot sector
    times 510-($-$$) db 0
    dw 0xAA55 ; boot signature the bios looks for. 
    ; Sector 2 - fills the entire second sector with T's
;times 512 db 'T' ; True(T)

; We now have 1 Megabyte(MB) of storage!! (P.S: Still not enough!!)






	









 
