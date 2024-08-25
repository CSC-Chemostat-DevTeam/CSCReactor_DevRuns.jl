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
ALL_CHS = [CH1, CH2, CH3, CH4, CH5]
let
    for ch in ALL_CHS
        _set_dry!(ch, false)
        _setup!(ch)
        _up_pulse_period!(ch)
    end

    for it in 1:Int(1e15)

        # # set dilution
        # if now() > DateTime("2024-07-04T23:01:00.010")
        #     for ch in [CH1, CH2, CH3]
        #         ch["dilution.target"] = 0.3
        #         _up_pulse_period!(ch)
        #     end
        # end

        println("-"^30)
        println("it: ", it)
        println("-"^30)
        try
            for ch in shuffle(ALL_CHS)
                _media_out_pulse(ch)
                for ch in shuffle(ALL_CHS)
                    _media_in_pulse(ch; v = true);
                end
                _air_in_pulse(ch)
                for ch in shuffle(ALL_CHS)
                    _media_in_pulse(ch; v = true);
                end
                _stirring_pulse(ch)
                for ch in shuffle(ALL_CHS)
                    _media_in_pulse(ch; v = true);
                end
            end

            # non blocking sleep
            # For quite down
            dt = 0.05
            for it in 1:floor(Int, 1/dt)
                # If we need to pump
                for ch in ALL_CHS
                    _media_in_pulse(ch; v = true);
                end
                sleep(dt)
            end

            for ch in shuffle(ALL_CHS)
                _meassure_OD(ch; v = true)
                for ch in shuffle(ALL_CHS)
                    _media_in_pulse(ch; v = true);
                end
            end

        catch err
            err isa InterruptException && rethrow(err)
            @error err
        end
    end
    nothing;
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-