function varargout = HMEC_heave_pitch_RAO_demo(varargin)
% HMEC_HEAVE_PITCH_RAO_DEMO Interactive coupled heave-pitch RAO demo.
%
% Run the interactive classroom demonstration:
%   HMEC_heave_pitch_RAO_demo
%
% Run numerical and matrix-consistency checks without opening the GUI:
%   report = HMEC_heave_pitch_RAO_demo('selftest')
%
% Coordinates and generalized loading:
%   q = [z; theta]          z [m], theta [rad]
%   F = [F_exc,3; M_exc,5] F [N], moment [N m]
%
% For one regular-wave frequency omega, with exp(i*omega*t):
%
%   Z(omega) q_hat = F_exc_hat,
%
%   Z = -omega^2 [M + A(omega)]
%       + i*omega [B(omega) + B_PTO + B_visc]
%       + [C + K_extra].
%
% The RAO vector is q_hat/a_hat. Therefore:
%   H3 = z_hat/a_hat       [m/m], dimensionless
%   H5 = theta_hat/a_hat   [rad/m] (or deg/m for display)
%
% Internally, every calculation uses SI units and radians. Controls use
% convenient engineering units. The frequency-dependent hydrodynamic
% matrices and excitation vector are smooth, physically constrained,
% BEM-like TEACHING curves. They are not validated predictions for a
% particular device. Replace calculateHeavePitchResponse() hydrodynamic
% curves with Capytaine/WAMIT/Nemoh/AQWA data for a device-specific case.
%
% This file uses base MATLAB UI and plotting functions only.

    if nargin > 0
        mode = char(varargin{1});
        if strcmpi(strtrim(mode), 'selftest')
            report = runHeavePitchSelfTest();
            if nargout > 0
                varargout{1} = report;
            else
                disp(report)
            end
            return
        end
    end

    defaults = defaultHeavePitchParameters();
    baseline.P = defaults;
    baseline.D = calculateHeavePitchResponse(defaults);

    colors.heave     = [0.0000 0.4470 0.7410];
    colors.pitch     = [0.8500 0.3250 0.0980];
    colors.total     = [0.0000 0.6200 0.4500];
    colors.baseline  = [0.4200 0.4200 0.4200];
    colors.wave      = [0.0000 0.4470 0.7410];
    colors.body      = [0.9290 0.6940 0.1250];
    colors.waterFill = [0.8200 0.9300 0.9800];
    colors.coupling  = [0.4940 0.1840 0.5560];

    fig = uifigure( ...
        'Name', 'HMEC | Coupled Heave-Pitch RAO Teaching Demo', ...
        'Position', [28 35 1570 900], ...
        'Color', [0.97 0.97 0.97]);

    root = uigridlayout(fig, [1 2]);
    root.ColumnWidth = {385, '1x'};
    root.RowHeight = {'1x'};
    root.Padding = [10 10 10 10];
    root.ColumnSpacing = 10;

    controlPanel = uipanel(root, ...
        'Title', 'Inputs, comparison case, and class questions', ...
        'FontWeight', 'bold');
    controlPanel.Layout.Row = 1;
    controlPanel.Layout.Column = 1;

    controls = uigridlayout(controlPanel, [25 2]);
    controls.ColumnWidth = {198, '1x'};
    controls.RowHeight = {50, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, ...
                          25, 25, 25, 26, 26, 34, 20, 30, 40, 40, 32, 26, 42};
    controls.Padding = [8 8 8 8];
    controls.RowSpacing = 4;
    controls.ColumnSpacing = 7;

    banner = uilabel(controls, ...
        'Text', ['Generic 18 m floating WEC/hull. Coefficients have realistic ' ...
                 'scale and matrix properties, but are not validated device data.'], ...
        'WordWrap', 'on', ...
        'FontWeight', 'bold', ...
        'FontColor', [0.55 0.20 0.05]);
    banner.Layout.Row = 1;
    banner.Layout.Column = [1 2];

    massSpinner = makeSpinner(controls, 2, 'Body mass, m [tonne]', ...
        [150 1000], 10, defaults.massTonnes, @updateAll);
    inertiaSpinner = makeSpinner(controls, 3, 'Pitch inertia, Iyy [10^6 kg m^2]', ...
        [3 60], 1, defaults.pitchInertia_Mkgm2, @updateAll);
    areaSpinner = makeSpinner(controls, 4, 'Waterplane area, A_wp [m^2]', ...
        [25 180], 5, defaults.waterplaneArea, @updateAll);
    pitchRestoringSpinner = makeSpinner(controls, 5, 'Pitch restoring, C55 [MN m/rad]', ...
        [3 80], 1, defaults.pitchRestoring_MNmPerRad, @updateAll);
    heavePtoSpinner = makeSpinner(controls, 6, 'Heave PTO damping [kN s/m]', ...
        [0 600], 10, defaults.heavePtoDamping_kNsPerM, @updateAll);
    pitchPtoSpinner = makeSpinner(controls, 7, 'Pitch PTO damping [MN m s/rad]', ...
        [0 20], 0.25, defaults.pitchPtoDamping_MNmsPerRad, @updateAll);
    heaveViscSpinner = makeSpinner(controls, 8, 'Extra heave damping [kN s/m]', ...
        [0 250], 5, defaults.heaveViscousDamping_kNsPerM, @updateAll);
    pitchViscSpinner = makeSpinner(controls, 9, 'Extra pitch damping [MN m s/rad]', ...
        [0 10], 0.20, defaults.pitchViscousDamping_MNmsPerRad, @updateAll);
    heaveStiffnessSpinner = makeSpinner(controls, 10, 'Extra heave stiffness [kN/m]', ...
        [0 1200], 25, defaults.extraHeaveStiffness_kNPerM, @updateAll);
    pitchStiffnessSpinner = makeSpinner(controls, 11, 'Extra pitch stiffness [MN m/rad]', ...
        [0 80], 1, defaults.extraPitchStiffness_MNmPerRad, @updateAll);
    couplingSpinner = makeSpinner(controls, 12, 'Heave-pitch coupling [%]', ...
        [0 150], 5, defaults.couplingPercent, @updateAll);
    addedMassScaleSpinner = makeSpinner(controls, 13, 'Added-mass scale [-]', ...
        [0.40 1.80], 0.05, defaults.addedMassScale, @updateAll);
    radiationScaleSpinner = makeSpinner(controls, 14, 'Radiation-damping scale [-]', ...
        [0.40 1.80], 0.05, defaults.radiationScale, @updateAll);
    waveAmplitudeSpinner = makeSpinner(controls, 15, 'Wave amplitude, a [m]', ...
        [0.05 1.50], 0.05, defaults.waveAmplitude, @updateAll);

    directPitchCheckbox = uicheckbox(controls, ...
        'Text', 'Include direct wave-excitation pitch moment', ...
        'Value', defaults.includeDirectPitchExcitation, ...
        'ValueChangedFcn', @updateAll);
    directPitchCheckbox.Layout.Row = 16;
    directPitchCheckbox.Layout.Column = [1 2];

    periodLabel = uilabel(controls, 'Text', 'Selected wave period [s]');
    periodLabel.Layout.Row = 17;
    periodLabel.Layout.Column = 1;
    selectedPeriodSpinner = uispinner(controls, ...
        'Limits', [defaults.periodMin defaults.periodMax], ...
        'Step', 0.25, ...
        'Value', defaults.selectedPeriod, ...
        'ValueDisplayFormat', '%.3g', ...
        'ValueChangedFcn', @updateAll);
    selectedPeriodSpinner.Layout.Row = 17;
    selectedPeriodSpinner.Layout.Column = 2;

    buttonGrid = uigridlayout(controls, [1 3]);
    buttonGrid.Layout.Row = 18;
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
    questionLabel.Layout.Row = 19;
    questionLabel.Layout.Column = [1 2];

    questionTitles = heavePitchQuestionTitles();
    questionDropDown = uidropdown(controls, ...
        'Items', questionTitles, ...
        'Value', questionTitles{1}, ...
        'ValueChangedFcn', @showQuestionPrompt);
    questionDropDown.Layout.Row = 20;
    questionDropDown.Layout.Column = [1 2];

    questionArea = uitextarea(controls, ...
        'Editable', 'off', ...
        'WordWrap', 'on', ...
        'Value', {'Select a question, ask for a prediction, then change the indicated control.'});
    questionArea.Layout.Row = [21 22];
    questionArea.Layout.Column = [1 2];

    revealButton = uibutton(controls, 'push', ...
        'Text', 'Reveal explanation', ...
        'ButtonPushedFcn', @revealQuestionAnswer);
    revealButton.Layout.Row = 23;
    revealButton.Layout.Column = [1 2];

    pitchUnitsLabel = uilabel(controls, 'Text', 'Pitch RAO display units');
    pitchUnitsLabel.Layout.Row = 24;
    pitchUnitsLabel.Layout.Column = 1;
    pitchUnitsDropDown = uidropdown(controls, ...
        'Items', {'deg/m', 'rad/m'}, ...
        'Value', defaults.pitchDisplayUnits, ...
        'ValueChangedFcn', @updateAll);
    pitchUnitsDropDown.Layout.Row = 24;
    pitchUnitsDropDown.Layout.Column = 2;

    statusLabel = uilabel(controls, ...
        'Text', 'Matrix and response checks pending ...', ...
        'WordWrap', 'on', ...
        'FontWeight', 'bold', ...
        'FontSize', 10);
    statusLabel.Layout.Row = 25;
    statusLabel.Layout.Column = [1 2];

    tabs = uitabgroup(root);
    tabs.Layout.Row = 1;
    tabs.Layout.Column = 2;

    responseTab = uitab(tabs, 'Title', 'Coupled RAOs, phase, and power');
    responseGrid = uigridlayout(responseTab, [2 2]);
    responseGrid.RowHeight = {'1x', '1x'};
    responseGrid.ColumnWidth = {'1x', '1x'};
    responseGrid.Padding = [10 10 10 10];
    responseGrid.RowSpacing = 10;
    responseGrid.ColumnSpacing = 10;

    heaveRaoAxis = uiaxes(responseGrid);
    heaveRaoAxis.Layout.Row = 1;
    heaveRaoAxis.Layout.Column = 1;
    pitchRaoAxis = uiaxes(responseGrid);
    pitchRaoAxis.Layout.Row = 1;
    pitchRaoAxis.Layout.Column = 2;
    phaseAxis = uiaxes(responseGrid);
    phaseAxis.Layout.Row = 2;
    phaseAxis.Layout.Column = 1;
    powerAxis = uiaxes(responseGrid);
    powerAxis.Layout.Row = 2;
    powerAxis.Layout.Column = 2;

    matrixTab = uitab(tabs, 'Title', 'Hydrodynamic matrices and excitation');
    matrixGrid = uigridlayout(matrixTab, [4 2]);
    matrixGrid.RowHeight = {'1x', '1x', '1x', '1x'};
    matrixGrid.ColumnWidth = {'1x', '1x'};
    matrixGrid.Padding = [10 10 10 10];
    matrixGrid.RowSpacing = 8;
    matrixGrid.ColumnSpacing = 10;

    addedHeaveAxis = uiaxes(matrixGrid);
    addedHeaveAxis.Layout.Row = 1;
    addedHeaveAxis.Layout.Column = 1;
    addedPitchAxis = uiaxes(matrixGrid);
    addedPitchAxis.Layout.Row = 1;
    addedPitchAxis.Layout.Column = 2;
    dampingHeaveAxis = uiaxes(matrixGrid);
    dampingHeaveAxis.Layout.Row = 2;
    dampingHeaveAxis.Layout.Column = 1;
    dampingPitchAxis = uiaxes(matrixGrid);
    dampingPitchAxis.Layout.Row = 2;
    dampingPitchAxis.Layout.Column = 2;
    addedCrossAxis = uiaxes(matrixGrid);
    addedCrossAxis.Layout.Row = 3;
    addedCrossAxis.Layout.Column = 1;
    dampingCrossAxis = uiaxes(matrixGrid);
    dampingCrossAxis.Layout.Row = 3;
    dampingCrossAxis.Layout.Column = 2;
    excitationForceAxis = uiaxes(matrixGrid);
    excitationForceAxis.Layout.Row = 4;
    excitationForceAxis.Layout.Column = 1;
    excitationMomentAxis = uiaxes(matrixGrid);
    excitationMomentAxis.Layout.Row = 4;
    excitationMomentAxis.Layout.Column = 2;

    motionTab = uitab(tabs, 'Title', 'Selected regular-wave motion');
    motionGrid = uigridlayout(motionTab, [3 2]);
    motionGrid.RowHeight = {'1x', '1x', 175};
    motionGrid.ColumnWidth = {'1.15x', '1x'};
    motionGrid.Padding = [10 10 10 10];
    motionGrid.RowSpacing = 10;
    motionGrid.ColumnSpacing = 10;

    animationAxis = uiaxes(motionGrid);
    animationAxis.Layout.Row = [1 2];
    animationAxis.Layout.Column = 1;
    heaveTimeAxis = uiaxes(motionGrid);
    heaveTimeAxis.Layout.Row = 1;
    heaveTimeAxis.Layout.Column = 2;
    pitchTimeAxis = uiaxes(motionGrid);
    pitchTimeAxis.Layout.Row = 2;
    pitchTimeAxis.Layout.Column = 2;
    summaryArea = uitextarea(motionGrid, ...
        'Editable', 'off', ...
        'WordWrap', 'on');
    summaryArea.Layout.Row = 3;
    summaryArea.Layout.Column = [1 2];

    equationTab = uitab(tabs, 'Title', 'Equation, units, and impedance');
    equationGrid = uigridlayout(equationTab, [2 2]);
    equationGrid.RowHeight = {'1x', '1x'};
    equationGrid.ColumnWidth = {520, '1x'};
    equationGrid.Padding = [10 10 10 10];
    equationGrid.RowSpacing = 10;
    equationGrid.ColumnSpacing = 10;

    equationArea = uitextarea(equationGrid, ...
        'Editable', 'off', ...
        'WordWrap', 'on');
    equationArea.Layout.Row = [1 2];
    equationArea.Layout.Column = 1;
    impedanceAxis = uiaxes(equationGrid);
    impedanceAxis.Layout.Row = 1;
    impedanceAxis.Layout.Column = 2;
    contributionAxis = uiaxes(equationGrid);
    contributionAxis.Layout.Row = 2;
    contributionAxis.Layout.Column = 2;

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
        P.pitchInertia_Mkgm2 = inertiaSpinner.Value;
        P.waterplaneArea = areaSpinner.Value;
        P.pitchRestoring_MNmPerRad = pitchRestoringSpinner.Value;
        P.heavePtoDamping_kNsPerM = heavePtoSpinner.Value;
        P.pitchPtoDamping_MNmsPerRad = pitchPtoSpinner.Value;
        P.heaveViscousDamping_kNsPerM = heaveViscSpinner.Value;
        P.pitchViscousDamping_MNmsPerRad = pitchViscSpinner.Value;
        P.extraHeaveStiffness_kNPerM = heaveStiffnessSpinner.Value;
        P.extraPitchStiffness_MNmPerRad = pitchStiffnessSpinner.Value;
        P.couplingPercent = couplingSpinner.Value;
        P.addedMassScale = addedMassScaleSpinner.Value;
        P.radiationScale = radiationScaleSpinner.Value;
        P.waveAmplitude = waveAmplitudeSpinner.Value;
        P.includeDirectPitchExcitation = directPitchCheckbox.Value;
        P.selectedPeriod = selectedPeriodSpinner.Value;
        P.pitchDisplayUnits = pitchUnitsDropDown.Value;
    end

    function updateAll(varargin)
        P = readControls();
        D = calculateHeavePitchResponse(P);

        plotResponse(P, D);
        plotMatrices(P, D);
        plotMotion(P, D);
        plotEquationAndImpedance(P, D);

        [checksPass, checkMessage] = heavePitchDiagnostics(P, D);
        statusLabel.Text = checkMessage;
        if checksPass
            statusLabel.FontColor = [0.00 0.45 0.15];
        else
            statusLabel.FontColor = [0.75 0.00 0.00];
        end
    end

    function plotResponse(P, D)
        [pitchScale, pitchUnits] = pitchDisplayScale(P.pitchDisplayUnits);
        [baselinePitchScale, ~] = pitchDisplayScale(P.pitchDisplayUnits);

        cla(heaveRaoAxis)
        hold(heaveRaoAxis, 'on')
        plot(heaveRaoAxis, baseline.D.period, abs(baseline.D.H(1,:)), '--', ...
            'Color', colors.baseline, 'LineWidth', 1.6, 'DisplayName', 'Comparison baseline');
        plot(heaveRaoAxis, D.period, abs(D.H(1,:)), '-', ...
            'Color', colors.heave, 'LineWidth', 2.3, 'DisplayName', 'Current case');
        markSelectedPeriod(heaveRaoAxis, P.selectedPeriod);
        hold(heaveRaoAxis, 'off')
        title(heaveRaoAxis, 'Heave RAO magnitude')
        xlabel(heaveRaoAxis, 'Wave period, T [s]')
        ylabel(heaveRaoAxis, '|H_3| = |z-hat|/a [m/m]')
        xlim(heaveRaoAxis, [P.periodMin P.periodMax])
        legend(heaveRaoAxis, 'Location', 'best')
        styleAxis(heaveRaoAxis)

        cla(pitchRaoAxis)
        hold(pitchRaoAxis, 'on')
        plot(pitchRaoAxis, baseline.D.period, baselinePitchScale*abs(baseline.D.H(2,:)), '--', ...
            'Color', colors.baseline, 'LineWidth', 1.6, 'DisplayName', 'Comparison baseline');
        plot(pitchRaoAxis, D.period, pitchScale*abs(D.H(2,:)), '-', ...
            'Color', colors.pitch, 'LineWidth', 2.3, 'DisplayName', 'Current case');
        markSelectedPeriod(pitchRaoAxis, P.selectedPeriod);
        hold(pitchRaoAxis, 'off')
        title(pitchRaoAxis, 'Pitch RAO magnitude')
        xlabel(pitchRaoAxis, 'Wave period, T [s]')
        ylabel(pitchRaoAxis, sprintf('|H_5| = |theta-hat|/a [%s]', pitchUnits))
        xlim(pitchRaoAxis, [P.periodMin P.periodMax])
        legend(pitchRaoAxis, 'Location', 'best')
        styleAxis(pitchRaoAxis)

        cla(phaseAxis)
        hold(phaseAxis, 'on')
        plot(phaseAxis, D.period, phaseDegrees(D.H(1,:)), '-', ...
            'Color', colors.heave, 'LineWidth', 2.0, 'DisplayName', 'Heave phase');
        plot(phaseAxis, D.period, phaseDegrees(D.H(2,:)), '-', ...
            'Color', colors.pitch, 'LineWidth', 2.0, 'DisplayName', 'Pitch phase');
        markSelectedPeriod(phaseAxis, P.selectedPeriod);
        hold(phaseAxis, 'off')
        title(phaseAxis, 'Response phase relative to wave elevation')
        xlabel(phaseAxis, 'Wave period, T [s]')
        ylabel(phaseAxis, 'Phase [deg]')
        xlim(phaseAxis, [P.periodMin P.periodMax])
        ylim(phaseAxis, [-190 190])
        legend(phaseAxis, 'Location', 'best')
        styleAxis(phaseAxis)

        cla(powerAxis)
        hold(powerAxis, 'on')
        plot(powerAxis, D.period, D.meanPtoPowerHeave/1e3, '-', ...
            'Color', colors.heave, 'LineWidth', 1.9, 'DisplayName', 'Heave PTO');
        plot(powerAxis, D.period, D.meanPtoPowerPitch/1e3, '-', ...
            'Color', colors.pitch, 'LineWidth', 1.9, 'DisplayName', 'Pitch PTO');
        plot(powerAxis, D.period, D.meanPtoPowerTotal/1e3, '-', ...
            'Color', colors.total, 'LineWidth', 2.4, 'DisplayName', 'Total');
        markSelectedPeriod(powerAxis, P.selectedPeriod);
        hold(powerAxis, 'off')
        title(powerAxis, sprintf('Mean mechanical PTO power for a = %.2f m', P.waveAmplitude))
        xlabel(powerAxis, 'Wave period, T [s]')
        ylabel(powerAxis, 'Mean power [kW]')
        xlim(powerAxis, [P.periodMin P.periodMax])
        legend(powerAxis, 'Location', 'best')
        styleAxis(powerAxis)
    end

    function plotMatrices(P, D)
        plotCoefficient(addedHeaveAxis, P, D.period, D.A33/1e3, ...
            baseline.D.period, baseline.D.A33/1e3, colors.heave, ...
            'A_{33}: heave added mass', 'A_{33} [tonne]');
        plotCoefficient(addedPitchAxis, P, D.period, D.A55/1e6, ...
            baseline.D.period, baseline.D.A55/1e6, colors.pitch, ...
            'A_{55}: pitch added inertia', 'A_{55} [10^6 kg m^2]');
        plotCoefficient(dampingHeaveAxis, P, D.period, D.B33/1e3, ...
            baseline.D.period, baseline.D.B33/1e3, colors.heave, ...
            'B_{33}: heave radiation damping', 'B_{33} [kN s/m]');
        plotCoefficient(dampingPitchAxis, P, D.period, D.B55/1e6, ...
            baseline.D.period, baseline.D.B55/1e6, colors.pitch, ...
            'B_{55}: pitch radiation damping', 'B_{55} [MN m s/rad]');
        plotCoefficient(addedCrossAxis, P, D.period, D.A35/1e6, ...
            baseline.D.period, baseline.D.A35/1e6, colors.coupling, ...
            'A_{35}=A_{53}: inertial coupling', 'A_{35} [10^6 kg m]');
        plotCoefficient(dampingCrossAxis, P, D.period, D.B35/1e6, ...
            baseline.D.period, baseline.D.B35/1e6, colors.coupling, ...
            'B_{35}=B_{53}: radiation coupling', 'B_{35} [MN s]');
        plotCoefficient(excitationForceAxis, P, D.period, abs(D.excitation(1,:))/1e3, ...
            baseline.D.period, abs(baseline.D.excitation(1,:))/1e3, colors.total, ...
            'Wave-excitation force transfer', '|F_{exc,3}|/a [kN/m]');
        plotCoefficient(excitationMomentAxis, P, D.period, abs(D.excitation(2,:))/1e3, ...
            baseline.D.period, abs(baseline.D.excitation(2,:))/1e3, colors.total, ...
            'Wave-excitation moment transfer', '|M_{exc,5}|/a [kN]');
    end

    function plotCoefficient(axisHandle, P, period, currentValue, basePeriod, baseValue, color, plotTitle, yLabelText)
        cla(axisHandle)
        hold(axisHandle, 'on')
        plot(axisHandle, basePeriod, baseValue, '--', ...
            'Color', colors.baseline, 'LineWidth', 1.3, 'DisplayName', 'Baseline');
        plot(axisHandle, period, currentValue, '-', ...
            'Color', color, 'LineWidth', 2.0, 'DisplayName', 'Current');
        markSelectedPeriod(axisHandle, P.selectedPeriod);
        hold(axisHandle, 'off')
        title(axisHandle, plotTitle)
        xlabel(axisHandle, 'T [s]')
        ylabel(axisHandle, yLabelText)
        xlim(axisHandle, [P.periodMin P.periodMax])
        styleAxis(axisHandle)
    end

    function plotMotion(P, D)
        renderHeavePitchFrame(animationAxis, P, D, 0, colors)

        t = linspace(0, 4*P.selectedPeriod, 700);
        eta = P.waveAmplitude*cos(D.selectedOmega*t);
        z = real(P.waveAmplitude*D.selectedH(1).*exp(1i*D.selectedOmega*t));
        theta = real(P.waveAmplitude*D.selectedH(2).*exp(1i*D.selectedOmega*t));
        slopeAngle = real(-1i*D.selectedWavenumber*P.waveAmplitude .* ...
            exp(1i*D.selectedOmega*t));

        cla(heaveTimeAxis)
        hold(heaveTimeAxis, 'on')
        plot(heaveTimeAxis, t, eta, '-', ...
            'Color', colors.wave, 'LineWidth', 1.7, 'DisplayName', 'Wave elevation eta');
        plot(heaveTimeAxis, t, z, '-', ...
            'Color', colors.heave, 'LineWidth', 2.1, 'DisplayName', 'Heave z');
        hold(heaveTimeAxis, 'off')
        title(heaveTimeAxis, sprintf('Heave at T = %.2f s', P.selectedPeriod))
        xlabel(heaveTimeAxis, 'Time [s]')
        ylabel(heaveTimeAxis, 'Elevation / displacement [m]')
        legend(heaveTimeAxis, 'Location', 'best')
        styleAxis(heaveTimeAxis)

        cla(pitchTimeAxis)
        hold(pitchTimeAxis, 'on')
        plot(pitchTimeAxis, t, slopeAngle*180/pi, '--', ...
            'Color', colors.wave, 'LineWidth', 1.6, 'DisplayName', 'Local wave slope');
        plot(pitchTimeAxis, t, theta*180/pi, '-', ...
            'Color', colors.pitch, 'LineWidth', 2.1, 'DisplayName', 'Pitch theta');
        hold(pitchTimeAxis, 'off')
        title(pitchTimeAxis, 'Pitch and local wave-slope angle')
        xlabel(pitchTimeAxis, 'Time [s]')
        ylabel(pitchTimeAxis, 'Angle [deg]')
        legend(pitchTimeAxis, 'Location', 'best')
        styleAxis(pitchTimeAxis)

        summaryText = sprintf([ ...
            'SELECTED FREQUENCY: T = %.2f s, omega = %.3f rad/s, a = %.2f m\n' ...
            'BODY: m = %.1f tonne, Iyy = %.2f x 10^6 kg m^2, A_wp = %.1f m^2\n' ...
            'RESTORING: C33 = %.1f kN/m, C55 = %.2f MN m/rad, C35 = C53 = %.1f kN\n' ...
            'HYDRODYNAMICS: A33 = %.1f tonne, A55 = %.2f x 10^6 kg m^2, ' ...
            'B33 = %.1f kN s/m, B55 = %.2f MN m s/rad\n' ...
            'RESPONSE: |H3| = %.3f m/m, phase = %.1f deg; ' ...
            '|H5| = %.4f rad/m = %.2f deg/m, phase = %.1f deg\n' ...
            'PHYSICAL AMPLITUDES: |z| = %.3f m, |theta| = %.2f deg; ' ...
            'mean PTO power = %.1f kW\n' ...
            'UNCOUPLED inertia-restoring estimates: heave T ~= %.2f s; pitch T ~= %.2f s'], ...
            P.selectedPeriod, D.selectedOmega, P.waveAmplitude, ...
            P.massTonnes, P.pitchInertia_Mkgm2, P.waterplaneArea, ...
            D.C(1,1)/1e3, D.C(2,2)/1e6, D.C(1,2)/1e3, ...
            D.selectedA(1,1)/1e3, D.selectedA(2,2)/1e6, ...
            D.selectedB(1,1)/1e3, D.selectedB(2,2)/1e6, ...
            abs(D.selectedH(1)), phaseDegrees(D.selectedH(1)), ...
            abs(D.selectedH(2)), abs(D.selectedH(2))*180/pi, ...
            phaseDegrees(D.selectedH(2)), ...
            P.waveAmplitude*abs(D.selectedH(1)), ...
            P.waveAmplitude*abs(D.selectedH(2))*180/pi, ...
            D.selectedMeanPtoPowerTotal/1e3, ...
            D.estimatedHeaveBalancePeriod, D.estimatedPitchBalancePeriod);
        summaryArea.Value = splitText(summaryText);
    end

    function plotEquationAndImpedance(P, D)
        equationText = sprintf([ ...
            'COUPLED FREQUENCY-DOMAIN EQUATION\n\n' ...
            '[-omega^2(M+A) + i omega(B+B_PTO+B_visc) + (C+K_extra)] q-hat = F-exc-hat\n\n' ...
            'q = [z; theta], with z in m and theta in rad.\n' ...
            'Generalized load = [vertical force; pitch moment] in [N; N m].\n\n' ...
            'MATRIX-ENTRY UNITS\n' ...
            'M33, A33: kg\n' ...
            'M35=A35 and M53=A53: kg m\n' ...
            'M55, A55: kg m^2\n\n' ...
            'B33: N s/m\n' ...
            'B35=B53: N s\n' ...
            'B55: N m s/rad\n\n' ...
            'C33: N/m\n' ...
            'C35=C53: N (equivalently force/rad or moment/m)\n' ...
            'C55: N m/rad\n\n' ...
            'RAO UNITS\n' ...
            'H3 = z-hat/a: m/m, dimensionless.\n' ...
            'H5 = theta-hat/a: rad/m (or deg/m), not dimensionless.\n\n' ...
            'CURRENT SELECTED-PERIOD MATRICES (SI)\n' ...
            'M+A = [%.4g, %.4g; %.4g, %.4g]\n' ...
            'B+external = [%.4g, %.4g; %.4g, %.4g]\n' ...
            'C+K = [%.4g, %.4g; %.4g, %.4g]\n\n' ...
            'For the plots at right, pitch is converted to an equivalent vertical ' ...
            'coordinate L*theta using L = %.1f m. This makes every scaled impedance ' ...
            'entry comparable in kN/m.'], ...
            D.selectedEffectiveMass(1,1), D.selectedEffectiveMass(1,2), ...
            D.selectedEffectiveMass(2,1), D.selectedEffectiveMass(2,2), ...
            D.selectedEffectiveDamping(1,1), D.selectedEffectiveDamping(1,2), ...
            D.selectedEffectiveDamping(2,1), D.selectedEffectiveDamping(2,2), ...
            D.totalStiffness(1,1), D.totalStiffness(1,2), ...
            D.totalStiffness(2,1), D.totalStiffness(2,2), ...
            P.referenceLength);
        equationArea.Value = splitText(equationText);

        scaledMagnitude = abs(D.selectedScaledImpedance)/1e3;
        cla(impedanceAxis)
        imagesc(impedanceAxis, scaledMagnitude)
        impedanceAxis.XTick = [1 2];
        impedanceAxis.YTick = [1 2];
        impedanceAxis.XTickLabel = {'z', 'L theta'};
        impedanceAxis.YTickLabel = {'F_z', 'M_y/L'};
        title(impedanceAxis, sprintf('|Scaled impedance Z| at T = %.2f s [kN/m]', P.selectedPeriod))
        colorbar(impedanceAxis)
        for rowIndex = 1:2
            for columnIndex = 1:2
                text(impedanceAxis, columnIndex, rowIndex, ...
                    sprintf('%.1f', scaledMagnitude(rowIndex,columnIndex)), ...
                    'HorizontalAlignment', 'center', ...
                    'FontWeight', 'bold', ...
                    'Color', [0.10 0.10 0.10]);
            end
        end
        impedanceAxis.Box = 'on';
        impedanceAxis.FontSize = 11;

        contributionValues = [norm(D.selectedScaledInertia,'fro'), ...
                              norm(D.selectedScaledDamping,'fro'), ...
                              norm(D.selectedScaledStiffness,'fro')]/1e3;
        cla(contributionAxis)
        bar(contributionAxis, contributionValues)
        contributionAxis.XTick = 1:3;
        contributionAxis.XTickLabel = {'|-omega^2(M+A)|', '|i omega B|', '|C+K|'};
        ylabel(contributionAxis, 'Frobenius norm [kN/m]')
        title(contributionAxis, 'Relative dynamic-stiffness contributions')
        styleAxis(contributionAxis)
    end

    function resetInputs(varargin)
        massSpinner.Value = defaults.massTonnes;
        inertiaSpinner.Value = defaults.pitchInertia_Mkgm2;
        areaSpinner.Value = defaults.waterplaneArea;
        pitchRestoringSpinner.Value = defaults.pitchRestoring_MNmPerRad;
        heavePtoSpinner.Value = defaults.heavePtoDamping_kNsPerM;
        pitchPtoSpinner.Value = defaults.pitchPtoDamping_MNmsPerRad;
        heaveViscSpinner.Value = defaults.heaveViscousDamping_kNsPerM;
        pitchViscSpinner.Value = defaults.pitchViscousDamping_MNmsPerRad;
        heaveStiffnessSpinner.Value = defaults.extraHeaveStiffness_kNPerM;
        pitchStiffnessSpinner.Value = defaults.extraPitchStiffness_MNmPerRad;
        couplingSpinner.Value = defaults.couplingPercent;
        addedMassScaleSpinner.Value = defaults.addedMassScale;
        radiationScaleSpinner.Value = defaults.radiationScale;
        waveAmplitudeSpinner.Value = defaults.waveAmplitude;
        directPitchCheckbox.Value = defaults.includeDirectPitchExcitation;
        selectedPeriodSpinner.Value = defaults.selectedPeriod;
        pitchUnitsDropDown.Value = defaults.pitchDisplayUnits;
        baseline.P = defaults;
        baseline.D = calculateHeavePitchResponse(defaults);
        updateAll();
    end

    function setCurrentBaseline(varargin)
        baseline.P = readControls();
        baseline.D = calculateHeavePitchResponse(baseline.P);
        updateAll();
    end

    function playMotion(varargin)
        P = readControls();
        D = calculateHeavePitchResponse(P);
        playButton.Enable = 'off';
        cleanup = onCleanup(@() setPlayButtonEnabled());
        frameTimes = linspace(0, 2*P.selectedPeriod, 140);
        for frameIndex = 1:numel(frameTimes)
            if ~isvalid(fig)
                return
            end
            renderHeavePitchFrame(animationAxis, P, D, frameTimes(frameIndex), colors)
            drawnow limitrate
            pause(0.012)
        end
        renderHeavePitchFrame(animationAxis, P, D, 0, colors)
        clear cleanup
        setPlayButtonEnabled();
    end

    function setPlayButtonEnabled()
        if isvalid(playButton)
            playButton.Enable = 'on';
        end
    end

    function showQuestionPrompt(varargin)
        [prompt, ~] = heavePitchQuestionText(questionDropDown.Value);
        questionArea.Value = splitText(sprintf([ ...
            'ASK THE CLASS:\n%s\n\nChange the indicated control and compare the ' ...
            'current curve with the dashed baseline.'], prompt));
    end

    function revealQuestionAnswer(varargin)
        [prompt, answer] = heavePitchQuestionText(questionDropDown.Value);
        questionArea.Value = splitText(sprintf( ...
            'QUESTION:\n%s\n\nEXPECTED EXPLANATION:\n%s', prompt, answer));
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
        axisHandle.FontSize = 10.5;
        axisHandle.LineWidth = 0.9;
    end
