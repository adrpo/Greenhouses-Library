within Greenhouse.Examples;
model GlobalSystem_1 "Greenhouse connected to a CHP and thermal energy storage"
  Real Mdot_2ry(start=0.528);
  Real E_gas_CHP(unit="kW.h");
  Real E_el_CHP(unit="kW.h");
  Real E_th_CHP(unit="kW.h");

  Real E_gen(unit="kW.h");
  Real E_G(unit="kW.h");

  Real E_amb_TES(unit="kW.h");

  Real Pi_buy(unit="1/(kW.h)")=0.05 "50euro/MWh";
  Real Pi_sell(unit="1/(kW.h)");
  Real E_el_sell(unit="kW.h");
  Real E_el_buy(unit="kW.h");
  Real C_sell;
  Real C_buy;

  Real E_gas_CHP_kWhm2(unit="kW.h/m2");
  Real E_el_CHP_kWhm2(unit="kW.h/m2");
  Real E_th_CHP_kWhm2(unit="kW.h/m2");
  Real E_gen_kWhm2(unit="kW.h/m2");
  Real E_G_kWhm2(unit="kW.h/m2");
  Real E_amb_TES_kWhm2(unit="kW.h/m2");
  Real E_el_sell_kWhm2(unit="kW.h/m2");
  Real E_el_buy_kWhm2(unit="kW.h/m2");

  Components.HVAC.CHP CHP(
    redeclare package Medium =
        Modelica.Media.Water.ConstantPropertyLiquidWater,
    Tmax=373.15,
    Th_nom=773.15)
    annotation (Placement(transformation(extent={{-20,-20},{10,10}})));

  Modelica.Fluid.Sensors.Temperature T_ex_CHP(redeclare package Medium =
        Modelica.Media.Water.ConstantPropertyLiquidWater)
    annotation (Placement(transformation(extent={{-32,2},{-24,8}})));
  Modelica.Fluid.Sensors.Temperature T_su_CHP(redeclare package Medium =
        Modelica.Media.Water.ConstantPropertyLiquidWater)
    annotation (Placement(transformation(extent={{-36,-14},{-28,-8}})));
  Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow Qdot_nom_gas_CHP
    annotation (Placement(transformation(extent={{40,-10},{24,6}})));
  Modelica.Blocks.Sources.Constant set_Qdot_nom_gas_CHP(k=2800e3)
    annotation (Placement(transformation(extent={{62,-8},{52,2}})));
  ThermoCycle.Components.Units.Tanks.HeatStorageWaterHeater.Heat_storage_hx_R
                                 TES(
    h_T=0.6,
    U_amb=2,
    steadystate_hx=false,
    Unom_hx=1000,
    steadystate_tank=false,
    redeclare package MainFluid =
        Modelica.Media.Water.ConstantPropertyLiquidWater,
    h2=1,
    h1=0.01,
    N1=1,
    N2=15,
    A_hx=3800,
    V_tank=385,
    Wdot_res=115500,
    redeclare package SecondaryFluid =
        Modelica.Media.Water.ConstantPropertyLiquidWater,
    Tmax=373.15,
    Tstart_inlet_tank=303.15,
    Tstart_outlet_tank=323.15,
    Tstart_inlet_hx=333.15,
    Tstart_outlet_hx=313.15)
    annotation (Placement(transformation(extent={{-10,26},{-40,56}})));

  Modelica.Fluid.Sensors.Temperature T_ex_TES(redeclare package Medium =
        Modelica.Media.Water.ConstantPropertyLiquidWater)
    annotation (Placement(transformation(extent={{-44,30},{-52,36}})));
  Modelica.Fluid.Sensors.Temperature T_su_G(redeclare package Medium =
        Modelica.Media.Water.ConstantPropertyLiquidWater)
    annotation (Placement(transformation(extent={{-22,66},{-14,72}})));
  Modelica.Fluid.Sensors.Temperature T_ex_G(redeclare package Medium =
        Modelica.Media.Water.ConstantPropertyLiquidWater)
    annotation (Placement(transformation(extent={{-16,34},{-8,40}})));

  ThermoCycle.Components.Units.ExpansionAndCompressionMachines.Pump_Mdot pump_2ry(
      redeclare package Medium =
        Modelica.Media.Water.ConstantPropertyLiquidWater, Mdot_0=20)
    annotation (Placement(transformation(extent={{-60,-46},{-48,-34}})));
  ThermoCycle.Components.FluidFlow.Reservoirs.SinkP sinkP_2ry(redeclare package
      Medium = Modelica.Media.Water.ConstantPropertyLiquidWater, p0=1000000)
    annotation (Placement(transformation(extent={{-76,-30},{-88,-18}})));
  ThermoCycle.Components.Units.PdropAndValves.Pdrop pdrop_2ry(
    Mdot_max=0.5,
    redeclare package Medium =
        Modelica.Media.Water.ConstantPropertyLiquidWater,
    DELTAp_max=1100)
    annotation (Placement(transformation(extent={{-88,-46},{-76,-34}})));

  Components.Greenhouse.Unit.Greenhouse
             G annotation (Placement(transformation(extent={{46,26},{94,62}})));
  ControlSystems.HVAC.Control_1 controller(T_max=343.15, T_min=303.15)
    annotation (Placement(transformation(extent={{-74,-2},{-54,18}})));
  ThermoCycle.Components.Units.ExpansionAndCompressionMachines.Pump_Mdot pump_1ry(
      redeclare package Medium =
        Modelica.Media.Water.ConstantPropertyLiquidWater, Mdot_0=0.528)
    annotation (Placement(transformation(extent={{24,44},{36,56}})));
  ThermoCycle.Components.Units.PdropAndValves.Pdrop pdrop_1ry(
    redeclare package Medium =
        Modelica.Media.Water.ConstantPropertyLiquidWater,
    Mdot_max=0.5,
    DELTAp_max=1100)
    annotation (Placement(transformation(extent={{-6,48},{6,60}})));

  ThermoCycle.Components.FluidFlow.Reservoirs.SinkP sinkP_1ry(redeclare package
      Medium = Modelica.Media.Water.ConstantPropertyLiquidWater, p0=1000000)
    annotation (Placement(transformation(extent={{6,62},{-6,74}})));
  Modelica.Blocks.Sources.RealExpression set_Mdot_2ry(y=Mdot_2ry)
    annotation (Placement(transformation(extent={{-88,-18},{-74,-6}})));
