class Api {
  static const String baseUrl =
      "https://api-litera-production.up.railway.app/api";

  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith("http")) return path;
    if (path.startsWith("/")) {
      return "https://api-litera-production.up.railway.app$path";
    }
    return "https://api-litera-production.up.railway.app/$path";
  }
}