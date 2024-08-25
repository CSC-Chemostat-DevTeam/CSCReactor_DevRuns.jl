## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# PIN LAYOUT

PUMP_1_PIN = 15
PUMP_2_PIN = 9
PUMP_3_PIN = 11
PUMP_4_PIN = 4
PUMP_5_PIN = 3
PUMP_6_PIN = 2
PUMP_7_PIN = 14

STIRREL_PIN = 6

CH1_LASER_PIN = 5
CH1_CONTROL_LED_PIN = 29
CH1_VIAL_LED_PIN = 33

CH2_LASER_PIN = 8
CH2_CONTROL_LED_PIN = 43
CH2_VIAL_LED_PIN = 47

CH3_LASER_PIN = 7
CH3_VIAL_LED_PIN = 25
CH3_CONTROL_LED_PIN = 51

CH4_LASER_PIN = 12
CH4_CONTROL_LED_PIN = 35
CH4_VIAL_LED_PIN = 39

CH5_LASER_PIN = 10
CH5_CONTROL_LED_PIN = 27
CH5_VIAL_LED_PIN = 31


## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# LOG
logdir!(joinpath(@__DIR__, "logs"))

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
function _up_pulse_period!(ch)
    _abs_flux = ch["dilution.target"] * ch["vial.working_volume"] # mL / h
    _abs_flux = _abs_flux / ch["pump.medium.in.per_pulse_volume"] # pulses / h
    _pulse_period = 1 / _abs_flux # h
    _pulse_period = _pulse_period * 60 * 60 # second
    ch["pump.medium.in.pulse_period.target"] = _pulse_period
    return _pulse_period
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
function _set_pin_modes!(ch)
    # $INO:PIN-MODE:PIN:MODE%
    ch["run.dry"] && return
    pin = ch["pump.air.in.pin"]
    isnothing(pin) || send_csvcmd(sp, "INO", "PIN-MODE", pin, OUTPUT)
    pin = ch["pump.medium.in.pin"]
    isnothing(pin) || send_csvcmd(sp, "INO", "PIN-MODE", pin, OUTPUT)
    pin = ch["stirrel.pin"]
    isnothing(pin) || send_csvcmd(sp, "INO", "PIN-MODE", pin, OUTPUT)
    pin = ch["pump.medium.out.pin"]
    isnothing(pin) || send_csvcmd(sp, "INO", "PIN-MODE", pin, OUTPUT)
    pin = ch["laser.pin"]
    isnothing(pin) || send_csvcmd(sp, "INO", "PIN-MODE", pin, OUTPUT)
    pin = ch["led1.pin"]
    isnothing(pin) || send_csvcmd(sp, "INO", "PIN-MODE", pin, INPUT_PULLUP)
    pin = ch["led2.pin"]
    isnothing(pin) || send_csvcmd(sp, "INO", "PIN-MODE", pin, INPUT_PULLUP)
end

# medium out
function _media_out_pulse(ch; v = true)
    # TODO: add all nums to ch
    try
        # enable
        ch["pump.medium.out.enable"] || return
        # check period
        elp = time() - ch["pump.medium.out.last_pulse.time"]
        elp < ch["pump.medium.out.pulse_period.min"] && return # no time yet
        ch["pump.medium.out.last_pulse.time"] = time()
        # pulse
        if !ch["run.dry"]
            res = send_csvcmd(sp, "INO", "DIGITAL-S-PULSE", 
                ch["pump.medium.out.pin"], 1, 301, 0;
            )
            # res["done_ack"]
            # return res
        end
        v && @info("MEDIA OUT", 
            ch = ch["ch.name"],
            target_period = ch["pump.medium.out.pulse_period.min"],
            meassured_period = elp
        )
    catch err
        err isa InterruptException && rethrow(err)
        @error err
    end
end

# air in
function _air_in_pulse(ch; v = true)
    # TODO: add all nums to ch
    try
        # enable
        ch["pump.air.in.enable"] || return
        # check period
        elp = time() - ch["pump.air.in.last_pulse.time"]
        elp < ch["pump.air.in.pulse_period.min"] && return # no time yet
        ch["pump.air.in.last_pulse.time"] = time()
        # pulse
        if !ch["run.dry"]
            send_csvcmd(sp, "INO", "DIGITAL-S-PULSE", 
                ch["pump.air.in.pin"], 1, 700, 0;
            )
            # res["done_ack"]
            # return res
        end
        v && @info("AIR IN", 
            ch = ch["ch.name"],
            target_period = ch["pump.air.in.pulse_period.min"],
            meassured_period = elp
        )
    catch err
        err isa InterruptException && rethrow(err)
        @error err
    end
