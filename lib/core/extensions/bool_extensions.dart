part of 'extensions.dart';
extension BoolExtensions on bool{
  String sortBy(dynamic title)=> this == true ? "&sort_by_$title=1" : "";
}