equation
  Mdot_2ry = if time<1e4 then 20 else (if controller.CHP then 20 else 0);

  der(E_gas_CHP*1e3*3600) = CHP.Qdot_gas;
  der(E_el_CHP*1e3*3600) = CHP.Wdot_el;
  der(E_th_CHP*1e3*3600) = CHP.prescribedHeatFlow.Q_flow;

  E_gen = E_th_CHP;
  E_G = G.E_th_tot;

  der(E_amb_TES*1e3*3600) = sum(TES.cell1DimInc_hx.Q_tot);

  Pi_sell = Pi_buy/4;
  der(E_el_sell*1e3*3600) = max(0,CHP.Wdot_el-G.illu.W_el);
  der(E_el_buy*1e3*3600) = max(0,G.illu.W_el-CHP.Wdot_el);
  C_sell = Pi_sell*E_el_sell;
  C_buy = Pi_buy*E_el_buy;

  E_gas_CHP_kWhm2=E_gas_CHP/G.surface.k;
  E_el_CHP_kWhm2=E_el_CHP/G.surface.k;
  E_th_CHP_kWhm2=E_th_CHP/G.surface.k;
  E_gen_kWhm2=E_gen/G.surface.k;
  E_G_kWhm2=E_G/G.surface.k;
  E_amb_TES_kWhm2=E_amb_TES/G.surface.k;
  E_el_sell_kWhm2=E_el_sell/G.surface.k;
  E_el_buy_kWhm2=E_el_buy/G.surface.k;

  connect(T_ex_CHP.port, CHP.OutFlow) annotation (Line(
      points={{-28,2},{-28,-2.6},{-20,-2.6}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(T_su_CHP.port, CHP.InFlow) annotation (Line(
      points={{-32,-14},{-26,-14},{-26,-17.3},{-20,-17.3}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(Qdot_nom_gas_CHP.port, CHP.HeatSource) annotation (Line(
      points={{24,-2},{20,-2},{20,0.25},{7.75,0.25}},
      color={191,0,0},
      smooth=Smooth.None));
  connect(set_Qdot_nom_gas_CHP.y, Qdot_nom_gas_CHP.Q_flow) annotation (Line(
      points={{51.5,-3},{46,-3},{46,-2},{40,-2}},
      color={0,0,127},
      smooth=Smooth.None,
      pattern=LinePattern.Dash));
  connect(T_su_G.port, TES.MainFluid_ex) annotation (Line(
      points={{-18,66},{-18,64},{-25.2,64},{-25.2,53.9},{-25,53.9}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(T_ex_G.port, TES.MainFluid_su) annotation (Line(
      points={{-12,34},{-12,29.15},{-19.45,29.15}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(CHP.OutFlow, TES.SecondaryFluid_ex) annotation (Line(
      points={{-20,-2.6},{-36,-2.6},{-36,36},{-31,36},{-31,36.5}},
      color={0,0,255},
      smooth=Smooth.None,
      thickness=0.5));
  connect(pdrop_2ry.OutFlow, pump_2ry.inlet) annotation (Line(
      points={{-77.5,-40},{-74,-40},{-74,-39.7},{-58.32,-39.7}},
      color={0,0,255},
      smooth=Smooth.None,
      thickness=0.5));
  connect(sinkP_2ry.flangeB, pump_2ry.inlet) annotation (Line(
      points={{-76.96,-24},{-68,-24},{-68,-39.7},{-58.32,-39.7}},
      color={0,0,255},
      smooth=Smooth.None));

  connect(T_ex_TES.port, TES.SecondaryFluid_su) annotation (Line(
      points={{-48,30},{-42,30},{-42,46.1},{-31,46.1}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(pdrop_2ry.InFlow, TES.SecondaryFluid_su) annotation (Line(
      points={{-86.5,-40},{-92,-40},{-92,46},{-31,46},{-31,46.1}},
      color={0,0,255},
      smooth=Smooth.None,
      thickness=0.5));
  connect(TES.Temperature, controller.T_tank) annotation (Line(
      points={{-18.85,45.35},{-22,45.35},{-22,42},{-82,42},{-82,4},{-75,4}},
      color={0,0,127},
      smooth=Smooth.None,
      pattern=LinePattern.Dash));
  connect(controller.CHP, CHP.on_off) annotation (Line(
      points={{-53.5,14},{-42,14},{-42,-22},{-4,-22},{-4,-18.8},{-4.7,-18.8}},
      color={255,0,255},
      smooth=Smooth.None,
      pattern=LinePattern.Dash));
  connect(pdrop_1ry.OutFlow, pump_1ry.inlet) annotation (Line(
      points={{4.5,54},{12,54},{12,50.3},{25.68,50.3}},
      color={0,0,255},
      smooth=Smooth.None,
      thickness=0.5));
  connect(sinkP_1ry.flangeB, pump_1ry.inlet) annotation (Line(
      points={{5.04,68},{12,68},{12,50.3},{25.68,50.3}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(G.flangeB, TES.MainFluid_su) annotation (Line(
      points={{53.4,29.2},{20.5,29.2},{20.5,29.15},{-19.45,29.15}},
      color={0,0,255},
      smooth=Smooth.None,
      thickness=0.5));
  connect(pump_1ry.outlet, G.flangeA) annotation (Line(
      points={{33.36,54.44},{33.36,53.7},{53.4,53.7},{53.4,39}},
      color={0,0,255},
      smooth=Smooth.None,
      thickness=0.5));
  connect(pdrop_1ry.InFlow, TES.MainFluid_ex) annotation (Line(
      points={{-4.5,54},{-8,54},{-8,53.9},{-25,53.9}},
      color={0,0,255},
      smooth=Smooth.None,
      thickness=0.5));
  connect(G.PID_Mdot_CS, pump_1ry.flow_in) annotation (Line(
      points={{86.6,34.6},{96,34.6},{96,68},{22,68},{22,54.8},{28.08,54.8}},
      color={0,0,127},
      smooth=Smooth.None,
      pattern=LinePattern.Dash));
  connect(T_ex_TES.T, controller.T_low_TES) annotation (Line(
      points={{-50.8,33},{-50.8,32},{-80,32},{-80,8},{-75,8}},
      color={0,0,127},
      smooth=Smooth.None,
      pattern=LinePattern.Dash));
  connect(G.PID_Mdot_CS, controller.Mdot_1ry) annotation (Line(
      points={{86.6,34.6},{96,34.6},{96,18},{-78,18},{-78,12},{-75,12}},
      color={0,0,127},
      smooth=Smooth.None,
      pattern=LinePattern.Dash));
  connect(set_Mdot_2ry.y, pump_2ry.flow_in) annotation (Line(
      points={{-73.3,-12},{-56,-12},{-56,-35.2},{-55.92,-35.2}},
      color={0,0,127},
      smooth=Smooth.None,
      pattern=LinePattern.Dash));
  connect(pump_2ry.outlet, CHP.InFlow) annotation (Line(
      points={{-50.64,-35.56},{-19.32,-35.56},{-19.32,-17.3},{-20,-17.3}},
      color={0,0,255},
      smooth=Smooth.None,
      thickness=0.5));
  annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
            -100},{100,100}}), graphics={
        Text(
          extent={{-64,60},{-28,50}},
          lineColor={0,0,0},
          pattern=LinePattern.Dash,
          fillColor={215,215,215},
          fillPattern=FillPattern.Solid,
          textString="Thermal Energy
Storage"),
        Text(
          extent={{56,26},{82,20}},
          lineColor={0,0,0},
          pattern=LinePattern.Dash,
          fillColor={215,215,215},
          fillPattern=FillPattern.Solid,
          textString="Greenhouse"),
        Text(
          extent={{-18,-22},{8,-28}},
          lineColor={0,0,0},
          pattern=LinePattern.Dash,
          fillColor={215,215,215},
          fillPattern=FillPattern.Solid,
          textString="CHP")}), Icon(graphics={
        Ellipse(lineColor = {75,138,73},
                fillColor={255,255,255},
                fillPattern = FillPattern.Solid,
                extent={{-100,-100},{100,100}}),
        Polygon(lineColor = {0,0,255},
                fillColor = {75,138,73},
                pattern = LinePattern.None,
                fillPattern = FillPattern.Solid,
                points={{-36,60},{64,0},{-36,-60},{-36,60}})}));
end GlobalSystem_1;
