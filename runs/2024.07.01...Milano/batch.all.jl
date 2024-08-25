begin
    using CSCReactor_jlOs
    using LibSerialPort
    using JSON
    using Random
end

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
ALL_CHS = [CH1, CH2, CH3, CH4, CH5]
let
    for ch in ALL_CHS
        _setup!(ch)
        _set_dry!(ch, false)
        _up_pulse_period!(ch)
    end

    for it in 1:Int(1e15)
        println("-"^30)
        println("it: ", it)
        println("-"^30)
        try
            for ch in shuffle(ALL_CHS)
                _air_in_pulse(ch)
                _stirring_pulse(ch)
            end

            # non blocking sleep
            # For quite down
            dt = 0.05
            for it in 1:floor(Int, 1/dt)
                # If we need to pump
                sleep(dt)
            end

            for ch in shuffle(ALL_CHS)
                _meassure_OD(ch; v = true)
            end

        catch err
            err isa InterruptException && rethrow(err)
            @error err
        end
    end
    nothing;
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-