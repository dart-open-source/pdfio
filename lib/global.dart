


import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';


int any2int(dynamic o){
  try{
    return int.parse(o.toString().split('.').first);
  }catch(e){
    return 0;
  }
}

String int2hex(int n,{int padLeft=8}){
  return n.toRadixString(16).padLeft(padLeft, '0');
}

DateTime timedate([Duration duration]){
  if(duration!=null){
    var isAdd=duration>Duration.zero;
    if(isAdd){
      return DateTime.now().add(duration);
    }else{
      return DateTime.now().subtract(duration);
    }
  }
  return DateTime.now();
}

String timestamp([dynamic duration]){
  if(duration is Duration){
    return timedate(duration).toString();
  }
  if(duration is int){
    return DateTime.fromMicrosecondsSinceEpoch(duration).toString();
  }
  return timedate().toString();
}

DateTime timeparse(String from){
  return DateTime.parse(from);
}
String timeymd([Duration duration]){
  return timedate(duration).toIso8601String().split('T').first;
}

int timeint([Duration duration]){
  return timedate(duration).millisecondsSinceEpoch;
}

Duration timediff([int start,int end]){
  var origin=end??timeint();
  var res=Duration(milliseconds: (origin-start));
  if(res==Duration.zero) return Duration(milliseconds: 1);
  return res;
}

int duration2time(String input) {
  return DateTime.parse('${timeymd()} $input').millisecondsSinceEpoch;
}

String str2md5(String input) {
  return md5.convert(utf8.encode(input)).toString();
}


Future<void> delayed(Duration duration) async {
  await Future.delayed(duration);
}

String fileNameStarReset(String string) {
  for(var i=0;i<20;i++){
    string=string.replaceAll('****', '***');
  }
  return string;
}

String convertBytes(int size){
  var Kb = 1024.0;
  var Mb = Kb * 1024;
  var Gb = Mb * 1024;
  var Tb = Gb * 1024;
  var Pb = Tb * 1024;
  if (size <Kb) return size.toString() + 'B';
  if (size <Mb) return (size / Kb).toStringAsFixed(2) + 'KB';
  if (size <Gb) return (size/ Mb).toStringAsFixed(2) + 'MB';
  if (size <Tb) return (size / Gb).toStringAsFixed(2) + 'GB';
  if (size <Pb) return (size / Tb).toStringAsFixed(2) + 'TB';
  return (size / Pb).toStringAsFixed(2) + 'PB';
}
