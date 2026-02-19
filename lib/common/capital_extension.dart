extension CapitalExtension on String {
  String capitalise() {
    if (this.length == 1) {
      return this;
    }

    final capitalised = this.split(' ').map((s) {
      if (s.length == 1) {
        return s;
      }

      return s[0].toUpperCase() + s.substring(1);
    });

    return capitalised.join(' ');
  }
}