
# run in QTSpim

        .text
main:
        # setup
        li $t1, 1
        li $t3, 3
        li $t4, 0

        # program
loop:
        add $t4, $t4, $t1
        bne $t4, $t3, loop



        # return to caller
        jr $ra