end

function P = defaultHeavePitchParameters()
    P.rho = 1025;                              % seawater density [kg/m^3]
    P.g = 9.81;                                % gravity [m/s^2]
    P.waterDepth = 80;                         % [m]
    P.periodMin = 3.0;                         % [s]
    P.periodMax = 16.0;                        % [s]
    P.numberOfPeriods = 560;

    % Generic elongated floating WEC/hull dimensions used for coefficient
    % scaling and the motion sketch. They do not define a detailed hull.
    P.referenceLength = 18.0;                  % [m]
    P.referenceBeam = 6.0;                     % [m]
    P.bodyDepth = 4.2;                         % visual depth [m]
    P.waterplaneArea = 80.0;                   % [m^2]
    P.massTonnes = 420.0;                      % [tonne]
    P.referenceDraft = P.massTonnes*1e3/(P.rho*P.waterplaneArea); % [m]
    P.pitchInertia_Mkgm2 = 13.0;               % [10^6 kg m^2]

    P.pitchRestoring_MNmPerRad = 18.0;         % [MN m/rad]
    P.heavePtoDamping_kNsPerM = 130.0;         % [kN s/m]
    P.pitchPtoDamping_MNmsPerRad = 2.50;       % [MN m s/rad]
    P.heaveViscousDamping_kNsPerM = 30.0;      % [kN s/m]
    P.pitchViscousDamping_MNmsPerRad = 0.60;   % [MN m s/rad]
    P.extraHeaveStiffness_kNPerM = 0.0;        % [kN/m]
    P.extraPitchStiffness_MNmPerRad = 0.0;     % [MN m/rad]

    P.couplingPercent = 100.0;
    P.addedMassScale = 1.0;
    P.radiationScale = 1.0;
    P.excitationScale = 1.0;
    P.includeDirectPitchExcitation = true;

    P.waveAmplitude = 0.50;                    % [m]
    P.selectedPeriod = 7.00;                   % [s]
    P.pitchDisplayUnits = 'deg/m';
