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
    # portname = "/dev/cu.usbmodem14201"
    portname = "/dev/cu.usbmodem14201"
    
    baudrate = 19200
    global sp = LibSerialPort.open(portname, baudrate)
    nothing
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
OD_TEST_CHS = [CH2, CH3, CH4, CH5]
ALL_CHS = [CH1, CH2, CH3, CH4, CH5]

let
    for ch in ALL_CHS
        _setup!(ch)
        _set_dry!(ch, false)
        _up_pulse_period!(ch)
    end

    for it in 1:500
        @show it
        # _media_in_pulse(CH1)
        _media_out_pulse(CH1)
        # _media_in_pulse(CH3)
        # _media_out_pulse(CH3)
    end
end


## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
OD_TEST_CHS = [CH2, CH3, CH4, CH5]
ALL_CHS = [CH1, CH2, CH3, CH4, CH5]
let
    for ch in ALL_CHS
        _setup!(ch)
        _set_dry!(ch, false)
        _up_pulse_period!(ch)
    end

    for it in 1:50
        println("-"^30)
        println("it: ", it)
        println("-"^30)

        for ch in shuffle(ALL_CHS)
            _media_out_pulse(ch)
            _air_in_pulse(ch)
        end

    end
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
OD_TEST_CHS = [CH2, CH3, CH4, CH5]
ALL_CHS = [CH1, CH2, CH3, CH4, CH5]
let
    for ch in ALL_CHS
        _setup!(ch)
        _set_dry!(ch, false)
        _up_pulse_period!(ch)
    end

    for it in 1:3
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
                _meassure_OD(CH4; v = true)
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