import 'dart:io';
import 'dart:math';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';

class ConcatPart {
  final String path;
  final double? from;
  final double? take;

  ConcatPart(this.path, {this.from, this.take});
}

class MediaTransformer {
  static String formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) +
        ' ' +
        suffixes[i];
  }
  Future<void> concat(List<ConcatPart> values, void onSuccess(String out)) async {
    Directory tempDir = await getTemporaryDirectory();
    final inputs = values.map((f) {
      List<String> args = [];
      args.add("-i ${f.path}");
      return args.join(" ");
    });
    final int t = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
    String out = "${tempDir.path}/${t}_out.mp4";
    final trims = List.generate(values.length, (index) => index).map((i) {
      final start = "start=${values[i].from ?? 0}";
      final end = values[i].take != null ? ":end=${values[i].take}" : "";
      return "[$i:v]trim=$start$end,setpts=PTS-STARTPTS[v$i]; [$i:a]atrim=$start$end,asetpts=PTS-STARTPTS[a$i]";
    });
    final parts = List.generate(values.length, (index) => index).map((i) => "[v$i][a$i]");
    final filter = ' -filter_complex "${trims.join("; ")}; ${parts.join("")} concat=n=${values.length}:v=1:a=1 [v] [a]" -map "[v]" -map "[a]" -max_muxing_queue_size 4096 $out';
    final cmd = inputs.join(" ") + filter;
    print(cmd);
    await FFmpegKit.executeAsync(cmd, (session) async {
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        onSuccess(out);
      } else if (ReturnCode.isCancel(returnCode)) {
        // CANCEL
      } else {
        throw returnCode.toString();
      }
    });
  }

  Future<void> concatToGif(List<ConcatPart> values, void onSuccess(String out)) async {
    Directory tempDir = await getTemporaryDirectory();
    final inputs = values.map((f) {
      List<String> args = [];
      args.add("-i ${f.path}");
      return args.join(" ");
    });
    final int t = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
    String out = "${tempDir.path}/${t}_out.gif";
    final trims = List.generate(values.length, (index) => index).map((i) {
      final start = "start=${(values[i].from ?? 0).toStringAsFixed(2)}";
      final end = values[i].take != null ? ":end=${values[i].take!.toStringAsFixed(2)}" : "";
      return "[$i:v]trim=$start$end,setpts=PTS-STARTPTS[v$i]";
    });
    final parts = List.generate(values.length, (index) => index).map((i) => "[v$i]");
    final filter = ' -filter_complex "${trims.join("; ")}; ${parts.join("")} concat=n=${values.length}:v=1:a=0 [v]; [v] fps=24,scale=480:-1,split [a][b];[a] palettegen [p];[b][p] paletteuse [r]" -map "[r]" -max_muxing_queue_size 4096 $out';
    final cmd = inputs.join(" ") + filter;
    print(cmd);
    await FFmpegKit.executeAsync(cmd, (session) async {
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        onSuccess(out);
      } else if (ReturnCode.isCancel(returnCode)) {
        // CANCEL
      } else {
        throw returnCode.toString();
      }
    });
  }
}