end

function D = calculateHeavePitchResponse(P)
    D.period = linspace(P.periodMin, P.periodMax, P.numberOfPeriods);
    D.omega = 2*pi./D.period;
    numberOfFrequencies = numel(D.omega);

    bodyMass = P.massTonnes*1e3;
    bodyPitchInertia = P.pitchInertia_Mkgm2*1e6;
    D.Mbody = diag([bodyMass, bodyPitchInertia]);

    D.C33 = P.rho*P.g*P.waterplaneArea;
    D.C55 = P.pitchRestoring_MNmPerRad*1e6;
    couplingScale = P.couplingPercent/100;

    % Symmetric hydrostatic coupling. The correlation form guarantees a
    % positive-definite hydrostatic matrix while couplingPercent is in the
    % classroom range. The sign depends on reference point and geometry in
    % a real model; a positive sign is chosen here for a clear demonstration.
    hydrostaticCorrelation = 0.10*couplingScale;
    D.C35 = hydrostaticCorrelation*sqrt(D.C33*D.C55);
    D.C = [D.C33 D.C35; D.C35 D.C55];
    D.Kextra = diag([P.extraHeaveStiffness_kNPerM*1e3, ...
                     P.extraPitchStiffness_MNmPerRad*1e6]);
    D.totalStiffness = D.C + D.Kextra;

    referenceDisplacedMass = P.rho*P.waterplaneArea*P.referenceDraft;
    referenceHydrodynamicPitchInertia = referenceDisplacedMass * ...
        (P.referenceLength^2 + P.referenceDraft^2)/12;

    x3 = D.omega/(2*pi/7.2);
    x5 = D.omega/(2*pi/8.8);

    D.A33 = P.addedMassScale*referenceDisplacedMass .* ...
        (0.52 + 0.20./(1 + x3.^2) + 0.16*exp(-((x3 - 1)/0.50).^2));
    D.A55 = P.addedMassScale*referenceHydrodynamicPitchInertia .* ...
        (0.60 + 0.16./(1 + x5.^2) + 0.12*exp(-((x5 - 1)/0.55).^2));

    addedMassCorrelation = 0.18*couplingScale .* ...
        exp(-((0.5*(x3 + x5) - 1)/1.40).^2);
    D.A35 = addedMassCorrelation .* sqrt(D.A33.*D.A55);

    heaveDampingScale = sqrt(D.C33*referenceDisplacedMass);
    pitchDampingScale = sqrt(D.C55*referenceHydrodynamicPitchInertia);
    D.B33 = P.radiationScale*0.55*heaveDampingScale .* ...
        x3.^2 .* exp(1 - x3.^2);
    D.B55 = P.radiationScale*0.35*pitchDampingScale .* ...
        x5.^2 .* exp(1 - x5.^2);

    dampingCorrelation = -0.22*couplingScale .* ...
        exp(-((0.5*(x3 + x5) - 1)/1.20).^2);
    D.B35 = dampingCorrelation .* sqrt(D.B33.*D.B55);

    % Excitation vector per unit incident-wave amplitude. Long waves give
    % F_exc,3/a -> C33. The pitch-moment component follows wave slope and
    % includes the hydrostatic reference-point coupling term. The complex
    % phase is essential: force and moment need not peak at the same instant.
    D.wavenumber = dispersionWavenumber(D.omega, P.waterDepth, P.g);
    heaveExcitationShape = (1 + 0.12*x3.^2) ./ sqrt(1 + (x3/1.65).^6);
    pitchSlopeShape = exp(-0.10*x5.^2) ./ sqrt(1 + (x5/1.80).^4);
    waveSlopePerAmplitude = -1i*D.wavenumber.*pitchSlopeShape;

    D.excitation = zeros(2, numberOfFrequencies);
    D.excitation(1,:) = P.excitationScale .* ...
        (D.C33*heaveExcitationShape + 0.25*D.C35*waveSlopePerAmplitude);
    D.excitation(2,:) = P.excitationScale .* ...
        (D.C35*heaveExcitationShape + D.C55*waveSlopePerAmplitude);
    if ~P.includeDirectPitchExcitation
        D.excitation(2,:) = 0;
    end

    D.Bexternal = diag([ ...
        (P.heavePtoDamping_kNsPerM + P.heaveViscousDamping_kNsPerM)*1e3, ...
        (P.pitchPtoDamping_MNmsPerRad + P.pitchViscousDamping_MNmsPerRad)*1e6]);

    D.H = zeros(2, numberOfFrequencies);
    D.A = zeros(2,2,numberOfFrequencies);
    D.B = zeros(2,2,numberOfFrequencies);
    D.dynamicStiffness = zeros(2,2,numberOfFrequencies);

    for frequencyIndex = 1:numberOfFrequencies
        D.A(:,:,frequencyIndex) = [ ...
            D.A33(frequencyIndex), D.A35(frequencyIndex); ...
            D.A35(frequencyIndex), D.A55(frequencyIndex)];
        D.B(:,:,frequencyIndex) = [ ...
            D.B33(frequencyIndex), D.B35(frequencyIndex); ...
            D.B35(frequencyIndex), D.B55(frequencyIndex)];
        D.dynamicStiffness(:,:,frequencyIndex) = ...
            -D.omega(frequencyIndex)^2*(D.Mbody + D.A(:,:,frequencyIndex)) ...
            + 1i*D.omega(frequencyIndex)*(D.B(:,:,frequencyIndex) + D.Bexternal) ...
            + D.totalStiffness;
        D.H(:,frequencyIndex) = D.dynamicStiffness(:,:,frequencyIndex) \ ...
            D.excitation(:,frequencyIndex);
    end

    heavePto = P.heavePtoDamping_kNsPerM*1e3;
    pitchPto = P.pitchPtoDamping_MNmsPerRad*1e6;
    D.meanPtoPowerHeave = 0.5*heavePto .* ...
        (D.omega*P.waveAmplitude .* abs(D.H(1,:))).^2;
    D.meanPtoPowerPitch = 0.5*pitchPto .* ...
        (D.omega*P.waveAmplitude .* abs(D.H(2,:))).^2;
    D.meanPtoPowerTotal = D.meanPtoPowerHeave + D.meanPtoPowerPitch;

    [~, heaveBalanceIndex] = min(abs(D.totalStiffness(1,1) ...
        - D.omega.^2.*(D.Mbody(1,1) + D.A33)));
    [~, pitchBalanceIndex] = min(abs(D.totalStiffness(2,2) ...
        - D.omega.^2.*(D.Mbody(2,2) + D.A55)));
    D.estimatedHeaveBalancePeriod = D.period(heaveBalanceIndex);
    D.estimatedPitchBalancePeriod = D.period(pitchBalanceIndex);

    D.selectedOmega = 2*pi/P.selectedPeriod;
    D.selectedWavenumber = dispersionWavenumber(D.selectedOmega, P.waterDepth, P.g);
    D.selectedH = [ ...
        interp1(D.period, D.H(1,:), P.selectedPeriod, 'pchip'); ...
        interp1(D.period, D.H(2,:), P.selectedPeriod, 'pchip')];
    D.selectedA = interpolateMatrix(D.period, D.A, P.selectedPeriod);
    D.selectedB = interpolateMatrix(D.period, D.B, P.selectedPeriod);
    D.selectedExcitation = [ ...
        interp1(D.period, D.excitation(1,:), P.selectedPeriod, 'pchip'); ...
        interp1(D.period, D.excitation(2,:), P.selectedPeriod, 'pchip')];
    D.selectedMeanPtoPowerHeave = interp1(D.period, D.meanPtoPowerHeave, P.selectedPeriod, 'pchip');
    D.selectedMeanPtoPowerPitch = interp1(D.period, D.meanPtoPowerPitch, P.selectedPeriod, 'pchip');
    D.selectedMeanPtoPowerTotal = interp1(D.period, D.meanPtoPowerTotal, P.selectedPeriod, 'pchip');

    D.selectedEffectiveMass = D.Mbody + D.selectedA;
    D.selectedEffectiveDamping = D.selectedB + D.Bexternal;
    D.selectedScaledInertia = scaleGeneralizedMatrix( ...
        -D.selectedOmega^2*D.selectedEffectiveMass, P.referenceLength);
    D.selectedScaledDamping = scaleGeneralizedMatrix( ...
        1i*D.selectedOmega*D.selectedEffectiveDamping, P.referenceLength);
    D.selectedScaledStiffness = scaleGeneralizedMatrix( ...
        D.totalStiffness, P.referenceLength);
    D.selectedScaledImpedance = D.selectedScaledInertia + ...
        D.selectedScaledDamping + D.selectedScaledStiffness;
