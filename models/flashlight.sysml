package FlashlightSpecificationAndDesign {
    public import ScalarValues::*;
    public import SI::*;
    public import USCustomaryUnits::*;

    // create a Requirements package that contains the hierarchy of requirements that compose the flashlight specification
    package Requirements{
        requirement flashlightSpecification{
            requirement userInterface;
            requirement illumination{
                // the following is a simple text-based requirement
                requirement fieldOfView{
                    doc /* The flashlight field of view shall be 0 - 20 degrees.*/
                }
                requirement lightPower{
                    doc /* The light power shall be a minumum of TBD lumens.*/            
                }
            }
            requirement physical{
                requirement portability;
                requirement size{
                    doc /* The flashlight shall be less than 6 inches in length.*/    
                }
                // the following is a more precisely specified requirement using constraints
                requirement weight{
                    doc /* The weight shall be less than 0.25 lbs.*/  
                    attribute actualWeight :> ISQ::mass;
                    require constraint {actualWeight <= 0.25 [lb]}
                }
            }
            requirement reliability;
            requirement cost;
        }
    }

    // create a package called ActionTree that contains the actions and flows to produceDirectedLight
    package ActionTree{
        action produceDirectedLight{
            in item onOffCmd; //input
            // the following output (i.e., lightOut) from produceDirectedLight is equal to (i.e., bound to) the lightOut from the action directLight;
            out item lightOut = directLight.lightOut;

            // declare each nested action and their inputs and outputs
            action provideDCPwr{
                out item dcPwr;
            }
            action connectDCPwr {
                in item onOffCmd = produceDirectedLight.onOffCmd;
                in item dcPwrIn;
                out item dcPwrOut;
            }
            action generateLight{
                in item dcPwrIn;
                out item light;
            }
            action directLight{
                in item lightIn;
                out item lightOut;
            }
            // the following declares a fork node named fork1 that is succeeded by two parallel actions (provideDCPwr and connectDCPowr)
            fork fork1;
                then provideDCPwr; // succession
                then connectDCPwr; // succession

            // define a control flow (i.e., succession) beginning with a start node and then fork1
            // note that start node does not have to be declared. It is available by default.
            first start then fork1;

            // define input/output flow from the output of one action to the input of another action
            flow from provideDCPwr.dcPwr to connectDCPwr.dcPwrIn;
            flow from connectDCPwr.dcPwrOut to generateLight.dcPwrIn;
            flow from generateLight.light to directLight.lightIn;
        }
    }

    // create a PartsTree package that contains the flashlight,
    // along with its key features such as attributes, ports, and actions, its parts, and its part interconnections
    package PartsTree{ 
        part flashlight {
            // flashlight attributes
            attribute mass :> ISQ::mass;
            attribute fov:Real;
            attribute illuminationLevel:Real;

            // flashlight ports
            port cmdPort;
            port lightOutPort;

            // flashlight perform action. The flashlight performs the action called produceDirectedLight 
            // that is contained in the Action Tree
            perform ActionTree::produceDirectedLight;    

            // the flashlight exhibits its flashlight states wich are initial, off, and on;
            exhibit state flashlightStates{
                // declare the states
                state initial;
                state off;                                 
                state on{
                    // define the do action by referring to (actually subsetting) 
                    // the action above 'perfrom ActionTree::produceDirectedLight'
                    do produceDirectedLight;
                }

                // each of the state transitions is defined
                // the transitions just specify the start and end states of the transition
                // the triggering events are not included for simplicity
                transition initial then off;
                transition off_To_on
                    first off
                    then on;
                transition on_To_off
                    first on
                    then off;
            }
            // the battery is a referential part of the flashlight
            ref part battery [2]{ // the multiplicity of 2 signifies that a flashlight has 2 batteries.
                attribute power:> ISQ::power;
                port dcPwrOutPort;
                perform produceDirectedLight.provideDCPwr;
            }
            // the following are composite parts of the flashlight
            part switch{
                port cmdPort;
                port inPort;
                port outPort;
                perform produceDirectedLight.connectDCPwr;
            }
            part lamp{
                attribute efficiency:Real;
                port dcPwrInPort;
                port lightOutPort;
                perform produceDirectedLight.generateLight;
            }
            part optics{
                port lightInPort;
                port lightOutPort;
                perform produceDirectedLight.directLight;
                part reflector{
                    attribute radius:> ISQ::length;
                }
                part lens;
            }
            part structure{
                part frontHousing;
                part middleHousing;
                part backHousing;
            }

            // the following establish connections
            // the binding connections assert that the cmdPort on the flashlight is the same as the cmdPort on the switch
            // and similarly for the lightOutPort
            bind cmdPort = switch.cmdPort;
            bind lightOutPort = optics.lightOutPort;

            // the connections connect a port on one part to a port to on another part
            connect battery.dcPwrOutPort to switch.inPort;
            connect switch.outPort to lamp.dcPwrInPort; 
            connect lamp.lightOutPort to optics.lightInPort;
        }
    }
    // create an RequirementsAllocation package that contains the allocation of requirements to the flashlight design features
    package RequirementsAllocation{
        // this package imports the Requirements package and the PartsTree packge to access the elements contained in these packages
        // without having to use their fully qualified name such as Requirements::flashlightSpecification
        public import Requirements::*;
        public import PartsTree::*;

        // the following allocates the flashlightSpecification to the flashlight
        allocate flashlightSpecification to flashlight{
            allocate flashlightSpecification.physical.weight to flashlight.mass; // nested allocation
            allocate flashlightSpecification.illumination.fieldOfView to flashlight.fov;
            allocate flashlightSpecification.illumination.lightPower to flashlight.illuminationLevel;
        }
    }
}