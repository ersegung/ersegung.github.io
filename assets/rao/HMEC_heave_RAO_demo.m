function varargout = HMEC_heave_RAO_demo(varargin)
% HMEC_HEAVE_RAO_DEMO Interactive 1-DOF heave RAO teaching demonstration.
%
% Run the interactive demo:
%   HMEC_heave_RAO_demo
%
% Run the numerical self-checks without opening the interface:
%   report = HMEC_heave_RAO_demo('selftest')
%
% Governing equation for one regular-wave frequency omega:
%
%   [m + A33(omega)] z_ddot
% + [B33(omega) + B_visc + B_PTO] z_dot
% + [C33 + K_extra] z = F_exc,3(t)
%
% with
%
%   H3(omega) = z_hat/a_hat
%             = [F_exc,3(omega)/a_hat] ...
%               / {C33 + K_extra - omega^2[m + A33(omega)]
%                  + i*omega[B33(omega) + B_visc + B_PTO]}.
%
% Internally, all quantities use SI units. The controls display convenient
% engineering units (tonne, kN, and kN*s/m). The frequency-dependent
% hydrodynamic coefficients are smooth, BEM-like TEACHING curves. They have
% physically reasonable limits and orders of magnitude, but they are not a
% validated prediction for a particular WEC. Replace the coefficient
% generator near the end of this file with Capytaine/WAMIT data for a
% device-specific exercise.
%
% This file uses only base MATLAB UI and plotting functions.

    if nargin > 0
        mode = char(varargin{1});
        if strcmpi(strtrim(mode), 'selftest')
            report = runHeaveSelfTest();
            if nargout > 0
                varargout{1} = report;
            else
                disp(report)
            end
            return
        end
    end

    defaults = defaultHeaveParameters();
    baseline.P = defaults;
    baseline.D = calculateHeaveResponse(defaults);

    colors.current   = [0.0000 0.4470 0.7410];
    colors.baseline  = [0.4200 0.4200 0.4200];
    colors.phase     = [0.8500 0.3250 0.0980];
    colors.power     = [0.0000 0.6200 0.4500];
    colors.wave      = [0.0000 0.4470 0.7410];
    colors.body      = [0.9290 0.6940 0.1250];
    colors.waterFill = [0.8200 0.9300 0.9800];

    fig = uifigure( ...
        'Name', 'HMEC | 1-DOF Heave RAO Teaching Demo', ...
        'Position', [45 45 1510 875], ...
        'Color', [0.97 0.97 0.97]);

    root = uigridlayout(fig, [1 2]);
    root.ColumnWidth = {345, '1x'};
    root.RowHeight = {'1x'};
    root.Padding = [10 10 10 10];
    root.ColumnSpacing = 10;

    controlPanel = uipanel(root, ...
        'Title', 'Inputs, comparison case, and class questions', ...
        'FontWeight', 'bold');
    controlPanel.Layout.Row = 1;
    controlPanel.Layout.Column = 1;

    controls = uigridlayout(controlPanel, [20 2]);
    controls.ColumnWidth = {170, '1x'};
    controls.RowHeight = {58, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, ...
                          38, 22, 34, 34, 128, 36, 36, 44, '1x'};
    controls.Padding = [8 8 8 8];
    controls.RowSpacing = 5;
    controls.ColumnSpacing = 8;

    banner = uilabel(controls, ...
        'Text', ['Teaching coefficients: realistic order of magnitude and ' ...
                 'physically constrained, but not validated device data.'], ...
        'WordWrap', 'on', ...
        'FontWeight', 'bold', ...
        'FontColor', [0.55 0.20 0.05]);
    banner.Layout.Row = 1;
    banner.Layout.Column = [1 2];

    massSpinner = makeSpinner(controls, 2, 'Body mass, m [tonne]', ...
        [45 250], 5, defaults.massTonnes, @updateAll);
    radiusSpinner = makeSpinner(controls, 3, 'Waterplane radius [m]', ...
        [1.5 5.0], 0.1, defaults.waterplaneRadius, @updateAll);
    ptoDampingSpinner = makeSpinner(controls, 4, 'PTO damping [kN s/m]', ...
        [0 250], 5, defaults.ptoDamping_kNsPerM, @updateAll);
    viscDampingSpinner = makeSpinner(controls, 5, 'Viscous damping [kN s/m]', ...
        [0 120], 5, defaults.viscousDamping_kNsPerM, @updateAll);
    extraStiffnessSpinner = makeSpinner(controls, 6, 'Extra stiffness [kN/m]', ...
        [0 500], 10, defaults.extraStiffness_kNPerM, @updateAll);
    addedMassScaleSpinner = makeSpinner(controls, 7, 'Added-mass scale [-]', ...
        [0.40 1.80], 0.05, defaults.addedMassScale, @updateAll);
    radiationScaleSpinner = makeSpinner(controls, 8, 'Radiation-damping scale [-]', ...
        [0.40 1.80], 0.05, defaults.radiationScale, @updateAll);
    excitationScaleSpinner = makeSpinner(controls, 9, 'Excitation scale [-]', ...
        [0.50 1.50], 0.05, defaults.excitationScale, @updateAll);
    waveAmplitudeSpinner = makeSpinner(controls, 10, 'Wave amplitude, a [m]', ...
        [0.05 1.50], 0.05, defaults.waveAmplitude, @updateAll);
    selectedPeriodSpinner = makeSpinner(controls, 11, 'Selected wave period [s]', ...
        [defaults.periodMin defaults.periodMax], 0.25, defaults.selectedPeriod, @updateAll);

    buttonGrid = uigridlayout(controls, [1 3]);
    buttonGrid.Layout.Row = 12;
    buttonGrid.Layout.Column = [1 2];
    buttonGrid.ColumnWidth = {'1x', '1x', '1x'};
    buttonGrid.Padding = [0 0 0 0];
    buttonGrid.ColumnSpacing = 5;

    resetButton = uibutton(buttonGrid, 'push', ...
        'Text', 'Reset', ...
        'ButtonPushedFcn', @resetInputs);
    baselineButton = uibutton(buttonGrid, 'push', ...
        'Text', 'Set baseline', ...
        'ButtonPushedFcn', @setCurrentBaseline);
    playButton = uibutton(buttonGrid, 'push', ...
        'Text', 'Play motion', ...
        'ButtonPushedFcn', @playMotion);

    questionLabel = uilabel(controls, ...
        'Text', 'Class prediction question', ...
        'FontWeight', 'bold');
    questionLabel.Layout.Row = 13;
    questionLabel.Layout.Column = [1 2];

    questionTitles = heaveQuestionTitles();
    questionDropDown = uidropdown(controls, ...
        'Items', questionTitles, ...
        'Value', questionTitles{1}, ...
        'ValueChangedFcn', @showQuestionPrompt);
    questionDropDown.Layout.Row = 14;
    questionDropDown.Layout.Column = [1 2];

    questionArea = uitextarea(controls, ...
        'Editable', 'off', ...
        'WordWrap', 'on', ...
        'Value', {'Select a question, ask for a prediction, then change the control.'});
    questionArea.Layout.Row = [15 16];
    questionArea.Layout.Column = [1 2];

    revealButton = uibutton(controls, 'push', ...
        'Text', 'Reveal explanation', ...
        'ButtonPushedFcn', @revealQuestionAnswer);
    revealButton.Layout.Row = 17;
    revealButton.Layout.Column = [1 2];

    statusLabel = uilabel(controls, ...
        'Text', 'Model checks pending ...', ...
        'WordWrap', 'on', ...
        'FontWeight', 'bold');
    statusLabel.Layout.Row = [18 19];
    statusLabel.Layout.Column = [1 2];

    tabs = uitabgroup(root);
    tabs.Layout.Row = 1;
    tabs.Layout.Column = 2;

    raoTab = uitab(tabs, 'Title', 'RAO, phase, and PTO power');
    raoGrid = uigridlayout(raoTab, [2 2]);
    raoGrid.RowHeight = {'1x', '1x'};
    raoGrid.ColumnWidth = {'1x', '1x'};
    raoGrid.Padding = [10 10 10 10];
    raoGrid.RowSpacing = 10;
    raoGrid.ColumnSpacing = 10;

    raoAxis = uiaxes(raoGrid);
    raoAxis.Layout.Row = 1;
    raoAxis.Layout.Column = [1 2];

    phaseAxis = uiaxes(raoGrid);
    phaseAxis.Layout.Row = 2;
    phaseAxis.Layout.Column = 1;

    powerAxis = uiaxes(raoGrid);
    powerAxis.Layout.Row = 2;
    powerAxis.Layout.Column = 2;

    coefficientTab = uitab(tabs, 'Title', 'Hydrodynamic coefficient curves');
    coefficientGrid = uigridlayout(coefficientTab, [3 1]);
    coefficientGrid.RowHeight = {'1x', '1x', '1x'};
    coefficientGrid.ColumnWidth = {'1x'};
    coefficientGrid.Padding = [10 10 10 10];
    coefficientGrid.RowSpacing = 10;

    addedMassAxis = uiaxes(coefficientGrid);
    addedMassAxis.Layout.Row = 1;
    dampingAxis = uiaxes(coefficientGrid);
    dampingAxis.Layout.Row = 2;
    excitationAxis = uiaxes(coefficientGrid);
    excitationAxis.Layout.Row = 3;

    motionTab = uitab(tabs, 'Title', 'Selected regular-wave response');
    motionGrid = uigridlayout(motionTab, [2 2]);
    motionGrid.RowHeight = {'1x', '1x'};
    motionGrid.ColumnWidth = {'1.15x', '1x'};
    motionGrid.Padding = [10 10 10 10];
    motionGrid.RowSpacing = 10;
    motionGrid.ColumnSpacing = 10;

    animationAxis = uiaxes(motionGrid);
    animationAxis.Layout.Row = [1 2];
    animationAxis.Layout.Column = 1;

    timeAxis = uiaxes(motionGrid);
    timeAxis.Layout.Row = 1;
    timeAxis.Layout.Column = 2;

    summaryArea = uitextarea(motionGrid, ...
        'Editable', 'off', ...
        'WordWrap', 'on');
    summaryArea.Layout.Row = 2;
    summaryArea.Layout.Column = 2;

    updateAll();

    function spinner = makeSpinner(parent, rowNumber, labelText, limits, step, value, callback)
        label = uilabel(parent, 'Text', labelText);
        label.Layout.Row = rowNumber;
        label.Layout.Column = 1;
        spinner = uispinner(parent, ...
            'Limits', limits, ...
            'Step', step, ...
            'Value', value, ...
            'ValueDisplayFormat', '%.3g', ...
            'ValueChangedFcn', callback);
        spinner.Layout.Row = rowNumber;
        spinner.Layout.Column = 2;
    end

    function P = readControls()
        P = defaults;
        P.massTonnes = massSpinner.Value;
        P.waterplaneRadius = radiusSpinner.Value;
        P.ptoDamping_kNsPerM = ptoDampingSpinner.Value;
        P.viscousDamping_kNsPerM = viscDampingSpinner.Value;
        P.extraStiffness_kNPerM = extraStiffnessSpinner.Value;
        P.addedMassScale = addedMassScaleSpinner.Value;
        P.radiationScale = radiationScaleSpinner.Value;
        P.excitationScale = excitationScaleSpinner.Value;
        P.waveAmplitude = waveAmplitudeSpinner.Value;
        P.selectedPeriod = selectedPeriodSpinner.Value;
    end

    function updateAll(varargin)
        P = readControls();
        D = calculateHeaveResponse(P);

        plotHeaveRAO(P, D);
        plotHeaveCoefficients(P, D);
        plotHeaveMotion(P, D);

        [checksPass, checkMessage] = heaveDiagnostics(P, D);
        statusLabel.Text = checkMessage;
        if checksPass
            statusLabel.FontColor = [0.00 0.45 0.15];
        else
            statusLabel.FontColor = [0.75 0.00 0.00];
        end
    end

    function plotHeaveRAO(P, D)
        cla(raoAxis)
        hold(raoAxis, 'on')
        plot(raoAxis, baseline.D.period, abs(baseline.D.H), '--', ...
            'Color', colors.baseline, 'LineWidth', 1.7, ...
            'DisplayName', 'Comparison baseline');
        plot(raoAxis, D.period, abs(D.H), '-', ...
            'Color', colors.current, 'LineWidth', 2.4, ...
            'DisplayName', 'Current case');
        markSelectedPeriod(raoAxis, P.selectedPeriod);
        plot(raoAxis, D.estimatedResonancePeriod, ...
            interp1(D.period, abs(D.H), D.estimatedResonancePeriod, 'pchip'), ...
            'o', 'Color', colors.phase, 'MarkerFaceColor', colors.phase, ...
            'HandleVisibility', 'off');
        hold(raoAxis, 'off')
        title(raoAxis, 'Heave RAO magnitude')
        xlabel(raoAxis, 'Wave period, T [s]')
        ylabel(raoAxis, '|H_3| = |z-hat|/a [-]')
        xlim(raoAxis, [P.periodMin P.periodMax])
        legend(raoAxis, 'Location', 'northeast')
        styleAxis(raoAxis)

        cla(phaseAxis)
        hold(phaseAxis, 'on')
        plot(phaseAxis, baseline.D.period, phaseDegrees(baseline.D.H), '--', ...
            'Color', colors.baseline, 'LineWidth', 1.5, ...
            'DisplayName', 'Baseline');
        plot(phaseAxis, D.period, phaseDegrees(D.H), '-', ...
            'Color', colors.phase, 'LineWidth', 2.1, ...
            'DisplayName', 'Current');
        markSelectedPeriod(phaseAxis, P.selectedPeriod);
        hold(phaseAxis, 'off')
        title(phaseAxis, 'Motion phase relative to wave elevation')
        xlabel(phaseAxis, 'Wave period, T [s]')
        ylabel(phaseAxis, 'Phase(H_3) [deg]')
        xlim(phaseAxis, [P.periodMin P.periodMax])
        ylim(phaseAxis, [-190 190])
        styleAxis(phaseAxis)

        cla(powerAxis)
        hold(powerAxis, 'on')
        plot(powerAxis, baseline.D.period, baseline.D.meanPtoPower/1e3, '--', ...
            'Color', colors.baseline, 'LineWidth', 1.5, ...
            'DisplayName', 'Baseline');
        plot(powerAxis, D.period, D.meanPtoPower/1e3, '-', ...
            'Color', colors.power, 'LineWidth', 2.1, ...
            'DisplayName', 'Current');
        markSelectedPeriod(powerAxis, P.selectedPeriod);
        hold(powerAxis, 'off')
        title(powerAxis, sprintf('Mean mechanical PTO power for a = %.2f m', P.waveAmplitude))
        xlabel(powerAxis, 'Wave period, T [s]')
        ylabel(powerAxis, 'P-bar_P_T_O [kW]')
        xlim(powerAxis, [P.periodMin P.periodMax])
        styleAxis(powerAxis)
    end

    function plotHeaveCoefficients(P, D)
        cla(addedMassAxis)
        hold(addedMassAxis, 'on')
        plot(addedMassAxis, baseline.D.period, baseline.D.addedMass/1e3, '--', ...
            'Color', colors.baseline, 'LineWidth', 1.5, 'DisplayName', 'Baseline');
        plot(addedMassAxis, D.period, D.addedMass/1e3, '-', ...
            'Color', colors.current, 'LineWidth', 2.1, 'DisplayName', 'Current');
        markSelectedPeriod(addedMassAxis, P.selectedPeriod);
        hold(addedMassAxis, 'off')
        title(addedMassAxis, 'Added mass A_{33}(omega)')
        xlabel(addedMassAxis, 'Wave period, T [s]')
        ylabel(addedMassAxis, 'A_{33} [tonne]')
        xlim(addedMassAxis, [P.periodMin P.periodMax])
        legend(addedMassAxis, 'Location', 'best')
        styleAxis(addedMassAxis)

        cla(dampingAxis)
        hold(dampingAxis, 'on')
        plot(dampingAxis, baseline.D.period, baseline.D.radiationDamping/1e3, '--', ...
            'Color', colors.baseline, 'LineWidth', 1.5, 'DisplayName', 'Baseline');
        plot(dampingAxis, D.period, D.radiationDamping/1e3, '-', ...
            'Color', colors.phase, 'LineWidth', 2.1, 'DisplayName', 'Current');
        markSelectedPeriod(dampingAxis, P.selectedPeriod);
        hold(dampingAxis, 'off')
        title(dampingAxis, 'Radiation damping B_{33}(omega)')
        xlabel(dampingAxis, 'Wave period, T [s]')
        ylabel(dampingAxis, 'B_{33} [kN s/m]')
        xlim(dampingAxis, [P.periodMin P.periodMax])
        styleAxis(dampingAxis)

        cla(excitationAxis)
        hold(excitationAxis, 'on')
        plot(excitationAxis, baseline.D.period, abs(baseline.D.excitationPerAmplitude)/1e3, '--', ...
            'Color', colors.baseline, 'LineWidth', 1.5, 'DisplayName', 'Baseline');
        plot(excitationAxis, D.period, abs(D.excitationPerAmplitude)/1e3, '-', ...
            'Color', colors.power, 'LineWidth', 2.1, 'DisplayName', 'Current');
        markSelectedPeriod(excitationAxis, P.selectedPeriod);
        hold(excitationAxis, 'off')
        title(excitationAxis, 'Wave-excitation force transfer function')
        xlabel(excitationAxis, 'Wave period, T [s]')
        ylabel(excitationAxis, '|F_{exc,3}|/a [kN/m]')
        xlim(excitationAxis, [P.periodMin P.periodMax])
        styleAxis(excitationAxis)
    end

    function plotHeaveMotion(P, D)
        renderHeaveFrame(animationAxis, P, D, 0, colors)

        t = linspace(0, 4*P.selectedPeriod, 650);
        eta = P.waveAmplitude*cos(D.selectedOmega*t);
        z = real(P.waveAmplitude*D.selectedH.*exp(1i*D.selectedOmega*t));

        cla(timeAxis)
        hold(timeAxis, 'on')
        plot(timeAxis, t, eta, '-', ...
            'Color', colors.wave, 'LineWidth', 1.7, 'DisplayName', 'Wave elevation eta');
        plot(timeAxis, t, z, '-', ...
            'Color', colors.body, 'LineWidth', 2.2, 'DisplayName', 'Heave z');
        plot(timeAxis, [t(1) t(end)], [0 0], ':', ...
            'Color', [0.45 0.45 0.45], 'HandleVisibility', 'off');
        hold(timeAxis, 'off')
        title(timeAxis, sprintf('Steady harmonic response at T = %.2f s', P.selectedPeriod))
        xlabel(timeAxis, 'Time [s]')
        ylabel(timeAxis, 'Elevation / displacement [m]')
        legend(timeAxis, 'Location', 'best')
        styleAxis(timeAxis)

        summaryText = sprintf([ ...
            'SELECTED FREQUENCY\n' ...
            'T = %.2f s,  omega = %.3f rad/s,  a = %.2f m\n\n' ...
            'BODY AND RESTORING\n' ...
            'm = %.1f tonne\n' ...
            'A_wp = %.2f m^2\n' ...
            'C33 = rho g A_wp = %.1f kN/m\n' ...
            'K_total = %.1f kN/m\n\n' ...
            'HYDRODYNAMICS AT SELECTED T\n' ...
            'A33 = %.1f tonne\n' ...
            'B33 = %.1f kN s/m\n' ...
            '|F_exc,3|/a = %.1f kN/m\n\n' ...
            'RESPONSE\n' ...
            '|H3| = %.3f m/m\n' ...
            'phase(H3) = %.1f deg\n' ...
            'heave amplitude = %.3f m\n' ...
            'mean mechanical PTO power = %.2f kW\n\n' ...
            'Approximate inertia-restoring balance: T ~= %.2f s'], ...
            P.selectedPeriod, D.selectedOmega, P.waveAmplitude, ...
            P.massTonnes, D.waterplaneArea, D.hydrostaticStiffness/1e3, ...
            D.totalStiffness/1e3, D.selectedAddedMass/1e3, ...
            D.selectedRadiationDamping/1e3, ...
            abs(D.selectedExcitationPerAmplitude)/1e3, ...
            abs(D.selectedH), phaseDegrees(D.selectedH), ...
            P.waveAmplitude*abs(D.selectedH), D.selectedMeanPtoPower/1e3, ...
            D.estimatedResonancePeriod);
        summaryArea.Value = splitText(summaryText);
    end

    function resetInputs(~, ~)
        massSpinner.Value = defaults.massTonnes;
        radiusSpinner.Value = defaults.waterplaneRadius;
        ptoDampingSpinner.Value = defaults.ptoDamping_kNsPerM;
        viscDampingSpinner.Value = defaults.viscousDamping_kNsPerM;
        extraStiffnessSpinner.Value = defaults.extraStiffness_kNPerM;
        addedMassScaleSpinner.Value = defaults.addedMassScale;
        radiationScaleSpinner.Value = defaults.radiationScale;
        excitationScaleSpinner.Value = defaults.excitationScale;
        waveAmplitudeSpinner.Value = defaults.waveAmplitude;
        selectedPeriodSpinner.Value = defaults.selectedPeriod;
        baseline.P = defaults;
        baseline.D = calculateHeaveResponse(defaults);
        updateAll();
    end

    function setCurrentBaseline(~, ~)
        baseline.P = readControls();
        baseline.D = calculateHeaveResponse(baseline.P);
        updateAll();
    end

    function playMotion(~, ~)
        P = readControls();
        D = calculateHeaveResponse(P);
        playButton.Enable = 'off';
        cleanup = onCleanup(@() setPlayButtonEnabled());
        frameTimes = linspace(0, 2*P.selectedPeriod, 120);
        for frameIndex = 1:numel(frameTimes)
            if ~isvalid(fig)
                return
            end
            renderHeaveFrame(animationAxis, P, D, frameTimes(frameIndex), colors)
            drawnow limitrate
            pause(0.015)
        end
        renderHeaveFrame(animationAxis, P, D, 0, colors)
        clear cleanup
        setPlayButtonEnabled();
    end

    function setPlayButtonEnabled()
        if isvalid(playButton)
            playButton.Enable = 'on';
        end
    end

    function showQuestionPrompt(~, ~)
        [prompt, ~] = heaveQuestionText(questionDropDown.Value);
        questionArea.Value = splitText(sprintf('ASK THE CLASS:\n%s\n\nThen change the indicated control and compare with the dashed baseline.', prompt));
    end

    function revealQuestionAnswer(~, ~)
        [prompt, answer] = heaveQuestionText(questionDropDown.Value);
        questionArea.Value = splitText(sprintf('QUESTION:\n%s\n\nEXPECTED EXPLANATION:\n%s', prompt, answer));
    end

    function markSelectedPeriod(axisHandle, selectedPeriod)
        limits = ylim(axisHandle);
        plot(axisHandle, [selectedPeriod selectedPeriod], limits, ':', ...
            'Color', [0.25 0.25 0.25], ...
            'LineWidth', 1.0, ...
            'HandleVisibility', 'off');
        ylim(axisHandle, limits)
    end

    function styleAxis(axisHandle)
        axisHandle.Box = 'on';
        axisHandle.XGrid = 'on';
        axisHandle.YGrid = 'on';
        axisHandle.GridAlpha = 0.18;
        axisHandle.FontSize = 11;
        axisHandle.LineWidth = 0.9;
    end