end

function matrixValue = interpolateMatrix(period, matrixSeries, selectedPeriod)
    matrixValue = zeros(2,2);
    for rowIndex = 1:2
        for columnIndex = 1:2
            matrixValue(rowIndex,columnIndex) = interp1(period, ...
                squeeze(matrixSeries(rowIndex,columnIndex,:)), ...
                selectedPeriod, 'pchip');
        end
    end
end

function scaledMatrix = scaleGeneralizedMatrix(matrixValue, referenceLength)
    % q = D*q_scaled with q_scaled=[z; L*theta], D=diag(1,1/L).
    % Premultiplying by D' preserves virtual work and gives units N/m.
    coordinateMap = diag([1, 1/referenceLength]);
    scaledMatrix = coordinateMap.'*matrixValue*coordinateMap;
end

function renderHeavePitchFrame(axisHandle, P, D, time, colors)
    cla(axisHandle)
    hold(axisHandle, 'on')

    xExtent = max(16, 1.25*P.referenceLength);
    x = linspace(-xExtent, xExtent, 420);
    eta = P.waveAmplitude*cos(D.selectedWavenumber*x - D.selectedOmega*time);
    waterBottom = -10.0;

    patch(axisHandle, [x fliplr(x)], ...
        [eta waterBottom*ones(size(x))], ...
        colors.waterFill, 'EdgeColor', 'none', 'FaceAlpha', 0.78);
    plot(axisHandle, x, eta, '-', 'Color', colors.wave, 'LineWidth', 2.0)

    heave = real(P.waveAmplitude*D.selectedH(1)*exp(1i*D.selectedOmega*time));
    pitch = real(P.waveAmplitude*D.selectedH(2)*exp(1i*D.selectedOmega*time));

    halfLength = P.referenceLength/2;
    localX = [-halfLength, halfLength, 0.90*halfLength, -0.90*halfLength];
    localZ = [-0.55*P.bodyDepth, -0.55*P.bodyDepth, ...
               0.45*P.bodyDepth,  0.45*P.bodyDepth];
    rotation = [cos(pitch) -sin(pitch); sin(pitch) cos(pitch)];
    rotated = rotation*[localX; localZ];
    bodyX = rotated(1,:);
    bodyZ = rotated(2,:) + heave;

    patch(axisHandle, bodyX, bodyZ, colors.body, ...
        'EdgeColor', [0.15 0.15 0.15], 'LineWidth', 1.6);
    plot(axisHandle, 0, heave, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 5)

    mastLocal = rotation*[0 0; 0.45*P.bodyDepth 0.45*P.bodyDepth+2.0];
    plot(axisHandle, mastLocal(1,:), mastLocal(2,:)+heave, '-', ...
        'Color', [0.20 0.20 0.20], 'LineWidth', 3.0)

    seabed = waterBottom + 0.4;
    plot(axisHandle, [-xExtent xExtent], [seabed seabed], '-', ...
        'Color', [0.55 0.43 0.28], 'LineWidth', 4.0)

    leftAttachment = rotation*[-0.70*halfLength; -0.40*P.bodyDepth] + [0; heave];
    rightAttachment = rotation*[0.70*halfLength; -0.40*P.bodyDepth] + [0; heave];
    plot(axisHandle, [-0.65*xExtent leftAttachment(1)], ...
        [seabed leftAttachment(2)], '-', 'Color', [0.25 0.25 0.25], 'LineWidth', 1.1)
    plot(axisHandle, [0.65*xExtent rightAttachment(1)], ...
        [seabed rightAttachment(2)], '-', 'Color', [0.25 0.25 0.25], 'LineWidth', 1.1)

    text(axisHandle, -xExtent+0.5, 4.4, ...
        sprintf('z = %.2f m     theta = %.2f deg', heave, pitch*180/pi), ...
        'FontWeight', 'bold', 'FontSize', 11)
    text(axisHandle, -xExtent+0.5, 3.7, ...
        'Pitch is exaggerated only by the actual computed angle (no visual scale factor).', ...
        'FontSize', 9, 'Color', [0.25 0.25 0.25])

    hold(axisHandle, 'off')
    xlim(axisHandle, [-xExtent xExtent])
    ylim(axisHandle, [waterBottom 5.0])
    title(axisHandle, 'Coupled heave and pitch in a regular wave (schematic)')
    xlabel(axisHandle, 'x [m]')
    ylabel(axisHandle, 'z [m]')
    axisHandle.Box = 'on';
    axisHandle.XGrid = 'off';
    axisHandle.YGrid = 'off';
    axisHandle.FontSize = 11;
