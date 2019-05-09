  document.write('<table class="flashcard"><tr><td><table class="kakijun"><tr><td class="kanjipic" id="kanjipic" onmouseover="animate_pic();" onmouseout="static_pic();"></td></tr><tr><td class="yomieigo" id="yomieigo" onmouseover="animate_pic();" onmouseout="static_pic();"><div id="yomi" class="yomi"></div><div id="eigo" class="eigo"></div></td></tr></table></td><td class="yomibig-holder"></td><td><table id="wordlist" class="wordlist"></table><table class="footer"><tr><td class="kjt" id="kjt"></td><td class="edit"></td></tr></table></td><td></td></tr></table><style type="text/css">body {zoom: 150%;}table.flashcard {margin-top: 5px;margin-left: auto;margin-right: auto;}table.flashcard td {vertical-align: top;}table.flashcard td.yomibig-holder {width: 350px;}table.kakijun {width: 190px;border-collapse: collapse;}table.kakijun td.kanjipic {zoom: 66.7%;height: 250px;width: 188px;font-family: "EPSON 教科書体Ｍ", "MS PGothic";font-size: 150pt;font-weight: bold;text-align: center;vertical-align: middle;border: 1px solid white;line-height: 80%;}table.kakijun td.kanjipic-hover {zoom: 66.7%;height: 250px;width: 188px;font-family: "MS PMincho";font-size: 130pt;text-align: center;vertical-align: middle;border: 1px dotted #EAEAEA;}table.kakijun td.yomieigo {height: 202px;}table.kakijun td.yomieigo-visible {height: 202px;}table.kakijun td.yomieigo div.yomi {font-family: "MS PMincho";font-size: 9pt;letter-spacing: 1px;padding-left: 25px;padding-right: 25px;padding-top: 25px;color: white;}table.kakijun td.yomieigo span.nanori-heading {font-size: 8pt;padding-right: 8px;color: white;}table.kakijun td.yomieigo div.eigo {font-family: "Georgia";font-size: 10pt;padding-top: 5px;padding-left: 25px;padding-right: 25px;color: white;}table.kakijun td.yomieigo span.on {color: white;}table.kakijun td.yomieigo span.kun {color: white;}table.kakijun td.yomieigo-visible div.yomi {font-family: "MS PMincho";font-size: 9pt;letter-spacing: 1px;padding-left: 25px;padding-right: 25px;padding-top: 25px;}table.kakijun td.yomieigo-visible span.nanori-heading {font-size: 8pt;padding-right: 8px;color: #990000;}table.kakijun td.yomieigo-visible div.eigo {font-family: "Georgia";font-size: 10pt;padding-top: 5px;padding-left: 25px;padding-right: 25px;}table.kakijun p {margin: 0;}table.yomibig {margin-top: 25px;margin-left: 70px;}table.yomibig td.yomibig-td {font-family: "MS PMincho";font-size: 34pt;font-weight: bold;border: none;vertical-align: top;text-align: center;}table.yomibig td.yomibig-td div {padding-bottom: 17px;height: 57px;}table.wordlist {border-collapse: collapse;width: 500px;margin-top: 15px;}table.footer {width: 500px;border-collapse: collapse;font-family: "MS PMincho";font-size: 8pt;margin-top: 17px;}table.footer td {padding-top: 5px;}table.footer td.edit {width: 50px;vertical-align: bottom;text-align: right;}table.footer td.kjt {width: 10px;font-family: "MS PMincho";font-size: 16pt;vertical-align: bottom;text-align: center;}table.footer td.kjt span.small {font-family: "MS PMincho";font-size: 8pt;}table.footer td.kjt span.small-red {font-family: "MS PMincho";font-size: 8pt;color: #A00000;}span.on {color: white;font-weight: bold;}span.kun {color: white;font-weight: bold;}</style>');

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


  var _havepic = null;

  function prepare() {
    var pic = new Image;
    pic.src = gif_path("static");
    pic.onload = function() { _havepic = true; populate(); }
    pic.onerror = function() { _havepic = false; populate(); }
  }

  function populate() {
    if (_timer) {
      clearInterval(_timer);
    }
    populate_kanjipic();
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



  function format_kana(kana) {
    return kana.replace(/\[/g, "<span class='on'>").replace(/\(/g, "<span class='kun'>").replace(/\]/g, "</span>").replace(/\)/g, "</span>");
  }

  function format_onyomibig_color(freq, on_max_freq) {
    return "white";
  }


  function hex(val) {
    ret = Math.round(val).toString(16);
    if (ret.length == 1) {
      ret = "0" + ret;
    }
    return ret;
  }

  function animate_pic() {
  }
  
  function static_pic() {
  }


  function gif_path(type /*'fast' or 'static'*/) {
    var path = "kanji-" + type + "/u" + _data.utf16 + ".gif";
    return "gif/" + path;
  }