end

function P = defaultHeaveParameters()
    P.rho = 1025;                         % seawater density [kg/m^3]
    P.g = 9.81;                           % gravitational acceleration [m/s^2]
    P.waterDepth = 60;                    % visual/dispersion water depth [m]
    P.hydrodynamicDraft = 4.0;            % reference displaced-water draft [m]
    P.periodMin = 2.5;                    % [s]
    P.periodMax = 15.0;                   % [s]
    P.numberOfPeriods = 520;

    P.waterplaneRadius = 3.0;             % [m]
    displacedMass = P.rho*pi*P.waterplaneRadius^2*P.hydrodynamicDraft;
    P.massTonnes = displacedMass/1e3;     % [tonne]

    P.ptoDamping_kNsPerM = 60;            % [kN s/m]
    P.viscousDamping_kNsPerM = 20;        % [kN s/m]
    P.extraStiffness_kNPerM = 0;          % [kN/m]

    P.addedMassScale = 1.0;
    P.radiationScale = 1.0;
    P.excitationScale = 1.0;

    P.waveAmplitude = 0.50;               % [m]
    P.selectedPeriod = 7.00;              % [s]
end

function D = calculateHeaveResponse(P)
    D.period = linspace(P.periodMin, P.periodMax, P.numberOfPeriods);
    D.omega = 2*pi./D.period;

    mass = P.massTonnes*1e3;
    radius = P.waterplaneRadius;
    D.waterplaneArea = pi*radius^2;
    displacedWaterMass = P.rho*D.waterplaneArea*P.hydrodynamicDraft;

    D.hydrostaticStiffness = P.rho*P.g*D.waterplaneArea;
    D.totalStiffness = D.hydrostaticStiffness + P.extraStiffness_kNPerM*1e3;

    % Smooth teaching coefficients. Their limiting behavior is chosen so
    % that B33 -> 0 at very low/high frequency and Fexc/a -> C33 for long
    % waves. The scale follows displaced-water mass and hydrostatic stiffness.
    characteristicOmega = 2*pi/6.0;
    x = D.omega/characteristicOmega;

    D.addedMass = P.addedMassScale*displacedWaterMass .* ...
        (0.62 + 0.18./(1 + x.^2) + 0.12*exp(-((x - 1)/0.45).^2));

    dampingScale = sqrt(D.hydrostaticStiffness*displacedWaterMass);
    D.radiationDamping = P.radiationScale*0.66*dampingScale .* ...
        x.^2 .* exp(1 - x.^2);

    D.excitationPerAmplitude = P.excitationScale*D.hydrostaticStiffness .* ...
        (1 + 0.18*x.^2) ./ sqrt(1 + (x/1.55).^6);

    externalDamping = (P.ptoDamping_kNsPerM + P.viscousDamping_kNsPerM)*1e3;
    D.dynamicStiffness = D.totalStiffness ...
        - D.omega.^2 .* (mass + D.addedMass) ...
        + 1i*D.omega .* (D.radiationDamping + externalDamping);

    D.H = D.excitationPerAmplitude ./ D.dynamicStiffness;
    D.meanPtoPower = 0.5*(P.ptoDamping_kNsPerM*1e3) .* ...
        (D.omega .* P.waveAmplitude .* abs(D.H)).^2;

    [~, resonanceIndex] = min(abs(D.totalStiffness ...
        - D.omega.^2 .* (mass + D.addedMass)));
    D.estimatedResonancePeriod = D.period(resonanceIndex);

    D.selectedOmega = 2*pi/P.selectedPeriod;
    D.selectedWavenumber = dispersionWavenumber(D.selectedOmega, P.waterDepth, P.g);
    D.selectedH = interp1(D.period, D.H, P.selectedPeriod, 'pchip');
    D.selectedAddedMass = interp1(D.period, D.addedMass, P.selectedPeriod, 'pchip');
    D.selectedRadiationDamping = interp1(D.period, D.radiationDamping, P.selectedPeriod, 'pchip');
    D.selectedExcitationPerAmplitude = interp1(D.period, D.excitationPerAmplitude, P.selectedPeriod, 'pchip');
    D.selectedMeanPtoPower = interp1(D.period, D.meanPtoPower, P.selectedPeriod, 'pchip');
