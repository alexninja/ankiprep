# encoding: UTF-8

filename = 'ねんにいちど - 年に一度.mp3'

File.open("filelist.txt","w:UTF-16LE") {|f| 
  f.write "\uFEFF"
  f.puts filename
  f.flush
}

#`d:\\tools\\winrar\\winrar.exe e D:\\Japanese\\dict\\audio\\JDIC_Audio_All_09April2010.zip -n@filelist.tmp -y -scu Shit\\`
`d:\\tools\\winrar\\winrar.exe x D:\\unrartest\\JDIC_Audio_All.rar -n@filelist.tmp -y -scu -ilog Shit\\`


