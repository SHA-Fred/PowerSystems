within PowerSystems;
model System "System reference"
  parameter SI.Frequency f_nom = 50 "nominal frequency"
   annotation(Evaluate=true, Dialog(group="System"), choices(choice=50 "50 Hz", choice=60 "60 Hz"));
  parameter SI.Frequency f = f_nom
    "frequency if fType_par = true, else initial frequency"
   annotation(Evaluate=true, Dialog(group="System"));
  parameter Boolean fType_par = true
    "= true, if system frequency defined by parameter f, else average frequency"
    annotation(Evaluate=true, Dialog(group="System"));
  parameter SI.Frequency f_lim[2]={0.5*f_nom, 2*f_nom}
    "limit frequencies (for supervision of average frequency)"
   annotation(Evaluate=true, Dialog(group="System",enable=not fType_par));
  parameter SI.Angle alpha0 = 0 "phase angle"
   annotation(Evaluate=true, Dialog(group="System"));
  parameter String ref = "synchron" "reference frame (3-phase)"
    annotation(Evaluate=true, Dialog(group="System", enable=sim=="tr"), choices(
      choice="synchron",
      choice="inertial"));
  parameter String ini = "st" "transient or steady-state initialisation"
   annotation(Evaluate=true, Dialog(group="Mode", enable=sim=="tr"), choices(
     choice="tr" "transient",
     choice="st" "steady"));
  parameter String sim = "tr" "transient or steady-state simulation"
   annotation(Evaluate=true, Dialog(group="Mode"), choices(
     choice="tr" "transient",
     choice="st" "steady"));
  final parameter SI.AngularFrequency omega_nom = 2*pi*f_nom
    "nominal angular frequency" annotation(Evaluate=true);
  final parameter Types.AngularVelocity w_nom = 2*pi*f_nom "nom r.p.m."
                 annotation(Evaluate=true, Dialog(group="Nominal"));
  final parameter Boolean synRef=if transientSim then ref=="synchron" else true
    annotation(Evaluate=true);

  final parameter Boolean steadyIni = ini=="st"
    "steady state initialisation of electric equations" annotation(Evaluate=true);
  final parameter Boolean transientSim = sim=="tr"
    "transient mode of electric equations" annotation(Evaluate=true);
  final parameter Boolean steadyIni_t = steadyIni and transientSim
    annotation(Evaluate=true);
  discrete SI.Time initime;
  SI.Angle theta(final start=0,
    stateSelect=if fType_par then StateSelect.default else StateSelect.always);
  SI.AngularFrequency omega(final start=2*pi*f);
/*
  Modelica.Blocks.Interfaces.RealInput omega_inp(min=0)
    "system ang frequency (optional, fType=sig)"
    annotation (extent=[90,-10; 110,10],    rotation=-180);

  Removed, since not input connector of inner/outer class not allowed in Modelica 3.
*/
  Interfaces.Frequency receiveFreq
    "receives weighted frequencies from generators"
   annotation (Placement(transformation(extent={{-96,64},{-64,96}}, rotation=0)));
initial equation
  if not fType_par then
    theta = omega*time;
  end if;

equation
  when initial() then
    initime = time;
  end when;
  if fType_par then
    omega = 2*pi*f;
    theta = omega*time;
    /*
   elseif fType == Types.FreqType.sig then
     omega = omega_inp;
     Removed, since input connector of inner/outer class not allowed in Modelica 3
    */
  else
    omega = if initial() then 2*pi*f else receiveFreq.w_H/receiveFreq.H;
    der(theta) = omega;
    when (omega < 2*pi*f_lim[1]) or (omega > 2*pi*f_lim[2]) then
      terminate("FREQUENCY EXCEEDS BOUNDS!");
    end when;
  end if;
  // set dummy values (to achieve balanced model)
  receiveFreq.h = 0.0;
  receiveFreq.w_h = 0.0;
  annotation (
  preferedView="info",
  defaultComponentName="system",
  defaultComponentPrefixes="inner",
  missingInnerMessage="No \"system\" component is defined.
    Drag PowerSystems.System into the top level of your model.",
  Window(
    x=0.13,
    y=0.1,
    width=0.81,
    height=0.83),
  Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={
        Rectangle(
          extent={{-100,100},{100,-100}},
          lineColor={0,120,120},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-100,100},{100,60}},
          lineColor={0,120,120},
          fillColor={0,120,120},
          fillPattern=FillPattern.Solid),
        Text(
          extent={{-60,100},{100,60}},
          lineColor={215,215,215},
          textString =                      "%name"),
        Text(
          extent={{-100,50},{100,20}},
          lineColor={0,0,0},
          textString =                      "f_nom=%f_nom"),
        Text(
          extent={{-100,-20},{100,10}},
          lineColor={0,0,0},
          textString=
             "f par:%fType_par"),
        Text(
          extent={{-100,-30},{100,-60}},
          lineColor={0,120,120},
          textString=
             "%ref"),
        Text(
          extent={{-100,-70},{100,-100}},
          lineColor={176,0,0},
          textString =                         "ini:%ini  sim:%sim")}),
  Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics),
  Documentation(info="<html>
<p>The model <b>System</b> represents a global reference for the following purposes:</p>
<p>It allows the choice of </p>
<ul>
<li> nominal frequency (default 50 or 60 Hertz, but arbitrary positive choice allowed)
<li> system frequency or initial system frequency, depending on frequency type</li>
<li> frequency type: parameter, signal, or average (machine-dependent) system frequency</li>
<li> lower and upper limit-frequencies</li>
<li> common phase angle for AC-systems</li>
<li> synchronous or inertial reference frame for AC-3phase-systems</li>
<li> transient or steady-state initialisation and simulation modes<br>
     For 'transient' initialisation no specific initial equations are defined.<br>
     This case allows also to use Dymola's steady-state initialisation, that is DIFFERENT from ours.<br>
     <b>Note:</b> the parameter 'sim' only affects AC three-phase components.</li>
</ul>
<p>It provides</p>
<ul>
<li> the system angular-frequency omega<br>
     For frequency-type 'parameter' this is simply a parameter value.<br>
     For frequency-type 'signal' it is a positive input signal.<br>
     For frequency-type 'average' it is a weighted average over the relevant generator frequencies.
<li> the system angle theta by integration of
<pre> der(theta) = omega </pre><br>
     This angle allows the definition of a rotating electrical <b>coordinate system</b><br>
     for <b>AC three-phase models</b>.<br>
     Root-nodes defining coordinate-orientation will choose a reference angle theta_ref (connector-variable theta[2]) according to the parameter <tt>ref</tt>:<br><br>
     <tt>theta_ref = theta if ref = \"synchron\"</tt> (reference frame is synchronously rotating with theta).<br>
     <tt>theta_ref = 0 if ref = \"inertial\"</tt> (inertial reference frame, not rotating).<br>

     where<br>
     <tt>theta = 1 :</tt> reference frame is synchronously rotating.<br>
     <tt>ref=0 :</tt> reference frame is at rest.<br>
     Note: Steady-state simulation is only possible for <tt>ref = \"synchron\"</tt>.<br><br>
     <tt>ref</tt> is determined by the parameter <tt>refFrame</tt> in the following way:

     </li>
</ul>
<p><b>Note</b>: Each model using <b>System</b> must use it with an <b>inner</b> declaration and instance name <b>system</b> in order that it can be accessed from all objects in the model.<br>When dragging the 'System' from the package browser into the diagram layer, declaration and instance name are automatically generated.</p>
<p><a href=\"PowerSystems.UsersGuide.Overview\">up users guide</a></p>
</html>
"));
end System;
