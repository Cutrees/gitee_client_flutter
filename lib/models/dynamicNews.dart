import 'package:json_annotation/json_annotation.dart';

import "user.dart";
import "repo.dart";
import "payload.dart";
part 'dynamicNews.g.dart';

@JsonSerializable()
class DynamicNews {
  DynamicNews();

  @JsonKey(fromJson: _idFromJson)
  String? id;
  String? type;
  User? actor;
  Repo? repo;
  bool? public;
  String? created_at;
  Payload? payload;

  static String? _idFromJson(Object? value) => value?.toString();

  factory DynamicNews.fromJson(Map<String, dynamic> json) =>
      _$DynamicNewsFromJson(json);
  Map<String, dynamic> toJson() => _$DynamicNewsToJson(this);
}
