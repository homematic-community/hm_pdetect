#!/bin/tclsh
source inc/settings.tcl
source inc/session.tcl

puts "Content-Type: text/html; charset=utf-8"
puts ""

if {[info exists sid] && [check_session $sid]} {

  set HM_LOGOUTPUT [loadFile /var/log/hm_pdetect.log]

  puts [subst {
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta http-equiv="Content-Type" content="text/html;charset=utf-8">
      <meta http-equiv="X-UA-Compatible" content="IE=edge">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <meta name="description" content="settings">
      <meta name="author" content="mail@jens-maus.de">
      <meta name="language" content="en, english">
      <meta http-equiv="refresh" content="5" >
      <!-- Bootstrap core CSS -->
      <link href="css/bootstrap.min.css" rel="stylesheet">
      <!-- Custom styles for this template -->
      <link href="css/custombootstrap.css" rel="stylesheet">
      <link href="css/custom.css" rel="stylesheet">
      <title>HM-pdetect Addon</title>
    </head>
    <body  style="zoom: 1; margin-top: 60px;">
    <div class="navbar navbar-default navbar-fixed-top" role="navigation">
      <div class="container">
        <div class="navbar-header">
          <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
            <span class="sr-only">Toggle navigation</span>
             <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </button>
          <a class="navbar-brand" href="en.index.cgi?sid=$sid"  target="_blank"><img src="img/logo.png" alt=""> &nbsp;
     &nbsp;</a>
          </div>
       <div class="collapse navbar-collapse">
          <ul class="nav navbar-nav ">
            <li><a href="en.index.cgi?sid=$sid">About</a></li>
            <li class="active"><a href="en.logoutput.cgi?sid=$sid">Logfile</a></li>
            <li><a href="en.settings.cgi?sid=$sid">Configuration</a></li>
          </ul>
          <ul class="nav navbar-nav navbar-right">
            <li><a href="logoutput.cgi?sid=$sid">Deutsch</a></li>
          </ul>
         </div><!--/.nav-collapse -->
      </div><!-- class="container" -->
    </div><!-- class="navbar ..." -->
    <div class="container center1 col-md-8" id="content">
    <legend>FRITZ!-based Presence Detection - Logfile</legend>
    <div class="well well-s">
    <p>
    Output of last executions:
    </p>
    <p>
    <pre>
$HM_LOGOUTPUT
    </pre>
    </p>
    </div><!--div class="well"-->
    </div><!--div class="container"-->
    </body>
    </html>
  }]
} else {
  puts "not authenticated"
}