end

function renderHeaveFrame(axisHandle, P, D, time, colors)
    cla(axisHandle)
    hold(axisHandle, 'on')

    xExtent = max(14, 3.5*P.waterplaneRadius);
    x = linspace(-xExtent, xExtent, 360);
    eta = P.waveAmplitude*cos(D.selectedWavenumber*x - D.selectedOmega*time);
    waterBottom = -8.0;

    patch(axisHandle, [x fliplr(x)], ...
        [eta waterBottom*ones(size(x))], ...
        colors.waterFill, 'EdgeColor', 'none', 'FaceAlpha', 0.78);
    plot(axisHandle, x, eta, '-', 'Color', colors.wave, 'LineWidth', 2.0)

    heave = real(P.waveAmplitude*D.selectedH*exp(1i*D.selectedOmega*time));
    bodyDraft = P.hydrodynamicDraft;
    freeboard = 1.45;
    radius = P.waterplaneRadius;

    bodyX = [-radius radius radius -radius];
    bodyZ = [heave-bodyDraft heave-bodyDraft heave+freeboard heave+freeboard];
    patch(axisHandle, bodyX, bodyZ, colors.body, ...
        'EdgeColor', [0.15 0.15 0.15], 'LineWidth', 1.5);
    plot(axisHandle, [-0.22*radius 0.22*radius], ...
        [heave+freeboard+0.25 heave+freeboard+0.25], ...
        'Color', [0.18 0.18 0.18], 'LineWidth', 3.0)

    seabed = waterBottom + 0.35;
    plot(axisHandle, [-xExtent xExtent], [seabed seabed], '-', ...
        'Color', [0.55 0.43 0.28], 'LineWidth', 4.0)

    elementTop = heave - bodyDraft;
    drawSpring(axisHandle, -0.38, seabed, elementTop, [0.15 0.15 0.15])
    drawDashpot(axisHandle, 0.38, seabed, elementTop, [0.15 0.15 0.15])

    plot(axisHandle, 0, heave, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 5)
    text(axisHandle, -xExtent+0.4, 2.65, ...
        sprintf('eta = %.2f m   z = %.2f m', eta(round(end/2)), heave), ...
        'FontWeight', 'bold', 'FontSize', 11)
    text(axisHandle, 0.65, seabed+0.25, 'equivalent PTO / mooring', ...
        'FontSize', 9, 'Color', [0.20 0.20 0.20])

    hold(axisHandle, 'off')
    xlim(axisHandle, [-xExtent xExtent])
    ylim(axisHandle, [waterBottom 3.2])
    title(axisHandle, 'Heaving body in a regular wave (visual schematic)')
    xlabel(axisHandle, 'x [m]')
    ylabel(axisHandle, 'z [m]')
    axisHandle.Box = 'on';
    axisHandle.XGrid = 'off';
    axisHandle.YGrid = 'off';
    axisHandle.FontSize = 11;
