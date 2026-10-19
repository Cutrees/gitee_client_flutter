import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class PhotoViewPage extends StatelessWidget {
  const PhotoViewPage(this.picUrl, {super.key});
  final String? picUrl;

  @override
  Widget build(BuildContext context) {
    final url = picUrl ?? '';
    final uri = Uri.tryParse(url);
    final valid =
        uri != null &&
        ['http', 'https'].contains(uri.scheme) &&
        uri.host.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('查看照片')),
      body: valid
          ? PhotoView(
              imageProvider: NetworkImage(url),
              backgroundDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              loadingBuilder: (context, event) =>
                  const Center(child: CircularProgressIndicator()),
              errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Text('图片加载失败')),
            )
          : const Center(child: Text('暂无图片')),
    );
  }
}
