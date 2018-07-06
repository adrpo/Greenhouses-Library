within Greenhouse.Components.HVAC;
model HeatPump_ConsoClim
  "Variation of ConsoClim model. Imposing the Wdot instead of the T_cd"
  replaceable package Medium1 =
    ThermoCycle.Media.StandardWater constrainedby
    Modelica.Media.Interfaces.PartialMedium "Condenser" annotation (choicesAllMatching = true);

  replaceable package Medium2 =
    ThermoCycle.Media.StandardWater constrainedby
    Modelica.Media.Interfaces.PartialMedium "Evaporator" annotation (choicesAllMatching = true);

  Modelica.Blocks.Interfaces.RealOutput W_dot_cp(start = 1) "[W]"
    annotation (Placement(transformation(extent={{54,98},{74,118}}),
        iconTransformation(
        extent={{-10,-10},{10,10}},
        rotation=90,
        origin={60,110})));
  Modelica.Blocks.Interfaces.RealOutput COP(start = 1)
    annotation (Placement(transformation(extent={{-70,100},{-50,120}}),
        iconTransformation(
        extent={{10,-10},{-10,10}},
        rotation=-90,
        origin={-60,110})));

  parameter Modelica.SIunits.Volume V=0.005 "Internal volume";
  parameter Modelica.SIunits.Area A = 10 "Heat exchange area";

  parameter Real COP_n=3.9505;
  parameter Real Q_dot_cd_n=10.02 "W";
  parameter Real T_su_ev_n=7 "�C";
  parameter Real T_ex_cd_n=35 "�C";
  parameter Real C0=0.949;
  parameter Real C1=-8.05;
  parameter Real C2=111.09;
  parameter Real D0=0.968;
  parameter Real D1=0.0226;
  parameter Real D2=-0.0063;
  parameter Real K1=0;
  parameter Real K2=0.67;
  parameter Real a = 0.7701;
  parameter Real b = 0.2299;
  parameter Boolean Variable_Compressor_Speed = false
    "Set false if the compressor speed is constant";

  Modelica.SIunits.MassFlowRate m_dot_ev;
  Modelica.SIunits.SpecificEnthalpy h_su_ev;
  Modelica.SIunits.SpecificEnthalpy h_ex_ev;
  Modelica.SIunits.HeatFlowRate Q_dot_cd;
  Modelica.SIunits.HeatFlowRate Q_dot_ev;
  Modelica.SIunits.HeatFlowRate Q_dot_cd_fl;
  Modelica.SIunits.Temperature T_su_ev;
  Modelica.SIunits.Temperature T_ex_cd;
  Modelica.SIunits.InstantaneousPower W_dot_n;
  Modelica.SIunits.InstantaneousPower W_dot_fl;
  Modelica.SIunits.InstantaneousPower W_dot_pl;
  Real DELTA_T;
  Real EIRFT;
  Real COP_fl;
  Real CAPFT;
  Real PLR;
  Real EIRFPLR;

  parameter Modelica.SIunits.Temperature Th_start = 35+273.15
    "Start value for the condenser temperature"      annotation(Dialog(tab="Initialization"));
  parameter Modelica.SIunits.Temperature Tmax = 273.15 + 100
    "Maximum temperature at the outlet";
  parameter Modelica.SIunits.Time tau = 60 "Start-up time constant";

  ThermoCycle.Interfaces.Fluid.FlangeA Supply_cd(redeclare package Medium =
        Medium1) annotation (Placement(transformation(extent={{80,-80},{100,-60}}),
        iconTransformation(extent={{80,-80},{100,-60}})));
  ThermoCycle.Interfaces.Fluid.FlangeB Exhaust_cd(redeclare package Medium =
        Medium1) annotation (Placement(transformation(extent={{80,60},{100,80}}),
        iconTransformation(extent={{80,60},{100,80}})));
  ThermoCycle.Interfaces.Fluid.FlangeA Supply_ev(redeclare package Medium =
        Medium2) annotation (Placement(transformation(extent={{-100,60},{-80,80}}),
        iconTransformation(extent={{-100,60},{-80,80}})));
  ThermoCycle.Interfaces.Fluid.FlangeB Exhaust_ev(redeclare package Medium =
        Medium2) annotation (Placement(transformation(extent={{-100,-80},{-80,-60}}),
        iconTransformation(extent={{-100,-80},{-80,-60}})));
  Modelica.Blocks.Interfaces.RealInput W_dot_set annotation (Placement(
        transformation(extent={{-34,-130},{6,-90}}), iconTransformation(
        extent={{-10,-10},{10,10}},
        rotation=90,
        origin={0,-110})));
  ThermoCycle.Components.FluidFlow.Pipes.Cell1DimInc fluid(
    Discretization=ThermoCycle.Functions.Enumerations.Discretizations.upwind_AllowFlowReversal,
    Mdotnom=0.1,
    redeclare model HeatTransfer =
        ThermoCycle.Components.HeatFlow.HeatTransfer.Constant,
    Vi=V,
    Ai=A,
    Unom=1000,
    redeclare package Medium = Medium1,
    pstart=10000000000,
    hstart=Medium1.specificEnthalpy_pT(1E5, Th_start))
                        annotation (Placement(transformation(
        extent={{-10,-10},{10,10}},
        rotation=90,
        origin={48,4})));
  ThermoCycle.Interfaces.HeatTransfer.HeatPortConverter heatPortConverter(A=A, N=1)
    annotation (Placement(transformation(extent={{0,-6},{20,14}})));
  Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow prescribedHeatFlow
    annotation (Placement(transformation(extent={{-46,-6},{-26,14}})));
  Modelica.Blocks.Continuous.FirstOrder firstOrder(T=tau)
    annotation (Placement(transformation(extent={{4,52},{24,72}})));
  Modelica.Blocks.Interfaces.BooleanInput on_off annotation (Placement(
        transformation(
        extent={{-20,-20},{20,20}},
        rotation=90,
        origin={10,-90}), iconTransformation(
        extent={{-6,-6},{6,6}},
        rotation=90,
        origin={40,-106})));
  Modelica.Fluid.Sensors.Temperature T_ex_cd_sensor(redeclare package Medium =
        Medium1)
    annotation (Placement(transformation(extent={{14,26},{30,38}})));