end

function [scale, unitsText] = pitchDisplayScale(displayUnits)
    if strcmpi(displayUnits, 'deg/m')
        scale = 180/pi;
        unitsText = 'deg/m';
    else
        scale = 1;
        unitsText = 'rad/m';
    end
end

function titles = heavePitchQuestionTitles()
    titles = { ...
        'Choose a prediction question ...', ...
        'Turn hydrodynamic coupling off', ...
        'Remove the direct pitch-excitation moment', ...
        'Increase pitch inertia', ...
        'Increase pitch restoring stiffness', ...
        'Increase pitch PTO damping', ...
        'Increase heave stiffness', ...
        'Increase wave amplitude', ...
        'Why are the two RAO units different?'};
end

function [prompt, answer] = heavePitchQuestionText(titleText)
    switch titleText
        case 'Turn hydrodynamic coupling off'
            prompt = ['Set heave-pitch coupling to 0%. Which curves change, and can heave still ' ...
                      'affect pitch through the equations?'];
            answer = ['All off-diagonal A35=A53, B35=B53, and C35=C53 terms vanish. The two ' ...
                      'dynamic equations then separate. Pitch can still respond if a direct wave ' ...
                      'excitation moment M_exc,5 is present, but heave motion itself no longer ' ...
                      'creates a pitch reaction in this model.'];
        case 'Remove the direct pitch-excitation moment'
            prompt = ['Uncheck the direct pitch-excitation moment while leaving coupling on. ' ...
                      'Will pitch necessarily become zero?'];
            answer = ['No. A vertical wave-excitation force can still produce pitch through the ' ...
                      'off-diagonal inertia, damping, and restoring terms. If coupling is also set ' ...
                      'to zero, then pitch becomes zero in this two-input teaching case.'];
        case 'Increase pitch inertia'
            prompt = ['Increase Iyy while holding hydrodynamic coefficients and C55 fixed. Does ' ...
                      'the pitch-dominated resonance region move to longer or shorter period?'];
            answer = ['Longer period. Greater rotational inertia lowers the angular frequency ' ...
                      'at which omega^2(Iyy+A55) balances the pitch restoring term. Coupling and ' ...
                      'frequency-dependent excitation can shift the actual RAO peak away from this ' ...
                      'simple estimate.'];
        case 'Increase pitch restoring stiffness'
            prompt = ['Increase C55 or extra pitch stiffness. Where should the pitch-dominated ' ...
                      'response move?'];
            answer = ['Toward shorter period (higher frequency), because the rotational restoring ' ...
                      'term is larger. The heave RAO may also change because the equations are coupled.'];
        case 'Increase pitch PTO damping'
            prompt = ['Increase pitch PTO damping. Does maximum pitch motion increase, and does ' ...
                      'absorbed pitch power always increase?'];
            answer = ['Maximum pitch motion generally decreases and the peak broadens. Absorbed ' ...
                      'power contains both the damping coefficient and angular-velocity squared, ' ...
                      'so it usually has an optimum rather than increasing without limit.'];
        case 'Increase heave stiffness'
            prompt = ['Increase extra heave stiffness while coupling is on. Could this change the ' ...
                      'pitch RAO as well as the heave RAO?'];
            answer = ['Yes. The heave-dominated resonance shifts toward shorter period, and the ' ...
                      'pitch curve can also change because the coupled impedance matrix must be ' ...
                      'inverted as a whole.'];
        case 'Increase wave amplitude'
            prompt = ['Double wave amplitude while the model remains linear. What changes in the ' ...
                      'RAOs, physical motion amplitudes, and ideal linear-PTO power?'];
            answer = ['The RAOs do not change. Both heave and pitch physical amplitudes double, ' ...
                      'and mean power in the linear dampers scales with amplitude squared. At large ' ...
                      'motions, real devices may leave the linear regime.'];
        case 'Why are the two RAO units different?'
            prompt = ['Heave and pitch are solved in one vector. Why is H3 dimensionless while H5 ' ...
                      'has units of rad/m or deg/m?'];
            answer = ['Both responses are divided by incident-wave amplitude in meters. Heave is ' ...
                      'a displacement in meters, so m/m is dimensionless. Pitch is an angle, so its ' ...
                      'RAO is angle per meter. Radians are dimensionless in SI algebra, but writing ' ...
                      'rad/m prevents a physically misleading comparison with heave.'];
        otherwise
            prompt = 'Choose a question from the menu.';
            answer = 'The explanation will appear here after a question is selected.';
    end
