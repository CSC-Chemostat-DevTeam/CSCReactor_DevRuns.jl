begin
    using CSCReactor_jlOs
    using LibSerialPort
    using JSON
end

# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
include("0.utils.jl")
include("0.ch.configs.jl")

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
let
    # portname = "/dev/cu.usbmodem14201"
    portname = "/dev/cu.usbmodem14101"
    
    baudrate = 19200
    global sp = LibSerialPort.open(portname, baudrate)
    nothing
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
let
    _setup!(CH4)
    _set_dry!(CH4, false)
    _up_pulse_period!(CH4)

    for it in 1:10
        println("-"^30)
        try
            _media_out_pulse(CH4)
            _media_in_pulse(CH4; v = true);
            _air_in_pulse(CH4)
            _media_in_pulse(CH4; v = true);
            _stirring_pulse(CH4)
            _media_in_pulse(CH4; v = true);

            # non blocking sleep
            for it in 1:10
                # If we need to pump
                _media_in_pulse(CH4; v = true);
                sleep(0.1)
            end

            _meassure_OD(CH4; v = true)

        catch err
            err isa InterruptException && rethrow(err)
            @error err
        end
    end
    nothing;
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-