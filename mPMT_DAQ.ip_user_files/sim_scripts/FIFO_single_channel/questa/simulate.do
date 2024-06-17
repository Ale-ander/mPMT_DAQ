onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib FIFO_single_channel_opt

do {wave.do}

view wave
view structure
view signals

do {FIFO_single_channel.udo}

run -all

quit -force
