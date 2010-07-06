classdef cantilever
  
  properties
    freq_min; % Hertz
    freq_max; % Hertz
    l; % overall cantilever length
    w; % overall cantilever width (total width of both legs)
    t; % overall cantilever thickness
    l_pr_ratio; % piezoresistor length ratio
    v_bridge; % Volts
    fluid;

    number_of_piezoresistors;
    rms_actuator_displacement_noise = 1e-12; % m
    alpha = 1e-6; % unitless
    amplifier = 'INA103';
    doping_type = 'boron';
    
    % (Optional) Account for tip mass loading or a thick material step at the base
    tip_mass;
    
    % (Optional) Account for a stiffening layer (step) or actuator (thermal or piezoelectric) at the base
    cantilever_type; % 'none', 'step', 'thermal', 'piezoelectric'
    l_a;
    w_a;
    t_a;

    v_actuator;
    R_heater;
    t_electrode;
    t_a_seed;
  end
  
  % Can be referred to with cantilever.variableName
  properties (Constant)
    
    % Material constants
    T = 300; % kelvin
    k_b = 1.38e-23; % J/K
    k_b_eV = 8.617343e-5; % eV/K
    q = 1.60218e-19; % Coulombs
    
    numFrequencyPoints = 500;
    numXPoints = 1000;

    % Fluid properties
    rho_water = 1e3; % kg/m^3
    eta_water = 0.9e-3; % Pa-sec
    rho_air = 1.2; % kg/m^3
    eta_air = 17e-6; % Pa-sec
        
    % Thermal properties
    % Si properties: http://www.ioffe.ru/SVA/NSM/Semicond/Si/thermal.html
    k_si = 130; % W/m-K
    k_al = 237; % W/m-K
    k_sio2 = 1.4; % W/m-K
    k_ti = 21.9;
    k_aln = 160; % W/m-K
    
    h_vacuum = 1e-6; % W/m^2-K - small but finite h for numerical stability
    h_air = 1000; % W/m^2-K
    h_water = 20000; % W/m^2-k

    % Actuator properties
    alpha_al = 23.1e-6;
    alpha_sio2 = 0.5e-6;
    alpha_si = 2.6e-6;
    alpha_ti = 8.6e-6;
    alpha_aln = 4.5e-6;
    d31_aln = 2.3e-12;

    % Mechanical material properties
    E_Si = 130e9;
    rho_Si = 2330;
    E_Al = 70e9;
    rho_Al = 2700;
    E_Ti = 90e9;
    rho_Ti = 4506;
    E_AlN = 396e9;
    rho_AlN = 3260;
    maxQ = 1000;
    minQ = 1e-6;

    % The optimization goals
    goalForceResolution = 0;
    goalDisplacementResolution = 1;
    
    % Store the Sader lookup table and vectors as a constant
    kappa_lookup = [0 0.125 0.25 0.5 0.75 1 2 3 5 7 10 20];
    reynolds_lookup = [-4 -3.5 -3 -2.5 -2 -1.5 -1 -.5 0 0.5 1 1.5 2 2.5 3 3.5 4];
    
    tau_lookup_real = ...
      [3919.41 59.3906  22.4062  9.13525  5.62175  4.05204  1.93036  1.2764   0.764081 0.545683 0.381972 0.190986;
      1531.90 59.3861  22.4061  9.13525  5.62175  4.05204  1.93036  1.2764   0.764081 0.545683 0.381972 0.190986;
      613.426 59.3420  22.4052  9.13523  5.62174  4.05204  1.93036  1.2764   0.764081 0.545683 0.381972 0.190986;
      253.109 58.9094  22.3962  9.13504  5.62172  4.05203  1.93036  1.2764   0.764081 0.545683 0.381972 0.190986;
      108.429 55.2882  22.3078  9.13319  5.62153  4.05199  1.93036  1.2764   0.764081 0.545683 0.381972 0.190986;
      48.6978 40.7883  21.5187  9.11481  5.61960  4.05160  1.93035  1.2764   0.764081 0.545683 0.381972 0.190986;
      23.2075 22.7968  17.5378  8.94370  5.60057  4.04771  1.93027  1.27639  0.76408  0.545683 0.381972 0.190986;
      11.8958 11.9511  11.0719  7.89716  5.43378  4.01051  1.92942  1.27629  0.764074 0.545682 0.381972 0.190986;
      6.64352 6.64381  6.47227  5.65652  4.64017  3.74600  1.92114  1.27536  0.764012 0.545671 0.38197  0.190986;
      4.07692 4.05940  3.99256  3.72963  3.37543  3.00498  1.85532  1.26646  0.763397 0.545564 0.381953 0.190985;
      2.74983 2.73389  2.69368  2.56390  2.39884  2.22434  1.61821  1.20592  0.757637 0.54452  0.381786 0.190981;
      2.02267 2.01080  1.98331  1.90040  1.79834  1.69086  1.31175  1.04626  0.721165 0.535593 0.38018  0.190932;
      1.60630 1.59745  1.57723  1.51690  1.44276  1.36416  1.08036  0.878177 0.635443 0.496169 0.368548 0.190459;
      1.36230 1.35532  1.33934  1.29142  1.23203  1.16842  0.932812 0.759965 0.551349 0.435586 0.334279 0.186672;
      1.21727 1.21141  1.19792  1.15718  1.10624  1.05117  0.84292  0.686229 0.493924 0.387183 0.295972 0.172722;
      1.13038 1.12518  1.11316  1.07668  1.03073  0.980721 0.78879  0.641744 0.458699 0.356289 0.268907 0.154450;
      1.07814 1.07334  1.06221  1.02827  0.985314 0.938346 0.756309 0.615164 0.437743 0.337813 0.252327 0.140852];
    
    tau_lookup_imag = ...
      [27984.8   44628.5     55176.1   71754     86311.5   100062    152411    203623    305570    407436    560225    1069521;
      9816.33   14113.1     17448.2   22690.6   27294.1   31642.3   48196.5   64391.4   96629.7   128843    177159    338212;
      3482.47   4464.16     5517.72   7175.41   8631.15   10006.2   15241.1   20362.3   30557     40743.6   56022.5   106952;
      1252.66   1415.42     1745.17   2269.09   2729.42   3164.23   4819.65   6439.14   9662.97   12884.3   17715.9   33821.2;
      458.386   457.863     552.862   717.635   863.138   1000.63   1524.112  2036.23   3055.7    4074.36   5602.25   10695.2;
      171.397   160.951     177.702   227.205   273.013   316.449   481.967   643.915   966.297   1288.43   1771.59   3382.12;
      65.8679   62.2225     61.626    72.6542   86.5364   100.144   152.418   203.625   305.57    407.436   560.225   1069.52;
      26.2106   25.21       24.1432   24.7484   27.9459   31.8957   48.2199   64.3973   96.6308  128.843   177.159   338.212;
      10.8983   10.6158     10.1909   9.7009    9.91067   10.648    15.3139   20.381    30.5604   40.7448   56.0229   106.952;
      4.78389   4.69492     4.53952   4.24925   4.09701   4.09433   5.01844   6.49605   9.67379   12.8879   17.7171   33.8214;
      2.23883   2.20681     2.14583   2.0088    1.89659   1.82463   1.85993   2.17718   3.08849   4.08581   5.60598   10.6956;
      1.12164   1.10851     1.08208   1.01654   0.953355  0.901676  0.81464   0.844519  1.04394   1.32116   1.78306   3.38349;
      0.596697  0.590686    0.578118  0.545082  0.510467  0.479247  0.403803  0.383595  0.409256  0.469688  0.589749  1.07377;
      0.332285  0.329276    1.32283   0.305262  0.285953  0.26763   0.216732  0.194409  0.186218  0.195634  0.221631  0.349855;
      0.191043  0.189434    0.185931  0.176166  0.165118  0.154323  0.122124  0.105573  0.0938839 0.0925686 0.09682   0.126835;
      0.112082  0.111181    0.109199  0.103595  0.0971392 0.0907188 0.0707736 0.059728  0.0505049 0.0476557 0.0471326 0.0534759;
      0.0665172 0.0659974   0.0648471 0.0615627 0.0577366 0.0538889 0.0416384 0.0345727 0.0282418 0.025856  0.024611  0.0252877];

  end
  
  methods (Abstract)
    doping_profile(self)
    doping_optimization_scaling(self)
    doping_cantilever_from_state(self)
    doping_current_state(self)
    doping_initial_conditions_random(self)
    doping_optimization_bounds(self, parameter_constraints)    
  end
  
  methods
    
    function self = cantilever(freq_min, freq_max, l, w, t, l_pr_ratio, v_bridge, doping_type)
      self.freq_min = freq_min;
      self.freq_max = freq_max;
      self.l = l;
      self.w = w;
      self.t = t;
      self.l_pr_ratio = l_pr_ratio;
      self.v_bridge = v_bridge;
      self.doping_type = doping_type;
      
      % Default values
      self.fluid = 'air'; 
      self.cantilever_type = 'none';
      self.l_a = 0;
      self.t_a = 0;
      self.w_a = 0;
      self.tip_mass = 0;
      self.t_electrode = 50e-9;
      self.t_a_seed = 50e-9;
      self.number_of_piezoresistors = 2;
    end
    
    % Calculate the actual dimensions (getter functions)
    function l_pr = l_pr(self)
      l_pr = self.l * self.l_pr_ratio;
    end
    
    function w_pr = w_pr(self)
      w_pr = self.w/2;
    end
    
    % ==================================
    % ========= Pretty output ==========
    % ==================================
    
    function check_valid_cantilever(self)
      validity_checks(1) = 1;
      validity_checks(2) = ~(strcmp(self.cantilever_type, 'none') && (self.l_a > 0));
      [valid, failed_index] = min(validity_checks);
      
      if ~valid
        sprintf('ERROR: Invalid cantilever - failed check #%d', failed_index)
        pause
      end
    end
    
    % fprintf performance
    function print_performance(self)
      
      self.check_valid_cantilever();
      
      % Calculate intermediate quantities
      [omega_damped_hz, Q] = self.omega_damped_hz_and_Q();
      [x, doping] = self.doping_profile();
      Nz = trapz(x, doping*1e6);
      
      [TMax_approx TTip_approx] = self.approxTempRise();
      [TMax, TTip] = self.calculateMaxAndTipTemp();
      
      thermoLimit = self.thermo_integrated()/self.force_sensitivity();
      
      fprintf('Freq range: %f to %f \n', self.freq_min, self.freq_max)
      fprintf('Operating fluid: %s \n', self.fluid);
      fprintf('Cantilever L/W/T: %f %f %f \n', self.l*1e6, self.w*1e6, self.t*1e6)
      fprintf('PR L/W: %f %f %f \n', self.l_pr()*1e6, self.w_pr()*1e6)
      fprintf('PR Length Ratio: %g \n', self.l_pr_ratio)
      fprintf('Number of silicon resistors: %f \n', self.number_of_piezoresistors)
      fprintf('\n')
      fprintf('Force resolution (N): %g \n', self.force_resolution())
      fprintf('Displacement resolution (m): %g \n', self.displacement_resolution())
      fprintf('Force Sensitivity (V/N) %g \n', self.force_sensitivity())
      fprintf('Displacement Sensitivity (V/m) %g \n', self.displacement_sensitivity())
      fprintf('Beta %g \n', self.beta())
      fprintf('Thermomechanical force noise limit: %g \n', thermoLimit);
      fprintf('\n')
      fprintf('Stiffness (N/m): %g \n', self.stiffness())
      fprintf('Vacuum freq: %f \n', self.omega_vacuum_hz())
      fprintf('Damped freq: %f \n', omega_damped_hz)
      fprintf('Quality factor: %f \n', Q)
      fprintf('\n')
      fprintf('Wheatstone bridge bias voltage: %f \n', self.v_bridge)
      fprintf('Resistance: %f \n', self.resistance())
      fprintf('Sheet Resistance: %f \n', self.sheet_resistance())
      fprintf('Power dissipation (mW): %g \n', self.power_dissipation()*1e3)
      fprintf('Approx. Temp Rises (C) - Tip: %f  Max: %f\n', TTip_approx, TMax_approx)
      fprintf('F-D Temp Rises (C)     - Tip: %f  Max: %f\n', TTip, TMax)
      fprintf('\n')
      fprintf('Integrated noise (V): %g \n', self.integrated_noise())
      fprintf('Integrated johnson noise (V): %g \n', self.johnson_integrated())
      fprintf('Integrated 1/f noise (V): %g \n', self.hooge_integrated())
      fprintf('Amplifier noise (V): %g \n', self.amplifier_integrated())
      fprintf('Thermomechanical noise (V): %g \n', self.thermo_integrated())
      fprintf('\n')
      fprintf('Johnson/Hooge: %g \n', self.johnson_integrated()/self.hooge_integrated())
      fprintf('Knee frequency (Hz): %g \n', self.knee_frequency())
      fprintf('Number of Carriers: %g \n', self.number_of_carriers());
      fprintf('Nz: %g \n', Nz)
      fprintf('\n')
      fprintf('\n')
      
      switch self.cantilever_type
        case 'none'
          % Do nothing special
        case 'step'
          fprintf('Step at base (um): %f thick x %f long \n', 1e6*self.t_a, 1e6*self.l_a)
        case 'thermal'
          fprintf('Actuator l/W/T: %f %f %f \n', 1e6*self.l_a, 1e6*self.w_a, 1e6*self.t_a)
          fprintf('Neutral axis (um): %f \n', 1e6*self.actuatorNeutralAxis())          
          fprintf('Actuator Voltage (): %f \n', self.v_actuator)
          fprintf('Heater resistance (kOhm): %f \n', 1e-3*self.R_heater)
          fprintf('Actuator Power (mW): %f \n', 1e3*self.heaterPower())
          fprintf('Tip Deflection (nm): %f \n', 1e9*self.tipDeflection())
        case 'piezoelectric'
          fprintf('Actuator l/W/T: %f %f %f \n', 1e6*self.l_a, 1e6*self.w_a, 1e6*self.t_a)
          fprintf('Neutral axis (um): %f \n', 1e6*self.actuatorNeutralAxis())          
          fprintf('Actuator Voltage (): %f \n', self.v_actuator)
          fprintf('Tip Deflection (nm): %f \n', 1e9*self.tipDeflection())          
      end
        
    end
    
    function print_performance_for_excel(self, varargin)

      % varargin gets another set of {} from the cantilever subclasses
      varargin = varargin{1};
      optargin = size(varargin, 2);
      
      if optargin == 1
        fid = varargin{1};
      elseif optargin == 0
        fid = 1; % Print to the stdout
      else
        fprintf('ERROR: Extra optional arguments')
      end
      
      % Calculate intermediate quantities
      [omega_damped_hz, Q] = self.omega_damped_hz_and_Q();
      [TMax, TTip] = self.calculateMaxAndTipTemp();
      [TMax_approx TTip_approx] = self.approxTempRise();
      thermoLimit = self.thermo_integrated()/self.force_sensitivity();

      variables_to_print = [self.freq_min, self.freq_max*1e-3, ...
        1e6*self.l 1e6*self.w 1e9*self.t 1e6*self.l_pr() 1e6*self.l_a 1e6*self.w_a 1e9*self.t_a, ...
        self.force_resolution()*1e12, thermoLimit*1e12, self.displacement_resolution()*1e9, ...
        self.omega_vacuum_hz()*1e-3, omega_damped_hz*1e-3, Q, self.stiffness()*1e3, ...
        self.v_bridge, self.resistance()*1e-3, self.sheet_resistance(), self.power_dissipation()*1e6, ...
        TMax, TTip, TMax_approx, TTip_approx, ...
        self.number_of_piezoresistors, ...
        self.effective_mass(), self.tip_mass, ...
        self.force_sensitivity(), self.beta(), self.gamma(), ...
        self.integrated_noise()*1e6, self.johnson_integrated()*1e6, ...
        self.hooge_integrated()*1e6, self.amplifier_integrated()*1e6, ...
        self.thermo_integrated()*1e6, self.knee_frequency(), self.number_of_carriers()];

      fprintf(fid, '%s \t', self.doping_type);
      fprintf(fid, '%s\t', self.fluid);
      fprintf(fid, '%s\t', self.cantilever_type);
      for print_index = 1:length(variables_to_print)
        fprintf(fid, '%.4g \t', variables_to_print(print_index));
      end
    end
    
    % ==================================
    % ===== Calculate resistance =======
    % ==================================
    
    % Calculate total resistance of piezoresistor. Includes effect of other resistances (gamma)
    % Units: ohms
    function resistance = resistance(self)
      number_of_squares = self.resistor_length()/self.w_pr();
      resistance = number_of_squares * self.sheet_resistance();
    end
    
    % Calculate resistor length, used to calculat resistance and number of carriers
    % Units: m
    function resistor_length = resistor_length(self)
      resistor_length = 2*self.l_pr();
    end
    
    % Calculate sheet resistance. Uses abstract method self.doping_profile() - which must be defined in a subclass.
    % Units: ohms
    function Rs = sheet_resistance(self)
      [x, doping] = self.doping_profile(); % x -> m, doping -> N/cm^3
      conductivity = self.conductivity(doping); % ohm-cm
      Rs = 1/trapz(x*1e2, conductivity); % convert x to cm
    end
    
    % Calculate conductivity for a given dopant concentration. Can use vectors or single values.
    % Units: C/V-sec-cm
    function sigma = conductivity(self, dopant_concentration)
      mu = self.mobility(dopant_concentration);
      sigma = mu.*self.q.*dopant_concentration;
    end
    
    % Data from "Modeling of Carrier Mobility Against Carrier Concentration in Arsenic-,  Phosphorus-,
    % and Boron-Doped  Silicon", Masetti, Serveri and Solmi - IEEE Trans. on Electron Devices, (1983)
    % Units: cm^2/V-sec
    function mobility = mobility(self, dopant_concentration)
      
      n = dopant_concentration;
      p = dopant_concentration;
      
      switch self.doping_type
        case 'arsenic'
          % Arsenic data
          mu_0 = 52.2;
          mu_max = 1417;
          mu_1 = 43.4;
          C_r = 9.96e16;
          C_s = 3.43e20;
          mobility_alpha = 0.680;
          mobility_beta = 2.0;
          mobility = mu_0 + (mu_max - mu_0)./(1 + (n./C_r).^mobility_alpha) - mu_1./(1 + (C_s./n).^mobility_beta);
          
        case 'phosphorus'
          % Phosphorus data
          mu_0 = 68.5;
          mu_max = 1414;
          mu_1 = 56.1;
          C_r = 9.2e16;
          C_s = 3.41e20;
          mobility_alpha = 0.711;
          mobility_beta = 1.98;
          mobility = mu_0 + (mu_max - mu_0)./(1 + (n./C_r).^mobility_alpha) - mu_1./(1 + (C_s./n).^mobility_beta);
          
        case 'boron'
          % Boron data
          mu_0 = 44.9;
          mu_max = 470.5;
          mu_1 = 29.0;
          C_r = 2.23e17;
          C_s = 6.1e20;
          mobility_alpha = 0.719;
          mobility_beta = 2.00;
          p_c = 9.23e16;
          mobility = mu_0.*exp(-p_c./n) + mu_max./(1 + (p./C_r).^mobility_alpha) - mu_1./(1 + (C_s./p).^mobility_beta);
          
      end
    end
    
    % ==================================
    % ======= Calculate noise ==========
    % ==================================
    
    % The number of current carriers in the piezoresistor. Integrate the carries to the junction depth
    % and multiply by the lateral dimensions of the piezoresistor.
    % Units: unitless
    function number_of_carriers = number_of_carriers(self)
      [x, doping] = self.doping_profile(); % Units: x -> m, doping -> N/cm^3
      Nz = trapz(x, doping*1e6); % doping: N/cm^3 -> N/m^3
      number_of_carriers = Nz*self.resistor_length()*self.w_pr();
    end
    
    % 1/f voltage power spectral density for the entire Wheatstone bridge
    % Units: V^2/Hz
    function hooge_PSD = hooge_PSD(self, freq)
      hooge_PSD = self.alpha*self.v_bridge^2*self.number_of_piezoresistors./(4*self.number_of_carriers()*freq);
    end
    
    % Integrated 1/f noise density for the entire Wheatstone bridge
    % Unit: V
    function hooge_integrated = hooge_integrated(self)
      hooge_integrated = sqrt(self.alpha*self.v_bridge^2*self.number_of_piezoresistors./(4*self.number_of_carriers())*log(self.freq_max/self.freq_min));
    end
    
    % Johnson noise PSD from the entire Wheatstone bridge. Equal to that of a single resistor
    % assuming that all four resistors are equal.
    % Units: V^2/Hz
    function johnson_PSD = johnson_PSD(self, freq)
      R_external = 700;
      resistance = self.resistance()/self.gamma(); % Account for gamma - can't do it in resistance() else circular ref
      johnson_PSD = 4*self.k_b*self.T*(resistance/2 + R_external/2) * ones(1, length(freq));
    end
    
    % Integrated Johnson noise
    % Unit: V
    function johnson_integrated = johnson_integrated(self)
      R_external = 700;
      johnson_integrated = sqrt(4*self.k_b*self.T*(self.resistance()/2 + R_external/2)*(self.freq_max - self.freq_min));
    end
    
    % Thermomechanical noise PSD
    % Units: V^2/Hz
    function thermo_PSD = thermo_PSD(self, freq)
      [omega_damped_hz, Q_M] = self.omega_damped_hz_and_Q();
      thermo_PSD = (self.force_sensitivity())^2 * 2*self.stiffness()*self.k_b*self.T/(pi*omega_damped_hz*Q_M) * ones(1, length(freq));
    end
    
    % Integrated thermomechanical noise
    % Unit: V
    function thermo_integrated = thermo_integrated(self)
      [omega_damped_hz, Q_M] = self.omega_damped_hz_and_Q();
      thermo_integrated = sqrt((self.force_sensitivity())^2 * 2*self.stiffness()*self.k_b*self.T/(pi*omega_damped_hz*Q_M)*(self.freq_max - self.freq_min));
    end
    
    % Accounts for the noise of the actuator that the cantilever is mounted on
    % Units: V
    function actuator_noise_integrated = actuator_noise_integrated(self)
      actuator_noise_integrated = self.rms_actuator_displacement_noise*self.stiffness()*self.force_sensitivity(); % V
    end
    
    
    % Amplifier noise PSD
    % Units: V^2/Hz
    function amplifier_PSD = amplifier_PSD(self, freq)
      switch self.amplifier
        case 'INA103'
          A_VJ = 1.2e-9; % 1.2 nV/rtHz noise floor
          A_IJ = 2e-12; % 2 pA/rtHz noise floor
          A_VF = 6e-9; % 6 nV/rtHz @ 1 Hz
          A_IF = 25e-12; % 25 pA/rtHz @ 1 Hz
        case 'AD8221'
          A_VJ = 8e-9;
          A_IJ = 40e-15;
          A_VF = 12e-9;
          A_IF = 550e-15;
        otherwise
          fprintf('ERROR: UNKNOWN AMPLIFIER')
          pause
      end
      
      R_effective = self.resistance()/2; % resistance seen by amplifier inputs
      amplifier_PSD = (A_VJ^2 + 2*(R_effective*A_IJ)^2) + (A_VF^2 + 2*(R_effective*A_IF)^2)./freq;
    end
    
    % Integrated amplifier noise
    % Units: V
    function amplifier_integrated = amplifier_integrated(self)
      
      switch self.amplifier
        case 'INA103'
          A_VJ = 1.2e-9; % 1.2 nV/rtHz noise floor
          A_IJ = 2e-12; % 2 pA/rtHz noise floor
          A_VF = 6e-9; % 6 nV/rtHz @ 1 Hz
          A_IF = 25e-12; % 25 pA/rtHz @ 1 Hz
        case 'AD8221'
          A_VJ = 8e-9;
          A_IJ = 40e-15;
          A_VF = 12e-9;
          A_IF = 550e-15;
        otherwise
          fprintf('ERROR: UNKNOWN AMPLIFIER')
          pause
      end
      R_effective = self.resistance()/2; % resistance seen by amplifier inputs
      amplifier_integrated = sqrt(A_VJ^2*(self.freq_max - self.freq_min) + A_VF^2*log(self.freq_max/self.freq_min) + ...
        2*(R_effective*A_IJ)^2*(self.freq_max - self.freq_min) + 2*(R_effective*A_IF)^2*log(self.freq_max/self.freq_min));
    end
    
    % Calculate the knee frequency (equating the Hooge and Johnson noise)
    % Equating 1/f noise and johnson... numPRS*alpha*V_bridge^2/(4*N*f_knee) = 4*kb*T*R
    % Leads to f_knee = alpha*V_bridge^2/(16*N*S_j^2)
    % Units: Hz
    function knee_frequency = knee_frequency(self)
      knee_frequency = self.number_of_piezoresistors*self.alpha*self.v_bridge^2/(16*self.number_of_carriers()*self.k_b*self.T*self.resistance());
    end
    
    % Integrated cantilever noise for given bandwidth
    % Units: V
    function integrated_noise = integrated_noise(self)
      integrated_actuator_noise = self.actuator_noise_integrated();
      integrated_noise = sqrt(integrated_actuator_noise^2 + self.johnson_integrated()^2 + self.hooge_integrated()^2 + self.thermo_integrated()^2 + self.amplifier_integrated()^2);
    end
    
    % Calculate the noise in V/rtHz at a given frequency
    function voltage_noise = voltage_noise(self, freq)
      voltage_noise = sqrt(self.johnson_PSD(freq) + self.hooge_PSD(freq) + self.thermo_PSD(freq) + self.amplifier_PSD(freq));
    end
    
    function plot_noise_spectrum(self)
      freq = logspace( log10(self.freq_min), log10(self.freq_max), cantilever.numFrequencyPoints);
      
      figure
      hold all
      plot(freq, sqrt(self.johnson_PSD(freq)), 'LineWidth', 2);
      plot(freq, sqrt(self.hooge_PSD(freq)), 'LineWidth', 2);
      plot(freq, sqrt(self.thermo_PSD(freq)), 'LineWidth', 2);
      plot(freq, sqrt(self.amplifier_PSD(freq)), 'LineWidth', 2);
      plot(freq, self.voltage_noise(freq), 'LineWidth', 2);
      hold off
      set(gca, 'xscale','log', 'yscale','log');
      set(gca, 'LineWidth', 1.5, 'FontSize', 14);
      ylabel('Noise Voltage Spectral Density (V/rtHz)', 'FontSize', 16);
      xlabel('Frequency (Hz)', 'FontSize', 16);
      legend('Johnson', 'Hooge', 'Thermo', 'Amp', 'Total')
    end
    
    function f_min_cumulative = f_min_cumulative(self)
      frequency = logspace(log10(self.freq_min), log10(self.freq_max), cantilever.numFrequencyPoints);
      noise = self.voltage_noise(frequency);
      sensitivity = self.force_sensitivity();
      force_noise_density = noise./sensitivity;
      f_min_cumulative = sqrt(cumtrapz(frequency, force_noise_density.^2));
    end
    
    
    % ==================================
    % ===== Calculate sensitivity ======
    % ==================================
    
    
    % Piezoresistance factor. Accounts for dopant concentration dependent piezoresistivity in silicon
    % Uses Richter's 2008 model from "Piezoresistance in p-type silicon revisited" for the case of T=300K
    % Could be readily generalized to account for temperature as well
    function piezoresistance_factor = piezoresistance_factor(self, dopant_concentration)
      switch self.doping_type
        case 'boron' % Apply the boron fit to all dopant types for now
          Nb = 6e19;
          Nc = 7e20;
          richter_alpha = 0.43;
          richter_gamma = 1.6;
          piezoresistance_factor = (1 + (dopant_concentration/Nb).^richter_alpha + (dopant_concentration/Nc).^richter_gamma).^-1;
        case {'phosphorus', 'arsenic'}
	  a = 0.2330;
          b = 5.61e21;
	  piezoresistance_factor = log10((b./dopant_concentration).^a);
      end
    end
    
    function max_factor = max_piezoresistance_factor(self)
      switch self.doping_type
        case 'boron'
          max_factor = 72e-11; % Pi at low concentration in 110 direction
        case 'phosphorus'
          max_factor = 103e-11; %Pi at low concentration in 100 direction
        case 'arsenic'
          max_factor = 103e-11; %Pi at low concentration in 100 direction
      end
    end
    
    % Reduction in sensitivity from piezoresistor not located just at the surface.
    % Calculated for the general case of an arbitrarily shaped doping profile. Taken from Sung-Jin Park's Hilton Head 2008 paper.
    % Units: None
    function beta = beta(self)
      [x, doping_concentration] = self.doping_profile();
      
      % x is supposed to vary from t/2 to -t/2 as it varies from the top to bottom surface
      x = (self.t/2 - x)*1e2; % x: m -> cm
      
      mu = self.mobility(doping_concentration); % cm^2/V-s
      P = self.piezoresistance_factor(doping_concentration);
      
      numerator = trapz(x, self.q.*mu.*doping_concentration.*P.*x);
      denominator = trapz(x, self.q.*mu.*doping_concentration);
      beta = 2*numerator/(self.t*1e2*denominator); % t: m -> cm
      
      % Ensure that beta doesn't become too small or negative
      beta_epsilon = 1e-6;
      beta = max(beta, beta_epsilon);
    end
    
    % Ratio of piezoresistor resistance to total resistance (< 1)
    function gamma = gamma(self)
      fixed_resistance = 50; % Ohms - assume metal vias and contact resistance
      gamma = self.resistance()/(self.resistance() + fixed_resistance);
    end
    
    % Units: V/N
    % TODO: Account for the transverse current flow at the end of the cantilever
    function force_sensitivity = force_sensitivity(self)
      force_sensitivity = 3*(self.l - self.l_pr()/2)*self.max_piezoresistance_factor()/(2*self.w*self.t^2)*self.beta()*self.gamma()*self.v_bridge;
    end
    
    function displacement_sensitivity = displacement_sensitivity(self)
      displacement_sensitivity = self.force_sensitivity()*self.stiffness();
    end
    
    
    % ====================================
    % === Calculate thermal properties ===
    % ====================================
    
    % Power dissipation (W) in the cantilever
    function power_dissipation = power_dissipation(self)
      power_dissipation = (self.v_bridge/2)^2/self.resistance();
    end
    
    % Calculate the approximate max and tip temperatures using lumped modeling
    % This works significantly better than F-D for design optimization
    % Units: K
    function [TMax TTip] = approxTempRise(self)
      
      switch self.fluid
        case 'vacuum'
          h = self.h_vacuum;
        case 'air'
          h = self.h_air;
        case 'water'
          h = self.h_water;
      end
      
      % Model the system as current sources (PR or heater) and resistors
      switch self.cantilever_type
        case 'none'
          R_conduction_pr  = self.l_pr()/(2*self.w*self.t*self.k_si);
          R_convection_pr = 1/(2*h*self.l_pr()*(self.w + self.t));
          R_conduction_tip  = (self.l - self.l_pr())/(2*self.w*self.t*self.k_si);          
          R_convection_tip = 1/(2*h*(self.l-self.l_pr())*(self.w + self.t));
          
          R_total = 1/(1/R_conduction_pr + 1/R_convection_pr + 1/(R_conduction_tip + R_convection_tip));

          TMax = self.power_dissipation()*R_total;
          TTip = self.power_dissipation()*R_total/(R_conduction_tip + R_convection_tip)*R_convection_tip;
          
        case 'step'
          R_conduction_pr  = self.l_pr()/(2*self.w*self.t*self.k_si) + self.l_a/(self.w_a*(self.t*self.k_si + self.t_a*self.k_al));
          R_convection_pr = 1/(2*h*(self.l_pr()+self.l_a)*(self.w + self.t));
          R_conduction_tip  = (self.l - self.l_pr())/(2*self.w*self.t*self.k_si);          
          R_convection_tip = 1/(2*h*(self.l-self.l_pr())*(self.w + self.t));
          
          R_total = 1/(1/R_conduction_pr + 1/R_convection_pr + 1/(R_conduction_tip + R_convection_tip));
          
          TMax = self.power_dissipation()*R_total;
          TTip = self.power_dissipation()*R_total/(R_conduction_tip + R_convection_tip)*R_convection_tip;
        case 'piezoelectric'
          R_conduction_pr  = self.l_pr()/(2*self.w*self.t*self.k_si) + self.l_a/(self.w_a*(self.k_si*self.t + self.k_aln*(self.t_a + self.t_a_seed) + 2*self.k_ti*self.t_electrode));
          R_convection_pr = 1/(2*h*self.l_pr()*(self.w + self.t));
          R_conduction_tip  = (self.l - self.l_pr())/(2*self.w*self.t*self.k_si);          
          R_convection_tip = 1/(2*h*(self.l-self.l_pr())*(self.w + self.t));

          R_total = 1/(1/R_conduction_pr + 1/R_convection_pr + 1/(R_conduction_tip + R_convection_tip));
          
          TMax = self.power_dissipation()*R_total;
          TTip = self.power_dissipation()*R_total/(R_conduction_tip + R_convection_tip)*R_convection_tip;
        case 'thermal'
          R_conduction_pr  = self.l_pr()/(2*self.w*self.t*self.k_si) + self.l_a/(self.w_a*(self.t*self.k_si + self.t_a*self.k_al));
          R_convection_pr = 1/(2*h*self.l_pr()*(self.w + self.t));
          R_conduction_tip  = (self.l - self.l_pr())/(2*self.w*self.t*self.k_si);          
          R_convection_tip = 1/(2*h*(self.l-self.l_pr())*(self.w + self.t));
          R_conduction_heater = self.l_a/(2*self.w_a*(self.t*self.k_si + self.t_a*self.k_al));
          R_convection_heater = 1/(2*h*self.l_a*(self.w_a + self.t_a));

          T_heater = self.heaterPower()/(1/R_convection_heater + 1/R_conduction_heater);
          
          R_total = 1/(1/(R_conduction_pr + 1/(1/R_convection_heater + 1/R_conduction_heater)) + 1/R_convection_pr + 1/(R_conduction_tip + R_convection_tip));

          TMaxDivider = 1/(1/R_convection_pr + 1/(R_conduction_tip + R_convection_tip)) / (R_conduction_pr + 1/(1/R_convection_pr + 1/(R_conduction_tip + R_convection_tip)));
          TTipDivider = R_convection_tip/(R_convection_tip + R_conduction_tip);
          
          TMax = T_heater*TMaxDivider + self.power_dissipation()*R_total;
          
          TTip = T_heater*TMaxDivider*TTipDivider + self.power_dissipation()*R_total/(R_conduction_tip + R_convection_tip)*R_convection_tip;
      end
    end
    
    % Model the temperature profile of a self-heated PR cantilever
    % - Assumes fixed temperature at the cantilever base, and adiabatic conditions at the tip, convection to ambient
    % - There is significant uncertainty in the convection coefficient
    
    % References used
    % - Finite differences: http://reference.wolfram.com/mathematica/tutorial/NDSolvePDE.html
    % - 1D Conduction Analysis: http://people.sc.fsu.edu/~burkardt/f_src/fd1d_heat_steady/fd1d_heat_steady.html
    function [x, T] = calculateTempProfile(self)
      n_points = self.numXPoints;
      totalLength = self.l + self.l_a;
      dx = totalLength/(n_points - 1);
      x = 0:dx:totalLength;
      power = (self.v_bridge/2)^2/self.resistance();
      Qgen = power/self.l_pr();
      perimeter = 2*(self.w + self.t);
      
      tempBase    = cantilever.T;
      tempAmbient = cantilever.T;
      
      % Choose the convection coefficient based upon the ambient fluid
      switch self.fluid
        case 'vacuum'
          h = self.h_vacuum;
        case 'air'
          h = self.h_air;
        case 'water'
          h = self.h_water;
      end

      % Determine the step and PR indices
      actuator_indices = find(x < self.l_a);
      cantilever_indices = find(x >= self.l_a);
      pr_indices = intersect(cantilever_indices, find(x <= self.l_a + self.l_pr()));
      
      % Build lookup vectors to find the thermal conductivity and heat generation terms
      K = self.w*self.k_si*self.t*ones(n_points, 1); % Initialize to a plain cantilever
      Q = zeros(n_points, 1);
      
      Q(pr_indices) = Qgen;
      switch self.cantilever_type
        case 'none'
        case 'step'
          K(actuator_indices) = self.w_a*(self.k_si*self.t + self.k_al*self.t_a);
        case 'thermal'
          Qheater = self.heaterPower()/self.l_a;
          Q(actuator_indices) = Qheater;
          K(actuator_indices) = self.w_a*(self.k_si*self.t + self.k_al*self.t_a);
        case 'piezoelectric'
          K(actuator_indices) = self.w_a*(self.k_si*self.t + self.k_aln*(self.t_a + self.t_a_seed) + 2*self.k_ti*self.t_electrode);          
      end
      
      % Build A and RHS
      A = zeros(n_points, n_points);
      rhs = zeros(n_points, 1);
      for ii = 2:n_points-1
        A(ii, ii-1) = -K(ii-1)/dx^2;
        A(ii, ii)   = (K(ii-1) + K(ii+1))/dx^2 + h*perimeter;
        A(ii, ii+1) = -K(ii+1)/dx^2;
        rhs(ii, 1) = Q(ii) + h*perimeter*tempAmbient;
      end
      A(1, 1) = 1; % Fixed temp at base
      rhs(1,1) = tempBase;      
      A(n_points, n_points-1:n_points) = [1 -1]; % Adiabatic at tip
      A = sparse(A); % Leads to a significant speed improvement
      
      % Solve and then return the temp rise relative to ambient
      T = A \ rhs;
      T = T - tempAmbient;
    end
    
    function plotTempProfile(self)
      [x, temp] = self.calculateTempProfile();
      figure
      plot(1e6*x, temp);
      xlabel('X (um)');
      ylabel('Temp Rise (K)');
    end
    
    function [TMax, TTip] = calculateMaxAndTipTemp(self)
      [tmp, temp] = self.calculateTempProfile();
      TMax = max(temp);
      TTip = temp(end);
    end
    
    % ==================================
    % ====== Calculate resolution ======
    % ==================================
    
    % Units: N
    function force_resolution = force_resolution(self)
      force_resolution = self.integrated_noise()/self.force_sensitivity();
    end
    
    function displacement_resolution = displacement_resolution(self)
      displacement_resolution = self.force_resolution()/self.stiffness();
    end
    
    % ==================================
    % ====== Multilayer beam mechanics and actuation ======
    % ==================================
    
  function Cm = calculateActuatorNormalizedCurvature(self)
    Zm = self.actuatorNeutralAxis();
    [z, E, A, I] = self.lookupActuatorMechanics();
    Z_offset = z - Zm;
    Cm = 1./sum(E.*(I + A.*Z_offset.^2));
  end
  
  function [z_layers, E_layers, A, I] = lookupActuatorMechanics(self)
      switch self.cantilever_type
        case 'none'
          fprintf('ERROR: No step')
        case {'step', 'thermal'}
          t_layers = [self.t self.t_a];
          w_layers = [self.w_a self.w_a];
          E_layers = [self.modulus() self.E_Al];
        case 'piezoelectric'
          t_layers = [self.t self.t_electrode self.t_a self.t_electrode];
          w_layers = [self.w_a self.w_a self.w_a self.w_a];
          E_layers = [self.modulus() self.E_Ti self.E_AlN self.E_Ti];
      end
      
      z_layers = zeros(1, length(t_layers));
      for ii = 1:length(t_layers)
        z_layers(ii) = sum(t_layers) - sum(t_layers(ii:end)) + t_layers(ii)/2; % z(1) = t(1)/2, z(2) = t(1) + t(2)/2
      end
      A = w_layers.*t_layers;
      I = (w_layers.*t_layers.^3)/12;
  end
    
  function Zm = actuatorNeutralAxis(self)
    [z, E, A, I] = self.lookupActuatorMechanics();
    Zm = sum(z.*E.*A)/sum(E.*A);
  end
  
  
  function [x, deflection] = calculateDeflection(self)
    n_points = self.numXPoints;
    totalLength = self.l + self.l_a;
    dx = totalLength/(n_points - 1);
    x = 0:dx:totalLength;
    
    M = 0; % external moment is zero
    P = 0; % external load is zero
    
    [z, E, A, I] = self.lookupActuatorMechanics();
    stress = self.calculateActuatorStress();
    
    % Calculate the curvature and neutral axis
    % The curvature may vary as a function of position (especially for thermal actuation), so calculate the
    % deflection by calculating the angle (from the curvature) and numerically integrating.
    C = zeros(length(x), 1);
    Zn = self.t/2*ones(length(x), 1); % At centroid by default
    
    % Calculate the curvature, C, and the neutral axis, Zn, along the cantilever length
    for ii = 1:length(x)
      if x(ii) <= self.l_a
        C(ii) = ((M - sum(z.*A.*stress(ii,:)))*sum(E.*A) + (P + sum(A.*stress(ii,:)))*sum(E.*z.*A))/ ...
          (sum(E.*A)*sum(E.*(I+A.*z.^2)) - sum(z.*E.*A)^2);
        Zn(ii) = ((M - sum(z.*A.*stress(ii,:)))*sum(z.*E.*A) + (P + sum(A.*stress(ii,:)))*sum(E.*(I + A.*z.^2)))/ ...
          ((M - sum(z.*A.*stress(ii,:)))*sum(E.*A) + (P + sum(A.*stress(ii,:)))*sum(E.*z.*A));
      end
    end
    
    theta = cumsum(C.*dx);
    deflection = cumsum(theta.*dx);
  end
  
  function strain = calculateActuatorStress(self)
    [z, E, A, I] = self.lookupActuatorMechanics();
    switch self.cantilever_type
      case 'thermal'
        [x_temp, temp] = self.calculateTempProfile();
        cte = [self.alpha_si self.alpha_al];
        strain = temp*(E.*cte); % size(x) by size(alpha) e.g. 500 x 3 in size
      case 'piezoelectric'
        E_field = [0 0 self.v_actuator/self.t_a 0]'; % Field from bottom to top
        d31 = [0 0 self.d31_aln 0]';
        strain = ones(self.numXPoints,1)*(E.*d31'.*E_field'); % size(x) by size(d31) e.g. 500 x 4 in size
    end
  end
  
    function power = heaterPower(self)
      power = self.v_actuator^2/self.R_heater;
    end
    
    function current = heaterCurrent(self)
      current = self.v_actuator/self.R_heater;
    end
    
    function z_tip = tipDeflection(self)
      [x, z] = self.calculateDeflection();
      z_tip = max(abs(z));
    end
    
    function plotDeflectionAndTemp(self)
      [x, deflection] = self.calculateDeflection();
      [x, temp] = self.calculateTempProfile();
      
      figure
      subplot(2,1,1);
      plot(1e6*x, temp);
      xlabel('Distance from Base (um)');
      ylabel('Temp Rise (K)');
      box off;
      ylim([0 20])
      
