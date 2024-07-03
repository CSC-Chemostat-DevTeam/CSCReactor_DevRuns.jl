begin
    using CSCReactor_jlOs
    using LibSerialPort
    using JSON
end

# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
include("0_utils.jl")

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
let
    portname = "/dev/cu.usbmodem14201"
    # portname = "/dev/cu.usbmodem14201"
    
    baudrate = 19200
    global sp = LibSerialPort.open(portname, baudrate)
    nothing
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# 
let
    # PIN CONFIGURATION
    _AIR_PUMP_PIN = PUMP_3_PIN
    _DIL_PUMP_PIN = PUMP_2_PIN
    _STIRREL_PIN = STIRREL_PIN
    _MEDIUM_OUT_PUMP_PIN = PUMP_1_PIN
    _LASER_PIN = CH1_LASER_PIN
    _LED1_PIN = CH1_VIAL_LED_PIN
    _LED2_PIN = CH1_CONTROL_LED_PIN
    
    # STATIC CONFIGURATION
    _WORKING_VOLUME = 25.0 # mL
    _DIL_PUMP_PULSE_DURATION = 50 # ms
    _OUT_PUMP_PULSE_DURATION = _DIL_PUMP_PULSE_DURATION * 3
    @assert _DIL_PUMP_PULSE_DURATION < _OUT_PUMP_PULSE_DURATION
    
    # STATIC CONFIGURATION
    _TARGET_DILUTION = 0.9 # 1 / h
    @show _TARGET_DILUTION

    # AUX COMPUTATIONS
    _ABS_FLUX = _TARGET_DILUTION * _WORKING_VOLUME # mL / h
    _PUMP_PER_PULSE_VOLUME = 0.054 # mL [MEASSURED]
    _ABS_FLUX = _ABS_FLUX / _PUMP_PER_PULSE_VOLUME # pulses / h
    _PULSE_PERIOD = 1 / _ABS_FLUX # h
    _PULSE_PERIOD = _PULSE_PERIOD * 60 * 60 # second
    @show _PULSE_PERIOD

    # $INO:PIN-MODE:PIN:MODE%
    res = send_csvcmd(sp, "INO", "PIN-MODE", 
        _AIR_PUMP_PIN, OUTPUT,
        _DIL_PUMP_PIN, OUTPUT,
        _STIRREL_PIN, OUTPUT,
        _MEDIUM_OUT_PUMP_PIN, OUTPUT,
        _LASER_PIN, OUTPUT,

        _LED1_PIN, INPUT_PULLUP,
        _LED2_PIN, INPUT_PULLUP,
    )

    last_dil_pulse_time = 0

    while true
        try
            # medium out
            res = send_csvcmd(sp, "INO", "DIGITAL-S-PULSE", 
                _MEDIUM_OUT_PUMP_PIN, 1, 301, 0;
            )
            # air in
            res = send_csvcmd(sp, "INO", "DIGITAL-S-PULSE", 
                _AIR_PUMP_PIN, 1, 502, 0;
            )
            # stirring
            res = send_csvcmd(sp, "INO", "DIGITAL-S-PULSE", 
                _STIRREL_PIN, 1, 249, 0;
            )

            # non blocking sleep/ pumping
            for it in 1:10
                # If we need to pump
                if (time() - last_dil_pulse_time > _PULSE_PERIOD)
                    # stirring
                    res = send_csvcmd(sp, "INO", "DIGITAL-S-PULSE", 
                        _DIL_PUMP_PIN, 1, _DIL_PUMP_PULSE_DURATION, 0;
                    )
                    @info("PUMPED", 
                        target_dilution = _TARGET_DILUTION,
                        target_period = _PULSE_PERIOD,
                        meassured_period = time() - last_dil_pulse_time
                    )
                    last_dil_pulse_time = time()
                end
                sleep(0.1)
            end

            send_csvcmd(sp, "INO", "ANALOG-WRITE", _LASER_PIN, 210);
            send_csvcmd(sp, "INO", "ANALOG-WRITE", _LASER_PIN, 210; log = false);
            sleep(0.4)

            global pkg1 = send_csvcmd(sp, "INO", "PULSE-IN", _LED1_PIN, 100)
            isempty(pkg1["done_ack"]) && continue
            val1 = parse(Int, pkg1["responses"][0]["data"][2])
            @show  val1

            pkg2 = send_csvcmd(sp, "INO", "PULSE-IN", _LED2_PIN, 100)
            isempty(pkg2["done_ack"]) && continue
            val2 = parse(Int, pkg2["responses"][0]["data"][2])
            @show  val2

            send_csvcmd(sp, "INO", "ANALOG-WRITE", _LASER_PIN, 0);
            send_csvcmd(sp, "INO", "ANALOG-WRITE", _LASER_PIN, 0; log = false);
        catch err
            @error err
        end
    end
    nothing;
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-