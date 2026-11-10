classdef UnitConverter
    methods (Static)
        % Базовые единицы (длина, время, масса)
        function m = cm_to_m(cm)       % сантиметры -> метры
            m = cm * 1e-2;
        end
        
        function cm = m_to_cm(m)       % метры -> сантиметры
            cm = m * 1e2;
        end
        
        function s = mus_to_s(mus)       % микросекунды -> секунды
            s = mus * 1e-6;
        end
        
        function mus = s_to_mus(s)       % секунды -> микросекунды
            mus = s * 1e6;
        end
        
        function kg = g_to_kg(g)       % граммы -> килограммы
            kg = g * 1e-3;
        end
        
        function g = kg_to_g(kg)       % килограммы -> граммы
            g = kg * 1e3;
        end
        % Сила: [F] = г·см/мкс²
        function N = system_force_to_N(F_custom)
            N = F_custom * 1e7;    % 1 ед. = 10^7 Н
        end
        
        function F_custom = N_to_system_force(N)
            F_custom = N * 1e-7;
        end
        
        % Давление: [P] = г/(см·мкс²)
        function MPa = system_pressure_to_MPa(P_custom)
            MPa = P_custom * 1e5;   % 1 ед. = 10^11 Па = 10^5 МПа
        end
        
        function P_custom = MPa_to_system_pressure(MPa)
            P_custom = MPa * 1e-5;
        end
        
        % Плотность: [R] = г/см
        function gcm = system_density_to_gcm(R_custom)
            gcm = R_custom;
        end

        function R_custom = gcm_to_system_density(gcm)
            R_custom = gcm;
        end

        % Момент силы: [M] = г·см²/мкс²
        function Nm = system_torque_to_Nm(T_custom)
            Nm = T_custom * 1e5;    % 1 ед. = 10^5 Н·м
        end
        
        function T_custom = Nm_to_system_torque(Nm)
            T_custom = Nm * 1e-5;
        end
        
        % Энергия: [E] = г·см²/мкс²
        function J = system_energy_to_J(E_custom)
            J = E_custom * 1e5;     % 1 ед. = 10^5 Дж
        end
        
        function E_custom = J_to_system_energy(J)
            E_custom = J * 1e-5;
        end
        
        % Скорость: [v] = см/мкс
        function ms = system_velocity_to_ms(v_custom)
            ms = v_custom * 1e4;    % 1 см/мкс = 10^4 м/с
        end
        
        function v_custom = ms_to_system_velocity(ms)
            v_custom = ms * 1e-4;
        end
        
        % Ускорение: [a] = см/мкс²
        function ms2 = system_acceleration_to_ms2(a_custom)
            ms2 = a_custom * 1e10;  % 1 см/мкс² = 10^10 м/с²
        end
        
        function a_custom = ms2_to_system_acceleration(ms2)
            a_custom = ms2 * 1e-10;
        end
        
        % Частота: [f] = 1/мкс
        function Hz = system_freq_to_Hz(f_custom)
            Hz = f_custom * 1e6;    % 1/мкс = 10^6 Гц
        end
        
        function f_custom = Hz_to_system_freq(Hz)
            f_custom = Hz * 1e-6;
        end
    end
end