%       ylim([min(temp) max(temp)])

      subplot(2,1,2);
      plot(1e6*x, 1e9*deflection);
      xlabel('Distance from Base (um)');
      ylabel('Cantilever Deflection (nm)');
      box off;
      ylim([-1000 0])
%       ylim(1e9*[min(deflection) max(deflection)])
    end
    

    
  
  
    % ==================================
    % ======== Beam mechanics ==========
    % ==================================
    
    % Calculate elastic modulus based upon dopant type. Assume we're using the best piezoresistor orientation.
    function elastic_modulus = modulus(self)
      switch self.doping_type
        case 'boron'
          elastic_modulus = 169e9; % <110> direction
        case 'phosphorus'
          elastic_modulus = 130e9; % <100> direction
        case 'arsenic'
          elastic_modulus = 130e9; % <100> direction
      end
    end
    
    % Bending stiffness of the cantilever to a point load at the tip
    % Units: N/m
    function stiffness = stiffness(self)
      k_tip = self.modulus() * self.w * self.t^3 / (4*self.l^3);
      
      % If there is an actuator/reinforcement step at the base, model as two springs in series
      switch self.cantilever_type
        case 'none'
          stiffness = k_tip;
        otherwise
          Cm_base = self.calculateActuatorNormalizedCurvature();
          k_base = 3/(Cm_base*self.l_a^3);
          stiffness = 1/(1/k_base + 1/k_tip);
      end
    end
        
    function effective_mass = effective_mass(self)
      cantilever_effective_mass = 0.243 * self.rho_Si * self.w * self.t * self.l;
      
      % Accounts for the lower curvature of the base vs. the cantilever
      base_mass = 0;
      Cm_tip = 12/(self.modulus()*self.w*self.t^3);
      
      switch self.cantilever_type
        case 'none'
        case {'step', 'thermal'}
          Cm_base = self.calculateActuatorNormalizedCurvature();
          correctionFactor = self.l_a/self.l*sqrt(2*self.t/self.t_a)*Cm_base/Cm_tip;
          base_mass = correctionFactor*self.w_a*self.l_a*(self.rho_Si*self.t + self.rho_Al*self.t_a);          
        case 'piezoelectric'
          Cm_base = self.calculateActuatorNormalizedCurvature();
          correctionFactor = self.l_a/self.l*sqrt(2*self.t/self.t_a)*Cm_base/Cm_tip;
          base_mass = correctionFactor*self.w_a*self.l_a*(self.rho_Si*self.t + 2*self.rho_Ti*self.t_electrode + ...
            self.rho_AlN*self.t_a + self.rho_AlN*self.t_a_seed);          
      end
      
      effective_mass = cantilever_effective_mass + base_mass + self.tip_mass;
    end
    
    function [rho_fluid, eta_fluid] = lookupFluidProperties(self)
      switch self.fluid
        case 'air'
          rho_fluid = self.rho_air;
          eta_fluid = self.eta_air;
        case 'water'
          rho_fluid = self.rho_water;
          eta_fluid = self.eta_water;
        otherwise
          fprintf('ERROR - Unknown fluid: %s', self.fluid);
          pause
      end
    end
    
    % Resonant frequency for undamped vibration (first mode)
    % Units: radians/sec
    function omega_vacuum = omega_vacuum(self)
      omega_vacuum = sqrt( self.stiffness() / self.effective_mass());
    end
    
    % Resonant frequency for undamped vibration (first mode)
    % Units: cycles/sec
    function omega_vacuum_hz = omega_vacuum_hz(self)
      omega_vacuum_hz = self.omega_vacuum() / (2*pi);
    end
    
    % Calculate the damped natural frequency and Q, which we know lies between zero and the natural frequency in vacuum.
    % Per Eysden and Sader (2007)
    function [omega_damped, Q] = omega_damped_and_Q(self)
      
      % If we're in vacuum, just return the vacuum frequency
      switch self.fluid
        case 'vacuum'
          omega_damped = self.omega_vacuum();
          Q = cantilever.maxQ;
          return;
      end
      
      % Inner function for solving the transcendental equation to find omega_damped
      % We're searching for a function minimum, so return the residual squared (continuous and smooth)
      function residual_squared = find_natural_frequency(omega_damped)
        hydro = self.hydrodynamic_function(omega_damped, rho_f, eta_f);
        residual = omega_damped - omega_vacuum*(1 + pi * rho_f * self.w/(4 * self.rho_Si * self.t) .* real(hydro)).^-0.5;
        residual_squared = residual^2;
      end
      
      % Lookup fluid properties once, then calculate omega_damped and Q
      [rho_f eta_f] = self.lookupFluidProperties();
      omega_vacuum = self.omega_vacuum();
      options = optimset('TolX', 10, 'TolFun', 1e-4, 'Display', 'off');
      omega_damped = fminbnd(@find_natural_frequency, 0, self.omega_vacuum(), options);
      
      hydro = self.hydrodynamic_function(omega_damped, rho_f, eta_f);
      Q = (4 * self.rho_Si * self.t / (pi * rho_f * self.w) + real(hydro)) / imag(hydro);

      % Sometimes our initial guess will turn up Q = NaN because it's outside the bounds of the interpolation
      % Usually this is because the cantilever is shorter than it is wide, and it will be fixed after
      % a few iterations
      if Q < cantilever.minQ || isnan(Q)
        Q = cantilever.minQ;
      elseif Q > cantilever.maxQ
        Q = cantilever.maxQ;
      end
    end
    
    function [omega_damped_hz, Q] = omega_damped_hz_and_Q(self)
      [omega_damped, Q] = self.omega_damped_and_Q();
      omega_damped_hz =  omega_damped/(2*pi);
    end
    
    % Calculate the quality factor for a given cantilever design assuming atmospheric pressure in air
    % Implemented per "Dependence of the quality factor of micromachined silicon beam resonators on pressure and geometry" by Blom (1992)
    % Is faster to calculate than Sader's
    function Q = calculateBlomQ(self)
      if strcmp(self.fluid, 'vacuum')
        Q = cantilever.maxQ;
        return;
      end
      
      [rho_f eta_f] = self.lookupFluidProperties();
      k_0 = 1.875; % first resonant mode factor
      omega_0 = self.omega_vacuum();
      R = sqrt(self.w*self.l/pi); % effective sphere radius
      delta = sqrt(2*eta_f/rho_f/omega_0); % boundary layer thickness
      
      Q = k_0^2/(12*pi*sqrt(3))*sqrt(self.rho_Si*self.modulus())*self.w*self.t^2/(self.l*R*(1+R/delta)*eta_f);
      Q = min(Q, cantilever.maxQ);
    end
    
    % Calculate the Reynold's number
    function reynolds = reynolds(self, omega, rho_f, eta_f)
      reynolds = (rho_f*omega*self.w^2)/eta_f;
    end
    
    % Calculate kappa for the first mode
    function kappa = kappa(self)
      C = 1.8751; % For the first resonant mode. Higher modes can be found by solving 1+cos(x)*cosh(x) = 0
      kappa = C * self.w / self.l;
    end
    
    % Calculate the hydrodynamic function for the inviscid case (Re >> 1)
    % Not generally useful, but included for completeness.
    % From "Resonant frequencies of a rectangular cantilever beam immersed in a fluid", Sader (2006)
    function hydro = hydrodynamic_function_inviscid(self)
      kappa = self.kappa();
      hydro = (1 + 0.74273*kappa + 0.14862*kappa^2)/(1 + 0.74273*kappa + 0.35004*kappa^2 + 0.058364*kappa^3);
    end
    
    % Calculate hydrodynamic function from the lookup table provided in Eysden and Sader (2007)
    function hydro = hydrodynamic_function(self, omega, rho_f, eta_f)
      
      % Calculate Re and kappa
      kappa = self.kappa();
      reynolds = self.reynolds(omega, rho_f, eta_f);
      log_reynolds = log10(reynolds);
      
      % Lookup the tau components
      tau_real = interp2(cantilever.kappa_lookup, cantilever.reynolds_lookup, cantilever.tau_lookup_real, kappa, log_reynolds, 'linear');
      tau_imag = interp2(cantilever.kappa_lookup, cantilever.reynolds_lookup, cantilever.tau_lookup_imag, kappa, log_reynolds, 'linear');
      
      hydro = complex(tau_real, tau_imag);
    end
    
    % ==================================
    % ======= Simulate response  =======
    % ==================================
    
    
    function [t, voltageNoise] = calculateSimulinkNoise(self, tMax, Fs)
      t = 0:1/Fs:tMax;

      % Calculate the voltage noise parameters
      whiteNoiseSigma = self.voltage_noise(self.freq_max);
      fCorner = self.knee_frequency();
      nyquistFreq = Fs/2;
      overSampleRatio = nyquistFreq/self.freq_max;

      % Generate voltage noise that matches the calculated spectrum
      bandwidth = self.freq_max - self.freq_min;
      whiteNoise = sqrt(bandwidth)*whiteNoiseSigma*randn(size(t))*sqrt(overSampleRatio);
      totalNoise = whiteNoise; % So that the RMS noise matches what I expect
      forceNoise = totalNoise/self.force_sensitivity();

      % For generating 1/f^2 noise
      % pinkNoise = 2*pi*cumsum(whiteNoise_forPink)*fCorner*sqrt(whiteNoiseSigma)/overSampleRatio;
      
      voltageNoise = [t' totalNoise'];
      
      % For checking that the numbers make sense
