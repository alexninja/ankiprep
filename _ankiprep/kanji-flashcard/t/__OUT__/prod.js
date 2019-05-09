  document.write('<table class="flashcard"><tr><td><table class="kakijun"><tr><td class="kanjipic" id="kanjipic" onmouseover="animate_pic();" onmouseout="static_pic();"></td><td class="kanjipic" id="kanjipic"></td></tr><tr><td class="yomieigo" id="yomieigo" onmouseover="animate_pic();" onmouseout="static_pic();"><div id="yomi" class="yomi"></div><div id="eigo" class="eigo"></div></td></tr></table></td><td class="yomibig-holder"><table class="yomibig"><tr><td id="yomibig-td" class="yomibig-td"></td></tr></table></td><td><table id="wordlist" class="wordlist"></table><table class="footer"><tr><td class="kjt" id="kjt"></td><td class="edit"></td></tr></table></td><td></td></tr></table><style type="text/css">body {zoom: 150%;}table.flashcard {margin-top: 5px;margin-left: auto;margin-right: auto;}table.flashcard td {vertical-align: top;}table.flashcard td.yomibig-holder {width: 350px;}table.kakijun {width: 190px;border-collapse: collapse;}table.kakijun td.kanjipic {zoom: 66.7%;height: 250px;width: 188px;font-family: "EPSON 教科書体Ｍ", "MS PGothic";font-size: 150pt;font-weight: bold;text-align: center;vertical-align: middle;border: 1px solid white;line-height: 80%;}table.kakijun td.kanjipic-hover {zoom: 66.7%;height: 250px;width: 188px;font-family: "MS PMincho";font-size: 130pt;text-align: center;vertical-align: middle;border: 1px dotted #EAEAEA;}table.kakijun td.yomieigo {height: 202px;}table.kakijun td.yomieigo-visible {height: 202px;}table.kakijun td.yomieigo div.yomi {font-family: "MS PMincho";font-size: 9pt;letter-spacing: 1px;padding-left: 25px;padding-right: 25px;padding-top: 25px;color: white;}table.kakijun td.yomieigo span.nanori-heading {font-size: 8pt;padding-right: 8px;color: white;}table.kakijun td.yomieigo div.eigo {font-family: "Georgia";font-size: 10pt;padding-top: 5px;padding-left: 25px;padding-right: 25px;color: white;}table.kakijun td.yomieigo span.on {color: white;}table.kakijun td.yomieigo span.kun {color: white;}table.kakijun td.yomieigo-visible div.yomi {font-family: "MS PMincho";font-size: 9pt;letter-spacing: 1px;padding-left: 25px;padding-right: 25px;padding-top: 25px;}table.kakijun td.yomieigo-visible span.nanori-heading {font-size: 8pt;padding-right: 8px;color: #990000;}table.kakijun td.yomieigo-visible div.eigo {font-family: "Georgia";font-size: 10pt;padding-top: 5px;padding-left: 25px;padding-right: 25px;}table.kakijun p {margin: 0;}table.yomibig {margin-top: 25px;margin-left: 70px;}table.yomibig td.yomibig-td {font-family: "MS PMincho";font-size: 34pt;font-weight: bold;border: none;vertical-align: top;text-align: center;}table.yomibig td.yomibig-td div {padding-bottom: 17px;height: 57px;}table.wordlist {border-collapse: collapse;width: 500px;margin-top: 15px;}table.wordlist p {margin-top: 0px;margin-bottom: 0px;}table.wordlist td.kana {font-family: "MS PMincho";font-size: 13pt;min-width: 100px;vertical-align: middle;text-align: left;padding-left: 7px;padding-right: 45px;padding-top: 17px;padding-bottom: 0;border-top: 1px dotted #E0E0E0;}table.wordlist td.kana-smaller {font-family: "MS PMincho";font-size: 12pt;min-width: 100px;vertical-align: middle;text-align: left;padding-left: 7px;padding-right: 15px;padding-top: 17px;padding-bottom: 0;border-top: 1px dotted #E0E0E0;}table.wordlist td.expr {font-family: "MS PMincho";font-size: 30pt;height: 58px;min-width: 250px;vertical-align: middle;text-align: left;padding-left: 7px;padding-right: 7px;padding-top: 14px;padding-bottom: 0;border-top: 1px dotted #E0E0E0;}table.wordlist td.expr-smaller {font-family: "MS PMincho";font-size: 22pt;height: 58px;min-width: 250px;vertical-align: middle;text-align: left;padding-left: 3px;padding-right: 3px;padding-top: 14px;padding-bottom: 0;border-top: 1px dotted #E0E0E0;}table.wordlist td.eigo {font-family: "Georgia";font-size: 10pt;padding-left: 7px;padding-right: 7px;padding-top: 6px;padding-bottom: 10px;border-bottom: 1px dotted #E0E0E0;}table.wordlist td.eigo-nonp {font-family: "Georgia";font-size: 10pt;padding-left: 7px;padding-right: 7px;padding-top: 6px;padding-bottom: 10px;border-bottom: 1px dotted #E0E0E0;color: #B2B2B2;}table.wordlist td.eigo-gray {font-family: "Georgia";font-size: 10pt;padding-left: 7px;padding-right: 7px;padding-top: 6px;padding-bottom: 10px;border-bottom: 1px dotted #E0E0E0;background-color: #EEEEEE;color: #999999;}table.wordlist td div.alts {font-family: "MS PMincho";font-size: 14pt;color: black;text-align: right;padding-top: 4px;}table.wordlist td div.alts span.gray {color: #A8A8A8;}table.wordlist td.expr span.hide-on {font-size: 28pt;color: white;border: 1px dotted #3366FF;margin-left: 1px;margin-right: 1px;}table.wordlist td.expr-smaller span.hide-on {font-size: 21pt;color: white;border: 1px dotted #3366FF;margin-left: 1px;margin-right: 1px;}table.wordlist td.expr span.hide-kun {font-size: 28pt;color: white;border: 1px dotted #BB0000;margin-left: 1px;margin-right: 1px;}table.wordlist td.expr-smaller span.hide-kun {font-size: 21pt;color: white;border: 1px dotted #BB0000;margin-left: 1px;margin-right: 1px;}table.wordlist td.expr span.hide-gray {font-size: 28pt;color: white;border: 1px dotted #999999;margin-left: 1px;margin-right: 1px;}table.wordlist td.expr-smaller span.hide-gray {font-size: 21pt;color: white;border: 1px dotted #999999;margin-left: 1px;margin-right: 1px;}table.footer {width: 500px;border-collapse: collapse;font-family: "MS PMincho";font-size: 8pt;margin-top: 17px;}table.footer td {padding-top: 5px;}table.footer td.edit {width: 50px;vertical-align: bottom;text-align: right;}table.footer td.kjt {width: 10px;font-family: "MS PMincho";font-size: 16pt;vertical-align: bottom;text-align: center;}table.footer td.kjt span.small {font-family: "MS PMincho";font-size: 8pt;}table.footer td.kjt span.small-red {font-family: "MS PMincho";font-size: 8pt;color: #A00000;}span.on {color: #3366FF;font-weight: bold;}span.kun {color: #BB0000;font-weight: bold;}</style>');

  var _timer = setInterval(function() {
    if (/loaded|complete/.test(document.readyState)) {
      prepare();
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

  var _yarr = [];
  for (var i in _data.yomi) {
    var y = _data.yomi[i];
    if (y.indexOf('-') == -1) {
      _yarr.push(y);
    }
  }
  _yarr.push("other");



  function prepare() {
    populate();
  }

  function populate() {
    if (_timer) {
      clearInterval(_timer);
    }
    populate_wordlist();
    populate_yomibig();
    populate_yomieigo();
    populate_kjt();
  }


  var _word_id = 0;

  function populate_wordlist() {
    var html = "";
    _word_id = 0;
    for (var i in _yarr) {
      var y = _yarr[i];
      var use = _data[y].use;
      if (use == true && "freq" in _data[y] && _data[y].freq == 0) {
        use = false;
      }
      html += format_word_trs(y, _data[y].words, use);
    }
    document.getElementById("wordlist").innerHTML = html;
  }

  function populate_yomibig() {
    var on_max_freq = 0;
    var onarr = [];
    for (var i in _yarr) {
      var y = _yarr[i];
      if (!_data[y].use || y == "other") {
        continue;
      }
      if ("freq" in _data[y]) {
        onarr.push(y);
        if (_data[y].freq > on_max_freq) {
          on_max_freq = _data[y].freq;
        }
      }
    }
    var html = "";
    for (var i in onarr) {
      var y = onarr[i];
      var ycln = y.replace("[","").replace("]","");
      html += "<div><span style='color:" + format_onyomibig_color(_data[y].freq, on_max_freq) + "'>" + ycln + "</span></div>";
    }
    document.getElementById("yomibig-td").innerHTML = html;
  }

  function populate_yomieigo() {
    var html = format_kana(_data.yomi.map( function(y) {return "<nobr>"+y+"</nobr>";} ).join('、<wbr>')) + "<p/>";
    if (_data.nanori.length > 0) {
      html += "<span class='nanori-heading'>名乗り</span>" + _data.nanori.map( function(y) {return "<nobr>"+y+"</nobr>";} ).join('、<wbr>');
    }
    document.getElementById("yomi").innerHTML = html;
    document.getElementById("eigo").innerHTML = _data.eigo;
  }

  function populate_kjt() {
    if ("kjt" in _data) {
      document.getElementById("kjt").innerHTML =
        "<nobr>" + _data.kjt + "<span class='small'> の </span><span class='small-red'>旧字体</span></nobr>";
    }
  }





  const _chunk_size = 512;



  function server_send_chunked(url, str, cur, tot, callback) {
    var chunk = str.substr(0, _chunk_size);
    var http = new XMLHttpRequest();
    http.open("GET", url + "/" + cur + "/" + tot + "/" + encodeURIComponent(chunk), true);

    if (callback == null) {
      /* we're cross-domain so send chunks blind, with a timeout in between */
      if (cur < tot) {
        setTimeout( function() {
            var remainder = str.substr(_chunk_size);
            server_send_chunked(url, remainder, cur+1, tot, null);
        }, 5);
      }
    }

    http.send(null);
  }


  function format_word_trs(yomi, words, use) {
    if (!use) {
      return "";
    }
    var list = words;
    if (list.length == 0) {
      list = [[yomi, "&lt;????&gt;", "", true]];
    }
    var html = "";
    for (var i in list) {
      var kana = list[i][0];
      var expr = list[i][1];
      var eigo = list[i][2];
      var pr = list[i][3];
      var alts = list[i][4] || "";
      var kana_css = "kana";
      var expr_css = "expr";
      var eigo_css = pr ? "eigo" : "eigo-nonp";
      if (expr.length >= 8 && words.length > 0) {
        expr_css = "expr-smaller";
        kana_css = "kana-smaller";
      }
      var brlist = kana.split("").filter( function(c) { return c == '[' || c == '('; } );
      var kn = expr.split("").filter( function(c) { return c == _data.kanji } ).length;
      for (var j = 0; j < kn; j++) {
        if (j < brlist.length) {
          if (brlist[j] == '[') {
            expr = expr.replace(_data.kanji, "<span class='hide-on'>*PLACEHOLDER*</span>");
          }
          else if (brlist[j] == '(') {
            expr = expr.replace(_data.kanji, "<span class='hide-kun'>*PLACEHOLDER*</span>");
          }
        }
        else {
          expr = expr.replace(_data.kanji, "<span class='hide-gray'>*PLACEHOLDER*</span>");
        }
      }
      expr = expr.replace(/\*PLACEHOLDER\*/g, _data.kanji);
      var mouse_code =
        "onmouseover='word_hover(" + '"' + eigo.replace(/'/g,"&#39;").replace(/"/g,"\\\"")
        + '","' + alts + '",' + _word_id + ");' "
        + "onmouseout='word_hover(" + '"","",' + _word_id + ");'";
      html += "<tr>"
        + "<td class='" + kana_css + "' " + mouse_code + "><nobr>" + format_kana(kana) + "</nobr></td>"
        + "<td class='" + expr_css + "' " + mouse_code + "><nobr>" + expr + "</nobr></td>";
      html += "</tr>";
      html += "<tr><td class='" + eigo_css + "' colspan='2' id='eigo_" + _word_id + "' " + mouse_code + "></td></tr>";
      _word_id++;
    }
    return html;
  }

  function format_kana(kana) {
    return kana.replace(/\[/g, "<span class='on'>").replace(/\(/g, "<span class='kun'>").replace(/\]/g, "</span>").replace(/\)/g, "</span>");
  }

  function format_onyomibig_color(freq, on_max_freq) {
    if (freq == 0) {
      return "#DDDDDD";
    }
    var full = { "R": 0, "G": 136, "B": 255 };
    var pale = { "R": 217, "G": 226, "B": 255 };
    var ratio = 1 - freq/on_max_freq;
    if (on_max_freq == 0) {
      ratio = 0;
    }
    var r = full.R + (pale.R - full.R) * ratio;
    var g = full.G + (pale.G - full.G) * ratio;
    var b = full.B + (pale.B - full.B) * ratio;
    return "#" + hex(r) + hex(g) + hex(b);
  }


  function hex(val) {
    ret = Math.round(val).toString(16);
    if (ret.length == 1) {
      ret = "0" + ret;
    }
    return ret;
  }

  function animate_pic() {
    document.getElementById("yomieigo").className = "yomieigo-visible";
  }
  
  function static_pic() {
    document.getElementById("yomieigo").className = "yomieigo";
  }

  function word_hover(eigo, alts, word_id) {
    var html = eigo;
    if (alts != "") {
      html += "<div class='alts'>"
           + alts.replace(';',' ').split(' ').map( function(x) {
               return (x[0] == '~') ? "<span class='gray'>" + x.substr(1) + "</span>" : x;
             }).join('　')
           + "</div>";
    }
    html = html.replace(new RegExp(_data.kanji,'g'), '◇');
    document.getElementById("eigo_" + word_id).innerHTML = html;
  }

  function gif_path(type /*'fast' or 'static'*/) {
    var path = "kanji-" + type + "/u" + _data.utf16 + ".gif";
    return "gif/" + path;
  }
