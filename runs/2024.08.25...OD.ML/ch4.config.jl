## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# COMMONS

# CHEMOSTATS
CH4 = Dict(
    # EXTRAS
    "ch.name" => "CH4",
    "run.dry" => false,
    
    # PIN LAYOUT
    "stirrel.pin" => nothing,
    "pump.air.in.pin" => nothing,
    "pump.medium.out.pin" => nothing,
    "pump.medium.in.pin" => nothing,
    "laser.pin" => CH4_LASER_PIN,
    "led1.pin" => CH4_CONTROL_LED_PIN,
    "led2.pin" => CH4_VIAL_LED_PIN,
    
    # CONFIG
    "vial.working_volume" => 25.0, # mL #TODO [MEASSURED]
    
    "pump.medium.in.per_pulse_volume" => 0.054, # mL #TODO [MEASSURED]
    "pump.medium.in.pulse_duration" => 50.0, # ms
    
    "pump.medium.out.pulse_duration" => 150.0, # ms

    "laser.pwm" => 210,
    
    # MAIN CONTROL
    "dilution.target" => 0.0, # 1/h

    # STATE
    "pump.medium.in.enable" => false, # NO PUMP
    "pump.medium.in.pulse_period.min" => 0,
    "pump.medium.in.pulse_period.target" => 0,
    "pump.medium.in.last_pulse.time" => 0,
    
    "pump.medium.out.enable" => false, # NO PUMP
    "pump.medium.out.pulse_period.min" => 0,
    "pump.medium.out.pulse_period.target" => nothing,
    "pump.medium.out.last_pulse.time" => 0,

    "stirrel.enable" => false, # CH1 on control
    "stirrel.pulse_period.min" => 3,
    "stirrel.pulse_period.target" => nothing,
    "stirrel.last_pulse.time" => 0,

    "pump.air.in.enable" => false, # CH2 on control
    "pump.air.in.pulse_period.min" => 0,
    "pump.air.in.pulse_period.target" => nothing,
    "pump.air.in.last_pulse.time" => 0,
)

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
return nothing