%       rmsVoltageNoise = sqrt(mean(totalNoise.^2))
%       expectedRmsVoltageNoise = whiteNoiseSigma*sqrt(nyquistFreq)
%       
%       rmsForceNoise = sqrt(mean(forceNoise.^2))
%       expectedRmsForceNoise = self.force_resolution()
%       pause
%       
%       figure
%       plot(t, 1e3*totalNoise)
%       xlabel('Time (s)');
%       ylabel('Output Referred Voltage Noise (mV)');
%       
%       figure
%       plot(t, 1e12*totalNoise/self.force_sensitivity())
%       xlabel('Time (s)');
%       ylabel('Output Referred Force Noise (pN)');
    end
    
    function [tSim, inputForce, actualForce, sensorForce] = simulateForceStep(self, tMax, Fs, forceMagnitude, forceDelay, forceHold)
      [time, inputNoise] = self.calculateSimulinkNoise(tMax, Fs);
      
      % Generate the force
      forceSignal = zeros(length(time), 1);
      forceSignal(find(time>forceDelay,1):find(time>forceDelay+forceHold,1)) = forceMagnitude;
      inputForce = [time' forceSignal];

      % Define the parameters
      [omega_damped Q] = self.omega_damped_and_Q();
      SFpr = self.force_sensitivity();
      k = self.stiffness();      
      m = k/omega_damped^2;
      b = k/omega_damped/Q;

      % Amplifier
      Kamp = 1e3;
      Famp = 800e3; % Hz
      Tamp = 1/(2*pi*Famp);
      Sfv = SFpr*Kamp;
      
      % Filters
      Tlowpass = 1/(2*pi*self.freq_max);
      Thighpass = 1/(2*pi*self.freq_min);
      
      options = simset('FixedStep', 1/Fs, 'SrcWorkspace', 'current');
      tSim = sim('sensorSimulation', tMax, options);
      
    end

    function simulateAndPlotForceStep(self, tMax, Fs, forceMagnitude, forceDelay, forceHold)
      [tSim, inputForce, actualForce, sensorForce] = self.simulateForceStep(tMax, Fs, forceMagnitude, forceDelay, forceHold);
      
      figure
      hold all
      plot(tSim*1e6, 1e12*inputForce(:,2)); % work from inputVoltage rather than inputForce due to diff in time
      plot(tSim*1e6, 1e12*actualForce);
      plot(tSim*1e6, 1e12*sensorForce);
      hold off
      xlabel('Time (microseconds)');
      ylabel('Output (pN)');
      legend_strings = {'Applied Force', 'Cantilever Response', 'Sensor Response'};
      legend(legend_strings, 'FontSize', 14, 'Location', 'Best')      
    end
    
    function simulateAndPlotMultipleForceSteps(self, tMax, Fs, forceMagnitude, forceDelay, forceHold, numSims)

      rms_mdf = self.force_resolution();
      pp_mdf = 3*rms_mdf;
      
      figure
      hold all

      % Do an initial simulation to find the expected trajectory
      [tSim, tmp, actualForce, tmp] = self.simulateForceStep(tMax, Fs, forceMagnitude, forceDelay, forceHold);
      
      % Fill in the grey background and draw the black nominal force line
      x = 1e6*[tSim ; flipud(tSim)];
      y = 1e12*[actualForce+pp_mdf ; flipud(actualForce-pp_mdf)];
      patch(x, y, [.9 .9 .9], 'EdgeColor', 'none')

      x = 1e6*[tSim ; flipud(tSim)];
      y = 1e12*[actualForce+rms_mdf ; flipud(actualForce-rms_mdf)];
      patch(x, y, [.6 .6 .6], 'EdgeColor', 'none')      
      
      % Do the simulations and plot
      colorBase = [11/255 132/255 199/255];
      for ii = 1:numSims
        randomColor = randn(1,3)*0.2;
        color = colorBase + randomColor;
        color(color>1) = 1;
        color(color<0) = 0;
        
        [tSim, tmp, actualForce, sensorForce] = self.simulateForceStep(tMax, Fs, forceMagnitude, forceDelay, forceHold);
        sensorForceAll(:, ii) = sensorForce;
        plot(1e6*tSim, 1e12*sensorForce, 'Color', color)
      end
      plot(1e6*tSim, 1e12*actualForce, '-', 'Color', [0 0 0], 'LineWidth', 3);      
      hold off
      xlabel('Time (microseconds)');
      ylabel('Output (pN)');
      
      averageSensorForce = mean(sensorForceAll, 2);
      figure
      hold all;
      plot(1e6*tSim, 1e12*actualForce, '-', 'Color', [0 0 0], 'LineWidth', 3);            
      plot(1e6*tSim, 1e12*averageSensorForce, '-', 'Color', [.5 .5 .5], 'LineWidth', 2);      
      hold off
      xlabel('Time (microseconds)');
      ylabel('Output (pN)');
    end
    
    function simulateAndPlotMultipleForceNoise(self, tMax, Fs, numSims)
      self.simulateAndPlotMultipleForceSteps(tMax, Fs, 0, 0, 0, numSims);
    end
    
    
    % ==================================
    % ========= Optimization  ==========
    % ==================================
    
    % Calculate force resolution from the cantilever state variable vector
    % Units: pN
    function force_resolution = optimize_force_resolution(self, x0)
      self = self.cantilever_from_state(x0);
      force_resolution = self.force_resolution()*1e12;
    end
    
    % Calculate displacement resolution from the cantilever state variable vector
    % Units: nm
    function displacement_resolution = optimize_displacement_resolution(self, x0)
      self = self.cantilever_from_state(x0);
      displacement_resolution = self.displacement_resolution()*1e9;
    end
    
    
    % Used by optimization to bring all state varibles to O(1)
    function scaling = optimization_scaling(self)
      l_scale = 1e6;
      w_scale = 1e6;
      t_scale = 1e9;
      l_pr_ratio_scale = 10;
      v_bridge_scale = 1;
      
      scaling = [l_scale, w_scale, t_scale, l_pr_ratio_scale, v_bridge_scale, self.doping_optimization_scaling()];
      
      % Actuator specific code
      switch self.cantilever_type
        case 'step'
          % Do nothing special
        case 'thermal'
          l_a_scale = 1e6;
          w_a_scale = 1e6;
          t_a_scale = 1e9;
          v_actuator_scale = 1;
          R_heater_scale = 1e-3;
          scaling = [scaling l_a_scale w_a_scale t_a_scale v_actuator_scale R_heater_scale];
        case 'piezoelectric'
          l_a_scale = 1e6;
          w_a_scale = 1e6;
          t_a_scale = 1e9;
          v_actuator_scale = 1;
          scaling = [scaling l_a_scale w_a_scale t_a_scale v_actuator_scale];
      end
    end
    
    % Update the changed optimization parameters
    % All optimization takes place for the same object (i.e. we update 'self') so things like 'fluid' are maintained
    function self = cantilever_from_state(self, x0)
      scaling = self.optimization_scaling();
      x0 = x0 ./ scaling;
      
      self.l = x0(1);
      self.w = x0(2);
      self.t = x0(3);
      self.l_pr_ratio = x0(4);
      self.v_bridge = x0(5);
      
      self = self.doping_cantilever_from_state(x0);
      
      % Actuator specific code
      switch self.cantilever_type
        case 'step'
          % Do nothing special
        case 'thermal'
          self.l_a = x0(8);
          self.w_a = x0(9);
          self.t_a = x0(10);
          self.v_actuator = x0(11);
          self.R_heater = x0(12);
        case 'piezoelectric'
          self.l_a = x0(8);
          self.w_a = x0(9);
          self.t_a = x0(10);
          self.v_actuator = x0(11);
      end
    end
    
    % Return state vector for the current state
    function x = current_state(self)
      x(1) = self.l;
      x(2) = self.w;
      x(3) = self.t;
      x(4) = self.l_pr_ratio;
      x(5) = self.v_bridge;
      
      self.doping_current_state()
      x = [x self.doping_current_state()];
      
      % Actuator specific code
      switch self.cantilever_type
        case 'step'
          % Do nothing special
        case 'thermal'
          x(8) = self.l_a;
          x(9) = self.w_a;
          x(10) = self.t_a;
          x(11) = self.v_actuator;
          x(12) = self.R_heater;
        case 'piezoelectric'
          x(8) = self.l_a;
          x(9) = self.w_a;
          x(10) = self.t_a;
          x(11) = self.v_actuator;
      end
    end
    
    % Set the minimum and maximum bounds for the cantilever state variables.
    % Bounds are written in terms of the initialization variables.
    % Secondary constraints (e.g. power dissipation, resonant frequency) are applied in optimization_constraints()
    function [lb ub] = optimization_bounds(self, parameter_constraints)
      
      min_l = 10e-6;
      max_l = 2e-3;
      
      min_w = 2e-6;
      max_w = 20e-6;
      
      min_t = 1e-6;
      max_t = 10e-6;
      
      min_l_pr_ratio = 0.01;
      max_l_pr_ratio = 0.99;
      
      min_v_bridge = 0.1;
      max_v_bridge = 10;
      
      [doping_lb doping_ub] = self.doping_optimization_bounds(parameter_constraints);
      
      actuator_lb = [];
      actuator_ub = [];
      % Actuator specific code
      switch self.cantilever_type
        case {'step', 'none'}
          % Override the default values if any were provided
          % constraints is a set of key value pairs, e.g.
          % constraints = {{'min_l', 'max_v_bridge'}, {5e-6, 10}}
          if ~isempty(parameter_constraints)
            keys = parameter_constraints{1};
            values = parameter_constraints{2};
            for ii = 1:length(keys)
              eval([keys{ii} '=' num2str(values{ii}) ';']);
            end
          end
        case 'thermal'
          min_l_a = 5e-6;
          max_l_a = 200e-6;
          
          min_w_a = 2e-6;
          max_w_a = 50e-6;
          
          min_t_a = 200e-9;
          max_t_a = 3e-6;
          
          min_v_actuator = .1;
          max_v_actuator = 10;
          
          min_R_heater = 200;
          max_R_heater = 5e3;

          % Override the default values if any were provided
          % constraints is a set of key value pairs, e.g.
          % constraints = {{'min_l', 'max_v_bridge'}, {5e-6, 10}}
          if ~isempty(parameter_constraints)
            keys = parameter_constraints{1};
            values = parameter_constraints{2};
            for ii = 1:length(keys)
              eval([keys{ii} '=' num2str(values{ii}) ';']);
            end
          end
          
          actuator_lb = [min_l_a min_w_a min_t_a min_v_actuator min_R_heater];
          actuator_ub = [max_l_a max_w_a max_t_a max_v_actuator max_R_heater];
        case 'piezoelectric'
          min_l_a = 5e-6;
          max_l_a = 200e-6;
          
          min_w_a = 2e-6;
          max_w_a = 30e-6;
          
          min_t_a = 200e-9;
          max_t_a = 3e-6;
          
          min_v_actuator = .1;
          max_v_actuator = 10;

          % Override the default values if any were provided
          % constraints is a set of key value pairs, e.g.
          % constraints = {{'min_l', 'max_v_bridge'}, {5e-6, 10}}
          if ~isempty(parameter_constraints)
            keys = parameter_constraints{1};
            values = parameter_constraints{2};
            for ii = 1:length(keys)
              eval([keys{ii} '=' num2str(values{ii}) ';']);
            end
          end
          
          actuator_lb = [min_l_a min_w_a min_t_a min_v_actuator];
          actuator_ub = [max_l_a max_w_a max_t_a max_v_actuator];
      end

      lb = [min_l, min_w, min_t, min_l_pr_ratio, min_v_bridge, doping_lb, actuator_lb];
      ub = [max_l, max_w, max_t, max_l_pr_ratio, max_v_bridge, doping_ub, actuator_ub];
    end
    
    function x0 = initial_conditions_random(self, parameter_constraints)
      [lb, ub] = self.optimization_bounds(parameter_constraints);
      
      % Random generation bounds. We use the conditions from
      % optimization_bounds so that we don't randomly generate
      % something outside of the allowable bounds.
      l_min = lb(1);
      l_max = ub(1);
      
      w_min = lb(2);
      w_max = ub(2);
      
      t_min = lb(3);
      t_max = ub(3);
      
      l_pr_ratio_min = lb(4);
      l_pr_ratio_max = ub(4);
      
      V_b_min = lb(5);
      V_b_max = ub(5);
      
      % Generate the random values
      l_random = l_min + rand*(l_max - l_min);
      w_random = w_min + rand*(w_max - w_min);
      t_random = t_min + rand*(t_max - t_min);
      l_pr_ratio_random = l_pr_ratio_min + rand*(l_pr_ratio_max - l_pr_ratio_min);
      v_bridge_random = V_b_min + rand*(V_b_max - V_b_min);
      
      x0_doping = self.doping_initial_conditions_random(parameter_constraints);
      
      x0_actuator = [];
      % Actuator specific code
      switch self.cantilever_type
        case 'thermal'
          l_a_min = lb(8);
          l_a_max = ub(8);
          
          w_a_min = lb(9);
          w_a_max = ub(9);
          
          t_a_min = lb(10);
          t_a_max = ub(10);
          
          v_actuator_min = lb(11);
          v_actuator_max = ub(11);
          
          R_heater_min = lb(12);
          R_heater_max = ub(12);
          
          l_a_random = l_a_min + rand*(l_a_max - l_a_min);
          w_a_random = w_a_min + rand*(w_a_max - w_a_min);
          t_a_random = t_a_min + rand*(t_a_max - t_a_min);
          v_actuator_random = v_actuator_min + rand*(v_actuator_max - v_actuator_min);
          R_heater_random = R_heater_min + rand*(R_heater_max - R_heater_min);
          x0_actuator = [l_a_random w_a_random t_a_random v_actuator_random R_heater_random];
        case 'piezoelectric'
          l_a_min = lb(8);
          l_a_max = ub(8);
          
          w_a_min = lb(9);
          w_a_max = ub(9);
          
          t_a_min = lb(10);
          t_a_max = ub(10);
          
          v_actuator_min = lb(11);
          v_actuator_max = ub(11);
          
          l_a_random = l_a_min + rand*(l_a_max - l_a_min);
          w_a_random = w_a_min + rand*(w_a_max - w_a_min);
          t_a_random = t_a_min + rand*(t_a_max - t_a_min);
          v_actuator_random = v_actuator_min + rand*(v_actuator_max - v_actuator_min);
          x0_actuator = [l_a_random w_a_random t_a_random v_actuator_random];
      end
      
      x0 = [l_random, w_random, t_random, l_pr_ratio_random, v_bridge_random, x0_doping, x0_actuator];
    end
    
    % Nonlinear optimization constraints. For a feasible design, all constraints are negative.
    function [C, Ceq] = optimization_constraints(self, x0, nonlinear_constraints)
      
      c_new = self.cantilever_from_state(x0);
      
      % Default aspect ratios that can be overriden
      min_w_t_ratio = 3;
      min_l_w_ratio = 3;
      min_pr_l_w_ratio = 2;
      min_pr_l = 5e-6;
      
      % Read out the constraints as key-value pairs, e.g. {{'omega_min_hz', 'min_k'}, {1000, 10}}
      if ~isempty(nonlinear_constraints)
        keys = nonlinear_constraints{1};
        values = nonlinear_constraints{2};
        for ii = 1:length(keys)
          eval([keys{ii} '=' num2str(values{ii}) ';']);
        end
      end
      
      % Force resolution must always be positive
      % We start with this single element vector and then append any additional constraints that the user has provided.
      C(1) = -c_new.force_resolution();
      
      % Resonant frequency
      if exist('omega_min_hz', 'var')
        switch self.fluid
          case 'vacuum'
            freq_constraint = omega_min_hz - c_new.omega_vacuum_hz();
          otherwise
            [omega_damped_hz, tmp] = c_new.omega_damped_hz_and_Q();
            freq_constraint = omega_min_hz - omega_damped_hz;
        end
        C = [C freq_constraint];
      end
      
      % Power dissipation
      if exist('max_power', 'var')
        power_constraint = c_new.power_dissipation() - max_power;
        C = [C power_constraint];
      end
      
      % Temp constraints
      if exist('tip_temp', 'var')
        [tmp, TTip] = c_new.approxTempRise();
        temp_constraint = TTip - tip_temp;
        C = [C temp_constraint];
      end
      
      if exist('max_temp', 'var')
        [TMax, tmp] = c_new.approxTempRise();
        temp_constraint = TMax - max_temp;
        C = [C temp_constraint];
      end
      
      % Min and maximum cantilever stiffness
      if exist('min_k', 'var')
        min_k_constraint = min_k - c_new.stiffness();
        C = [C min_k_constraint];
      end
      
      if exist('max_k', 'var')
        max_k_constraint = c_new.stiffness() - max_k;
        C = [C max_k_constraint];
      end
      
      if exist('max_v_actuator', 'var')
        max_v_actuator_constraint = c_new.v_actuator - max_v_actuator;
        C = [C max_v_actuator_constraint];
      end
      
      if exist('min_tip_deflection', 'var')
        min_tip_deflection_constraint = min_tip_deflection - c_new.tipDeflection();
        C = [C min_tip_deflection_constraint];
      end
      
      % Aspect ratio constraints. Default ratios can be changed.
      length_width_ratio = min_l_w_ratio - c_new.l/c_new.w;
      C = [C length_width_ratio];

      width_thickness_ratio = min_w_t_ratio - c_new.w/c_new.t;
      C = [C width_thickness_ratio];

      pr_length_width_ratio = min_pr_l_w_ratio - c_new.l_pr()/c_new.w_pr();
      C = [C pr_length_width_ratio];
      
      pr_length_constraint = min_pr_l - c_new.l_pr();
      C = [C pr_length_constraint];
      
      % Now for equality based constraints
      Ceq = [];
      
      % Fix the stiffness
      if exist('fixed_k', 'var')
        fixed_k_constraint = c_new.stiffness() - fixed_k;
        Ceq = [Ceq fixed_k_constraint];
      end
      
      if exist('fixed_v_bridge', 'var')
        fixed_v_bridge_constraint = c_new.v_bridge - fixed_v_bridge;
        Ceq = [Ceq fixed_v_bridge_constraint];
      end
      
      % Fix the resonant frequency
      if exist('fixed_f0', 'var')
        switch self.fluid
          case 'vacuum'
            fixed_f0_constraint = omega_min_hz - c_new.omega_vacuum_hz();
          otherwise
            [omega_damped_hz, tmp] = c_new.omega_damped_hz_and_Q();
            fixed_f0_constraint = omega_min_hz - omega_damped_hz;
        end
        Ceq = [Ceq fixed_f0_constraint];
      end
    end
    
    % The optimization isn't convex so isn't guaranteed to converge. In practice it converges about 95% of the time
    % depending on the initial guess and constraint set. For this reason, it is best to start from a random initial
    % seed and perform the optimization and checking to make sure that it converges repeatedly.
    function optimized_cantilever = optimize_performance(self, parameter_constraints, nonlinear_constraints, goal)
      
      percent_match = 0.001; % 0.1 percent
      randomize_starting_conditions = 1;
      
      converged = 0;
      ii = 1;
      resolution = [];
      while ~converged
        % Optimize another cantilever
        [c{ii}, exitflag] = self.optimize_performance_once(parameter_constraints, nonlinear_constraints, goal, randomize_starting_conditions);
        
        % If the optimization terminated abnormally (e.g. constraints not satisfied), skip to the next iteration
        if ~(exitflag == 1 || exitflag == 2)
          continue
        end
        
        % Record the resolution for the latest cantilever
        if goal == cantilever.goalForceResolution
          resolution(ii) = c{ii}.force_resolution();
        elseif goal == cantilever.goalDisplacementResolution
          resolution(ii) = c{ii}.displacement_resolution();
        end
        
        % If we have more than one result, consider stopping
        if ii > 1
          % Sort from smallest to largest, check if the two smallest values agree
          [resolution, sortIndex] = sort(resolution);
          fprintf('Resolutions so far: %s\n', mat2str(resolution, 3))
          resultsAgree = abs(1 - resolution(1)/resolution(2)) < percent_match;
          
          % If the results agree, then stop the loop. Otherwise, continue
          if resultsAgree
            fprintf('CONVERGED. Two best values: %s\n', mat2str(resolution(1:2), 3))
            optimized_cantilever = c{sortIndex(1)};
            converged = 1;
          else
            fprintf('NOT CONVERGED. Two best values: %s\n', mat2str(resolution(1:2), 3))
          end
        end
        
        % After a few tries, we'll just use the best result we came across
        if ii > 10
          [resolution, sortIndex] = sort(resolution);
          optimized_cantilever = c{sortIndex(1)};
          converged = 1;
        end
        
        % Increment
        ii = ii + 1;
      end
    end
    
    % Optimize, but don't randomize starting point
    function optimized_cantilever = optimize_performance_from_current(self, parameter_constraints, nonlinear_constraints, goal)
      randomize_starting_conditions = 0;
      [optimized_cantilever, tmp] = self.optimize_performance_once(parameter_constraints, nonlinear_constraints, goal, randomize_starting_conditions);
    end
    
    function [optimized_cantilever, exitflag] = optimize_performance_once(self, parameter_constraints, nonlinear_constraints, goal, randomize_starting_conditions)
      
      scaling = self.optimization_scaling();
      
      self.check_valid_cantilever();
      
      % If random_flag = 1, start from random conditions. Otherwise
      % start from the current cantilever state vector
      if randomize_starting_conditions == 1
        problem.x0 = scaling.*self.initial_conditions_random(parameter_constraints);
      else
        problem.x0 = scaling.*self.current_state();
      end
      
      if goal == cantilever.goalForceResolution
        problem.objective = @self.optimize_force_resolution;
      elseif goal == cantilever.goalDisplacementResolution
        problem.objective = @self.optimize_displacement_resolution;
      end
      
      [lb ub] = self.optimization_bounds(parameter_constraints);
      problem.lb = scaling.*lb;
      problem.ub = scaling.*ub;
      
      problem.options.TolFun = 1e-12;
      problem.options.TolCon = 1e-12;
      problem.options.TolX = 1e-12;
      
      problem.options.MaxFunEvals = 3000;
      problem.options.MaxIter = 2000;
      problem.options.Display = 'iter';
      problem.options.UseParallel = 'always'; % For multicore processors
      
      problem.options.Algorithm = 'Interior-point';
      problem.solver = 'fmincon';
      
      problem.nonlcon = @(x) self.optimization_constraints(x, nonlinear_constraints);
      
      [x, tmp, exitflag] = fmincon(problem);
      optimized_cantilever = self.cantilever_from_state(x);
    end
  end
end