end

function drawSpring(axisHandle, xCenter, zBottom, zTop, color)
    if zTop <= zBottom
        return
    end
    z = linspace(zBottom, zTop, 18);
    x = xCenter + 0.16*(-1).^(1:numel(z));
    x([1 end]) = xCenter;
    plot(axisHandle, x, z, '-', 'Color', color, 'LineWidth', 1.5)
end

function drawDashpot(axisHandle, xCenter, zBottom, zTop, color)
    if zTop <= zBottom
        return
    end
    zMid = 0.52*(zBottom + zTop);
    plot(axisHandle, [xCenter xCenter], [zBottom zMid-0.32], '-', ...
        'Color', color, 'LineWidth', 1.5)
    rectangle('Parent', axisHandle, 'Position', [xCenter-0.16 zMid-0.32 0.32 0.64], ...
        'EdgeColor', color, 'LineWidth', 1.4)
    plot(axisHandle, [xCenter xCenter], [zMid+0.32 zTop], '-', ...
        'Color', color, 'LineWidth', 1.5)
end

function k = dispersionWavenumber(omega, depth, g)
    % Newton iteration for omega^2 = g*k*tanh(k*h).
    k = max(omega.^2/g, 1e-8);
    for iteration = 1:40
        kh = k*depth;
        tanhKh = tanh(kh);
        sechSquared = 1./cosh(kh).^2;
        residual = g*k.*tanhKh - omega.^2;
        derivative = g*tanhKh + g*k*depth.*sechSquared;
        step = residual./derivative;
        k = max(k - step, 1e-10);
        if all(abs(step) < 1e-12)
            break
        end
    end
