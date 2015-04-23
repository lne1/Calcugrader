    .data
    .globl filename
filename: .asciiz "input.txt"
    .data 0x10010000
    .globl buffer
buffer: .space 1024 
    .globl option1Output
option1Output: .asciiz "Your GPA is: "
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
    lb $t0, buffer($t1) # load the first input byte to $t0
    beq $t0, 49, parseOption1 # 1 is 49 in ASCII, jump to option 1
    beq $t0, 50, parseOption2 # 2 is 50 in ASCII, jump to option 2
    beq $t0, 51, parseOption3 # 3 is 51 in ASCII, jump to option 3
    j exitError

parseOption1:
    li $s7, 1 # remember that the chosen option is 1
    li $s1, 0 # initialize the credit hours sum to 0
    li $s2, 0 # initialize the grade points sum to 0
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
    move $t1, $s7 # copy the number of classes

readLoop:
    ble $t1, 0, option1Calculation # if there are no more classes remaining, leave the loop
    lb $t2, buffer($s3) # load the credit hours (first character of the line) to $t2
    li $t3, 0 # initialize the count to 0
    li $t4, 1 # assuming credit hours are always 1 digit
    jal asciiToInteger # translate the credit hours to a number
    add $s1, $s1, $t3 # add the credit hours to the running sum
    move $t9, $t3 # copy the credit hours

    addi $s3, $s3, 2 # move to the grade received (skip past the comma)
    lb $t2, buffer($s3) # load the grade received (third character of the line) to $t2
    li $t3, 0 # initialize the count to 0
    li $t4, 1 # assuming grades are always 1 digit
    jal asciiToInteger # translate the grade to a number
    mulu $t3, $t3, $t9 # multiply the grade points by the credit hours
    add $s2, $s2, $t3 # add the grade points to the running sum
    
    addi $s3, $s3, 2 # go to the next line
    subi $t1, $t1, 1 # decrement the number of classes
    j readLoop

option1Calculation:
    sw   $s1, -88($fp) # these 3 lines convert the credit hours number to float register $f7
    lwc1 $f6, -88($fp)
    cvt.s.w $f7, $f6

    sw   $s2, -88($fp) # these 3 lines convert the grade points number to float register $f9
    lwc1 $f8, -88($fp)
    cvt.s.w $f9, $f8

    div.s $f12, $f9, $f7 # GPA = grade points / credit hours
    li $v0, 57 # syscall 57 is message dialog float
    la $a0, option1Output
    syscall

parseOption2:
    li $s3, 3 # fourth character
    li $s7, 2 # remember that the chosen option is 2
    lb $t2, buffer($s3) # load the first digit of the GPA (first character of the line) to $t2
    #li $f3, 0 # initialize the count to 0
    #li $f4, 1 # first digit is in the ones-column
    #jal asciiToFloat # translate the first digit to a number
    
    

parseOption3:
    li $s7, 3 # remember that the chosen option is 3
    
    j exit

nextStep:
    j exit

# overwrites $t5
# assumes that it was called by a jal, that $t2 contains the ASCII of the next digit to be converted, $t3 contains the running sum, and $t4 contains the exponent of this multiplication
# divides $t4 by 10
asciiToInteger:
    move $t5, $t4
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
    j cleanupAddition

ascii3:
    mulu $t5, $t5, 3 # multiply exponent by 3
    add $t3, $t3, $t5 # add exponent to sum
    j cleanupAddition

ascii4:
    mulu $t5, $t5, 4 # multiply exponent by 4
    add $t3, $t3, $t5 # add exponent to sum
    j cleanupAddition

ascii5:
    mulu $t5, $t5, 5 # multiply exponent by 5
    add $t3, $t3, $t5 # add exponent to sum
    j cleanupAddition

ascii6:
    mulu $t5, $t5, 6 # multiply exponent by 6
    add $t3, $t3, $t5 # add exponent to sum
    j cleanupAddition

ascii7:
    mulu $t5, $t5, 7 # multiply exponent by 7
    add $t3, $t3, $t5 # add exponent to sum
    j cleanupAddition

ascii8:
    mulu $t5, $t5, 8 # multiply exponent by 8
    add $t3, $t3, $t5 # add exponent to sum
    j cleanupAddition

ascii9:
    mulu $t5, $t5, 9 # multiply exponent by 9
    add $t3, $t3, $t5 # add exponent to sum
    j cleanupAddition

cleanupAddition:
    div $t4, $t4, 10
    jr $ra

# overwrites $f5
# assumes that it was called by a jal, that $t2 contains the ASCII of the next digit to be converted, $f3 contains the running sum, and $f4 contains the exponent of this multiplication
# divides $f4 by 10
#asciiToFloat:
#    mulu $f5, $f4, 10
#    beq $t2, 48, asciiFloat0
#    beq $t2, 49, asciiFloat1
#    beq $t2, 50, asciiFloat2
#    beq $t2, 51, asciiFloat3
#    beq $t2, 52, asciiFloat4
#    beq $t2, 53, asciiFloat5
#    beq $t2, 54, asciiFloat6
#    beq $t2, 55, asciiFloat7
#    beq $t2, 56, asciiFloat8
#    beq $t2, 57, asciiFloat9

#asciiFloat0:
#    j cleanupFloatAddition

#asciiFloat1:
#    add $f3, $f3, $f5 # add exponent to the sum
#    j cleanupFloatAddition

#asciiFloat2:
#    mulu $f5, $f5, 2 # multiply exponent by 2
#    add $f3, $f3, $f5 # add exponent to sum
#    j cleanupFloatAddition

#asciiFloat3:
#    mulu $f5, $f5, 3 # multiply exponent by 3
#    add $f3, $f3, $f5 # add exponent to sum
#    j cleanupFloatAddition

#asciiFloat4:
#    mulu $f5, $f5, 4 # multiply exponent by 4
#    add $f3, $f3, $f5 # add exponent to sum
#    j cleanupFloatAddition

#asciiFloat5:
#    mulu $f5, $f5, 5 # multiply exponent by 5
#    add $f3, $f3, $t5 # add exponent to sum
#    j cleanupFloatAddition

#asciiFloat6:
#    mulu $f5, $f5, 6 # multiply exponent by 6
#    add $f3, $f3, $f5 # add exponent to sum
#    j cleanupFloatAddition

#asciiFloat7:
#    mulu $f5, $f5, 7 # multiply exponent by 7
#    add $f3, $f3, $f5 # add exponent to sum
#    j cleanupFloatAddition

#asciiFloat8:
#    mulu $f5, $f5, 8 # multiply exponent by 8
#    add $f3, $f3, $f5 # add exponent to sum
#    j cleanupFloatAddition

#asciiFloat9:
#    mulu $f5, $f5, 9 # multiply exponent by 9
#    add $f3, $f3, $f5 # add exponent to sum
#    j cleanupFloatAddition

#cleanupFloatAddition:
#    div $f4, $f4, 10
#    jr $ra

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
