package QuadcopterSpecificationAndDesign {
    public import ScalarValues::*;
    public import SI::*;
    public import USCustomaryUnits::*;

    // create a Requirements package that contains the hierarchy of requirements
    // that compose the quadcopter specification
    package Requirements{
        requirement quadcopterSpecification{
            requirement userInterface{
                requirement commandInput{
                    doc /* The quadcopter shall accept pilot or autonomous flight commands through a command input interface.*/
                }
                requirement telemetry{
                    doc /* The quadcopter shall provide telemetry including battery state, attitude, altitude, and flight mode.*/
                }
            }

            requirement flightPerformance{
                requirement controlledFlight{
                    doc /* The quadcopter shall produce controlled vertical lift and directional motion.*/
                }
                requirement hover{
                    doc /* The quadcopter shall maintain stable hover in nominal operating conditions.*/
                }
                requirement flightTime{
                    doc /* The quadcopter shall operate for a minimum of TBD minutes on a fully charged battery.*/
                    attribute actualFlightTime :> ISQ::time;
                    require constraint {actualFlightTime >= 10 [min]}
                }
                requirement payload{
                    doc /* The quadcopter shall carry a payload of at least TBD mass.*/
                    attribute actualPayloadMass :> ISQ::mass;
                    require constraint {actualPayloadMass >= 0.10 [kg]}
                }
            }

            requirement physical{
                requirement portability;
                requirement size{
                    doc /* The quadcopter shall have a maximum diagonal motor-to-motor size of less than 45 centimeters.*/
                    attribute actualDiagonalSize :> ISQ::length;
                    require constraint {actualDiagonalSize <= 45 [cm]}
                }
                requirement weight{
                    doc /* The quadcopter takeoff mass shall be less than 2.0 kg.*/
                    attribute actualMass :> ISQ::mass;
                    require constraint {actualMass <= 2.0 [kg]}
                }
            }

            requirement energy{
                requirement batteryVoltage{
                    doc /* The quadcopter shall use a battery pack with nominal voltage suitable for the motor and ESC system.*/
                }
                requirement powerDistribution{
                    doc /* The quadcopter shall distribute electrical power from the battery to all propulsion and control components.*/
                }
            }

            requirement sensingAndControl{
                requirement attitudeSensing{
                    doc /* The quadcopter shall sense roll, pitch, and yaw attitude for flight stabilization.*/
                }
                requirement altitudeSensing{
                    doc /* The quadcopter shall estimate altitude for takeoff, landing, and hover control.*/
                }
                requirement flightControl{
                    doc /* The quadcopter shall compute motor commands from desired motion and sensed vehicle state.*/
                }
            }

            requirement safety{
                requirement failsafe{
                    doc /* The quadcopter shall enter a safe state when communication, power, or critical sensor faults are detected.*/
                }
                requirement lowBatteryProtection{
                    doc /* The quadcopter shall warn the operator or initiate landing when battery state is below a defined threshold.*/
                }
                requirement propellerGuarding{
                    doc /* The quadcopter should reduce risk of injury from rotating propellers where practical.*/
                }
            }

            requirement reliability;
            requirement cost;
        }
    }

    // create a package called ActionTree that contains the actions and flows
    // required to produce controlled flight
    package ActionTree{
        action produceControlledFlight{
            in item flightCmd;          // input command from operator or autonomy
            out item telemetryOut;      // output vehicle status
            out item thrustOut = combineThrust.thrustOut;

            // declare each nested action and their inputs and outputs
            action provideElectricalPower{
                out item dcPwr;
            }

            action distributeElectricalPower{
                in item dcPwrIn;
                out item propulsionPwr;
                out item controlPwr;
            }

            action receiveFlightCommand{
                in item flightCmdIn = produceControlledFlight.flightCmd;
                out item desiredMotion;
            }

            action measureVehicleState{
                in item controlPwrIn;
                out item sensedState;
            }

            action computeFlightControl{
                in item desiredMotionIn;
                in item sensedStateIn;
                in item controlPwrIn;
                out item motorCmd;
                out item telemetry;
            }

            action modulateMotorPower{
                in item motorCmdIn;
                in item propulsionPwrIn;
                out item motorPwr;
            }

            action generateRotorThrust{
                in item motorPwrIn;
                out item rotorThrust;
            }

            action combineThrust{
                in item rotorThrustIn;
                out item thrustOut;
            }

            action reportTelemetry{
                in item telemetryIn = computeFlightControl.telemetry;
                out item telemetryOut = produceControlledFlight.telemetryOut;
            }

            // fork power provision and command reception in parallel
            fork fork1;
                then provideElectricalPower;
                then receiveFlightCommand;

            // control flow beginning with a start node and then fork1
            first start then fork1;

            // power flow
            flow from provideElectricalPower.dcPwr to distributeElectricalPower.dcPwrIn;
            flow from distributeElectricalPower.controlPwr to measureVehicleState.controlPwrIn;
            flow from distributeElectricalPower.controlPwr to computeFlightControl.controlPwrIn;
            flow from distributeElectricalPower.propulsionPwr to modulateMotorPower.propulsionPwrIn;

            // command and sensing flow
            flow from receiveFlightCommand.desiredMotion to computeFlightControl.desiredMotionIn;
            flow from measureVehicleState.sensedState to computeFlightControl.sensedStateIn;

            // propulsion flow
            flow from computeFlightControl.motorCmd to modulateMotorPower.motorCmdIn;
            flow from modulateMotorPower.motorPwr to generateRotorThrust.motorPwrIn;
            flow from generateRotorThrust.rotorThrust to combineThrust.rotorThrustIn;

            // telemetry flow
            flow from computeFlightControl.telemetry to reportTelemetry.telemetryIn;
        }
    }

    // create a PartsTree package that contains the quadcopter,
    // its key features such as attributes, ports, and actions,
    // its parts, and its part interconnections
    package PartsTree{
        part quadcopter {
            // quadcopter attributes
            attribute mass :> ISQ::mass;
            attribute diagonalSize :> ISQ::length;
            attribute payloadMass :> ISQ::mass;
            attribute flightTime :> ISQ::time;
            attribute batteryStateOfCharge : Real;
            attribute hoverStability : Real;

            // quadcopter ports
            port cmdPort;
            port telemetryPort;
            port thrustOutPort;

            // the quadcopter performs the action called produceControlledFlight
            // that is contained in the ActionTree
            perform ActionTree::produceControlledFlight;

            // the quadcopter exhibits states for basic operating modes
            exhibit state quadcopterStates{
                // declare the states
                state initial;
                state off;
                state armed;
                state flying{
                    // define the do action by referring to the action above
                    do produceControlledFlight;
                }
                state landing{
                    do produceControlledFlight;
                }
                state fault;

                // define the state transitions
                transition initial then off;

                transition off_To_armed
                    first off
                    then armed;

                transition armed_To_flying
                    first armed
                    then flying;

                transition flying_To_landing
                    first flying
                    then landing;

                transition landing_To_off
                    first landing
                    then off;

                transition flying_To_fault
                    first flying
                    then fault;

                transition fault_To_off
                    first fault
                    then off;
            }

            // the battery is a referential part of the quadcopter
            ref part battery [1]{
                attribute capacity :> ISQ::electricCharge;
                attribute voltage :> ISQ::electricPotential;
                attribute power :> ISQ::power;
                port dcPwrOutPort;
                perform produceControlledFlight.provideElectricalPower;
            }

            // composite parts of the quadcopter
            part powerDistributionBoard{
                port dcPwrInPort;
                port propulsionPwrOutPort;
                port controlPwrOutPort;
                perform produceControlledFlight.distributeElectricalPower;
            }

            part receiver{
                port cmdInPort;
                port desiredMotionOutPort;
                perform produceControlledFlight.receiveFlightCommand;
            }

            part flightController{
                attribute controllerRate : Real;
                port desiredMotionInPort;
                port sensedStateInPort;
                port controlPwrInPort;
                port motorCmdOutPort;
                port telemetryOutPort;
                perform produceControlledFlight.computeFlightControl;
            }

            part sensorSuite{
                port controlPwrInPort;
                port sensedStateOutPort;
                perform produceControlledFlight.measureVehicleState;

                part imu{
                    attribute sampleRate : Real;
                    port attitudeOutPort;
                }

                part barometer{
                    attribute altitudeEstimate :> ISQ::length;
                    port altitudeOutPort;
                }

                part gps{
                    attribute positionAccuracy :> ISQ::length;
                    port positionOutPort;
                }
            }

            // four electronic speed controllers
            part esc [4]{
                port motorCmdInPort;
                port propulsionPwrInPort;
                port motorPwrOutPort;
                perform produceControlledFlight.modulateMotorPower;
            }

            // four motors
            part motor [4]{
                attribute maxPower :> ISQ::power;
                attribute rotationalSpeed : Real;
                port motorPwrInPort;
                port shaftOutPort;
            }

            // four propellers generate rotor thrust
            part propeller [4]{
                attribute diameter :> ISQ::length;
                attribute pitch :> ISQ::length;
                port shaftInPort;
                port rotorThrustOutPort;
                perform produceControlledFlight.generateRotorThrust;
            }

            part thrustMixer{
                port rotorThrustInPort;
                port thrustOutPort;
                perform produceControlledFlight.combineThrust;
            }

            part telemetryRadio{
                port telemetryInPort;
                port telemetryOutPort;
                perform produceControlledFlight.reportTelemetry;
            }

            part frameBody{
                part centerBody;
                part arm [4];
                part landingGear;
                part payloadMount;
                part propellerGuard [4];
            }

            // binding connections assert that external quadcopter ports
            // are the same as selected internal subsystem ports
            bind cmdPort = receiver.cmdInPort;
            bind telemetryPort = telemetryRadio.telemetryOutPort;
            bind thrustOutPort = thrustMixer.thrustOutPort;

            // power connections
            connect battery.dcPwrOutPort to powerDistributionBoard.dcPwrInPort;
            connect powerDistributionBoard.controlPwrOutPort to sensorSuite.controlPwrInPort;
            connect powerDistributionBoard.controlPwrOutPort to flightController.controlPwrInPort;
            connect powerDistributionBoard.propulsionPwrOutPort to esc.propulsionPwrInPort;

            // command and control connections
            connect receiver.desiredMotionOutPort to flightController.desiredMotionInPort;
            connect sensorSuite.sensedStateOutPort to flightController.sensedStateInPort;
            connect flightController.motorCmdOutPort to esc.motorCmdInPort;

            // propulsion chain connections
            connect esc.motorPwrOutPort to motor.motorPwrInPort;
            connect motor.shaftOutPort to propeller.shaftInPort;
            connect propeller.rotorThrustOutPort to thrustMixer.rotorThrustInPort;

            // telemetry connections
            connect flightController.telemetryOutPort to telemetryRadio.telemetryInPort;
        }
    }

    // create a RequirementsAllocation package that contains the allocation of
    // requirements to the quadcopter design features
    package RequirementsAllocation{
        // this package imports the Requirements package and the PartsTree package
        // to access the elements contained in these packages
        public import Requirements::*;
        public import PartsTree::*;

        // allocate the quadcopterSpecification to the quadcopter
        allocate quadcopterSpecification to quadcopter{
            allocate quadcopterSpecification.physical.weight to quadcopter.mass;
            allocate quadcopterSpecification.physical.size to quadcopter.diagonalSize;
            allocate quadcopterSpecification.flightPerformance.flightTime to quadcopter.flightTime;
            allocate quadcopterSpecification.flightPerformance.payload to quadcopter.payloadMass;
            allocate quadcopterSpecification.flightPerformance.hover to quadcopter.hoverStability;

            allocate quadcopterSpecification.userInterface.commandInput to quadcopter.cmdPort;
            allocate quadcopterSpecification.userInterface.telemetry to quadcopter.telemetryPort;

            allocate quadcopterSpecification.energy.batteryVoltage to quadcopter.battery.voltage;
            allocate quadcopterSpecification.energy.powerDistribution to quadcopter.powerDistributionBoard;

            allocate quadcopterSpecification.sensingAndControl.attitudeSensing to quadcopter.sensorSuite.imu;
            allocate quadcopterSpecification.sensingAndControl.altitudeSensing to quadcopter.sensorSuite.barometer;
            allocate quadcopterSpecification.sensingAndControl.flightControl to quadcopter.flightController;

            allocate quadcopterSpecification.safety.failsafe to quadcopter.quadcopterStates.fault;
            allocate quadcopterSpecification.safety.lowBatteryProtection to quadcopter.batteryStateOfCharge;
            allocate quadcopterSpecification.safety.propellerGuarding to quadcopter.frameBody.propellerGuard;
        }
    }
}