end

function degrees = phaseDegrees(complexValue)
    degrees = mod(angle(complexValue)*180/pi + 180, 360) - 180;
end

function lines = splitText(textValue)
    lines = regexp(textValue, '\n', 'split');
end

function titles = heaveQuestionTitles()
    titles = { ...
        'Choose a prediction question ...', ...
        'Increase body mass', ...
        'Increase added mass', ...
        'Increase waterplane radius', ...
        'Increase PTO damping', ...
        'Increase extra stiffness', ...
        'Increase wave amplitude'};
end

function [prompt, answer] = heaveQuestionText(titleText)
    switch titleText
        case 'Increase body mass'
            prompt = ['Hold the hydrodynamic curves and stiffness fixed. If body mass increases, ' ...
                      'does the main RAO peak move to a longer or shorter wave period?'];
            answer = ['Longer period. Greater effective inertia requires a lower angular frequency ' ...
                      'to balance the same restoring stiffness: omega_n^2[m+A33(omega_n)] ~= K. ' ...
                      'The peak height need not change monotonically because excitation and damping ' ...
                      'also vary with frequency.'];
        case 'Increase added mass'
            prompt = ['Raise the added-mass scale while keeping body mass and restoring fixed. ' ...
                      'What happens to the resonance region?'];
            answer = ['It generally moves to longer period for the same reason as increasing body ' ...
                      'mass: the water increases the effective inertia m+A33.'];
        case 'Increase waterplane radius'
            prompt = ['Increase the waterplane radius. The demo updates C33 = rho g A_wp and also ' ...
                      'scales the teaching hydrodynamic coefficients with displaced-water size. ' ...
                      'Which effect dominates the peak location?'];
            answer = ['For this baseline, the larger hydrostatic stiffness dominates and the peak ' ...
                      'moves to shorter period. This is a useful reminder that changing geometry ' ...
                      'usually changes C33, A33, B33, and Fexc together; a real BEM rerun is needed.'];
        case 'Increase PTO damping'
            prompt = ['Increase B_PTO. Will the RAO peak and the mean absorbed PTO power both ' ...
                      'always increase?'];
            answer = ['No. More damping lowers and broadens the motion peak. Mean PTO power is ' ...
                      '0.5 B_PTO omega^2 |z_hat|^2, so increasing B_PTO helps only until the reduced ' ...
                      'velocity offsets the larger damping coefficient. There is generally an optimum.'];
        case 'Increase extra stiffness'
            prompt = ['Increase K_extra while mass and hydrodynamic coefficients remain fixed. ' ...
                      'Does the resonance move to longer or shorter period?'];
            answer = ['Shorter period. Increasing restoring stiffness raises the natural angular ' ...
                      'frequency. Reactive PTO stiffness or mooring stiffness can therefore tune ' ...
                      'the response, but may also increase loads.'];
        case 'Increase wave amplitude'
            prompt = ['Double wave amplitude while all linear coefficients are unchanged. What ' ...
                      'changes: the RAO, the physical heave amplitude, or both?'];
            answer = ['The RAO does not change in linear theory because both excitation force and ' ...
                      'response scale with wave amplitude. Physical heave amplitude doubles, velocity ' ...
                      'doubles, and the ideal linear-damper mean PTO power scales with amplitude squared.'];
        otherwise
            prompt = 'Choose a question from the menu.';
            answer = 'The explanation will appear here after a question is selected.';
    end
