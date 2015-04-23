    .data
    .globl filename
filename: .asciiz "input.txt"
    .data 0x10010000
    .globl buffer
buffer: .space 1024 
    .globl hoursAddress
hoursAddress: .space 1024
    .globl gradesAddress
gradesAddress: .space 1024
    .globl errorMess
errorMess: .asciiz "Error encountered in input, exiting"

# citation: http://stackoverflow.com/questions/4147952/reading-files-with-mips-assembly
    .text
    .globl main
main:
    li $v0, 13 # syscall 13 is open file
    la $a0, filename # $a0 holds the input file name
    li $a1, 0 # $a1 is 0 for read, 1 for write 
    li $a2, 0 # $a2 is unused
    syscall

    move $s0, $v0 # syscall 13 puts the file descriptor in $v0, this saves it in $s0

    li $v0, 14 # syscall 14 is read from file
    move $a0, $s0 # syscall 14 gets the file descriptor from $a0
    la $a1, buffer # syscall 14 uses $a1 as the address of the input buffer
    la $a2, 1024 # syscall 14 uses $a2 as the maximum number of characters to read
    syscall
    
    li $v0, 16 # syscall 16 is close file
    move $a0, $s0 # move the file descriptor to $a0 again
    syscall

parseFile:
    li $s3, 0 # initialize the character counter to 0
    lb $t0, buffer($t1) # load the first input byte to $t0
    beq $t0, 49, parseOption1 # 1 is 49 in ASCII, jump to option 1
    beq $t0, 50, parseOption2 # 2 is 50 in ASCII, jump to option 2
    beq $t0, 51, parseOption3 # 3 is 51 in ASCII, jump to option 3
    j exitError

parseOption1:
    li $s7, 1 # remember that the chosen option is 1
    li $t1, 3 # fourth character
    lb $t2, buffer($t1) # load the fourth character
    beq $t2, 10, singleDigit # fourth character is a line ending, so the number of classes only has 1 digit
    j doubleDigit # otherwise, assume that it's a 2-digit number of classes

singleDigit:
    li $t1, 2 # third character in the file (assuming second is LF)
    lb $t2, buffer($t1) # load the third character (only digit in the number of classes) to $t2
    li $t3, 0 # initialize the count to 0
    li $t4, 1 # digit is in the ones-column
    jal asciiToInteger # add the digit to the class count sum
    
    move $s7, $t3 # set the permanent register for the number of classes
    li $s3, 4 # first line of classes starts at character 5
    j parseClasses

doubleDigit:
    li $t1, 2 # third character in the file (assuming second is LF)
    lb $t2, buffer($t1) # load the third character (first digit in the number of classes) to $t2 
    li $t3, 0 # initialize the count to 0
    li $t4, 10 # first digit is in the tens-column
    jal asciiToInteger # add the digit to the class count sum
    
    li $t1, 3 # fourth character in the file
    lb $t2, buffer($t1) # load the fourth character (second digit in the number of classes) to $t2
    jal asciiToInteger # add the digit to the class count sum
    
    move $s7, $t3 # set the permanent register for the number of classes
    li $s3, 5 # first line of classes starts at character 6
    j parseClasses

parseClasses:
    li $t6, 0 # number of classes, counting upwards (for memory write purposes)
    li $t1, s7 # copy the number of classes

readLoop:
    ble $t1, 0, nextStep # if there are no more classes remaining, leave the loop
    lb $t2, buffer($s3) # load the credit hours (first character of the line) to $t2
    li $t3, 0 # initialize the count to 0
    li $t4, 1 # assuming credit hours are always 1 digit
    jal asciiToInteger # translate the credit hours to a number
    sw $t3, hoursAddress($t6) # write the credit hours to memory

    addi $s3, $s3, 2 # move to the grade received (skip past the comma)
    lb $t2, buffer($s3) # load the grade received (third character of the line) to $t2
    li $t3, 0 # initialize the count to 0
    li $t4, 1 # assuming grades are always 1 digit
    jal asciiToInteger # translate the grade to a number
    sw $t3, gradesAddress($t6) # write the grade to memory
    
    addi $s3, $s3, 2 # go to the next line
    addi $t6, $t6, 1 # increment the class count
    subi $t1, $t1, 1 # decrement the number of classes
    j readLoop

parseOption2:
    li $s7, 2 # remember that the chosen option is 2

parseOption3:
    li $s7, 3 # remember that the chosen option is 3
    
    j exit

nextStep:
    j exit

# overwrites $t5
# assumes that it was called by a jal, that $t2 contains the ASCII of the next digit to be converted, $t3 contains the running sum, and $t4 contains the exponent of this multiplication
# divides $t4 by 10
asciiToInteger:
    mulu $t5, $t4, 10
    beq $t2, 48, ascii0
    beq $t2, 49, ascii1
    beq $t2, 50, ascii2
    beq $t2, 51, ascii3
    beq $t2, 52, ascii4
    beq $t2, 53, ascii5
    beq $t2, 54, ascii6
    beq $t2, 55, ascii7
    beq $t2, 56, ascii8
    beq $t2, 57, ascii9

ascii0:
    j cleanupAddition

ascii1:
    add $t3, $t3, $t5 # add exponent to the sum
    j cleanupAddition

ascii2:
    mulu $t5, $t5, 2 # multiply exponent by 2
    add $t3, $t3, $t5 # add exponent to sum

ascii3:
    mulu $t5, $t5, 3 # multiply exponent by 3
    add $t3, $t3, $t5 # add exponent to sum

ascii4:
    mulu $t5, $t5, 4 # multiply exponent by 4
    add $t3, $t3, $t5 # add exponent to sum

ascii5:
    mulu $t5, $t5, 5 # multiply exponent by 5
    add $t3, $t3, $t5 # add exponent to sum

ascii6:
    mulu $t5, $t5, 6 # multiply exponent by 6
    add $t3, $t3, $t5 # add exponent to sum

ascii7:
    mulu $t5, $t5, 7 # multiply exponent by 7
    add $t3, $t3, $t5 # add exponent to sum

ascii8:
    mulu $t5, $t5, 8 # multiply exponent by 8
    add $t3, $t3, $t5 # add exponent to sum

ascii9:
    mulu $t5, $t5, 9 # multiply exponent by 9
    add $t3, $t3, $t5 # add exponent to sum

cleanupAddition:
    div $t4, $t4, 10
    jr $ra

# this is just for debugging (for now)
printSomething:
    li $t1, 0 # offset for loading
    lb $t0, buffer($t1) # load the first input byte to $t0

    li $v0, 11
    move $a0, $t0
    syscall

    li $t1, 1
    lb $t0, buffer($t1)
    li $v0, 1
    move $a0, $t0
    syscall

    li $t1, 2
    lb $t0, buffer($t1)
    li $v0, 1
    move $a0, $t0
    syscall

    li $t1, 3
    lb $t0, buffer($t1)
    li $v0, 1
    move $a0, $t0
    syscall

    li $t1, 4
    lb $t0, buffer($t1)
    li $v0, 1
    move $a0, $t0
    syscall
    j exit

exitError:
    li $v0, 55 # syscall 55 is message dialog
    la $a0, errorMess # $a0 is the address for printing
    li $a1, 0 # $a1 is an option for message type, 0 is error
    syscall
    j exit

exit:
    li $v0, 10
    syscall