end

# stirring
function _stirring_pulse(ch; v = true)
    # TODO: add all nums to ch
    try
        # enable
        ch["stirrel.enable"] || return
        # check period
        elp = time() - ch["stirrel.last_pulse.time"]
        elp < ch["stirrel.pulse_period.min"] && return # no time yet
        ch["stirrel.last_pulse.time"] = time()
        # pulse
        if !ch["run.dry"]
            res = send_csvcmd(sp, "INO", "DIGITAL-S-PULSE", 
                ch["stirrel.pin"], 1, 300, 0;
            )
            # res["done_ack"]
            # return res
        end
        v && @info("STIRREL", 
            ch = ch["ch.name"],
            target_period = ch["stirrel.pulse_period.min"],
            meassured_period = elp
        )
    catch err
        err isa InterruptException && rethrow(err)
        @error err
    end
end

function _media_in_pulse(ch; v = true)
    try
        # enable
        ch["pump.medium.in.enable"] || return
        # check period
        elp = time() - ch["pump.medium.in.last_pulse.time"]
        elp < ch["pump.medium.in.pulse_period.target"] && return # no time yet
        ch["pump.medium.in.last_pulse.time"] = time()

        # pulse
        if !ch["run.dry"]
            res = send_csvcmd(sp, "INO", "DIGITAL-S-PULSE", 
                ch["pump.medium.in.pin"], 1, ch["pump.medium.in.pulse_duration"], 0;
            )
            # TODO: check command result
        end
        v && @info("MEDIUM IN", 
            ch = ch["ch.name"],
            target_dilution = ch["dilution.target"],
            target_period = ch["pump.medium.in.pulse_period.target"],
            meassured_period = elp
        )
    catch err
        err isa InterruptException && rethrow(err)
        @error err
    end
end

function _meassure_OD(ch; v = true)
    if ch["run.dry"] 
        v && @info("READING OD [DRY]", 
            ch = ch["ch.name"],
        )
        sleep(0.1 + 0.1 + 0.1 + 0.1)
        return
    end
    send_csvcmd(sp, "INO", "ANALOG-WRITE", ch["laser.pin"], ch["laser.pwm"]);
    send_csvcmd(sp, "INO", "ANALOG-WRITE", ch["laser.pin"], ch["laser.pwm"]; log = false);
    sleep(0.1)

    global pkg1 = send_csvcmd(sp, "INO", "PULSE-IN", ch["led1.pin"], 100)
    # isempty(pkg1["done_ack"]) && continue
    val1 = parse(Int, pkg1["responses"][0]["data"][2])

    pkg2 = send_csvcmd(sp, "INO", "PULSE-IN", ch["led2.pin"], 100)
    # isempty(pkg2["done_ack"]) && continue
    val2 = parse(Int, pkg2["responses"][0]["data"][2])

    send_csvcmd(sp, "INO", "ANALOG-WRITE", ch["laser.pin"], 0);
    send_csvcmd(sp, "INO", "ANALOG-WRITE", ch["laser.pin"], 0; log = false);

    v && @info("OD MEASSURED", 
        ch = ch["ch.name"],
        val1, val2
    )

    return nothing
end


function _setup!(ch)
    
    _set_pin_modes!(ch);

    ch["pump.medium.in.last_pulse.time"] = 0
    ch["pump.medium.out.last_pulse.time"] = 0
    ch["pump.air.in.last_pulse.time"] = 0
    ch["stirrel.last_pulse.time"] = 0

    return nothing
end

function _sync_key!(key, val, ch1...)
    for ch in ch1
        ch[key] = val
    end
end

function _set_dry!(ch, val)
    ch["run.dry"] = val
end

function _find_port()
    for port in get_port_list()
        port == "/dev/cu.usbmodem14101" && return port
        port == "/dev/cu.usbmodem14201" && return port
    end
    error("Port not found: ", get_port_list())
end

