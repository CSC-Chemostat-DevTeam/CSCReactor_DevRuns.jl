begin
    using CSCReactor_jlOs
    using LibSerialPort
    using JSON
    using Random
    using Dates
end

# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# Fri Jul  5 15:09 CEST 2024
# Fri Jul  5 15:29 CEST 2024
# 
# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
include("0.utils.jl")
include("0.ch.configs.jl")

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
let
    portname = _find_port()
    @show portname
    baudrate = 19200
    global sp = LibSerialPort.open(portname, baudrate)
    nothing
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
PUMPS = [PUMP_7_PIN, PUMP_6_PIN, PUMP_5_PIN, PUMP_4_PIN, PUMP_1_PIN, PUMP_2_PIN, PUMP_3_PIN]

let
    for it in 1:100
        @show it
        for pin in PUMPS
            send_csvcmd(sp, "INO", "PIN-MODE", pin, OUTPUT; log = true)
            send_csvcmd(sp, "INO", "DIGITAL-S-PULSE", pin, 1, 301, 0)
        end
    end
    
    nothing;
end