end

function [passed, message] = heaveDiagnostics(P, D)
    finiteCheck = all(isfinite(real(D.H))) && all(isfinite(imag(D.H)));
    positiveMass = all(D.addedMass > 0);
    nonnegativeDamping = all(D.radiationDamping >= -1e-9);
    positiveStiffness = D.totalStiffness > 0;
    selectedInRange = P.selectedPeriod >= P.periodMin && P.selectedPeriod <= P.periodMax;
    passed = finiteCheck && positiveMass && nonnegativeDamping && ...
        positiveStiffness && selectedInRange;

    if passed
        message = sprintf(['Checks PASS: finite RAO, A33 > 0, B33 >= 0, and K_total > 0.\n' ...
                           'Current approximate inertia-restoring balance: T ~= %.2f s.'], ...
                           D.estimatedResonancePeriod);
    else
        message = 'CHECK FAILED: inspect coefficient scales and total stiffness.';
    end
end

function report = runHeaveSelfTest()
    P = defaultHeaveParameters();
    D = calculateHeaveResponse(P);

    [basePeak, baseIndex] = max(abs(D.H));
    basePeakPeriod = D.period(baseIndex);

    Pmass = P;
    Pmass.massTonnes = 1.40*P.massTonnes;
    Dmass = calculateHeaveResponse(Pmass);
    [~, indexMass] = max(abs(Dmass.H));
    massPeakPeriod = Dmass.period(indexMass);

    Pstiff = P;
    Pstiff.extraStiffness_kNPerM = 200;
    Dstiff = calculateHeaveResponse(Pstiff);
    [~, indexStiff] = max(abs(Dstiff.H));
    stiffnessPeakPeriod = Dstiff.period(indexStiff);

    Pdamp = P;
    Pdamp.ptoDamping_kNsPerM = 180;
    Ddamp = calculateHeaveResponse(Pdamp);
    dampedPeak = max(abs(Ddamp.H));

    Pamp = P;
    Pamp.waveAmplitude = 2*P.waveAmplitude;
    Damp = calculateHeaveResponse(Pamp);

    checks = [ ...
        all(isfinite(real(D.H))) && all(isfinite(imag(D.H))), ...
        all(D.addedMass > 0), ...
        all(D.radiationDamping >= -1e-9), ...
        D.totalStiffness > 0, ...
        massPeakPeriod > basePeakPeriod, ...
        stiffnessPeakPeriod < basePeakPeriod, ...
        dampedPeak < basePeak, ...
        max(abs(Damp.H - D.H)) < 1e-12];

    if ~all(checks)
        error('HMEC_heave_RAO_demo:SelfTestFailed', ...
            'One or more heave-demo numerical checks failed.')
    end

    report.passed = true;
    report.defaultPeakPeriod_s = basePeakPeriod;
    report.defaultPeakRAO = basePeak;
    report.massIncreasePeakPeriod_s = massPeakPeriod;
    report.stiffnessIncreasePeakPeriod_s = stiffnessPeakPeriod;
    report.highDampingPeakRAO = dampedPeak;
    report.waveAmplitudeLeavesRAOUnchanged = true;

    fprintf(['HMEC heave demo self-test PASS. Default peak: %.2f s, |H3| = %.3f.\n'], ...
        basePeakPeriod, basePeak)
end
