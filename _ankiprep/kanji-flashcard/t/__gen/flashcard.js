


  var _yarr = [];
  for (var i in _data.yomi) {
    var y = _data.yomi[i];
    if (y.indexOf('-') == -1) {
      _yarr.push(y);
    }
  }
  _yarr.push("other");

  var _copybtn = document.getElementById("copybtn");

  var _havepic = null;

  function prepare() {
    var pic = new Image;
    pic.src = gif_path("static");
    pic.onload = function() { _havepic = true; populate(); }
    pic.onerror = function() { _havepic = false; populate(); }
  }

  function populate() {
    populate_kanjipic();
    populate_wordlist();
    populate_yomibig();
    populate_yomieigo();
    populate_kjt();
    populate_copybtn();
    populate_heisig();
  }

  function populate_kanjipic() {
    if (_havepic == true) {
      document.getElementById("kanjipic").innerHTML = "<img name='kanjipic' src='" + gif_path("static") + "' width='200' height='200'>";
    }
    else if (_havepic == false) {
      document.getElementById("kanjipic").innerHTML = _data.kanji;
    }
    else {
      alert("bad _havepic value");
    }
  }

  var _word_id = 0;

  function populate_wordlist() {
    for (var i in _yarr) {
      var y = _yarr[i];
      if (sum_word_counts(y) == 0) {
        _data[y].use = false;
      }
    }
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
    for (var i in _yarr) {
      var y = _yarr[i];
      var checkbox = document.getElementById("cb_" + y);
      if (checkbox) {
        checkbox.checked = _data[y].use;
        if (sum_word_counts(y) == 0) {
          checkbox.disabled = true;
        }
      }
    }
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


  function populate_heisig() {
    if (document.images.heisig_pic) {
      if (_data_override == null) {
        document.images.heisig_pic.src = "file:///" + _heisig_dir + "/" + _heisig_png;
      }
      else {
        document.images.heisig_pic.src = "http://127.0.0.1/kanji/heisig/" + _heisig_png;
      }
    }
  }

  function populate_copybtn(str, type) {
    if (_data_override == null) {
      /* being served from File:///, don't show the button */
      return;
    }
    if (str == null) {
      str = "copy";
    }
    if (type == null) {
      type = 0;
    }
    if (type == 0) {
      _copybtn.innerHTML = "<button onclick='server_copy_data();' onfocus='this.blur();'>" + str + "</button>";
    }
    else if (type == 1) {
      _copybtn.innerHTML = "<button onclick='server_copy_data();' onfocus='this.blur();' style='color:blue'><b>" + str + "</b></button>";
    }
    else if (type == -1) {
      _copybtn.innerHTML = "<button onclick='server_copy_data();' onfocus='this.blur();' style='color:red'><b>Error: " + str + "</b></button>";
    }
  }

  function checkbox_clicked(id) {
    var use = document.getElementById(id).checked;
    var y = id.substr(3);
    _data[y].use = use;
    populate_wordlist();
    populate_yomibig();
  }

  const _chunk_size = 512;


  function server_copy_data() {
    _copybtn.disabled = true;
    setTimeout( function() { _copybtn.disabled = false; }, 1000 );

    var url = "http://127.0.0.1/kanji/copy/" + _data.utf16;
    var str = JSON.stringify(_data)
    /* strip quotes around key names where possible */
      .replace(/"use":/g, "use:")
      .replace(/"freq":/g, "freq:")
      .replace(/"words":/g, "words:")
      .replace(/"yomi":/g, "yomi:")
      .replace(/"nanori":/g, "nanori:")
      .replace(/"eigo":/g, "eigo:")
      .replace(/"utf16":/g, "utf16:")
      .replace(/"kanji":/g, "kanji:")
      .replace(/"kjt":/g, "kjt:")
    /* format single and escaped-double quotes to Anki's liking */
      .replace(/'/g, "\\'")
      .replace(/\\"/g, '\\\\\\"');
    var tot = Math.floor(str.length / _chunk_size);
    if (str.length % _chunk_size > 0) {
      tot++;
    }
    server_send_chunked(url, str, 1, tot,
      function(resp) {
        populate_copybtn(resp, resp == "COPIED" ? 1 : -1);
        setTimeout( "populate_copybtn();", 1500 );
      }
    );
  }

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
    else {
      /* on the same domain, can afford to see results */
      http.onreadystatechange = function() {
        if (http.readyState == 4 && http.status == 200) {
          if (cur < tot) {
            var remainder = str.substr(_chunk_size);
            server_send_chunked(url, remainder, cur+1, tot, callback);
          }
          else {
            callback(http.responseText);
          }
        }
      }    
    }

    http.send(null);
  }

  function sum_word_counts(yomi) {
    var sum = 0;
    for (var i in _word_counts[yomi]) {
      sum += _word_counts[yomi][i];
    }
    return sum;
  }

  function format_word_trs(yomi, words, use) {
    if (yomi == "other" && sum_word_counts(yomi) == 0) {
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
      if (!use) {
        expr_css = "expr-gray";
        kana_css = "kana-gray";
        eigo_css = "eigo-gray";
      }
      var mouse_code =
        "onmouseover='word_hover(" + '"' + eigo.replace(/'/g,"&#39;").replace(/"/g,"\\\"")
        + '","' + alts + '",' + _word_id + ");' "
        + "onmouseout='word_hover(" + '"","",' + _word_id + ");'";
      html += "<tr>"
        + "<td class='" + kana_css + "' " + mouse_code + "><nobr>" + format_kana(kana) + "</nobr></td>"
        + "<td class='" + expr_css + "' " + mouse_code + "><nobr>" + expr + "</nobr></td>";
      html += "<td class='controls' rowspan='2'>";
      if (!use || words.length == 0) {
        html += "<img width='16' height='16' src='delete-gray.png'><br>";
        html += "<img width='16' height='16' src='up-gray.png'><br>";
        html += "<img width='16' height='16' src='down-gray.png'><br>";
      }
      else {
        html += "<img width='16' height='16' src='delete.png' onclick='delete_word(" + '"' + yomi + '",' + i + ")' onmouseover='this.style.cursor=" + '"' + "pointer" + '"' + "'><br>";
        if (i == 0) {
          html += "<img width='16' height='16' src='up-gray.png'><br>";
        }
        else {
          html += "<img width='16' height='16' src='up.png' onclick='move_word(" + '"' + yomi + '",' + i + ",-1)' onmouseover='this.style.cursor=" + '"' + "pointer" + '"' + "'><br>";
        }
        if (i == list.length - 1) {
          html += "<img width='16' height='16' src='down-gray.png'><br>";
        }
        else {
          html += "<img width='16' height='16' src='down.png' onclick='move_word(" + '"' + yomi + '",' + i + ",1)' onmouseover='this.style.cursor=" + '"' + "pointer" + '"' + "'><br>";
        }
      }
      html += "</td>";
      if (i == 0) {
        html += "<td class='yomiinfo' rowspan='" + list.length * 2 + "'>"
          + "<input type='checkbox' onclick='checkbox_clicked(this.id);' id='cb_" + yomi + "'>&nbsp;"
          + format_kana(yomi)
          + format_word_counts(yomi, use) + "</td>";
      }
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

  function format_word_counts(yomi, use) {
    var html = "";
    if (use) {
      html = "<div class='word-counts'>";
    }
    else {
      html = "<div class='word-counts-gray'>";
    }
    for (var i in _word_counts[yomi]) {
      if (i > 0) {
        html += "&nbsp;&nbsp;";
      }
      var wc = _word_counts[yomi][i];
      if (wc > 0 && use) {
        href = "../kanji-wordlists/w" + _data.utf16 + ".html#" + ["ank","pom","mon","edi"][i] + "_" + yomi;
        html += "<a href='" + href + "' target='wordlist'>" + wc + "</a>";
      }
      else {
        html += wc;
      }
    }
    html += "</div>";
    return html;
  }

  function hex(val) {
    ret = Math.round(val).toString(16);
    if (ret.length == 1) {
      ret = "0" + ret;
    }
    return ret;
  }

  function animate_pic() {
    if (_havepic == true) {
      document.getElementById("kanjipic").className = "kanjipic-hover";
      document.images.kanjipic.src = gif_path("fast");
    }
  }
  
  function static_pic() {
    if (_havepic == true) {
      document.getElementById("kanjipic").className = "kanjipic";
      document.images.kanjipic.src = gif_path("static");
    }
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
    document.getElementById("eigo_" + word_id).innerHTML = html;
  }

  function gif_path(type /*'fast' or 'static'*/) {
    var path = "kanji-" + type + "/u" + _data.utf16 + ".gif";
    if (_data_override) {
      return path;
    }
    else {
      return "file:///" + _gifdir + "/" + path;
    }
  }

  function add_word(yomi, expr, kana, eigo, priority, alts) {
    var new_word = [kana, expr, eigo, priority];
    for (var i in _data[yomi].words) {
      var word = _data[yomi].words[i];
      if (word[0] == new_word[0] &&
          word[1] == new_word[1] &&
          word[2] == new_word[2] &&
          word[3] == new_word[3]) {
        return;
      }
    }
    if (alts) {
      new_word.push(alts);
    }
    _data[yomi].words.push(new_word);
    populate_wordlist();
  }

  function delete_word(yomi, i) {
    _data[yomi].words.splice(i, 1);
    populate_wordlist();
  }

  function move_word(yomi, i, ix) {
    var tmp = _data[yomi].words[i];
    _data[yomi].words[i] = _data[yomi].words[i+ix];
    _data[yomi].words[i+ix] = tmp;
    populate_wordlist();
  }