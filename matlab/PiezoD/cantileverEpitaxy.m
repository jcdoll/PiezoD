% Model an epitaxial cantilever (B, P, As well supported)
% Assumes negligible dopant diffusion
classdef cantileverEpitaxy < cantilever
  properties
    dopant_concentration
    t_pr_ratio
  end
  
  methods
    function self = cantileverEpitaxy(freq_min, freq_max, l, w, t, ...
			l_pr_ratio, v_bridge, doping_type, dopant_concentration, t_pr_ratio)
			
      self = self@cantilever(freq_min, freq_max, l, w, t, ...
				l_pr_ratio, v_bridge, doping_type);
      self.dopant_concentration = dopant_concentration;
      self.t_pr_ratio = t_pr_ratio;
    end
    
    function print_performance(self)
      print_performance@cantilever(self); % print the base stuff
      fprintf('Dopant concentration (per cc): %g \n', self.dopant_concentration);
      fprintf('PR Thickness Ratio: %g \n', self.t_pr_ratio);
      fprintf('PR Thickness: %g \n', self.junction_depth());
      fprintf('\n')
    end
    
    function x_j = junction_depth(self)
      x_j = self.t * self.t_pr_ratio;
    end
    
    function print_performance_for_excel(self, varargin)
      % Call the superclass method first
      print_performance_for_excel@cantilever(self, varargin);
      
      % varargin gets another set of {} from the cantilever subclasses
      optargin = size(varargin, 2);
      if optargin == 1
        fid = varargin{1};
      elseif optargin == 0
        fid = 1; % Print to the stdout
      else
        fprintf('ERROR: Extra optional arguments')
      end
      
      % Then print out our additional variables
      variables_to_print = [self.dopant_concentration, self.t_pr_ratio];
      for print_index = 1:length(variables_to_print)
        fprintf(fid, '%4g\t', variables_to_print(print_index));
      end
      fprintf(fid, '\n');
    end
    
    % Return the electrically active dopant concentration profile
    % Units: cm^-3
    function [z, active_doping, total_doping] = doping_profile(self)
      n_points = self.numZPoints; % # of points of doping profile
      z = linspace(0, self.t, n_points);

      % Initialize to the background concentration
      background_concentration = 1e15;
      active_doping = ones(1, n_points)*background_concentration;

      % Fill in the epitaxial region, assume active = total
      active_doping(z<=self.junction_depth()) = self.dopant_concentration;
      total_doping = active_doping;
    end
    
    % Calculate sheet resistance
    % Units: ohms
    function Rs = sheet_resistance(self)
      conductivity = self.conductivity(self.dopant_concentration); % ohm-cm
      Rs = 1/(self.junction_depth()*1e2*conductivity); % t_j -> cm
    end    
    
		% We assume a constant concentration so can just integrated to get N_z
    % Units: carries/m^2
    function Nz = Nz(self)
      Nz = self.junction_depth()*self.dopant_concentration*1e6;
    end
    
    function alpha = alpha(self)
      alpha = self.default_alpha; % use the alpha from the superclass
    end    
    
    % ========= Optimization  ==========
    function scaling = doping_optimization_scaling(self)
      concentration_scale = 1e-19;
      t_pr_ratio_scale = 10;
      scaling = [concentration_scale t_pr_ratio_scale];
    end
    
    function self = doping_cantilever_from_state(self, x0)
      self.dopant_concentration = x0(6);
      self.t_pr_ratio = x0(7);
    end
    
    function x = doping_current_state(self)
      x(1) = self.dopant_concentration;
      x(2) = self.t_pr_ratio;
    end
    
    function [lb ub] = doping_optimization_bounds(self, parameter_constraints)
      
      min_dopant_concentration = 1e17;
      
      % Approximate solid solubilities at 1000C
      switch self.doping_type
        case 'boron'
          max_dopant_concentration = 2e20;
        case 'phosphorus'
          max_dopant_concentration = 4e20;
        case 'arsenic'
          max_dopant_concentration = 8e20;
      end
      
      min_t_pr_ratio = 0.01;
      max_t_pr_ratio = 0.99;
      
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
      
      lb = [min_dopant_concentration min_t_pr_ratio];
      ub = [max_dopant_concentration max_t_pr_ratio];
    end
    
    function x0 = doping_initial_conditions_random(self, parameter_constraints)
      [lb, ub] = self.doping_optimization_bounds(parameter_constraints);
      
      n_min = lb(1);
      n_max = ub(1);
      
      t_pr_ratio_min = lb(2);
      t_pr_ratio_max = ub(2);
      
      % Generate the random values
      dopant_concentration_random = 10^(log10(n_min) + ...
				rand*(log10(n_max) - log10(n_min))); % logarithmically distributed
      t_pr_ratio_random = t_pr_ratio_min + rand*(t_pr_ratio_max - t_pr_ratio_min);
      
      x0 = [dopant_concentration_random, t_pr_ratio_random];
    end
  end
end