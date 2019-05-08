
  document.write('<table class="flashcard"><tr><td class="expr" id="expr" onmouseover="replay_start();" onmouseout="replay_stop();"></td><tr><tr><td><table class="kanaeigo" id="kanaeigo"></table></td></tr></table><style type="text/css">body {zoom: 150%;}table.flashcard {border-collapse: collapse;margin-top: 50px;margin-left: auto;margin-right: auto;}table.flashcard td {vertical-align: top;text-align: center;}table.flashcard td.expr {height: 250px;padding-top: 60px;font-family: "MS Mincho";font-size: 38pt;}table.kanaeigo {border-collapse: collapse;width: 500px;max-width: 600px;}table.kanaeigo td {vertical-align: middle;}table.kanaeigo td.kana {font-family: "MS PMincho";font-weight: bold;text-align: left;padding-top: 17px;font-size: 15pt;padding-left: 10px;padding-right: 20px;padding-bottom: 0px;border-top: 1px solid #E8E8E8;}table.kanaeigo td.alts {font-family: "MS PMincho";font-size: 12pt;text-align: right;padding-top: 17px;padding-left: 30px;padding-right: 10px;padding-bottom: 0px;border-top: 1px solid #E8E8E8;}table.kanaeigo td.eigo {font-family: "Tahoma";font-size: 9pt;text-align: left;padding-top: 13px;padding-bottom: 18px;color: black;padding-left: 10px;padding-right: 10px;border-bottom: 1px solid #E8E8E8;}span.gray {color: #A2A2A2;}</style>');

  var _timer = setInterval(function() {
    if (/loaded|complete/.test(document.readyState)) {
      populate();
    }
  }, 10);

  try {
    var _data = eval('(' + clean_garbage(data) + ')');
  }
  catch(e) {
    alert('kanji data eval exception: name = [' + e.name  + ']; message = [' + e.message + ']');
  }
  function clean_garbage(str) {
    return str.replace(/&quot;/g,'"').replace(/<span class=".+">/,"").replace('</span>',"");
  }

  /* undecorate() sets these globals */

  var _pr = null;
  var _audio = null;
  var _audio_volume = 600;

  var _mp3list = [];
  var _replaying = false;

  /* main function */

  function populate() {
    if (_timer) {
      clearInterval(_timer);
    }
    document.getElementById("expr").innerHTML = _data.expr;
    var kanaeigo_tr = "";

    for (var i in _data.yomi) {
      var yomi = _data.yomi[i];
      var kana = undecorate(yomi.kana);
      var audio_main_kana = _audio;
      var kana_html = kana;
      if (_pr == false && i > 0) {
        kana_html = gray(kana);
      }

      var kana_audio = [];

      alts_expr = yomi.alts[1].map( function(a) {
        a = undecorate(a);
        if (_audio == true && audio_main_kana) {
          // use this alt expr for audio. mark current kana as 'used'.
          var filename = kana + ' - ' + a + '.mp3';
          _mp3list.push(filename);
          kana_audio.push(kana);
        }
        if (_pr == false) {
          a = gray(a);
        }
        return a;
      });

      alts_kana = yomi.alts[0].map( function(a) {
        a = undecorate(a);
        if (_audio == true) {
          var filename = a + ' - ' + _data.expr + '.mp3';
          _mp3list.push(filename);
        }
        if (_pr == false) {
          a = gray(a);
        }
        return a;
      });

      var alts_html = alts_kana.concat(alts_expr).join('　');

      if (audio_main_kana == true) {
        if (kana_audio.indexOf(kana) == -1) {
          // insert at front of playback list
          var filename = kana + ' - ' + _data.expr + '.mp3';
          _mp3list.splice(0, 0, filename);
        }
      }

      var eigo_html = yomi.eigo;

      kanaeigo_tr +=
        "<tr>" +
          "<td class='kana'>" +
            "<nobr>" + kana_html + "</nobr>" +
          "</td>" +
          "<td class='alts'>" +
            "<nobr>" + alts_html + "</nobr>" +
          "</td>" +
        "</tr>" +
        "<tr>" +
          "<td class='eigo' colspan='2'>" + eigo_html + "</td>" +
        "</tr>";
    }

    document.getElementById("kanaeigo").innerHTML = kanaeigo_tr;

    server_audio_play(_mp3list);
  }

  /* string utility functions */

  function undecorate(str) {
    if (str[0] == '~') {
      str = str.substr(1);
      _pr = false;
    }
    else {
      _pr = true;
    }

    while (str.substr(str.length-1) == '!') {
      str = str.substr(0, str.length-1);
      _audio_volume *= 0.55;
    }

    if (str.substr(str.length-1) == '*') {
      str = str.substr(0, str.length-1);
      _audio = true;
    }
    else {
      _audio = false;
    }
    return str;
  }

  function gray(str) {
    return "<span class='gray'>" + str + "</span>";
  }



  /* audio functions */

  function server_audio_play(mp3list) {
    if (mp3list.length == 0) {
      return;
    }
    var url = "http://127.0.0.1/audio/play/" + Math.round(_audio_volume) + '/' + encodeURIComponent(mp3list[0]);
    var http = new XMLHttpRequest();
    http.open("GET", url, true);
    http.send();
    if (mp3list.length > 1) {
      setTimeout(
        function() { server_audio_play(mp3list.slice(1)); },
        1500 );
    }
  }

  function replay_start() {
    if (_replaying) {
      return;
    }
    _replaying = true;
    document.getElementById("expr").style.backgroundColor = "#F6F6FF";
    replay_looped();
  }

  function replay_looped() {
    if (_replaying) {
      server_audio_play(_mp3list);
      setTimeout( replay_looped, 3000);
    }
  }

  function replay_stop() {
    _replaying = false;
    document.getElementById("expr").style.backgroundColor = "white";
  }