end

function [passed, message] = heavePitchDiagnostics(P, D)
    finiteCheck = all(isfinite(real(D.H(:)))) && all(isfinite(imag(D.H(:))));
    differenceA = D.A(1,2,:) - D.A(2,1,:);
    differenceB = D.B(1,2,:) - D.B(2,1,:);
    symmetryA = max(abs(differenceA(:))) < 1e-7;
    symmetryB = max(abs(differenceB(:))) < 1e-7;
    symmetryC = abs(D.C(1,2) - D.C(2,1)) < 1e-9;

    determinantA = squeeze(D.A(1,1,:).*D.A(2,2,:) - D.A(1,2,:).^2);
    determinantB = squeeze(D.B(1,1,:).*D.B(2,2,:) - D.B(1,2,:).^2);
    positiveSemidefiniteA = all(D.A33 >= 0) && all(D.A55 >= 0) && ...
        all(determinantA >= -1e-3*max(1,max(abs(determinantA))));
    positiveSemidefiniteB = all(D.B33 >= -1e-9) && all(D.B55 >= -1e-9) && ...
        all(determinantB >= -1e-3*max(1,max(abs(determinantB))));
    positiveStiffness = all(eig(0.5*(D.totalStiffness + D.totalStiffness.')) > 0);
    selectedInRange = P.selectedPeriod >= P.periodMin && P.selectedPeriod <= P.periodMax;

    passed = finiteCheck && symmetryA && symmetryB && symmetryC && ...
        positiveSemidefiniteA && positiveSemidefiniteB && positiveStiffness && selectedInRange;

    if passed
        message = sprintf([ ...
            'Checks PASS: finite RAOs; A, B, C symmetric; A and B positive semidefinite; K positive. ' ...
            'Balance estimates: heave %.2f s, pitch %.2f s.'], ...
            D.estimatedHeaveBalancePeriod, D.estimatedPitchBalancePeriod);
    else
        message = 'CHECK FAILED: inspect matrix symmetry, definiteness, coefficient scales, and stiffness.';
    end
end

function report = runHeavePitchSelfTest()
    P = defaultHeavePitchParameters();
    D = calculateHeavePitchResponse(P);

    determinantA = squeeze(D.A(1,1,:).*D.A(2,2,:) - D.A(1,2,:).^2);
    determinantB = squeeze(D.B(1,1,:).*D.B(2,2,:) - D.B(1,2,:).^2);

    Puncoupled = P;
    Puncoupled.couplingPercent = 0;
    Puncoupled.includeDirectPitchExcitation = false;
    Duncoupled = calculateHeavePitchResponse(Puncoupled);

    PcoupledOnly = P;
    PcoupledOnly.includeDirectPitchExcitation = false;
    DcoupledOnly = calculateHeavePitchResponse(PcoupledOnly);

    Pinertia = P;
    Pinertia.pitchInertia_Mkgm2 = 1.50*P.pitchInertia_Mkgm2;
    Dinertia = calculateHeavePitchResponse(Pinertia);

    PpitchDamping = P;
    PpitchDamping.pitchPtoDamping_MNmsPerRad = 8.0;
    DpitchDamping = calculateHeavePitchResponse(PpitchDamping);

    PheaveStiffness = P;
    PheaveStiffness.extraHeaveStiffness_kNPerM = 600;
    DheaveStiffness = calculateHeavePitchResponse(PheaveStiffness);

    Pamplitude = P;
    Pamplitude.waveAmplitude = 2*P.waveAmplitude;
    Damplitude = calculateHeavePitchResponse(Pamplitude);

    checks = [ ...
        all(isfinite(real(D.H(:)))) && all(isfinite(imag(D.H(:)))), ...
        max(abs(reshape(D.A(1,2,:) - D.A(2,1,:), [], 1))) < 1e-7, ...
        max(abs(reshape(D.B(1,2,:) - D.B(2,1,:), [], 1))) < 1e-7, ...
        min(determinantA) >= -1e-3*max(1,max(abs(determinantA))), ...
        min(determinantB) >= -1e-3*max(1,max(abs(determinantB))), ...
        all(eig(D.totalStiffness) > 0), ...
        max(abs(Duncoupled.H(2,:))) < 1e-12, ...
        max(abs(DcoupledOnly.H(2,:))) > 1e-5, ...
        Dinertia.estimatedPitchBalancePeriod > D.estimatedPitchBalancePeriod, ...
        max(abs(DpitchDamping.H(2,:))) < max(abs(D.H(2,:))), ...
        DheaveStiffness.estimatedHeaveBalancePeriod < D.estimatedHeaveBalancePeriod, ...
        max(abs(Damplitude.H(:) - D.H(:))) < 1e-12];

    if ~all(checks)
        error('HMEC_heave_pitch_RAO_demo:SelfTestFailed', ...
            'One or more coupled-demo numerical checks failed.')
    end

    [peakHeaveRao, heaveIndex] = max(abs(D.H(1,:)));
    [peakPitchRao, pitchIndex] = max(abs(D.H(2,:)));

    report.passed = true;
    report.defaultHeavePeakPeriod_s = D.period(heaveIndex);
    report.defaultHeavePeakRAO_mPerM = peakHeaveRao;
    report.defaultPitchPeakPeriod_s = D.period(pitchIndex);
    report.defaultPitchPeakRAO_radPerM = peakPitchRao;
    report.defaultPitchPeakRAO_degPerM = peakPitchRao*180/pi;
    report.uncoupledNoPitchInputGivesZeroPitch = true;
    report.couplingTransfersHeaveInputIntoPitch = true;
    report.increasedPitchInertiaMovesBalanceToLongerPeriod = true;
    report.increasedPitchDampingLowersPitchPeak = true;
    report.waveAmplitudeLeavesRAOsUnchanged = true;

    fprintf([ ...
        'HMEC coupled demo self-test PASS. Heave peak: %.2f s, %.3f m/m; ' ...
        'pitch peak: %.2f s, %.2f deg/m.\n'], ...
        report.defaultHeavePeakPeriod_s, report.defaultHeavePeakRAO_mPerM, ...
        report.defaultPitchPeakPeriod_s, report.defaultPitchPeakRAO_degPerM)
end

function k = dispersionWavenumber(omega, depth, g)
    % Newton iteration for omega^2 = g*k*tanh(k*h). Supports scalars/vectors.
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
