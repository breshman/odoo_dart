class UserContext {
  const UserContext({
    this.lang = 'es_PE',
    this.tz = 'America/Lima',
    this.uid = 0,
  });

  final String lang;
  final String tz;
  final int uid;

  Map<String, dynamic> toJson() => {'lang': lang, 'tz': tz, 'uid': uid};
}
