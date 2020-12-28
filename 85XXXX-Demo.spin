{
    --------------------------------------------
    Filename: 85XXXX-Demo.spin
    Author: Jesse Burt
    Description: Demo of the 85XXXX FRAM driver
    Copyright (c) 2020
    Started Sep 10, 2020
    Updated Dec 28 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_HZ      = 1_000_000
    ADDR_BITS   = %000
    READCNT     = 64
    MEM_SIZE    = 256                           ' kbits (256, 512, 1024, etc)
' --

    STATUS_LINE = 10
    CLK_FREQ    = (_clkmode >> 6) * _xinfreq    ' derive clock frequency
    CYCLES_USEC = CLK_FREQ / 1_000_000          ' cycles in 1 microsecond

    MEM_END     = (MEM_SIZE * 1024) / 8         ' last address of device
    ERASED_CELL = $00

OBJ

    ser         : "com.serial.terminal.ansi"
    cfg         : "core.con.boardcfg.flip"
    time        : "time"
    mem         : "memory.fram.85xxxx.i2c"

VAR

    byte _buff[READCNT+1]

PUB Main{} | mem_base

    setup{}

    mem_base := 0
    repeat
        readtest(mem_base)

        ser.hexdump(@_buff, mem_base, READCNT, 16, 0, 5)
        ser.newline{}

        case ser.charin{}
            "[":
                mem_base := (mem_base - READCNT) #> 0
            "]":
                mem_base := (mem_base + READCNT) <# (MEM_END-READCNT)
            "s":
                mem_base := 0
            "e":
                mem_base := MEM_END-READCNT
            "w":
                writetest(mem_base)
            "x":
                erasetest(mem_base)
            "q":
                ser.strln(string("Halting"))
                quit
            other:

    repeat

PUB EraseTest(start_addr) | stime, etime
' Erase a page of memory
    bytefill(@_buff, ERASED_CELL, READCNT)      ' fill temp buff with $00
    ser.position(0, STATUS_LINE+2)
    ser.str(string("Erasing page..."))
    stime := cnt
    mem.writebytes(start_addr, READCNT, @_buff) ' write temp buff to memory
    etime := cnt-stime

    cycletime(etime)                            ' report cycle time, in usec

PUB ReadTest(start_addr) | stime, etime
' Read a page of memory
    bytefill(@_buff, 0, READCNT)
    ser.position(0, STATUS_LINE)
    ser.str(string("Reading page..."))
    stime := cnt
    mem.readbytes(start_addr, READCNT, @_buff)  ' read page into hub array
    etime := cnt-stime

    cycletime(etime)

PUB WriteTest(start_addr) | stime, etime, tmp
' Write a test string to the memory
    bytemove(@tmp, string("TEST"), 4)
    ser.position(0, STATUS_LINE+1)
    ser.str(string("Writing test value..."))
    stime := cnt
    mem.writebytes(start_addr, 4, @tmp)
    etime := cnt-stime

    cycletime(etime)

PRI CycleTime(cycles)
' Display cycle time (in microseconds) on the terminal
    ser.dec(cycles)
    ser.str(string(" cycles ("))
    ser.dec(cycles / CYCLES_USEC)
    ser.str(string("usec)"))
    ser.clearline{}
    return cycles / CYCLES_USEC

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if mem.startx(I2C_SCL, I2C_SDA, I2C_HZ, ADDR_BITS)
        ser.strln(string("85xxxx driver started"))
    else
        ser.strln(string("85xxxx driver failed to start - halting"))
        repeat

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
