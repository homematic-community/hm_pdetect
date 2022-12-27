#!/bin/tclsh
source inc/session.tcl

puts "Content-Type: text/html; charset=utf-8"
puts ""

if {[info exists sid] && [check_session $sid]} {
  puts [subst {
    <!DOCTYPE HTML>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta http-equiv="Content-Type" content="text/html;charset=utf-8">
      <meta http-equiv="X-UA-Compatible" content="IE=edge">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <meta name="description" content="settings">
      <meta name="author" content="https://github.com/homematic-community/hm_pdetect">
      <meta name="language" content="en, english">
      <!-- Bootstrap core CSS -->
      <link href="css/bootstrap.min.css" rel="stylesheet">
      <!-- Custom styles for this template -->
      <link href="css/custombootstrap.css" rel="stylesheet">
      <link href="css/custom.css" rel="stylesheet">
      <title>HM-pdetect Addon</title>
    </head>
    <body class='body-blu' style="zoom: 1; margin-top: 60px;">
    <div class="navbar navbar-default navbar-fixed-top" role="navigation">
      <div class="container">
        <div class="navbar-header">
          <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
            <span class="sr-only">Toggle navigation</span>
             <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </button>
          <a class="navbar-brand" href="#"  target="_blank"><img src="img/logo.png" alt=""> &nbsp;
     &nbsp;</a>
          </div>
       <div class="collapse navbar-collapse">
          <ul class="nav navbar-nav ">
            <li class="active"><a href="en.index.cgi?sid=$sid">About</a></li>
            <li><a href="en.logoutput.cgi?sid=$sid">Logfile</a></li>
            <li><a href="en.settings.cgi?sid=$sid">Configuration</a></li>
          </ul>
          <ul class="nav navbar-nav navbar-right">
            <li><a href="index.cgi?sid=$sid">Deutsch</a></li>
          </ul>
         </div><!--/.nav-collapse -->
      </div><!-- class="container" -->
    </div><!-- class="navbar ..." -->

    <div class="container center1 col-md-8" id="content">
    <legend>FRITZ!-based Presence Detection for HomeMatic - hm_pdetect</legend>
    <div class="well well-s">
    <b>General</b>
    <p>
    This CCU-Addon allows to implement a general home presence detection system within a <a href="https://www.homematic.com/">eQ3 HomeMatic</a> homeautomation system. It regularly queries the WiFi/LAN status of user devices (e.g. Smartphones) logging in/out of <a href="https://www.avm.de/">AVM FRITZ!</a> WiFi routers (e.g. FRITZ!Box, FRITZ!Repeater). Upon manually configured MAC and IP addresses of user devices this addon is able to set the general home presence status of that user in terms of setting CCU-based system variables. These variables can then be evaluated within the general HomeMatic home automation system. In addition, any device that is not recognized as a configured user devices or known device will otherwise be considered a guest device and a separate system variable set accordingly. This allows to identify any guests being present at the house so that e.g. the heating system of a guest room could be switched on/off accordingly.
    </p>

    <b>Features</b>
    <p>
    <ul>
    <li>Querying of several FRITZ!-devices (FRITZ!Box/Repeater) in one run</li>
    <li>User-definable interval for querying FRITZ!-devices regularly</li>
    <li>Support for manually triggering execution via CUxD SystemExec calls.</li>
    <li>Support for FRITZ!Box/Repeater local network login with and without password</li>
    <li>Possibility to remotely query FRITZ!-devices via https</li>
    <li>Support for querying a dedicated guest-WiFi network</li>
    <li>User device definition based on MAC and/or IP address</li>
    <li>Possibility to define multiple devices per user</li>
    <li>Automatically generates all necessary CCU system variables</li>
    <li>Additional String and Enum system variable to easily display the general presence status at home</li>
    <li>Guest detection based on unknown devices being identified in a dedicated Guest-WiFi</li>
    <li>Guest detection can be applied to the whole WiFi/LAN environment</li>
    <li>Web based configuration pages accessible via CCU-WebUI</li>
    </ul>
    </p>

    <b>Supported CCU models</b>
    <ul>
      <li><a href="https://www.eq-3.de/produkte/homematic/zentralen-und-gateways/smart-home-zentrale-ccu3.html">HomeMatic CCU3</a> / <a href="https://raspberrymatic.de/">RaspberryMatic</a></li>
      <li><a href="https://www.eq-3.de/produkt-detail-zentralen-und-gateways/items/homematic-zentrale-ccu-2.html">HomeMatic CCU2</a></li>
      <li>HomeMatic CCU1</li>
    </ul>

    <b>Supported FRITZ! models</b>
    <ul>
    <li>All models of FRITZ!Box and FRITZ!Repeater running with FRITZ!OS 6 or newer</li>
    </ul>

    <b>Configuration FRITZ! device</b>
    <ol>
      <li>Open the web configuration of the individual FRITZ!-device (e.g. <a href="https://fritz.box/">https://fritz.box/</a>)
      <li>Create a new dedicated user via <i>System->FRITZ!Box-User->Add User</i>
      <ul>
        <li>Restrict access rights of user to <i>FRITZ!Box Settings</i> only
      </ul>
      <li>Open the Homenetwork-Login configuration at <i>System->FRITZ!Box-User->Login to Homenetwork</i>
      <ul>
        <li>Modify login setting to <i>Login with FRITZ!Box-Username and Password</i>
      </ul>
    </ol>

    <b>Installation as CCU Addon</b>
    <ol>
      <li>Download of recent Addon-Release from <a href="https://github.com/jhomematic-community/hm_pdetect/releases">Github</a></li>
      <li>Installation of Addon archive (<code>hm_pdetect-X.X.tar.gz</code>) via WebUI interface of CCU device</li>
      <li>Configuration of FRITZ!Box/Repeater (see next section)</li>
      <li>Configuration of Addon using the WebUI accessible <a href="en.settings.cgi?sid=$sid">config pages</a></li>
    </ol>

    <b>Manual CUxD SystemExec Execution</b>
    <p>
    Instead of automatically calling hm_pdetect on a predefined interval one can also trigger its execution using a CUxD (<a href="https://www.cuxd.de">www.cuxd.de</a>) SystemExec call within HomeMatic scripts on the CCU following the following syntax:<br>

    <p>
    <code>
    dom.GetObject("CUxD.CUX2801001:1.CMD_EXEC").State("/usr/local/addons/hm_pdetect/run.sh &lt;iterations&gt; &lt;waittime&gt; &");
    </code>
    </p>

    Please note the &lt;iterations&gt; and &lt;waittime&gt; which allows to additionally specify how many times hm_pdetect should be executed with a certain amount of wait time in between. One example of such an execution can be:<br><br>

    <p>
    <code>
    dom.GetObject("CUxD.CUX2801001:1.CMD_EXEC").State("/usr/local/addons/hm_pdetect/run.sh 5 2 &");
    </code>
    </p>

    This will execute hm_pdetect for a total amount of 5 times with a waittime of 2 seconds between each execution.
    </p>

    <b>Support</b>
    <p>
    In case of problems/bugs or if you have any feature requests please feel free to open a <a href="https://github.com/homematic-community/hm_pdetect/issues">new ticket</a> at the Github project pages. To seek for help for configuring/using this Addon please use the following german language based fora thread: <a href="http://homematic-forum.de/forum/viewtopic.php?f=18&t=23907">hm_pdetect</a>.
    </p>

    <b>License</b>
    <p>The use and development of this addon is based on version 3 of the LGPL open source license.</p>

    <b>Authors</b>
    <p>Copyright (c) 2015-2023 Jens Maus &lt;mail@jens-maus.de&gt;</p>

    <b>Notice</b>
    <p>
    This Addon uses KnowHow that was developed throughout the following projects:
    <ul>
      <li><a href="https://github.com/jollyjinx/homematic">https://github.com/jollyjinx/homematic</a></li>
      <li><a href="https://github.com/max2play/webinterface">https://github.com/max2play/webinterface</a></li>
    </ul>
    </p>

    </div>
    </div>
    </body>
    </html>
  }]
} else {
  puts "not authenticated"
}