equation
  if cardinality(on_off)==0 then
    on_off = true "Pressure set by parameter";
  end if;
  assert(fluid.T < Tmax,"Maximum temperature reached at the heat pump outlet");
  firstOrder.u= if on_off then 1 else 0;

  m_dot_ev = Supply_ev.m_flow;
  Supply_ev.m_flow + Exhaust_ev.m_flow = 0;
  Supply_ev.p = Exhaust_ev.p;
  h_su_ev = inStream(Supply_ev.h_outflow);
  h_su_ev = Supply_ev.h_outflow;
  h_ex_ev = Exhaust_ev.h_outflow;

  W_dot_n = Q_dot_cd_n/COP_n;

  prescribedHeatFlow.Q_flow = firstOrder.y*firstOrder.u* Q_dot_cd;

  Q_dot_ev = m_dot_ev*(h_su_ev-h_ex_ev);
  Q_dot_cd = W_dot_cp+Q_dot_ev;

  DELTA_T = T_su_ev/T_ex_cd - ((T_su_ev_n+273.15)/(T_ex_cd_n+273.15));
  T_su_ev = Medium2.temperature(state=Medium2.setState_phX(Supply_ev.p,h_su_ev,Supply_ev.Xi_outflow));
  T_ex_cd = T_ex_cd_sensor.T;
  EIRFT = C0+C1*DELTA_T+C2*DELTA_T^2;
  COP_fl = COP_n/EIRFT;

  CAPFT = min(1,D0 + D1*(T_su_ev - (T_su_ev_n+273.15)) + D2*(T_ex_cd - (T_ex_cd_n+273.15)));
  Q_dot_cd_fl = CAPFT*Q_dot_cd_n;
  W_dot_fl = Q_dot_cd_fl/COP_fl;

  PLR = min(1,max(0,Q_dot_cd/Q_dot_cd_fl));
  W_dot_pl = EIRFPLR*W_dot_fl;
  EIRFPLR = K1+(K2-K1)*PLR+(1-K2)*PLR^2;

  if noEvent(Variable_Compressor_Speed) then

    if noEvent((W_dot_set <= W_dot_fl) and (W_dot_set >=0)) then

      W_dot_cp = W_dot_set;

      if noEvent(PLR >= 0.3) then
        COP = COP_fl*(PLR/(a*PLR+b));
        Q_dot_cd = W_dot_cp*COP;

      elseif noEvent(PLR <=0) then
        Q_dot_cd = 0;
        COP = 0;

      else
        COP = 0.3*Q_dot_cd_fl/(W_dot_n*EIRFT*CAPFT*(K1+(K2-K1)*0.3+(1-K2)*0.3^2))*(PLR/(a*PLR+0.3*b));
        Q_dot_cd = W_dot_cp*COP;

      end if;

    elseif noEvent((W_dot_set <= W_dot_fl) and (W_dot_set < 0)) then

      Q_dot_cd = 0;
      W_dot_cp = 0;
      COP = 0;

    else

      W_dot_cp = W_dot_fl;
      COP = Q_dot_cd_fl/W_dot_fl;
      Q_dot_cd = Q_dot_cd_fl;

    end if;

  else

    if noEvent((W_dot_set <= W_dot_fl) and (W_dot_set >=0)) then

      W_dot_cp = W_dot_set;

      if noEvent(PLR >= 0) then
        Q_dot_cd = W_dot_cp*COP;
        COP = COP_fl*(PLR/(a*PLR+b));

      else
        Q_dot_cd = 0;
        COP = 0;

      end if;

    elseif noEvent((W_dot_set <= W_dot_fl) and (W_dot_set < 0)) then

      Q_dot_cd = 0;
      W_dot_cp = 0;
      COP = 0;

    else

      W_dot_cp = W_dot_fl;
      COP = Q_dot_cd_fl/W_dot_fl;
      Q_dot_cd = Q_dot_cd_fl;

    end if;

  end if;

  connect(fluid.Wall_int,heatPortConverter. thermalPortL) annotation (Line(
      points={{43,4},{20,4}},
      color={255,0,0},
      smooth=Smooth.None));
  connect(heatPortConverter.heatPort,prescribedHeatFlow. port) annotation (Line(
      points={{0,4},{-26,4}},
      color={191,0,0},
      smooth=Smooth.None));
  connect(Supply_cd, fluid.InFlow) annotation (Line(
      points={{90,-70},{90,-38},{48,-38},{48,-6}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(fluid.OutFlow, Exhaust_cd) annotation (Line(
      points={{47.9,14},{47.9,39},{90,39},{90,70}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(T_ex_cd_sensor.port, Exhaust_cd) annotation (Line(
      points={{22,26},{48,26},{47.9,39},{90,39},{90,70}},
      color={0,127,255},
      smooth=Smooth.None));
  annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
            -100},{100,100}}), graphics), Icon(coordinateSystem(
          preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics={
        Polygon(
          points={{-10,20},{10,20},{-10,-20},{10,-20},{-10,20}},
          lineColor={0,0,0},
          smooth=Smooth.None,
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid,
          origin={0,80},
          rotation=-90),
        Polygon(
          points={{-20,-20},{20,-20},{10,20},{-10,20},{-20,-20}},
          lineColor={0,0,0},
          smooth=Smooth.None,
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid,
          origin={0,-80},
          rotation=-90),
        Rectangle(extent={{-96,40},{-70,-40}}, lineColor={0,0,0}),
        Rectangle(extent={{70,40},{96,-40}}, lineColor={0,0,0}),
        Line(
          points={{-20,80},{-76,80},{-76,40}},
          color={0,0,0},
          smooth=Smooth.None),
        Line(
          points={{-76,-40},{-76,-80},{-20,-80}},
          color={0,0,0},
          smooth=Smooth.None),
        Line(
          points={{20,-80},{76,-80},{76,-40}},
          color={0,0,0},
          smooth=Smooth.None),
        Line(
          points={{76,40},{76,80},{20,80}},
          color={0,0,0},
          smooth=Smooth.None),
        Rectangle(
          extent={{-100,100},{100,-100}},
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Text(
          extent={{-80,98},{-40,84}},
          lineColor={0,0,255},
          textString="COP"),
        Text(
          extent={{34,100},{84,80}},
          lineColor={0,0,255},
          textString="W_dot_cp"),
        Rectangle(
          extent={{-92,60},{-88,40}},
          lineColor={0,0,255},
          fillPattern=FillPattern.Solid,
          fillColor={0,0,255}),
        Rectangle(
          extent={{-92,-40},{-88,-60}},
          lineColor={0,0,255},
          fillPattern=FillPattern.Solid,
          fillColor={0,0,255}),
        Rectangle(
          extent={{88,60},{92,40}},
          lineColor={0,0,255},
          fillPattern=FillPattern.Solid,
          fillColor={0,0,255}),
        Rectangle(
          extent={{88,-40},{92,-60}},
          lineColor={0,0,255},
          fillPattern=FillPattern.Solid,
          fillColor={0,0,255})}),
          Documentation(info="<html>
<p>
This model is used to determine the performances of a heat pump for different 
operating conditions. The ConsoClim model developed by the MINES PARISTECH 
is used. 
</p>
<p>
The model predicts the performances of the system with three polynomial laws. 
The parameters of the model are identified with manufacturer data. 
</p>
<p>
The first and the second law (EIRFT and CAPFT) are used respectively to determine
the COP and the heating capacity of the machine at full load. These two polynomial
laws depend on the outside air temperature (T_a_out) and the temperature of the 
water at the exhaust of the condenser (T_w). The third law is used to determine 
the performances of the system at part load. 
</p>
</html>"));
end HeatPump_ConsoClim;
